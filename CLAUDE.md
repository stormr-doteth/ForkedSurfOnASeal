# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Dev Commands

This project uses Rojo 7.7.0-rc.1 (managed via Rokit) to sync a Roblox game between filesystem and Studio.

```bash
rojo serve                    # Live-sync to Roblox Studio (connect via Rojo plugin)
rojo build -o build.rbxlx     # Build a place file from source
rojo syncback default.project.json --input surf.rbxl -y  # Extract .rbxl back to filesystem
```

No linting, type-checking, or test tools are configured.

## Architecture

This is **Surf on a Seal** — a multiplayer surf racing game where players ride seal characters down procedurally assembled tracks.

### Custom Character System

Players do NOT use standard Roblox characters for movement. Each player gets a compound Model:

- **SealRoot** — the actual physics root, network-owned by the player
- **SappySeal** — the visual seal model with cosmetics attached
- **Character** — the Roblox character, set to `PlatformStand = true`, hidden, massless, in `VisualCollision` collision group
- **VisualRoot** — welds Character HRP to SappySeal via Motor6D + AlignPosition following SealRoot

The character hierarchy lives at `workspace.[PlayerName]/` (a Model containing all four parts). Access the seal via `player.Character.Parent.SappySeal`.

### Player Data

Player data is materialized as a **live Folder tree** under `ReplicatedStorage.PlayerData.[PlayerName]`. Scripts read/write data by navigating this folder hierarchy — never call DataStore directly. The schema is defined by `PlayerDataTemplate` in `PlayerDataManager/`. DataStore key: `"UserID_" .. userId .. "_V2"`.

Key data paths: `Economy.Coins`, `CareerStats.TotalWins`, `Inventory.Accessory/SealSkins/Trails/Emotes`, `Equipped.SealSkin/Trail/Accessories`, `BattlepassData`, `Miscellaneous.DailyRewardInfo`.

### Networking

All RemoteEvents/BindableEvents are pre-created instances under `ReplicatedStorage.Networking/`, split into `Client/` (server→client) and `Server/` (client→server). Two exceptions create ad-hoc remotes at runtime: `ShutdownScript` and `StickerWheelServer`.

### Core Game Loop (MasterScript)

`ServerScriptService/MasterScript/init.server.luau` runs a `while true` loop:

1. **Build track** — randomly selects weighted segments from `ServerStorage.TrackSegments`, clones and chains them end-to-end in `workspace.CurrentMap`
2. **Intermission** (40s) — picks 3 random modifiers, shows them at 20s, fires `RaceStartEvent` at 10s, teleports stragglers at 5s
3. **Race** (360s) — opens `StartingDoor`, timer accelerates as players finish (`wait(1 / (1 + NumCompletedPlayers))`)
4. **Cleanup** — fires end-game events, resets GameStats, clears CurrentMap, stops all modifiers

Player completion fires `MasterScript.PlayerCompleted` BindableEvent → awards placement coins (different amounts for normal vs pro servers, detected by `game.PlaceId`).

### Cosmetics

Applied via `ReplicatedStorage.HelperModules.ToggleCosmetic` — handles accessories (Motor6D to SealRef), seal skins (SurfaceAppearance swap), and trails. Always targets the SappySeal model. Max 5 accessories enforced server-side in `EquipItem`.

### Modifiers

Seven purchasable round modifiers (Clown, Fart, Gravity, Gubby, InfiniteBoosts, Invulnerability, RainingSeals). Each is a module in `MasterScript/Modifiers/` exporting `{StartModifier, StopModifier}`. Activation flows through `ModifierManager` → `PurchaseItem` BindableEvent → purchase prompt → `ReleaseModiferLock` on completion.

### Economy

`PurchaseHandler` processes Dev Products and GamePasses via `MarketplaceService.ProcessReceipt`. Uses a separate `"PurchaseHistory"` DataStore for idempotency. Featured Shop uses a ticket-based purchase flow through BindableFunctions.

### Time Trials System

A separate sub-place (`timetrials.project.json`, built via `rojo build timetrials.project.json -o timetrials.rbxlx`) providing solo practice runs on individual tracks.

**Key files:**
- `src/TimeTrials/StarterGui/TimeTrialUI.client.luau` — all client UI: track picker, live timer/progress bar, splits panel, loading screen, finish splash, and results screen
- `src/TimeTrials/ServerScriptService/TimeTrialServer.server.luau` — server: track building, timing, PB saving, split tracking

**UI flow:** `picker` → `waiting` (loading overlay) → `racing` (timer + progress bar + splits) → `finish` (FINISH! splash slides in from right, holds ~1.5s) → `results` (PersonalResultsFrame animates in with split breakdown)

**Reuses main game UI:** The time trials client disables several built-in scripts and drives their UI elements directly:
- `RaceFinishScript` (disabled) — we control `FinishFrame` for the finish splash
- `RaceEndMenuScript` (disabled) — we populate `PersonalResultsFrame` / `StatsFrame` with splits data
- `TimerLabelScript` (disabled) — we drive `BuiltInTimerLabel` as a count-up timer
- `ProgressBarScript` (disabled) — we drive pin position from player Z-position

**Important:** Any full-screen frame (like `RaceFinishFrame`, `LoadingOverlay`) must be set `Visible = false` when not actively shown, otherwise it blocks mouse input (camera controls). The loading screen slides off like a curtain (position tween) rather than fading.

**Networking remotes** (under `ReplicatedStorage.Networking`): `SelectTrack`, `ReturnToLobby`, `CancelRun`, `ReadyForCountdown` (client→server); `TrackList`, `StartTimer`, `StopTimer`, `ShowTimeTrialResults`, `UpdateProgessBar`, `SendBestSplits` (server→client); `ReportSplits` (client→server).

## Important Caveats

- **Client scripts are binary .rbxm** — StarterPlayerScripts (SappyControls), StarterCharacterScripts, and all StarterGui screens are NOT editable as text. Only server and ReplicatedStorage `.luau` files are source-editable.
- **Rojo syncback requires unique sibling names** — duplicate instance names under the same parent will fail syncback. Rename duplicates in Studio first.
- **Avatar type must be R6** — the game requires R6 avatar type set in Game Settings (not carried by Rojo).
- **Studio API access required** — enable "Allow HTTP Requests" and "Enable Studio Access to API Services" in Game Settings > Security for DataStore to work in Studio testing.
- **Dev IDs** — userIds `1170122` and `3401001` get free modifier activation. Usernames `stormcell` and `skill24` have admin shutdown access.
