
-- Constants --

local ChangeSettingEvent = game.ReplicatedStorage.Networking.Server.RemoteEvents.ChangeSetting


-- Event Functions --

ChangeSettingEvent.OnServerEvent:Connect(function(RequestingPlayer, SettingName, NewValue)
	
	-- Find their PlayerData
	local PlayerData = game.ReplicatedStorage.PlayerData:FindFirstChild(RequestingPlayer.Name)
	if not PlayerData then
		return
	end
	
	-- Make sure the setting they're trying to change exists
	if not PlayerData.Settings:FindFirstChild(SettingName) then
		return
	end
	
	-- Change their settings
	PlayerData.Settings[SettingName].Value = NewValue
	
end)