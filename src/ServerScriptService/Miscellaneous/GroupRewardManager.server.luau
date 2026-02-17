
-- Event Functions --

game.Players.PlayerAdded:Connect(function(NewPlayer)
	
	local PlayerData = game.ReplicatedStorage.PlayerData:WaitForChild(NewPlayer.Name, 60)
	
	if not PlayerData then
		return
	end
	
	if PlayerData.Inventory.Accessory:FindFirstChild("SappyFriend") then
		return
	end
	
	if not NewPlayer:IsInGroup(35583238) then
		return
	end
	
	local NewMarker = Instance.new("StringValue")
	NewMarker.Name = "SappyFriend"
	NewMarker.Parent = PlayerData.Inventory.Accessory
	
	game.ReplicatedStorage.Networking.Client.RemoteEvents.ShowNewItem:FireClient(NewPlayer, "SappyFriend", nil, true)
	
end)

