
-- Constants --

local RunService = game:GetService("RunService")
local AnalyticsService = game:GetService("AnalyticsService")
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local ItemDirectory = require(game.ReplicatedStorage.Directories.ItemDirectory)
local BattlepassPool = require(game.ReplicatedStorage.Directories.BattlepassPool)

local PurchaseHistoryStore = DataStoreService:GetDataStore("PurchaseHistory")

local PurchaseEvent = game.ReplicatedStorage.Networking.Server.BindableEvents.PurchaseItem
local PurchaseEventRemote = game.ReplicatedStorage.Networking.Server.RemoteEvents.PurchaseDevProduct
local ProcessFeaturedShopTicketEvent = game.ReplicatedStorage.Networking.Server.BindableFunctions.ProcessFeaturedShopTicket
local ProcessWeeklyPrizeTicket = game.ReplicatedStorage.Networking.Server.BindableFunctions.ProcessWeeklyPrizeTicket
local SendNotificationEvent = game.ReplicatedStorage.Networking.Client.RemoteEvents.SendNotification
local PlayerFinishedPurchaseEvent = game.ReplicatedStorage.Networking.Server.BindableEvents.PlayerFinishedPurchaseEvent

local PriceDirectory = require(game.ReplicatedStorage.Directories.PriceDirectory)


-- Settings --

local Products = {
	
	-- Weekly Prize Pull
	["WeeklyPrizePull"] = {ID = 3226237938, Type = Enum.InfoType.Product},
	
	-- Coin Purchases
	["CoinPurchase_1"] = {ID = 3226222535, Type = Enum.InfoType.Product, AwardAmount = 500},
	["CoinPurchase_2"] = {ID = 3226222628, Type = Enum.InfoType.Product, AwardAmount = 1200},
	["CoinPurchase_3"] = {ID = 3226222771, Type = Enum.InfoType.Product, AwardAmount = 3000},
	["CoinPurchase_4"] = {ID = 3226222888, Type = Enum.InfoType.Product, AwardAmount = 6000},
	["CoinPurchase_5"] = {ID = 3226222969, Type = Enum.InfoType.Product, AwardAmount = 12000},
	
	-- Featured shop rarities
	["FeaturedCommon"] = {ID = 3226221952, Type = Enum.InfoType.Product},
	["FeaturedUncommon"] = {ID = 3226222086, Type = Enum.InfoType.Product},
	["FeaturedRare"] = {ID = 3226222196, Type = Enum.InfoType.Product},
	["FeaturedLegendary"] = {ID = 3226222320, Type = Enum.InfoType.Product},
	
	-- Single item dev products
	["EmoteBounce"] = {ID = 3307335854, Type = Enum.InfoType.Product},
	["EmoteOrangeJustice"] = {ID = 3349487533, Type = Enum.InfoType.Product},
	
	-- GamePasses
	["StarterPack"] = {ID = 1128718679, Type = Enum.InfoType.GamePass},
	["UltimateStarterPack"] = {ID = 1130333021, Type = Enum.InfoType.GamePass},
	["TinyBundle"] = {ID = 1132152805, Type = Enum.InfoType.GamePass},
	["GalaxyBundle"] = {ID = 1240208402, Type = Enum.InfoType.GamePass},
	["BeeBundle"] = {ID = 1268465087, Type = Enum.InfoType.GamePass},
	
	-- Battle pass stuff
	["UnlockGoldTrack"] = {ID = 3268176075, Type = Enum.InfoType.Product},
	["BattlepassTier"] = {ID = 3268171085, Type = Enum.InfoType.Product},
	
	-- Modifiers
	["FartModifier"] = {ID = 3296241000, Type = Enum.InfoType.Product},
	["ClownModifier"] = {ID = 3296229925, Type = Enum.InfoType.Product},
	["GravityModifier"] = {ID = 3296240666, Type = Enum.InfoType.Product},
	
	["InfiniteBoostsModifier"] = {ID = 3297876113, Type = Enum.InfoType.Product},
	["GubbyModifier"] = {ID = 3298635476, Type = Enum.InfoType.Product},
	["RainingSealsModifier"] = {ID = 3300039546, Type = Enum.InfoType.Product},
	["InvulnerabilityModifier"] = {ID = 3316362604, Type = Enum.InfoType.Product},
	
}


local TestingMode = false


-- Variables --

local ProductFunctions = {}
local PreviousPrices = {}


-- Awarding Functions --

ProductFunctions[Products["InvulnerabilityModifier"].ID] = function(player, PurchaseState)
	
	if PurchaseState == "Canceled" then
		game.ReplicatedStorage.Networking.Server.BindableEvents.ReleaseModiferLock:Fire("InvulnerabilityModifier")
		return
	end
	
	require(game.ServerScriptService.MasterScript.Modifiers.InvulnerabilityModifier).StartModifier()
	
	SendNotificationEvent:FireAllClients(player.DisplayName .. " has activated INVULNERABILITY!", Color3.fromRGB(255, 230, 44))
	
	PlayerFinishedPurchaseEvent:Fire(player)
	
	return true
	
end

ProductFunctions[Products["RainingSealsModifier"].ID] = function(player, PurchaseState)
	
	if PurchaseState == "Canceled" then
		game.ReplicatedStorage.Networking.Server.BindableEvents.ReleaseModiferLock:Fire("RainingSealsModifier")
		return
	end
	
	require(game.ServerScriptService.MasterScript.Modifiers.RainingSealsModifier).StartModifier()
	
	SendNotificationEvent:FireAllClients(player.DisplayName .. " has activated RAINING SEALS!", Color3.fromRGB(255, 230, 44))
	
	PlayerFinishedPurchaseEvent:Fire(player)
	
	return true
	
end

ProductFunctions[Products["GubbyModifier"].ID] = function(player, PurchaseState)
	
	if PurchaseState == "Canceled" then
		game.ReplicatedStorage.Networking.Server.BindableEvents.ReleaseModiferLock:Fire("GubbyModifier")
		return
	end
	
	require(game.ServerScriptService.MasterScript.Modifiers.GubbyModifier).StartModifier()
	
	SendNotificationEvent:FireAllClients(player.DisplayName .. " has activated GUBBY MODE!", Color3.fromRGB(255, 230, 44))
	
	PlayerFinishedPurchaseEvent:Fire(player)
	
	return true
	
end

ProductFunctions[Products["InfiniteBoostsModifier"].ID] = function(player, PurchaseState)
	
	if PurchaseState == "Canceled" then
		game.ReplicatedStorage.Networking.Server.BindableEvents.ReleaseModiferLock:Fire("InfiniteBoostsModifier")
		return
	end
	
	require(game.ServerScriptService.MasterScript.Modifiers.InfiniteBoostsModifier).StartModifier()
	
	SendNotificationEvent:FireAllClients(player.DisplayName .. " has activated INFINITE BOOSTS!", Color3.fromRGB(255, 230, 44))
	
	PlayerFinishedPurchaseEvent:Fire(player)
	
	return true
	
end

ProductFunctions[Products["GravityModifier"].ID] = function(player, PurchaseState)
	
	if PurchaseState == "Canceled" then
		game.ReplicatedStorage.Networking.Server.BindableEvents.ReleaseModiferLock:Fire("GravityModifier")
		return
	end
	
	require(game.ServerScriptService.MasterScript.Modifiers.GravityModifier).StartModifier()
	
	SendNotificationEvent:FireAllClients(player.DisplayName .. " has activated LOW GRAVITY!", Color3.fromRGB(255, 230, 44))
	
	PlayerFinishedPurchaseEvent:Fire(player)
	
	return true
	
end

ProductFunctions[Products["ClownModifier"].ID] = function(player, PurchaseState)
	
	if PurchaseState == "Canceled" then
		game.ReplicatedStorage.Networking.Server.BindableEvents.ReleaseModiferLock:Fire("ClownModifier")
		return
	end
	
	require(game.ServerScriptService.MasterScript.Modifiers.ClownModifier).StartModifier()
	
	SendNotificationEvent:FireAllClients(player.DisplayName .. " has activated CLOWN NOSES!", Color3.fromRGB(255, 230, 44))
	
	PlayerFinishedPurchaseEvent:Fire(player)
	
	return true
	
end

ProductFunctions[Products["FartModifier"].ID] = function(player, PurchaseState)
	
	if PurchaseState == "Canceled" then
		game.ReplicatedStorage.Networking.Server.BindableEvents.ReleaseModiferLock:Fire("FartModifier")
		return
	end
	
	require(game.ServerScriptService.MasterScript.Modifiers.FartModifier).StartModifier()
	
	SendNotificationEvent:FireAllClients(player.DisplayName .. " has activated FARTING SEALS!", Color3.fromRGB(255, 230, 44))
	
	PlayerFinishedPurchaseEvent:Fire(player)
	
	return true
	
end

ProductFunctions[Products["BattlepassTier"].ID] = function(player, PurchaseState)
	
	if PurchaseState == "Canceled" then
		return
	end
	
	local PlayerData = game.ReplicatedStorage.PlayerData:FindFirstChild(player.Name)
	if not PlayerData then
		return false
	end
	
	-- Get their current tier and make sure there is a tier for them to buy into
	local CurrentTier = PlayerData.BattlepassData.Battlepass_1.CurrentTier.Value
	if not BattlepassPool[CurrentTier + 1] then
		return false
	end
	
	-- Increment their CurrentTier value
	PlayerData.BattlepassData.Battlepass_1.CurrentTier.Value = PlayerData.BattlepassData.Battlepass_1.CurrentTier.Value + 1
	
	-- Get the name of the free item for this new tier
	local FreeItemName = BattlepassPool[CurrentTier + 1].FreeTrack
	
	if not PlayerData.Inventory[ItemDirectory[FreeItemName].ItemType]:FindFirstChild(FreeItemName) then
		
		-- Add free track item to player's inventory
		local NewItemMarker = Instance.new("StringValue")
		NewItemMarker.Name = FreeItemName
		NewItemMarker.Parent = PlayerData.Inventory[ItemDirectory[FreeItemName].ItemType]
		
		game.ReplicatedStorage.Networking.Client.RemoteEvents.ShowNewItem:FireClient(player, FreeItemName, nil, true)
		
	end
	
	-- If they have the gold track unlocked, give them that item too
	if PlayerData.BattlepassData.Battlepass_1.GoldTrackUnlocked.Value then
		local GoldItemName = BattlepassPool[CurrentTier + 1].GoldTrack
		if not PlayerData.Inventory[ItemDirectory[GoldItemName].ItemType]:FindFirstChild(GoldItemName) then

			local NewItemMarker = Instance.new("StringValue")
			NewItemMarker.Name = GoldItemName
			NewItemMarker.Parent = PlayerData.Inventory[ItemDirectory[GoldItemName].ItemType]

			game.ReplicatedStorage.Networking.Client.RemoteEvents.ShowNewItem:FireClient(player, GoldItemName, nil, true)

		end
	end
	
	return true
	
end

ProductFunctions[Products["UnlockGoldTrack"].ID] = function(player, PurchaseState)
	
	if PurchaseState == "Canceled" then
		return
	end
	
	local PlayerData = game.ReplicatedStorage.PlayerData:FindFirstChild(player.Name)
	if not PlayerData then
		return false
	end
	
	-- Tick their GoldTrackUnlocked value to true
	PlayerData.BattlepassData.Battlepass_1.GoldTrackUnlocked.Value = true
	
	-- Give them all the items they need
	for i = 1, PlayerData.BattlepassData.Battlepass_1.CurrentTier.Value do
		
		local GoldItemName = BattlepassPool[i].GoldTrack
		
		if not PlayerData.Inventory[ItemDirectory[GoldItemName].ItemType]:FindFirstChild(GoldItemName) then
			
			local NewItemMarker = Instance.new("StringValue")
			NewItemMarker.Name = GoldItemName
			NewItemMarker.Parent = PlayerData.Inventory[ItemDirectory[GoldItemName].ItemType]
			
			game.ReplicatedStorage.Networking.Client.RemoteEvents.ShowNewItem:FireClient(player, GoldItemName, nil, true)
			
		end
	end
	
	return true
	
end

ProductFunctions[Products["WeeklyPrizePull"].ID] = function(player, PurchaseState)
	return ProcessWeeklyPrizeTicket:Invoke(player, PurchaseState)
end

ProductFunctions[Products["CoinPurchase_1"].ID] = function(player, PurchaseState)
	
	if PurchaseState == "Canceled" then
		return
	end
	
	local PlayerData = game.ReplicatedStorage.PlayerData:FindFirstChild(player.Name)
	if PlayerData then
		
		PlayerData.Economy.Coins.Value = PlayerData.Economy.Coins.Value + Products["CoinPurchase_1"].AwardAmount
		
		AnalyticsService:LogEconomyEvent(
			player,
			Enum.AnalyticsEconomyFlowType.Source,
			"Coins",
			Products["CoinPurchase_1"].AwardAmount, -- Amount collected
			PlayerData.Economy.Coins.Value, -- Current balance
			Enum.AnalyticsEconomyTransactionType.IAP.Name, -- Transaction type
			"Coin Purchase 500"
		)
		
		return true
	else
		return false
	end
	
end

ProductFunctions[Products["CoinPurchase_2"].ID] = function(player, PurchaseState)
	
	if PurchaseState == "Canceled" then
		return
	end
	
	local PlayerData = game.ReplicatedStorage.PlayerData:FindFirstChild(player.Name)
	if PlayerData then
		
		PlayerData.Economy.Coins.Value = PlayerData.Economy.Coins.Value + Products["CoinPurchase_2"].AwardAmount
		
		AnalyticsService:LogEconomyEvent(
			player,
			Enum.AnalyticsEconomyFlowType.Source,
			"Coins",
			Products["CoinPurchase_2"].AwardAmount, -- Amount collected
			PlayerData.Economy.Coins.Value, -- Current balance
			Enum.AnalyticsEconomyTransactionType.IAP.Name, -- Transaction type
			"Coin Purchase 1200"
		)
		
		return true
	else
		return false
	end
	
end

ProductFunctions[Products["CoinPurchase_3"].ID] = function(player, PurchaseState)
	
	if PurchaseState == "Canceled" then
		return
	end
	
	local PlayerData = game.ReplicatedStorage.PlayerData:FindFirstChild(player.Name)
	if PlayerData then
		
		PlayerData.Economy.Coins.Value = PlayerData.Economy.Coins.Value + Products["CoinPurchase_3"].AwardAmount
		
		AnalyticsService:LogEconomyEvent(
			player,
			Enum.AnalyticsEconomyFlowType.Source,
			"Coins",
			Products["CoinPurchase_3"].AwardAmount, -- Amount collected
			PlayerData.Economy.Coins.Value, -- Current balance
			Enum.AnalyticsEconomyTransactionType.IAP.Name, -- Transaction type
			"Coin Purchase 3000"
		)
		
		return true
	else
		return false
	end
	
end

ProductFunctions[Products["CoinPurchase_4"].ID] = function(player, PurchaseState)
	
	if PurchaseState == "Canceled" then
		return
	end
	
	local PlayerData = game.ReplicatedStorage.PlayerData:FindFirstChild(player.Name)
	if PlayerData then
		
		PlayerData.Economy.Coins.Value = PlayerData.Economy.Coins.Value + Products["CoinPurchase_4"].AwardAmount
		
		AnalyticsService:LogEconomyEvent(
			player,
			Enum.AnalyticsEconomyFlowType.Source,
			"Coins",
			Products["CoinPurchase_4"].AwardAmount, -- Amount collected
			PlayerData.Economy.Coins.Value, -- Current balance
			Enum.AnalyticsEconomyTransactionType.IAP.Name, -- Transaction type
			"Coin Purchase 6000"
		)
		
		return true
	else
		return false
	end
	
end

ProductFunctions[Products["CoinPurchase_5"].ID] = function(player, PurchaseState)
	
	if PurchaseState == "Canceled" then
		return
	end
	
	local PlayerData = game.ReplicatedStorage.PlayerData:FindFirstChild(player.Name)
	if PlayerData then
		
		PlayerData.Economy.Coins.Value = PlayerData.Economy.Coins.Value + Products["CoinPurchase_5"].AwardAmount
		
		AnalyticsService:LogEconomyEvent(
			player,
			Enum.AnalyticsEconomyFlowType.Source,
			"Coins",
			Products["CoinPurchase_5"].AwardAmount, -- Amount collected
			PlayerData.Economy.Coins.Value, -- Current balance
			Enum.AnalyticsEconomyTransactionType.IAP.Name, -- Transaction type
			"Coin Purchase 12000"
		)
		
		return true
	else
		return false
	end
	
end

ProductFunctions[Products["FeaturedCommon"].ID] = function(player, PurchaseState)
	return ProcessFeaturedShopTicketEvent:Invoke(player, PurchaseState)
end

ProductFunctions[Products["FeaturedUncommon"].ID] = function(player, PurchaseState)
	return ProcessFeaturedShopTicketEvent:Invoke(player, PurchaseState)
end

ProductFunctions[Products["FeaturedRare"].ID] = function(player, PurchaseState)
	return ProcessFeaturedShopTicketEvent:Invoke(player, PurchaseState)
end

ProductFunctions[Products["FeaturedLegendary"].ID] = function(player, PurchaseState)
	return ProcessFeaturedShopTicketEvent:Invoke(player, PurchaseState)
end

ProductFunctions[Products["StarterPack"].ID] = function(player)
	
	local PlayerData = game.ReplicatedStorage.PlayerData:FindFirstChild(player.Name)
	if PlayerData then
		
		-- Give them coins
		PlayerData.Economy.Coins.Value = PlayerData.Economy.Coins.Value + 1000
		
		AnalyticsService:LogEconomyEvent(
			player,
			Enum.AnalyticsEconomyFlowType.Source,
			"Coins",
			1000, -- Amount collected
			PlayerData.Economy.Coins.Value, -- Current balance
			Enum.AnalyticsEconomyTransactionType.IAP.Name, -- Transaction type
			"Starter Pack"
		)
		
		-- Give them the ski hat
		local NewMarker = Instance.new("StringValue")
		NewMarker.Name = "Italian_Ski_Cap"
		NewMarker.Parent = PlayerData.Inventory.Accessory
		
		game.ReplicatedStorage.Networking.Client.RemoteEvents.ShowNewItem:FireClient(player, "Italian_Ski_Cap", nil, true)
		
		-- Give them the pink ribbons
		local NewMarker = Instance.new("StringValue")
		NewMarker.Name = "Pink_Ribbon"
		NewMarker.Parent = PlayerData.Inventory.Accessory
		
		game.ReplicatedStorage.Networking.Client.RemoteEvents.ShowNewItem:FireClient(player, "Pink_Ribbon", nil, true)
		
		-- Give them the ice trail
		local NewMarker = Instance.new("StringValue")
		NewMarker.Name = "IceTrail"
		NewMarker.Parent = PlayerData.Inventory.Trails
		
		game.ReplicatedStorage.Networking.Client.RemoteEvents.ShowNewItem:FireClient(player, "IceTrail", nil, true)
		
		game.ReplicatedStorage.Networking.Client.RemoteEvents.UpdateGamepassOwned:FireClient(player, "StarterPack")
		
		return true
	else
		return false
	end
	
end

ProductFunctions[Products["UltimateStarterPack"].ID] = function(player)
	
	local PlayerData = game.ReplicatedStorage.PlayerData:FindFirstChild(player.Name)
	if PlayerData then
		
		-- Give them coins
		PlayerData.Economy.Coins.Value = PlayerData.Economy.Coins.Value + 2000
		
		AnalyticsService:LogEconomyEvent(
			player,
			Enum.AnalyticsEconomyFlowType.Source,
			"Coins",
			2000, -- Amount collected
			PlayerData.Economy.Coins.Value, -- Current balance
			Enum.AnalyticsEconomyTransactionType.IAP.Name, -- Transaction type
			"Ultimate Starter Pack"
		)
		
		-- Give them the sick glasses
		local NewMarker = Instance.new("StringValue")
		NewMarker.Name = "Sick_Glasses"
		NewMarker.Parent = PlayerData.Inventory.Accessory
		
		game.ReplicatedStorage.Networking.Client.RemoteEvents.ShowNewItem:FireClient(player, "Sick_Glasses", nil, true)
		
		-- Give them the fat sign
		local NewMarker = Instance.new("StringValue")
		NewMarker.Name = "Fat_Sign"
		NewMarker.Parent = PlayerData.Inventory.Accessory
		
		game.ReplicatedStorage.Networking.Client.RemoteEvents.ShowNewItem:FireClient(player, "Fat_Sign", nil, true)
		
		-- Give them the gold beanie
		local NewMarker = Instance.new("StringValue")
		NewMarker.Name = "GoldWinterCap"
		NewMarker.Parent = PlayerData.Inventory.Accessory
		
		game.ReplicatedStorage.Networking.Client.RemoteEvents.ShowNewItem:FireClient(player, "GoldWinterCap", nil, true)
		
		game.ReplicatedStorage.Networking.Client.RemoteEvents.UpdateGamepassOwned:FireClient(player, "UltimateStarterPack")
		
		return true
	else
		return false
	end
	
end

ProductFunctions[Products["TinyBundle"].ID] = function(player)
	
	local PlayerData = game.ReplicatedStorage.PlayerData:FindFirstChild(player.Name)
	if PlayerData then
		
		local NewMarker = Instance.new("StringValue")
		NewMarker.Name = "Black_Cap_Tiny"
		NewMarker.Parent = PlayerData.Inventory.Accessory
		
		game.ReplicatedStorage.Networking.Client.RemoteEvents.ShowNewItem:FireClient(player, "Black_Cap_Tiny", nil, true)
		
		local NewMarker = Instance.new("StringValue")
		NewMarker.Name = "Propeller_Beanie_Tiny"
		NewMarker.Parent = PlayerData.Inventory.Accessory
		
		game.ReplicatedStorage.Networking.Client.RemoteEvents.ShowNewItem:FireClient(player, "Propeller_Beanie_Tiny", nil, true)
		
		local NewMarker = Instance.new("StringValue")
		NewMarker.Name = "Beret_Tiny"
		NewMarker.Parent = PlayerData.Inventory.Accessory
		
		game.ReplicatedStorage.Networking.Client.RemoteEvents.ShowNewItem:FireClient(player, "Beret_Tiny", nil, true)
		
		local NewMarker = Instance.new("StringValue")
		NewMarker.Name = "SealCowboyHat_Tiny"
		NewMarker.Parent = PlayerData.Inventory.Accessory
		
		game.ReplicatedStorage.Networking.Client.RemoteEvents.ShowNewItem:FireClient(player, "SealCowboyHat_Tiny", nil, true)
		
		local NewMarker = Instance.new("StringValue")
		NewMarker.Name = "BlueWinterCap_Tiny"
		NewMarker.Parent = PlayerData.Inventory.Accessory
		
		game.ReplicatedStorage.Networking.Client.RemoteEvents.ShowNewItem:FireClient(player, "BlueWinterCap_Tiny", nil, true)
		
		game.ReplicatedStorage.Networking.Client.RemoteEvents.UpdateGamepassOwned:FireClient(player, "TinyBundle")
		
		return true
	else
		return false
	end
	
end

ProductFunctions[Products["GalaxyBundle"].ID] = function(player)
	
	local PlayerData = game.ReplicatedStorage.PlayerData:FindFirstChild(player.Name)
	if PlayerData then
		
		local NewMarker = Instance.new("StringValue")
		NewMarker.Name = "GalaxySeal"
		NewMarker.Parent = PlayerData.Inventory.SealSkins
		
		game.ReplicatedStorage.Networking.Client.RemoteEvents.ShowNewItem:FireClient(player, "GalaxySeal", nil, true)
		
		local NewMarker = Instance.new("StringValue")
		NewMarker.Name = "StarShutters"
		NewMarker.Parent = PlayerData.Inventory.Accessory
		
		game.ReplicatedStorage.Networking.Client.RemoteEvents.ShowNewItem:FireClient(player, "StarShutters", nil, true)
		
		local NewMarker = Instance.new("StringValue")
		NewMarker.Name = "StarTrail"
		NewMarker.Parent = PlayerData.Inventory.Trails
		
		game.ReplicatedStorage.Networking.Client.RemoteEvents.ShowNewItem:FireClient(player, "StarTrail", nil, true)
		
		game.ReplicatedStorage.Networking.Client.RemoteEvents.UpdateGamepassOwned:FireClient(player, "GalaxyBundle")
		
		return true
	else
		return false
	end
	
end

ProductFunctions[Products["BeeBundle"].ID] = function(player)

	local PlayerData = game.ReplicatedStorage.PlayerData:FindFirstChild(player.Name)
	if PlayerData then

		local NewMarker = Instance.new("StringValue")
		NewMarker.Name = "BeeSeal"
		NewMarker.Parent = PlayerData.Inventory.SealSkins

		game.ReplicatedStorage.Networking.Client.RemoteEvents.ShowNewItem:FireClient(player, "BeeSeal", nil, true)

		local NewMarker = Instance.new("StringValue")
		NewMarker.Name = "BeeAntennae"
		NewMarker.Parent = PlayerData.Inventory.Accessory

		game.ReplicatedStorage.Networking.Client.RemoteEvents.ShowNewItem:FireClient(player, "BeeAntennae", nil, true)

		local NewMarker = Instance.new("StringValue")
		NewMarker.Name = "BeeWings"
		NewMarker.Parent = PlayerData.Inventory.Accessory

		game.ReplicatedStorage.Networking.Client.RemoteEvents.ShowNewItem:FireClient(player, "BeeWings", nil, true)
		
		local NewMarker = Instance.new("StringValue")
		NewMarker.Name = "BeeFlower"
		NewMarker.Parent = PlayerData.Inventory.Accessory

		game.ReplicatedStorage.Networking.Client.RemoteEvents.ShowNewItem:FireClient(player, "BeeFlower", nil, true)
		
		local NewMarker = Instance.new("StringValue")
		NewMarker.Name = "FlowerTrail"
		NewMarker.Parent = PlayerData.Inventory.Trails

		game.ReplicatedStorage.Networking.Client.RemoteEvents.ShowNewItem:FireClient(player, "FlowerTrail", nil, true)


		game.ReplicatedStorage.Networking.Client.RemoteEvents.UpdateGamepassOwned:FireClient(player, "BeeBundle")

		return true
	else
		return false
	end

end

ProductFunctions[Products["EmoteBounce"].ID] = function(player, PurchaseState)
	
	if PurchaseState == "Canceled" then
		return
	end
	
	local PlayerData = game.ReplicatedStorage.PlayerData:FindFirstChild(player.Name)
	if PlayerData then
		
		local NewMarker = Instance.new("StringValue")
		NewMarker.Name = "EmoteBounce"
		NewMarker.Parent = PlayerData.Inventory.Emotes
		
		game.ReplicatedStorage.Networking.Client.RemoteEvents.ShowNewItem:FireClient(player, "EmoteBounce", nil, true)
		
		game.ReplicatedStorage.Networking.Client.RemoteEvents.UpdateGamepassOwned:FireClient(player, "EmoteBounce")
		
		return true
	else
		return false
	end
	
end

ProductFunctions[Products["EmoteOrangeJustice"].ID] = function(player, PurchaseState)

	if PurchaseState == "Canceled" then
		return
	end

	local PlayerData = game.ReplicatedStorage.PlayerData:FindFirstChild(player.Name)
	if PlayerData then

		local NewMarker = Instance.new("StringValue")
		NewMarker.Name = "EmoteOrangeJustice"
		NewMarker.Parent = PlayerData.Inventory.Emotes

		game.ReplicatedStorage.Networking.Client.RemoteEvents.ShowNewItem:FireClient(player, "EmoteOrangeJustice", nil, true)

		game.ReplicatedStorage.Networking.Client.RemoteEvents.UpdateGamepassOwned:FireClient(player, "EmoteOrangeJustice")

		return true
	else
		return false
	end

end


-- Functions --

local function GetDateTime()
	
	-- Convert seconds to a readable time table
	local timeTable = os.date("!*t", (os.time() - 21600))
	
	-- Determine AM or PM and adjust hour format
	local hour = timeTable.hour
	local ampm = "am"
	
	if hour == 0 then
		hour = 12 -- Midnight case (00:00 → 12:00am)
	elseif hour == 12 then
		ampm = "pm" -- Noon case (12:00 → 12:00pm)
	elseif hour > 12 then
		hour = hour - 12
		ampm = "pm"
	end
	
	-- Format MM/DD/YYYY @HH:MMam/pm
	return string.format("%02d/%02d/%04d @%02d:%02d%s", 
		timeTable.month, timeTable.day, timeTable.year, 
		hour, timeTable.min, ampm
	)
	
end

local function updatePriceDirectory()
	local PricesChanged = false
	for productName, productInfo in pairs(Products) do
		
		-- Use pcall to handle any API errors
		local Attempts = 0
		local success, productData
		
		repeat
			success, productData = pcall(function()
				return MarketplaceService:GetProductInfo(productInfo.ID, productInfo.Type)
			end)
			if not success then
				Attempts = Attempts + 1
				wait(1)
			end
		until success or Attempts >= 10
		
		if success and productData then
			PriceDirectory.PriceTable[productName] = productData.PriceInRobux or 9999999
			if PreviousPrices[productName] then
				if productData.PriceInRobux ~= PreviousPrices[productName] then
					PricesChanged = true
				end
			else
				PricesChanged = true
			end
			--print("Updated price for " .. productName .. ": " .. PriceDirectory[productName] .. " Robux")
		else
			warn("Failed to fetch price data for " .. productName)
		end
		PreviousPrices[productName] = productData.PriceInRobux
		-- Small delay between API calls to avoid rate limiting
		--task.wait(0.5)
	end
	if PricesChanged then
		PriceDirectory.PriceUpdate:Fire()
		local CoinPrices = {}
		for ProductName, Price in pairs (PriceDirectory.PriceTable) do
			if string.find(ProductName, "CoinPurchase_") then
				CoinPrices[ProductName] = Price
			end
		end
		local GamepassPrices = {}
		for ProductName, Price in pairs (PriceDirectory.PriceTable) do
			if Products[ProductName].Type == Enum.InfoType.GamePass then
				GamepassPrices[ProductName] = Price
			end
		end
		game.ReplicatedStorage.Networking.Client.RemoteEvents.UpdateCoinPrices:FireAllClients(CoinPrices)
		game.ReplicatedStorage.Networking.Client.RemoteEvents.UpdateGamepassPrices:FireAllClients(GamepassPrices)
	end
end

-- Function to handle GamePass awards
local function handleGamePassPurchase(player, gamePassId)
	
	-- Check if this GamePass has already been awarded to the player
	local userId = player.UserId
	local success, purchaseHistory = pcall(function()
		return PurchaseHistoryStore:GetAsync("UserID_" .. userId) or {}
	end)
	
	if not success then
		warn("Failed to get purchase history for user", userId)
		return
	end
	
	-- Generate a unique identifier for this GamePass award
	local purchaseId = "GamePass_" .. gamePassId
	
	-- Check if this GamePass was already awarded
	if purchaseHistory["PurchaseID_" .. purchaseId] and purchaseHistory["PurchaseID_" .. purchaseId].Granted == true then
		-- This GamePass was already awarded to the player
		if not RunService:IsStudio() then
			return
		elseif TestingMode == false then
			return
		end
	end
	
	-- Check if we have a function to handle this GamePass
	if not ProductFunctions[gamePassId] then
		warn("No product function for GamePass ID:", gamePassId)

		-- Record that we couldn't award this GamePass
		purchaseHistory["PurchaseID_" .. purchaseId] = {
			ProductId = gamePassId,
			Timestamp = os.time(),
			Granted = false
		}

		pcall(function()
			PurchaseHistoryStore:SetAsync("UserID_" .. userId, purchaseHistory)
		end)

		return
	end
	
	game.ReplicatedStorage.Networking.Server.BindableEvents.RecordAnalytic:Fire(player, "Shop Depth", 4)
	
	-- Try to award the GamePass benefits
	local awardSuccess, result = pcall(function()
		ProductFunctions[gamePassId](player)
	end)
	
	if not awardSuccess then
		warn("Item reward function failed: " .. result)
		return
	end
	
	-- Update the purchase history
	purchaseHistory["PurchaseID_" .. purchaseId] = {
		ProductId = gamePassId,
		Timestamp = GetDateTime(),
		Granted = true
	}
	
	-- Save the updated purchase history
	local saveSuccess = false
	local Attempts = 0
	
	repeat
		saveSuccess = pcall(function()
			PurchaseHistoryStore:SetAsync("UserID_" .. userId, purchaseHistory)
		end)
		if not saveSuccess then
			Attempts = Attempts + 1
			wait(5)
		end
	until saveSuccess or Attempts == 10
	
	if not saveSuccess then
		warn("Failed to save GamePass award history for user", userId)
	end
end

local function HandlePurchasePrompt(RequestingPlayer, TargetItemName)
	
	local TargetItemID = nil
	local TargetItemType = nil
	
	for ItemName, ItemInfo in pairs (Products) do
		if ItemName == TargetItemName then
			TargetItemID = ItemInfo.ID
			TargetItemType = ItemInfo.Type
			break
		end
	end
	
	if TargetItemType == Enum.InfoType.Product then
		MarketplaceService:PromptProductPurchase(RequestingPlayer, TargetItemID)
	elseif TargetItemType == Enum.InfoType.GamePass then
		MarketplaceService:PromptGamePassPurchase(RequestingPlayer, TargetItemID)
	end
	
end


-- Callback Functions --

MarketplaceService.PromptProductPurchaseFinished:Connect(function(UserID, ProductID, WasPurchased)
	if not WasPurchased then
		
		local Player = game.Players:GetPlayerByUserId(UserID)
		if not Player then
			return
		end
		
		ProductFunctions[ProductID](Player, "Canceled")
		
		PlayerFinishedPurchaseEvent:Fire(Player)
		
	end
end)

MarketplaceService.ProcessReceipt = function(receiptInfo)
	
	-- Get information from the receipt
	local userId = receiptInfo.PlayerId
	local productId = receiptInfo.ProductId
	local purchaseId = receiptInfo.PurchaseId
	
	-- Get the player who made the purchase
	local player = Players:GetPlayerByUserId(userId)
	if not player then
		-- Player is not in the game, return NotProcessedYet
		-- This will allow the callback to be called again when the player rejoins
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	
	-- Check if this purchase was already processed
	local success, purchaseHistory = pcall(function()
		return PurchaseHistoryStore:GetAsync("UserID_" .. userId) or {}
	end)
	
	if not success then
		warn("Failed to get purchase history for user", userId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	
	-- Check if this purchase was already processed
	if purchaseHistory["PurchaseID_" .. purchaseId] then
		-- This purchase was already processed
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	
	-- Check if we have a function to handle this product
	--[[if not ProductFunctions[productId] then
		warn("No product function for product ID:", productId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end]]
	
	-- Try to award the product
	local NoErrors, TicketResult = pcall(function()
		return ProductFunctions[productId](player, "Purchased")
	end)
	
	if not NoErrors or not TicketResult then
		warn("Failed to award product", productId, "to player", player.Name)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	
	-- Record the purchase in the player's purchase history
	purchaseHistory["PurchaseID_" .. purchaseId] = {
		ProductId = productId,
		Timestamp = GetDateTime(),
		Granted = true
	}
	
	-- Save the updated purchase history
	local saveSuccess = false
	local Attempts = 0
	
	repeat
		saveSuccess = pcall(function()
			PurchaseHistoryStore:SetAsync("UserID_" .. userId, purchaseHistory)
		end)
		if not saveSuccess then
			Attempts = Attempts + 1
			wait(5)
		end
	until saveSuccess or Attempts == 10
	
	if not saveSuccess then
		warn("Failed to save purchase history for user", userId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	
	game.ReplicatedStorage.Networking.Server.BindableEvents.RecordAnalytic:Fire(player, "Shop Depth", 4)
	
	-- Return PurchaseGranted to signal that the purchase was processed successfully
	return Enum.ProductPurchaseDecision.PurchaseGranted
	
end


-- Event Functions --

-- Connect to the GamePass purchase finished event
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
	if wasPurchased then
		handleGamePassPurchase(player, gamePassId)
	end
end)

-- Check if players already own GamePasses when they join
Players.PlayerAdded:Connect(function(player)
	for productName, productInfo in pairs(Products) do -- Check for each GamePass
		if productInfo.Type == Enum.InfoType.GamePass then
			
			local success, ownsPass = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, productInfo.ID)
			end)
			
			if success and ownsPass then
				-- Player already owns this GamePass, award it if not already awarded
				handleGamePassPurchase(player, productInfo.ID)
			end
			
			-- Small delay between API calls to avoid rate limiting
			task.wait(0.5)
			
		end
	end
end)

game.ReplicatedStorage.Networking.Server.RemoteFunctions.RequestPurchasableCoinAmounts.OnServerInvoke = function(RequestingPlayer)
	local InfoTable = {}
	for ProductName, ProductInfo in pairs (Products) do
		if string.find(ProductName, "CoinPurchase_") then
			InfoTable[ProductName] = ProductInfo.AwardAmount
		end
	end
	return InfoTable
end

game.ReplicatedStorage.Networking.Server.RemoteEvents.RequestCoinPrices.OnServerEvent:Connect(function(RequestingPlayer)
	local CoinPrices = {}
	for ProductName, Price in pairs (PriceDirectory.PriceTable) do
		if string.find(ProductName, "CoinPurchase_") then
			CoinPrices[ProductName] = Price
		end
	end
	game.ReplicatedStorage.Networking.Client.RemoteEvents.UpdateCoinPrices:FireClient(RequestingPlayer, CoinPrices)
end)

game.ReplicatedStorage.Networking.Server.RemoteEvents.RequestGamepassPrices.OnServerEvent:Connect(function(RequestingPlayer)
	local GamepassPrices = {}
	for ProductName, Price in pairs (PriceDirectory.PriceTable) do
		if Products[ProductName].Type == Enum.InfoType.GamePass then
			GamepassPrices[ProductName] = Price
		end
	end
	game.ReplicatedStorage.Networking.Client.RemoteEvents.UpdateGamepassPrices:FireClient(RequestingPlayer, GamepassPrices)
end)


-- Events --

PurchaseEvent.Event:Connect(HandlePurchasePrompt)
PurchaseEventRemote.OnServerEvent:Connect(HandlePurchasePrompt)


-- Setup --

-- Initial price update
updatePriceDirectory()


-- Loops --

while true do
	wait(60)
	updatePriceDirectory()
end