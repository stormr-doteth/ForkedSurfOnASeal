
-- Constants --

local AnalyticsService = game:GetService("AnalyticsService")

local PlayerDataFolders = game.ReplicatedStorage.PlayerData
local ClaimEvent = game.ReplicatedStorage.Networking.Server.RemoteEvents.ClaimDailyGift
local RequestDataEvent = game.ReplicatedStorage.Networking.Server.RemoteEvents.RequestDailyGiftData
local UpdateDataEvent = game.ReplicatedStorage.Networking.Client.RemoteEvents.UpdateDailyGiftInfo
local ShowNewItemEvent = game.ReplicatedStorage.Networking.Client.RemoteEvents.ShowNewItem


-- Settings --

local DailyRewards = {
	Day1 = {Image = "rbxassetid://138051675185371", RewardName = "75 COINS", RewardValue = 75},
	Day2 = {Image = "rbxassetid://138051675185371", RewardName = "100 COINS", RewardValue = 100},
	Day3 = {Image = "rbxassetid://138051675185371", RewardName = "125 COINS", RewardValue = 125},
	Day4 = {Image = "rbxassetid://138051675185371", RewardName = "150 COINS", RewardValue = 150},
	Day5 = {Image = "rbxassetid://138051675185371", RewardName = "175 COINS", RewardValue = 175},
	Day6 = {Image = "rbxassetid://138051675185371", RewardName = "200 COINS", RewardValue = 200},
	Day7 = {Image = "rbxassetid://138051675185371", RewardName = "350 COINS", RewardValue = 350},
}


-- Functions --

local function GetUnixTimeCentral()
	
	local utcTime = os.time()
	local offset = -6 -- Default to CST (UTC -6)
	
	-- Check if daylight savings is active
	local isDST = os.date("!*t").isdst
	if isDST then
		offset = -5 -- CDT (UTC -5) during daylight savings
	end
	
	-- Convert to Central Time
	return utcTime + (offset * 3600)
	
end

local function GetNextMidnightUnixCT()
	
	local utcTime = os.time()
	
	-- Determine Central Time offset
	local offset = -6 -- Default to CST (UTC -6)
	if os.date("!*t").isdst then
		offset = -5 -- CDT (UTC -5) during daylight savings
	end
	
	-- Convert UTC time to Central Time
	local centralTime = os.date("!*t", utcTime + (offset * 3600))
	
	-- Create a table for the next midnight in Central Time
	local nextMidnightCT = {
		year = centralTime.year,
		month = centralTime.month,
		day = centralTime.day + 1, -- Move to the next day
		hour = 0,
		min = 0,
		sec = 0,
		isdst = centralTime.isdst -- Preserve daylight savings flag
	}
	
	-- Get Unix timestamp for next midnight in Central Time
	return os.time(nextMidnightCT)
end

local function SendInfo(Player)
	
	local PlayerData = PlayerDataFolders:FindFirstChild(Player.Name)
	if not PlayerData then
		return
	end
	
	local CurrentDay = PlayerData.Miscellaneous.DailyRewardInfo.CurrentDay.Value
	
	local ModifiedTable = {}
	for DayName, DayInfo in pairs (DailyRewards) do
		
		ModifiedTable[DayName] = {}
		
		local DayNum = string.gsub(DayName, "Day", "")
		local DayInt = tonumber(DayNum)
		
		--if CurrentDay > DayInt then
			ModifiedTable[DayName].Image = DayInfo.Image
			ModifiedTable[DayName].RewardName = DayInfo.RewardName
			ModifiedTable[DayName].Claimed = PlayerData.Miscellaneous.DailyRewardInfo.DayClaims[DayName .. "Claimed"].Value
		--[[elseif CurrentDay == DayInt and PlayerData.Miscellaneous.DailyRewardInfo.NextClaim.Value <= GetUnixTimeCentral() then
			ModifiedTable[DayName].Image = DayInfo.Image
			ModifiedTable[DayName].RewardName = DayInfo.RewardName
			ModifiedTable[DayName].Claimed = PlayerData.Miscellaneous.DailyRewardInfo.DayClaims[DayName .. "Claimed"].Value
		else
			ModifiedTable[DayName].Image = UnknownImage
			ModifiedTable[DayName].RewardName = "???"
			ModifiedTable[DayName].Claimed = PlayerData.Miscellaneous.DailyRewardInfo.DayClaims[DayName .. "Claimed"].Value
		end]]
		
	end
	
	UpdateDataEvent:FireClient(Player, ModifiedTable)
	
end


-- Event Functions --

ClaimEvent.OnServerEvent:Connect(function(RequestingPlayer, DayName)
	
	local PlayerData = PlayerDataFolders:FindFirstChild(RequestingPlayer.Name)
	if not PlayerData then
		return
	end
	
	if PlayerData.Miscellaneous.DailyRewardInfo.NextClaim.Value > GetUnixTimeCentral() then
		return
	end
	
	local CurrentDay = PlayerData.Miscellaneous.DailyRewardInfo.CurrentDay.Value
	local AmountIncrease = DailyRewards["Day" .. CurrentDay].RewardValue
	
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
		"Daily Rewards"
	)
	
	local WeekID = PlayerData.Miscellaneous.DailyRewardInfo.WeekID.Value
	game.ReplicatedStorage.Networking.Server.BindableEvents.RecordAnalytic:Fire(RequestingPlayer, "Daily Depth", CurrentDay + 1, WeekID)
	
	PlayerData.Miscellaneous.DailyRewardInfo.NextClaim.Value = GetNextMidnightUnixCT()
	
	if CurrentDay < 7 then
		PlayerData.Miscellaneous.DailyRewardInfo.CurrentDay.Value = CurrentDay + 1
		PlayerData.Miscellaneous.DailyRewardInfo.DayClaims["Day" .. CurrentDay .. "Claimed"].Value = true
	else
		PlayerData.Miscellaneous.DailyRewardInfo.CurrentDay.Value = 1
		PlayerData.Miscellaneous.DailyRewardInfo.WeekID.Value = PlayerData.Miscellaneous.DailyRewardInfo.WeekID.Value + 1
		for _, DayValue in pairs (PlayerData.Miscellaneous.DailyRewardInfo.DayClaims:GetChildren()) do
			DayValue.Value = false
		end
	end
	
	ShowNewItemEvent:FireClient(RequestingPlayer, "Coins", DailyRewards["Day" .. CurrentDay].RewardName)
	
	SendInfo(RequestingPlayer)
	
end)


-- Events --

RequestDataEvent.OnServerEvent:Connect(SendInfo)