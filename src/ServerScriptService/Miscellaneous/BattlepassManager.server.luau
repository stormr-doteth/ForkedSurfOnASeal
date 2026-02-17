
-- Notes --

--[[ 

	hi future stormcell/skilly, if you want to change the current battle pass, well you're in luck! I know how still
	it's hardcoded in, so you're gonna have to change "Battlepass_1" in BattlepassFrameScript, BattlepassPool, BattlepassManager, and PurchaseHandler
	have fun!

]]


-- Constants --

local AnalyticsService = game:GetService("AnalyticsService")

local ItemDirectory = require(game.ReplicatedStorage.Directories.ItemDirectory)
local BattlepassPool = require(game.ReplicatedStorage.Directories.BattlepassPool)

local BuyBattlepassTierEvent = game.ReplicatedStorage.Networking.Server.RemoteEvents.BuyBattlepassTier


-- Settings --

local CurrentBattlepass = "Battlepass_1"
local CoinPrice = 500


-- Event Functions --

BuyBattlepassTierEvent.OnServerEvent:Connect(function(RequestingPlayer, CurrencyType)
	
	-- Check for their PlayerData
	local PlayerData = game.ReplicatedStorage.PlayerData:FindFirstChild(RequestingPlayer.Name)
	if not PlayerData then
		return
	end
	
	-- Make sure they have enough coins
	if PlayerData.Economy.Coins.Value < CoinPrice then
		return
	end
	
	-- Get their current tier and make sure there is a tier for them to buy into
	local CurrentTier = PlayerData.BattlepassData[CurrentBattlepass].CurrentTier.Value
	if not BattlepassPool[CurrentTier + 1] then
		return
	end
	
	-- Take their money
	PlayerData.Economy.Coins.Value = PlayerData.Economy.Coins.Value - CoinPrice
	
	-- Analytics pl0x
	AnalyticsService:LogEconomyEvent(
		RequestingPlayer,
		Enum.AnalyticsEconomyFlowType.Sink,
		"Coins",
		CoinPrice, -- Amount spent
		PlayerData.Economy.Coins.Value, -- Current balance
		Enum.AnalyticsEconomyTransactionType.Shop.Name, -- Transaction type
		"Battlepass Tier Purchase"
	)
	
	-- Increment their CurrentTier value
	PlayerData.BattlepassData[CurrentBattlepass].CurrentTier.Value = PlayerData.BattlepassData[CurrentBattlepass].CurrentTier.Value + 1
	
	-- Get the name of the free item for this new tier
	local FreeItemName = BattlepassPool[CurrentTier + 1].FreeTrack
	
	if not PlayerData.Inventory[ItemDirectory[FreeItemName].ItemType]:FindFirstChild(FreeItemName) then
		
		
		-- Add free track item to player's inventory
		local NewItemMarker = Instance.new("StringValue")
		NewItemMarker.Name = FreeItemName
		NewItemMarker.Parent = PlayerData.Inventory[ItemDirectory[FreeItemName].ItemType]
		
		game.ReplicatedStorage.Networking.Client.RemoteEvents.ShowNewItem:FireClient(RequestingPlayer, FreeItemName, nil, true)
		
	end
	
	-- If they have the gold track unlocked, give them that item too
	if PlayerData.BattlepassData[CurrentBattlepass].GoldTrackUnlocked.Value then
		local GoldItemName = BattlepassPool[CurrentTier + 1].GoldTrack
		if not PlayerData.Inventory[ItemDirectory[GoldItemName].ItemType]:FindFirstChild(GoldItemName) then
			
			local NewItemMarker = Instance.new("StringValue")
			NewItemMarker.Name = GoldItemName
			NewItemMarker.Parent = PlayerData.Inventory[ItemDirectory[GoldItemName].ItemType]
			
			game.ReplicatedStorage.Networking.Client.RemoteEvents.ShowNewItem:FireClient(RequestingPlayer, GoldItemName, nil, true)
			
		end
	end
	
end)
