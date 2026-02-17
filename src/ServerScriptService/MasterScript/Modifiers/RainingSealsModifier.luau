
-- Constants --

local TriggerEvent = game.ReplicatedStorage.Networking.Client.RemoteEvents.StartModifier
local ListModifierEvent = game.ReplicatedStorage.Networking.Client.RemoteEvents.ListModifierEvent
local Modifier = {}


-- Variables --

local ModifierOn = false


-- Module Functions --

Modifier.StartModifier = function()
	
	-- Make sure this modifier isn't already on
	if ModifierOn then
		return
	end
	
	TriggerEvent:FireAllClients("RainingSeals", true)
	
	ModifierOn = true
	
	ListModifierEvent:FireAllClients(script.Name)
	
end

Modifier.StopModifier = function()
	
	-- Make sure this modifier isn't already off
	if not ModifierOn then
		return
	end
	
	TriggerEvent:FireAllClients("RainingSeals", false)
	
	ModifierOn = false
	
end


-- Setup --

return Modifier