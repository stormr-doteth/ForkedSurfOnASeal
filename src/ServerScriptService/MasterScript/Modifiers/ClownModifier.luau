
-- Constants --

local ListModifierEvent = game.ReplicatedStorage.Networking.Client.RemoteEvents.ListModifierEvent
local Modifier = {}
local ToggleCosmetic = require(game.ReplicatedStorage.HelperModules.ToggleCosmetic)


-- Variables --

local ModifierOn = false


-- Module Functions --

Modifier.StartModifier = function()
	
	-- Make sure this modifier isn't already on
	if ModifierOn then
		return
	end
	
	for _, Player in pairs (game.Players:GetPlayers()) do
		if Player.Character then
			if Player.Character.Parent:FindFirstChild("SappySeal") then
				ToggleCosmetic(Player.Character.Parent.SappySeal, "ClownNose")
			end
		end
	end
	
	ModifierOn = true
	
	ListModifierEvent:FireAllClients(script.Name)
	
end

Modifier.StopModifier = function()
	
	-- Make sure this modifier isn't already off
	if not ModifierOn then
		return
	end
	
	for _, Player in pairs (game.Players:GetPlayers()) do
		if Player.Character then
			if Player.Character.Parent:FindFirstChild("SappySeal") then
				if Player.Character.Parent.SappySeal:FindFirstChild("ClownNose") then
					Player.Character.Parent.SappySeal.ClownNose:Destroy()
				end
			end
		end
	end
	
	ModifierOn = false
	
end


-- Setup --

return Modifier