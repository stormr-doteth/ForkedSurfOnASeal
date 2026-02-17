
-- Constants --

local AnalyticsService = game:GetService("AnalyticsService")
local PolicyService = game:GetService("PolicyService")
local WeeklyPrizePool = require(game.ReplicatedStorage.Directories.WeeklyPrizePool)()
local ItemDirectory = require(game.ReplicatedStorage.Directories.ItemDirectory)
local PriceDirectory = require(game.ReplicatedStorage.Directories.PriceDirectory)

local UpdateWeeklyPrizesEvent = game.ReplicatedStorage.Networking.Client.RemoteEvents.UpdateWeeklyPrizes
local RequestWeeklyPrizeDataEvent = game.ReplicatedStorage.Networking.Server.RemoteEvents.RequestWeeklyPrizeData
local OpenCrateEvent = game.ReplicatedStorage.Networking.Server.RemoteEvents.OpenWeeklyCrate
local StartCrateOpenEvent = game.ReplicatedStorage.Networking.Client.RemoteEvents.StartCrateOpen

local PurchaseEvent = game.ReplicatedStorage.Networking.Server.BindableEvents.PurchaseItem
local ProcessWeeklyPrizeTicket = game.ReplicatedStorage.Networking.Server.BindableFunctions.ProcessWeeklyPrizeTicket

local ChestNotificationEvent = game.ReplicatedStorage.Networking.Client.RemoteEvents.ChestNotification


-- Variables --

local PriceCache = {} -- forgive me
local NotifiationCooldowns = {}


-- Settings --

local CoinPriceTable = {
	["11_ItemsRemaining"] = 0, -- FREE, IMMEDIATE GRATIFICATION
	["10_ItemsRemaining"] = 300,
	["9_ItemsRemaining"] = 600,
	["8_ItemsRemaining"] = 1000,
	["7_ItemsRemaining"] = 1500,
	["6_ItemsRemaining"] = 2100,
	["5_ItemsRemaining"] = 2800,
	["4_ItemsRemaining"] = 3500,
	["3_ItemsRemaining"] = 4300,
	["2_ItemsRemaining"] = 5400,
	["1_ItemsRemaining"] = 7000,
}

-- Base weight settings for rarities
local BaseWeights = {
	Common = 70,
	Uncommon = 24,
	Rare = 5,
	Legendary = 1,
}

-- Weight multipliers that control how much each rarity's probability increases
-- Higher values = steeper increase in probability
local WeightMultipliers = {
	Common = 3.0,     -- Common items increase most in probability
	Uncommon = 2.0,   -- Uncommon items increase second most
	Rare = 1.5,       -- Rare items increase third most
	Legendary = 1,  -- Legendary items increase least
}

-- Variables --

local CurrentWeeklySeed = 0
local WeeklyPrizes = {}
local OpenTickets = {}
local CurrentCrateSeed = math.random(1, 99999)
local CurrentRobuxPrice = 0


local PolicyReturns = {}


-- Functions --

function DeepCopy(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		copy = {}
		for orig_key, orig_value in next, orig, nil do
			copy[DeepCopy(orig_key)] = DeepCopy(orig_value)
		end
		setmetatable(copy, DeepCopy(getmetatable(orig)))
	else -- number, string, boolean, etc
		copy = orig
	end
	return copy
end

local function RoundToNearestHundredth(num)
	return math.floor(num * 100 + 0.5) / 100
end

local function GetWeeklyNumberCentralTime()

	local utcTime = os.time() -- Get current UTC timestamp
	local dateInfo = os.date("!*t", utcTime) -- Get UTC date details

	-- Determine if we're in Daylight Saving Time (CDT = UTC-5, CST = UTC-6)
	local month, day, wday = dateInfo.month, dateInfo.day, dateInfo.wday
	local isDST = false

	if month > 3 and month < 11 then
		isDST = true -- Always DST between April and October
	elseif month == 3 then
		-- DST starts on the second Sunday of March
		local firstDayWday = os.date("!*t", os.time{year=dateInfo.year, month=3, day=1}).wday
		local secondSunday = 15 - firstDayWday
		isDST = day >= secondSunday
	elseif month == 11 then
		-- DST ends on the first Sunday of November
		local firstDayWday = os.date("!*t", os.time{year=dateInfo.year, month=11, day=1}).wday
		local firstSunday = 8 - firstDayWday
		isDST = day < firstSunday
	end

	local timezoneOffset = isDST and -5 or -6 -- CDT = UTC-5, CST = UTC-6

	-- Convert UTC to Central Time
	local centralTime = utcTime + (timezoneOffset * 3600)
	local centralDateInfo = os.date("!*t", centralTime)

	-- Adjust so weeks start on Sunday
	local weekDay = centralDateInfo.wday -- 1 = Sunday, 2 = Monday, ..., 7 = Saturday
	local weekStartOffset = weekDay - 1
	local adjustedYDay = centralDateInfo.yday - weekStartOffset
	local weekNumber = math.floor((adjustedYDay - 1) / 7) + 1

	-- Generate a deterministic number using the year and week number
	local seed = centralDateInfo.year * 100 + weekNumber
	math.randomseed(seed)

	return math.random(1, 1000000) -- Adjust range as needed

end

local function GetRandomEntries(seed, dataTable, numEntries)

	math.randomseed(seed) -- Set the random seed for deterministic output

	local shuffled = {} -- Table to store shuffled entries
	local usedIndices = {} -- Table to keep track of used indices

	-- Ensure we don't request more entries than available
	local count = math.min(numEntries, #dataTable)

	for i = 1, count do
		local index
		repeat
			index = math.random(1, #dataTable)
		until not usedIndices[index] -- Ensure unique selection

		usedIndices[index] = true
		table.insert(shuffled, dataTable[index])
	end

	return shuffled

end

local function BuildPlayerPrizePool(Player)

	local PlayerData = game.ReplicatedStorage.PlayerData:FindFirstChild(Player.Name)
	if PlayerData then

		local LocalPrizes = DeepCopy(WeeklyPrizes)

		local OwnedTable = {
			Common = 0,
			Uncommon = 0,
			Rare = 0,
			Legendary = 0
		}

		for i, ItemData in pairs (LocalPrizes) do
			if PlayerData.Inventory[ItemDirectory[ItemData.ItemName].ItemType]:FindFirstChild(ItemData.ItemName) then
				OwnedTable[ItemData.Rarity] = OwnedTable[ItemData.Rarity] + 1
				ItemData.Owned = true
			end
		end

		-- Calculate remaining items in each rarity
		local RemainingItems = {
			Common = 5 - OwnedTable.Common,
			Uncommon = 3 - OwnedTable.Uncommon, 
			Rare = 2 - OwnedTable.Rare,
			Legendary = 1 - OwnedTable.Legendary
		}

		-- Calculate total items owned
		local TotalOwnedItems = OwnedTable.Common + OwnedTable.Uncommon + OwnedTable.Rare + OwnedTable.Legendary

		-- Create a copy of base weights for modification
		local ShareTable = {
			Common = BaseWeights.Common,
			Uncommon = BaseWeights.Uncommon,
			Rare = BaseWeights.Rare,
			Legendary = BaseWeights.Legendary,
		}

		-- Apply dynamic weight adjustments based on owned items
		if TotalOwnedItems > 0 then
			for rarity, remaining in pairs(RemainingItems) do
				if remaining > 0 then
					-- Increase weights based on items collected and rarity multiplier
					local boost = TotalOwnedItems * WeightMultipliers[rarity]
					ShareTable[rarity] = BaseWeights[rarity] + boost
				else
					ShareTable[rarity] = 0
				end
			end
		end

		-- Set weights to 0 for rarities with no items left
		if RemainingItems.Common <= 0 then
			ShareTable.Common = 0
		end

		if RemainingItems.Uncommon <= 0 then
			ShareTable.Uncommon = 0
		end

		if RemainingItems.Rare <= 0 then
			ShareTable.Rare = 0
		end

		if RemainingItems.Legendary <= 0 then
			ShareTable.Legendary = 0
		end

		-- Calculate total shares
		local TotalShares = ShareTable.Common + ShareTable.Uncommon + ShareTable.Rare + ShareTable.Legendary

		-- Calculate per-item probabilities
		local CommonChance = 0
		if RemainingItems.Common > 0 then
			CommonChance = (ShareTable.Common / TotalShares) / RemainingItems.Common
		end

		local UncommonChance = 0
		if RemainingItems.Uncommon > 0 then
			UncommonChance = (ShareTable.Uncommon / TotalShares) / RemainingItems.Uncommon
		end

		local RareChance = 0
		if RemainingItems.Rare > 0 then
			RareChance = (ShareTable.Rare / TotalShares) / RemainingItems.Rare
		end

		local LegendaryChance = 0
		if RemainingItems.Legendary > 0 then
			LegendaryChance = (ShareTable.Legendary / TotalShares) / RemainingItems.Legendary
		end

		-- Calculate item chances for display
		local ChanceTable = {
			Common = RoundToNearestHundredth(CommonChance * 100),
			Uncommon = RoundToNearestHundredth(UncommonChance * 100),
			Rare = RoundToNearestHundredth(RareChance * 100),
			Legendary = RoundToNearestHundredth(LegendaryChance * 100),
		}

		local CoinPrice = CoinPriceTable[11 - TotalOwnedItems .. "_ItemsRemaining"] or "null"
		local NextCoinPrice = CoinPriceTable[11 - (TotalOwnedItems + 1) .. "_ItemsRemaining"] or "null"
		
		PriceCache[Player] = CoinPrice

		-- Debug info if needed
		-- print("Player: " .. Player.Name)
		-- print("Total owned: " .. TotalOwnedItems .. " items")
		-- print("Shares: Common=" .. ShareTable.Common .. ", Uncommon=" .. ShareTable.Uncommon .. ", Rare=" .. ShareTable.Rare .. ", Legendary=" .. ShareTable.Legendary)
		-- print("Chances: Common=" .. ChanceTable.Common .. "%, Uncommon=" .. ChanceTable.Uncommon .. "%, Rare=" .. ChanceTable.Rare .. "%, Legendary=" .. ChanceTable.Legendary .. "%")

		return LocalPrizes, ChanceTable, TotalOwnedItems, CoinPrice, ShareTable, NextCoinPrice

	end

end

local function UpdatePrizePool(WeeklySeed)

	WeeklyPrizes = {}

	for i, Value in pairs (GetRandomEntries(WeeklySeed, WeeklyPrizePool.Common, 5)) do
		table.insert(WeeklyPrizes,
			{
				ItemName = Value,
				Rarity = "Common",
				FlavorText = ItemDirectory[Value].FlavorText,
				IconID = ItemDirectory[Value].IconID,
				Owned = false,
			})
	end

	for i, Value in pairs (GetRandomEntries(WeeklySeed, WeeklyPrizePool.Uncommon, 3)) do
		table.insert(WeeklyPrizes,
			{
				ItemName = Value,
				Rarity = "Uncommon",
				FlavorText = ItemDirectory[Value].FlavorText,
				IconID = ItemDirectory[Value].IconID,
				Owned = false,
			})
	end

	for i, Value in pairs (GetRandomEntries(WeeklySeed, WeeklyPrizePool.Rare, 2)) do
		table.insert(WeeklyPrizes,
			{
				ItemName = Value,
				Rarity = "Rare",
				FlavorText = ItemDirectory[Value].FlavorText,
				IconID = ItemDirectory[Value].IconID,
				Owned = false,
			})
	end

	for i, Value in pairs (GetRandomEntries(WeeklySeed, WeeklyPrizePool.Legendary, 1)) do
		table.insert(WeeklyPrizes,
			{ItemName = Value,
				Rarity = "Legendary",
				FlavorText = ItemDirectory[Value].FlavorText,
				IconID = ItemDirectory[Value].IconID,
				Owned = false,
			})
	end

	for _, Player in pairs (game.Players:GetPlayers()) do

		local PlayerPrizePool, ChanceTable, TotalOwnedItems, CoinPrice, ShareTable, NextCoinPrice = BuildPlayerPrizePool(Player)

		UpdateWeeklyPrizesEvent:FireClient(Player, PlayerPrizePool, ChanceTable, TotalOwnedItems, CoinPrice, NextCoinPrice, CurrentRobuxPrice)

	end

end

local function ChooseRandomItem(SharePool, PlayerPrizePool)

	-- Use consistent random seed handling
	math.randomseed(CurrentCrateSeed)
	CurrentCrateSeed = CurrentCrateSeed + 1

	-- Select a rarity based on weights in SharePool
	local ChosenRarity = SharePool[math.random(1, #SharePool)]

	-- Collect all unowned items of the chosen rarity
	local RarityPrizePool = {}
	for i, ItemData in pairs(PlayerPrizePool) do
		if ItemData.Rarity == ChosenRarity and not ItemData.Owned then
			table.insert(RarityPrizePool, ItemData.ItemName)
		end
	end

	-- Choose a random item from the rarity's available items
	local ChosenItem = RarityPrizePool[math.random(1, #RarityPrizePool)]

	return ChosenItem
end


function GetWeeklyUniqueID()
	
	local time = os.time()
	local date = os.date("*t", time)
	
	-- Calculate the week number
	local dayOfYear = date.yday
	local weekNumber = math.floor((dayOfYear - 1) / 7) + 1
	
	-- Create a unique ID using Year + Week
	local uniqueID = date.year .. weekNumber
	
	return uniqueID
	
end

local function OpenCrate(Player, PlayerPrizePool, ShareTable, TotalOwnedItems)
	
	game.ReplicatedStorage.Networking.Server.BindableEvents.RecordAnalytic:Fire(Player, "Shop Depth", 4)
	game.ReplicatedStorage.Networking.Server.BindableEvents.RecordAnalytic:Fire(Player, "Prize Depth", TotalOwnedItems + 2, GetWeeklyUniqueID())
	
	-- Create the weighted pool of rarities based on current ShareTable
	local SharePool = {}
	for RarityName, ShareAmount in pairs(ShareTable) do
		for i = 1, ShareAmount do
			table.insert(SharePool, RarityName)
		end
	end

	-- Debug info about current weights (uncomment if needed)
	-- print("Opening crate for " .. Player.Name)
	-- print("Total rarities in pool: " .. #SharePool)
	-- print("Weights - Common: " .. (ShareTable.Common or 0) .. 
	--       ", Uncommon: " .. (ShareTable.Uncommon or 0) .. 
	--       ", Rare: " .. (ShareTable.Rare or 0) .. 
	--       ", Legendary: " .. (ShareTable.Legendary or 0))

	-- Choose an item based on weighted rarities
	local ChosenItem = ChooseRandomItem(SharePool, PlayerPrizePool)
	local DummyList = {}

	-- Create dummy list for animation
	for i = 1, 41 do
		table.insert(DummyList, ChooseRandomItem(SharePool, PlayerPrizePool))
	end

	-- Add item to player's inventory
	local PlayerData = game.ReplicatedStorage.PlayerData:FindFirstChild(Player.Name)
	local NewItemMarker = Instance.new("StringValue")
	NewItemMarker.Name = ChosenItem
	NewItemMarker.Parent = PlayerData.Inventory[ItemDirectory[ChosenItem].ItemType]
	
	-- Increment their cosmetics owned
	PlayerData.CareerStats.TotalCosmeticsOwned.Value = PlayerData.CareerStats.TotalCosmeticsOwned.Value + 1

	-- Get the rarity of the chosen item (for logging)
	--[[local chosenRarity = ""
	for _, itemData in pairs(PlayerPrizePool) do
		if itemData.ItemName == ChosenItem then
			chosenRarity = itemData.Rarity
			break
		end
	end]]

	-- Optional debug log of what item was awarded
	-- print("Player received " .. chosenRarity .. " item: " .. ChosenItem)

	-- Start crate opening animation on client
	StartCrateOpenEvent:FireClient(Player, ChosenItem, DummyList)

	-- Recalculate prize pool with updated weights after opening
	local PlayerPrizePool, ChanceTable, TotalOwnedItems, CoinPrice, ShareTable, NextCoinPrice = BuildPlayerPrizePool(Player)

	-- Update client with new prize data
	UpdateWeeklyPrizesEvent:FireClient(Player, PlayerPrizePool, ChanceTable, TotalOwnedItems, CoinPrice, NextCoinPrice, CurrentRobuxPrice)
	
	-- Update their CareerStats
	PlayerData.CareerStats.TotalChestsOpened.Value = PlayerData.CareerStats.TotalChestsOpened.Value + 1
	
end


-- Event Functions --

OpenCrateEvent.OnServerEvent:Connect(function(RequestingPlayer, CurrencyType)
	
	-- Get their regional compliance info if it hasn't already been gotten
	if not PolicyReturns[RequestingPlayer] then
		
		local PolicyInfo = nil
		local success = nil
		local Attempts = 0
		
		repeat
			success, PolicyInfo = pcall(function()
				return PolicyService:GetPolicyInfoForPlayerAsync(RequestingPlayer)
			end)
			if not success then
				Attempts = Attempts + 1
				wait(1)
			end
		until success or Attempts >= 10
		
		PolicyReturns[RequestingPlayer] = PolicyInfo
		
	end
	
	-- Check for regional compliance
	if not PolicyReturns[RequestingPlayer] or PolicyReturns[RequestingPlayer].ArePaidRandomItemsRestricted then
		return
	end
	
	-- Make sure their PlayerData exists
	local PlayerData = game.ReplicatedStorage.PlayerData:FindFirstChild(RequestingPlayer.Name)
	if not PlayerData then
		return
	end
	
	-- Get their PlayerPrizePool and ChanceTable for this moment in time
	local PlayerPrizePool, ChanceTable, TotalOwnedItems, CoinPrice, ShareTable, NextCoinPrice = BuildPlayerPrizePool(RequestingPlayer)
	
	-- Don't let them go any further!
	if TotalOwnedItems >= 11 then
		return
	end
	
	if CurrencyType == "Coins" then
		
		-- Make sure they have enough coins
		if PlayerData.Economy.Coins.Value < CoinPrice then
			return
		end
		
		-- Take their coins
		PlayerData.Economy.Coins.Value = PlayerData.Economy.Coins.Value - CoinPrice
		
		AnalyticsService:LogEconomyEvent(
			RequestingPlayer,
			Enum.AnalyticsEconomyFlowType.Sink,
			"Coins",
			CoinPrice, -- Amount spent
			PlayerData.Economy.Coins.Value, -- Current balance
			Enum.AnalyticsEconomyTransactionType.Shop.Name, -- Transaction type
			"Weekly Prize Pull"
		)
		
		-- Open the crate for them
		OpenCrate(RequestingPlayer, PlayerPrizePool, ShareTable, TotalOwnedItems)
		
	else
		
		-- Make sure they don't already have an open ticket
		if OpenTickets[RequestingPlayer] then
			return
		end
		
		-- Log their ticket so we can refer back to it after the purchase decision is made
		OpenTickets[RequestingPlayer] = {PlayerPrizePool = PlayerPrizePool, ShareTable = ShareTable, TotalOwnedItems = TotalOwnedItems}
		
		-- PurchaseHandler stuff goes here
		PurchaseEvent:Fire(RequestingPlayer, "WeeklyPrizePull")
		
	end
	
end)

RequestWeeklyPrizeDataEvent.OnServerEvent:Connect(function(RequestingPlayer)
	local PlayerPrizePool, ChanceTable, TotalOwnedItems, CoinPrice, ShareTable, NextCoinPrice = BuildPlayerPrizePool(RequestingPlayer)
	UpdateWeeklyPrizesEvent:FireClient(RequestingPlayer, PlayerPrizePool, ChanceTable, TotalOwnedItems, CoinPrice, NextCoinPrice, CurrentRobuxPrice)
end)

ProcessWeeklyPrizeTicket.OnInvoke = function(Player, PurchaseStatus)
	if OpenTickets[Player] then
		
		if PurchaseStatus == "Canceled" then
			OpenTickets[Player] = nil
			return
		end
		
		local PlayerPrizePool = OpenTickets[Player].PlayerPrizePool
		local SharePool = OpenTickets[Player].ShareTable
		local TotalOwnedItems = OpenTickets[Player].TotalOwnedItems
		OpenCrate(Player, PlayerPrizePool, SharePool, TotalOwnedItems)
		
		OpenTickets[Player] = nil
		
		return true
		
	else
		return false
	end
end

PriceDirectory.PriceUpdate.Event:Connect(function()
	CurrentRobuxPrice = PriceDirectory:GetPrice("WeeklyPrizePull")
	for _, Player in pairs (game.Players:GetPlayers()) do
		local PlayerPrizePool, ChanceTable, TotalOwnedItems, CoinPrice, ShareTable, NextCoinPrice = BuildPlayerPrizePool(Player)
		UpdateWeeklyPrizesEvent:FireClient(Player, PlayerPrizePool, ChanceTable, TotalOwnedItems, CoinPrice, NextCoinPrice, CurrentRobuxPrice)
	end
end)

-- Manage notifications
game.ReplicatedStorage.PlayerData.ChildAdded:Connect(function(NewChild)
	local Player = game.Players:FindFirstChild(NewChild.Name)
	if Player then
		NewChild.Economy.Coins.Changed:Connect(function(NewValue)
			if NewChild.Settings.ShopPromptEnabled.Value then
				if PriceCache[Player] and NewValue >= PriceCache[Player] and not NotifiationCooldowns[Player] then
					NotifiationCooldowns[Player] = true
					if PriceCache[Player] ~= 0 then
						ChestNotificationEvent:FireClient(Player, "You have enough coins to open a chest!")
					else
						ChestNotificationEvent:FireClient(Player, "You have a FREE chest available!")
					end
					wait(120)
					NotifiationCooldowns[Player] = nil
				end
			end
		end)
	end
end)

game.Players.PlayerRemoving:Connect(function(RemovingPlayer)
	PriceCache[RemovingPlayer] = nil
end)


-- Setup --

CurrentRobuxPrice = PriceDirectory:GetPrice("WeeklyPrizePull")


-- Loops --

while true do
	--pcall(function()
	local WeeklySeed = GetWeeklyNumberCentralTime()
	if CurrentWeeklySeed ~= WeeklySeed then
		CurrentWeeklySeed = WeeklySeed
		UpdatePrizePool(WeeklySeed)
	end
	wait(1)
	--end)
end