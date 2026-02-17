
-- Constants --

local AnalyticsService = game:GetService("AnalyticsService")

local TimedGiftFolder = game.ReplicatedStorage.GameStats.TimedGifts
local ClaimEvent = game.ReplicatedStorage.Networking.Server.RemoteEvents.ClaimTimedGift
local ShowNewItemEvent = game.ReplicatedStorage.Networking.Client.RemoteEvents.ShowNewItem


-- Settings --

local GiftRewards = {
	Gift1 = 60,
	Gift2 = 80,
	Gift3 = 100,
	Gift4 = 150,
	Gift5 = 200,
	Gift6 = 250,
	Gift7 = 300,
	Gift8 = 400,
	Gift9 = 500,
}

local GiftNums = { -- Used for AnalyticsService
	Gift1 = 3,
	Gift2 = 4,
	Gift3 = 5,
	Gift4 = 6,
	Gift5 = 7,
	Gift6 = 8,
	Gift7 = 9,
	Gift8 = 10,
	Gift9 = 11,
}



-- Event Functions --

game.Players.PlayerAdded:Connect(function(NewPlayer)
	local NewFolder = script.TimedGiftDataTemplate:Clone()
	NewFolder.Name = NewPlayer.Name
	NewFolder.Parent = TimedGiftFolder
end)

game.Players.PlayerRemoving:Connect(function(RemovingPlayer)
	local FolderToRemove = TimedGiftFolder:FindFirstChild(RemovingPlayer.Name)
	if FolderToRemove then
		FolderToRemove:Destroy()
	end
end)

ClaimEvent.OnServerEvent:Connect(function(RequestingPlayer, GiftName)
	
	local PlayerTimedGiftFolder = TimedGiftFolder:FindFirstChild(RequestingPlayer.Name)
	if not PlayerTimedGiftFolder then
		return
	end
	
	if PlayerTimedGiftFolder[GiftName].Value ~= 0 then
		return
	end
	
	local PlayerData = game.ReplicatedStorage.PlayerData:FindFirstChild(RequestingPlayer.Name)
	if not PlayerData then
		return
	end
	
	local AmountIncrease = GiftRewards[GiftName]
	
	PlayerData.Economy.Coins.Value = PlayerData.Economy.Coins.Value + AmountIncrease
	PlayerData.CareerStats.TotalCoinsCollected.Value = PlayerData.CareerStats.TotalCoinsCollected.Value + AmountIncrease
	
	-- Log how many coins they got
	AnalyticsService:LogEconomyEvent(
		RequestingPlayer,
		Enum.AnalyticsEconomyFlowType.Source,
		"Coins",
		AmountIncrease, -- Amount earned
		PlayerData.Economy.Coins.Value, -- Current balance
		Enum.AnalyticsEconomyTransactionType.TimedReward.Name, -- Transaction type
		"Timed Gifts"
	)
	
	game.ReplicatedStorage.Networking.Server.BindableEvents.RecordAnalytic:Fire(RequestingPlayer, "Gift Depth", GiftNums[GiftName])
	
	ShowNewItemEvent:FireClient(RequestingPlayer, "Coins", GiftRewards[GiftName] .. " COINS")
	
end)


-- Loops --

while true do
	
	for _, PlayerTimedGiftFolder in pairs (TimedGiftFolder:GetChildren()) do
		for _, TimedGiftData in pairs (PlayerTimedGiftFolder:GetChildren()) do
			TimedGiftData.Value = math.clamp(TimedGiftData.Value - 1, 0, 99999999)
		end
	end
	
	wait(1)
	
end