
-- Constants --

local DontShowEvent = game.ReplicatedStorage.Networking.Server.RemoteEvents.DontShowPlushiePrompt


-- Event Functions --

DontShowEvent.OnServerEvent:Connect(function(RequestingPlayer)
	
	-- Find their PlayerData
	local PlayerData = game.ReplicatedStorage.PlayerData:FindFirstChild(RequestingPlayer.Name)
	if not PlayerData then
		return
	end
	
	-- Change the value
	PlayerData.DataFlags.DontShowPlushiePrompt.Value = true
	
end)