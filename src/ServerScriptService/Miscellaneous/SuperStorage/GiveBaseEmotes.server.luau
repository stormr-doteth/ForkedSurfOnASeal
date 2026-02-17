
-- Event Functions --

game.ReplicatedStorage.PlayerData.ChildAdded:Connect(function(NewPlayerData)
	
	local AssociatedPlayer = game.Players:FindFirstChild(NewPlayerData.Name)
	
	if not AssociatedPlayer or NewPlayerData.Inventory.Emotes:FindFirstChild("EmoteWave") then
		return
	end
	
	local NewMarker = Instance.new("StringValue")
	NewMarker.Name = "EmoteWave"
	NewMarker.Parent = NewPlayerData.Inventory.Emotes
	
	local NewMarker = Instance.new("StringValue")
	NewMarker.Name = "EmoteDance"
	NewMarker.Parent = NewPlayerData.Inventory.Emotes
	
	NewPlayerData.Equipped.Emotes.Emote1.Value = "EmoteWave"
	NewPlayerData.Equipped.Emotes.Emote2.Value = "EmoteDance"
	
	game.ReplicatedStorage.Networking.Client.RemoteEvents.ShowNewItem:FireClient(AssociatedPlayer, "EmoteWave", nil, true)
	game.ReplicatedStorage.Networking.Client.RemoteEvents.ShowNewItem:FireClient(AssociatedPlayer, "EmoteDance", nil, true)
	
end)