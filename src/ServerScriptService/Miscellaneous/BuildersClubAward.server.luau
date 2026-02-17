
-- Event Functions --

game.Players.PlayerAdded:Connect(function(NewPlayer)
	if NewPlayer.MembershipType == Enum.MembershipType.Premium then
		
		local PlayerData = game.ReplicatedStorage.PlayerData:WaitForChild(NewPlayer.Name, 60)
		
		if not PlayerData then
			return
		end
		
		if PlayerData.Inventory.Accessory:FindFirstChild("BC_Hard_Hat") then
			return
		end
		
		local NewMarker = Instance.new("StringValue")
		NewMarker.Name = "BC_Hard_Hat"
		NewMarker.Parent = PlayerData.Inventory.Accessory
		
		game.ReplicatedStorage.Networking.Client.RemoteEvents.ShowNewItem:FireClient(NewPlayer, "BC_Hard_Hat", nil, true)
		
	end
end)