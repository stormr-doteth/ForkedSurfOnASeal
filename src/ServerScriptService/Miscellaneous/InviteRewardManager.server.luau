
-- Settings --

local RewardItemName = "MiniSeal"


-- Event Functions --

game.Players.PlayerAdded:Connect(function(NewPlayer)
	
	local JoinData = NewPlayer:GetJoinData()
	local ReferredUserID = JoinData.ReferredByPlayerId
	
	if not ReferredUserID then
		return
	end
	
	local ReferredPlayer = game.Players:GetPlayerByUserId(ReferredUserID)
	
	if not ReferredPlayer then
		return
	end
	
	local PlayerData = game.ReplicatedStorage.PlayerData:FindFirstChild(ReferredPlayer.Name)
	if not PlayerData then
		return
	end
	
	if PlayerData.Inventory.Accessory:FindFirstChild(RewardItemName) then
		return
	end
	
	local NewItemMarker = Instance.new("StringValue")
	NewItemMarker.Name = RewardItemName
	NewItemMarker.Parent = PlayerData.Inventory.Accessory
	
	-- Increment their cosmetics owned
	PlayerData.CareerStats.TotalCosmeticsOwned.Value = PlayerData.CareerStats.TotalCosmeticsOwned.Value + 1
	
	game.ReplicatedStorage.Networking.Client.RemoteEvents.ShowNewItem:FireClient(ReferredPlayer, RewardItemName, true)
	--game.ReplicatedStorage.Networking.Client.RemoteEvents.SendNotification:FireClient(ReferredPlayer, "Your invited friend joined the game, here's your prize!", Color3.fromRGB(255, 255, 127))
	
	--print(ReferredPlayer.Name .. " sucessfully invited " .. NewPlayer.Name .. " to the game!")
	
end)