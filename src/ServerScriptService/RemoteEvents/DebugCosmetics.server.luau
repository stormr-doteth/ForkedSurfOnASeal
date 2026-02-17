
-- Constants --

local DebugCosmeticsEvent = game.ReplicatedStorage.Networking.Server.RemoteEvents.DebugCosmetic
local ToggleCosmetic = require(game.ReplicatedStorage.HelperModules.ToggleCosmetic)


-- Event Functions --

DebugCosmeticsEvent.OnServerEvent:Connect(function(RequestingPlayer, ItemName)
	if RequestingPlayer.Name == "Stormcell" or RequestingPlayer.Name == "skill24" then
		
		local Character = RequestingPlayer.Character
		if not Character then
			return
		end
		
		local SappySeal = Character.Parent:FindFirstChild("SappySeal")
		if not SappySeal then
			return
		end
		
		ToggleCosmetic(SappySeal, ItemName)
		
	end
end)