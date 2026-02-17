
-- Constants --

local PurchaseEvent = game.ReplicatedStorage.Networking.Server.BindableEvents.PurchaseItem
local SendNotificationEvent = game.ReplicatedStorage.Networking.Client.RemoteEvents.SendNotification

local ModifierDirectory = require(game.ReplicatedStorage.Directories.ModifierDirectory)

local ReleaseEvent = game.ReplicatedStorage.Networking.Server.BindableEvents.ReleaseModiferLock
local ModifierRequestEvent = game.ReplicatedStorage.Networking.Server.RemoteEvents.ModifierRequestEvent

local LockedModifierInfoEvent = game.ReplicatedStorage.Networking.Client.RemoteEvents.LockedModifierInfoEvent
local PlayerFinishedPurchaseEvent = game.ReplicatedStorage.Networking.Server.BindableEvents.PlayerFinishedPurchaseEvent


-- Variables --

local LockedModifiers = {}
local PlayerDebounces = {}


-- Functions --

local function SendLockedModifierInfo()
	LockedModifierInfoEvent:FireAllClients(LockedModifiers)
end


-- Event Functions --

ModifierRequestEvent.OnServerEvent:Connect(function(RequestingPlayer, ModifierName)
	
	-- Make sure they aren't on cooldown
	if PlayerDebounces[RequestingPlayer] then
		return
	end
	
	-- Make sure it is not already locked
	if LockedModifiers[ModifierName] then
		return
	end
	
	-- Lock that modifier
	LockedModifiers[ModifierName] = true
	
	-- Make sure all the clients know what modifiers are locked
	SendLockedModifierInfo()
	
	if RequestingPlayer.UserId == 1170122 or RequestingPlayer.UserId == 3401001 then
		require(game.ServerScriptService.MasterScript.Modifiers[ModifierName]).StartModifier()
		SendNotificationEvent:FireAllClients(RequestingPlayer.DisplayName .. " has activated " .. string.upper(ModifierDirectory[ModifierName].FlavorText) .. "!", Color3.fromRGB(255, 230, 44))
		return
	end
	
	-- Prompt the player to purchase the modifier
	PurchaseEvent:Fire(RequestingPlayer, ModifierName)
	
	-- Debounce this player since purchase prompts can only be sent so fast
	PlayerDebounces[RequestingPlayer] = true
	
end)

PlayerFinishedPurchaseEvent.Event:Connect(function(Player)
	PlayerDebounces[Player] = nil
end)

-- Used by MasterScript & PurchaseHandler to reset either all locked modifiers or just one
ReleaseEvent.Event:Connect(function(ModifierName)
	if ModifierName then
		LockedModifiers[ModifierName] = nil
	else
		LockedModifiers = {}
	end
	SendLockedModifierInfo()
end)