
-- Constants --

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
	
	workspace.Gravity = 100
	
	ModifierOn = true
	
	ListModifierEvent:FireAllClients(script.Name)
	
end

Modifier.StopModifier = function()
	
	-- Make sure this modifier isn't already off
	if not ModifierOn then
		return
	end
	
	workspace.Gravity = 196.2
	
	ModifierOn = false
	
end


-- Setup --

return Modifier