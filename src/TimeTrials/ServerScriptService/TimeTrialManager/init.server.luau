
-- TimeTrialManager: Solo time trial experience
-- Players pick a track segment, 10 copies are chained together, and they race for a personal best.

-- Services --

local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

local TeleportCharacter = require(game.ServerScriptService.HelperModules.TeleportCharacter)

-- GameStats (needed by built-in ProgressBarScript and TimerLabelScript) --

local GameStats = Instance.new("Folder")
GameStats.Name = "GameStats"
GameStats.Parent = game.ReplicatedStorage

local RoundTimer = Instance.new("IntValue")
RoundTimer.Name = "RoundTimer"
RoundTimer.Value = 0
RoundTimer.Parent = GameStats

local TimerPrefix = Instance.new("StringValue")
TimerPrefix.Name = "TimerPrefix"
TimerPrefix.Value = ""
TimerPrefix.Parent = GameStats

local TimerMultiplier = Instance.new("IntValue")
TimerMultiplier.Name = "TimerMultiplier"
TimerMultiplier.Value = 1
TimerMultiplier.Parent = GameStats

-- Networking --

local Networking = game.ReplicatedStorage.Networking
local SelectTrackRemote = Networking.Server.RemoteEvents.SelectTrack
local ReturnToLobbyRemote = Networking.Server.RemoteEvents.ReturnToLobby
local CancelRunRemote = Networking.Server.RemoteEvents.CancelRun
local PlayerWinRemote = Networking.Server.RemoteEvents.PlayerWin
local ReadyForCountdownRemote = Networking.Server.RemoteEvents.ReadyForCountdown

local TrackListRemote = Networking.Client.RemoteEvents.TrackList
local StartTimerRemote = Networking.Client.RemoteEvents.StartTimer
local StopTimerRemote = Networking.Client.RemoteEvents.StopTimer
local ShowTimeTrialResultsRemote = Networking.Client.RemoteEvents.ShowTimeTrialResults
local RaceStartEvent = Networking.Client.RemoteEvents.RaceStartEvent
local SendNotificationEvent = Networking.Client.RemoteEvents.SendNotification
local UpdateProgessBar = Networking.Client.RemoteEvents.UpdateProgessBar
local SendBestSplitsRemote = Networking.Client.RemoteEvents.SendBestSplits
local ReportSplitsRemote = Networking.Server.RemoteEvents.ReportSplits


-- Constants --

local SEGMENT_COUNT = 2 -- NOTE: set to 2 for testing (normally 10)
local MAIN_PLACE_ID = 113818546781660 -- Main game place ID


-- State --

local PlayerStates = {} -- { [Player] = { trackName, startTime, running } }
local PlayerReportedSplits = {} -- { [Player] = { split1, split2, ... } }


-- Functions --

local function GetBestSplits(player, trackName)
	local playerData = game.ReplicatedStorage.PlayerData:FindFirstChild(player.Name)
	if not playerData then return {} end
	local careerStats = playerData:FindFirstChild("CareerStats")
	if not careerStats then return {} end
	local splitsFolder = careerStats:FindFirstChild("TimeTrialSplits")
	if not splitsFolder then return {} end
	local trackFolder = splitsFolder:FindFirstChild(trackName)
	if not trackFolder then return {} end

	local splits = {}
	for i = 1, SEGMENT_COUNT do
		local val = trackFolder:FindFirstChild("Split" .. i)
		if val then
			splits[i] = val.Value
		end
	end
	return splits
end

local function SaveBestSplits(player, trackName, splits)
	local playerData = game.ReplicatedStorage.PlayerData:FindFirstChild(player.Name)
	if not playerData then return end
	local careerStats = playerData:FindFirstChild("CareerStats")
	if not careerStats then return end

	local splitsFolder = careerStats:FindFirstChild("TimeTrialSplits")
	if not splitsFolder then
		splitsFolder = Instance.new("Folder")
		splitsFolder.Name = "TimeTrialSplits"
		splitsFolder.Parent = careerStats
	end

	local trackFolder = splitsFolder:FindFirstChild(trackName)
	if not trackFolder then
		trackFolder = Instance.new("Folder")
		trackFolder.Name = trackName
		trackFolder.Parent = splitsFolder
	end

	-- Clear old splits and write new ones
	for _, child in pairs(trackFolder:GetChildren()) do
		child:Destroy()
	end
	for i, splitTime in ipairs(splits) do
		local val = Instance.new("NumberValue")
		val.Name = "Split" .. i
		val.Value = splitTime
		val.Parent = trackFolder
	end
end

local function GetTrackNames()
	local trackNames = {}
	for _, seg in pairs(game.ServerStorage.TrackSegments:GetChildren()) do
		table.insert(trackNames, seg.Name)
	end
	table.sort(trackNames)
	return trackNames
end

local function BuildTimeTrialTrack(segmentName)
	local segment = game.ServerStorage.TrackSegments:FindFirstChild(segmentName)
	if not segment then return false end

	workspace.CurrentMap:ClearAllChildren()

	local LastSegment = workspace.Lobby.StartTrackHere
	local LastTrackEnd = workspace.Lobby.TrackEnd
	local checkpointZPositions = {}

	for i = 1, SEGMENT_COUNT do
		local NewSegment = segment:Clone()
		NewSegment:PivotTo(LastTrackEnd.CFrame)
		NewSegment.TrackStart.Transparency = 1
		NewSegment.TrackEnd.Transparency = 1

		-- Remove checkpoint arch from first segment, disable effects on others
		local arch = NewSegment:FindFirstChild("CheckpointArch")
		if arch then
			if i == 1 then
				arch:Destroy()
			else
				local teleportDest = arch:FindFirstChild("TeleportDestination")
				if teleportDest then
					local effectScript = teleportDest:FindFirstChild("CheckpointEffectScript")
					if effectScript then
						effectScript.Disabled = true
					end
				end
			end
		end

		NewSegment.SegmentNumber.Value = i
		NewSegment.Parent = workspace.CurrentMap

		LastSegment = NewSegment
		LastTrackEnd = NewSegment.TrackEnd
	end

	-- Collect checkpoint Z positions from each segment's TrackEnd (except the last segment)
	local segments = workspace.CurrentMap:GetChildren()
	table.sort(segments, function(a, b) return a.SegmentNumber.Value < b.SegmentNumber.Value end)
	for idx, seg in ipairs(segments) do
		local trackEnd = seg:FindFirstChild("TrackEnd")
		if trackEnd and idx < SEGMENT_COUNT then
			table.insert(checkpointZPositions, trackEnd.Position.Z)
		end
	end

	-- Place end platform at the end
	local NewEndPlatform = game.ServerStorage.EndPlatform:Clone()
	NewEndPlatform:PivotTo(LastSegment.TrackEnd.CFrame)
	NewEndPlatform.Parent = workspace.CurrentMap

	-- Calculate track data for progress bar
	local TrackData = {}
	local TotalDistance = 0
	local startZ = workspace.Lobby.TrackEnd.Position.Z
	local endZ = LastSegment.TrackEnd.Position.Z
	for _, seg in ipairs(workspace.CurrentMap:GetChildren()) do
		local trackStart = seg:FindFirstChild("TrackStart")
		local trackEnd = seg:FindFirstChild("TrackEnd")
		if trackStart and trackEnd then
			local dist = math.abs(trackEnd.Position.Z - trackStart.Position.Z)
			table.insert(TrackData, dist)
			TotalDistance = TotalDistance + dist
		end
	end

	return true, TrackData, TotalDistance, startZ, endZ, checkpointZPositions
end

local function FormatTime(seconds)
	local mins = math.floor(seconds / 60)
	local secs = seconds % 60
	return string.format("%02d:%06.3f", mins, secs)
end

local function HandlePlayerFinish(player)
	local state = PlayerStates[player]
	if not state or not state.running then return end

	state.running = false
	local elapsed = os.clock() - state.startTime

	-- Check personal best
	local playerData = game.ReplicatedStorage.PlayerData:FindFirstChild(player.Name)
	if not playerData then return end

	local careerStats = playerData:FindFirstChild("CareerStats")
	if not careerStats then return end

	local pbFolder = careerStats:FindFirstChild("TimeTrialBests")
	if not pbFolder then
		-- Create it if missing
		pbFolder = Instance.new("Folder")
		pbFolder.Name = "TimeTrialBests"
		pbFolder.Parent = careerStats
	end

	local currentPB = nil
	local isNewPB = false

	local pbValue = pbFolder:FindFirstChild(state.trackName)
	if pbValue then
		currentPB = pbValue.Value
		if elapsed < currentPB then
			pbValue.Value = elapsed
			isNewPB = true
		end
	else
		-- First time completing this track
		local newPB = Instance.new("NumberValue")
		newPB.Name = state.trackName
		newPB.Value = elapsed
		newPB.Parent = pbFolder
		isNewPB = true
		currentPB = nil
	end

	StopTimerRemote:FireClient(player)
	ShowTimeTrialResultsRemote:FireClient(player, elapsed, currentPB, isNewPB, state.trackName)

	if isNewPB then
		SendNotificationEvent:FireClient(player, "NEW PERSONAL BEST! (" .. FormatTime(elapsed) .. ")", Color3.fromRGB(255, 230, 44))

		-- Wait briefly for client to report splits (client fires ReportSplits on receiving results)
		task.spawn(function()
			local trackName = state.trackName
			task.wait(1)
			local reportedSplits = PlayerReportedSplits[player]
			if reportedSplits and #reportedSplits > 0 then
				SaveBestSplits(player, trackName, reportedSplits)
			end
		end)
	end
end


-- Events --

Players.PlayerAdded:Connect(function(player)
	local trackNames = GetTrackNames()

	-- Wait for client to be ready then send track list
	task.delay(3, function()
		TrackListRemote:FireClient(player, trackNames)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	PlayerStates[player] = nil
	PlayerReportedSplits[player] = nil
end)

-- Player reports their split times (client fires this on finish)
ReportSplitsRemote.OnServerEvent:Connect(function(player, splits)
	if type(splits) ~= "table" then return end
	-- Validate: must be an array of numbers, max SEGMENT_COUNT entries
	local validated = {}
	for i = 1, math.min(#splits, SEGMENT_COUNT) do
		if type(splits[i]) == "number" then
			table.insert(validated, splits[i])
		end
	end
	PlayerReportedSplits[player] = validated
end)

-- Player selects a track
SelectTrackRemote.OnServerEvent:Connect(function(player, trackName)
	-- Validate
	if type(trackName) ~= "string" then return end
	if not game.ServerStorage.TrackSegments:FindFirstChild(trackName) then return end

	-- Build the track
	local success, trackData, totalDistance, startZ, endZ, checkpointZPositions = BuildTimeTrialTrack(trackName)
	if not success then return end

	-- Fire progress bar update so client can render segments and track player position
	TimerPrefix.Value = ""
	UpdateProgessBar:FireClient(player, trackData, totalDistance, startZ, endZ, checkpointZPositions)

	-- Send saved best splits for delta comparison
	local bestSplits = GetBestSplits(player, trackName)
	SendBestSplitsRemote:FireClient(player, bestSplits)

	-- Reset boosts to 3
	game.ReplicatedStorage.Networking.Client.RemoteEvents.ResetBoostInventory:FireClient(player)

	-- Close starting door first
	workspace.Lobby.StartingDoor.CanCollide = true
	workspace.Lobby.StartingDoor.Transparency = 0.5

	-- Teleport player to start
	TeleportCharacter(player, workspace.Lobby.StartTrackHere, true)

	-- Mark player as in countdown so cancel can abort it
	PlayerStates[player] = {
		trackName = trackName,
		startTime = nil,
		running = false,
	}

	-- Wait for client loading screen to finish, then start countdown
	task.spawn(function()
		-- Wait for client to signal it's ready for the countdown
		local ready = false
		local conn
		conn = ReadyForCountdownRemote.OnServerEvent:Connect(function(p)
			if p == player then
				ready = true
				conn:Disconnect()
			end
		end)

		-- Timeout after 10s in case client never fires
		local waitStart = os.clock()
		while not ready and (os.clock() - waitStart) < 10 do
			task.wait(0.1)
			if not player.Parent or not PlayerStates[player] then
				conn:Disconnect()
				return
			end
		end
		conn:Disconnect()

		RaceStartEvent:FireClient(player)

		-- Wait 10 seconds to match the client countdown (10, 9, ... 1, then GO appears)
		for i = 1, 10 do
			task.wait(1)
			-- If player cancelled/left during countdown, abort
			if not player.Parent or not PlayerStates[player] then return end
		end

		-- Open starting door and start timer the moment "GO" appears
		workspace.Lobby.StartingDoor.CanCollide = false
		workspace.Lobby.StartingDoor.Transparency = 1

		-- Set state and start timer
		PlayerStates[player] = {
			trackName = trackName,
			startTime = os.clock(),
			running = true,
		}

		StartTimerRemote:FireClient(player)
	end)
end)

-- Player finishes (via PlayerWin remote from client SappyControls)
PlayerWinRemote.OnServerEvent:Connect(function(player)
	HandlePlayerFinish(player)
end)

-- Listen to the local BindableEvent
script.PlayerCompleted.Event:Connect(function(player)
	HandlePlayerFinish(player)
end)

-- Also listen to the MasterScript shim's BindableEvent (EndPlatform fires this one)
game.ServerScriptService.MasterScript.PlayerCompleted.Event:Connect(function(player)
	HandlePlayerFinish(player)
end)

-- Cancel current run and return to track picker
CancelRunRemote.OnServerEvent:Connect(function(player)
	PlayerStates[player] = nil
	StopTimerRemote:FireClient(player)
	workspace.CurrentMap:ClearAllChildren()

	-- Close starting door
	workspace.Lobby.StartingDoor.CanCollide = true
	workspace.Lobby.StartingDoor.Transparency = 0.5

	-- Teleport player back to lobby
	TeleportCharacter(player, workspace.Lobby.StartTrackHere, true)
end)

-- Return to main game
ReturnToLobbyRemote.OnServerEvent:Connect(function(player)
	TeleportService:Teleport(MAIN_PLACE_ID, player)
end)
