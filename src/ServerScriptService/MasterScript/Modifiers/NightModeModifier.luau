
-- Constants --

local ListModifierEvent = game.ReplicatedStorage.Networking.Client.RemoteEvents.ListModifierEvent
local Modifier = {}


-- Variables --

local ModifierOn = false


-- Module Functions --

Modifier.StartModifier = function()

	if ModifierOn then
		return
	end

	game.Lighting.ClockTime = 0

	ModifierOn = true

	ListModifierEvent:FireAllClients(script.Name)

end

Modifier.StopModifier = function()

	if not ModifierOn then
		return
	end

	game.Lighting.ClockTime = 14

	ModifierOn = false

end


-- Setup --

return Modifier