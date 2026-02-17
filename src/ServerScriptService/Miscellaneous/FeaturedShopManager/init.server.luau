
-- Constants --

local FeaturedShopPool = require(game.ReplicatedStorage.Directories.FeaturedShopPool)()
local ItemDirectory = require(game.ReplicatedStorage.Directories.ItemDirectory)
local ToggleCosmetic = require(game.ReplicatedStorage.HelperModules.ToggleCosmetic)

local UpdateFeaturedShopEvent = game.ReplicatedStorage.Networking.Client.RemoteEvents.UpdateFeaturedShop
local PurchaseFeaturedItemEvent = game.ReplicatedStorage.Networking.Server.RemoteEvents.PurchaseFeaturedItem
local RequestFeaturedShopDataEvent = game.ReplicatedStorage.Networking.Server.RemoteEvents.RequestFeaturedShopData
local ShowNewItemEvent = game.ReplicatedStorage.Networking.Client.RemoteEvents.ShowNewItem

local PurchaseEvent = game.ReplicatedStorage.Networking.Server.BindableEvents.PurchaseItem
local ProcessFeaturedShopTicketEvent = game.ReplicatedStorage.Networking.Server.BindableFunctions.ProcessFeaturedShopTicket

local PriceDirectory = require(game.ReplicatedStorage.Directories.PriceDirectory)


-- Settings --

local PedalstoolColors = {
	Common = Color3.fromRGB(138, 243, 255),
	Uncommon = Color3.fromRGB(99, 255, 75),
	Rare = Color3.fromRGB(207, 110, 255),
	Legendary = Color3.fromRGB(255, 183, 101),
}

local GradientColors = {
	Common = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(85, 170, 255)),
	Uncommon = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(85, 255, 0)),
	Rare = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(168, 78, 198)),
	Legendary = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 170, 0)),
}

local VFX_Colors = {
	Common = ColorSequence.new(Color3.fromRGB(138, 243, 255)),
	Uncommon = ColorSequence.new(Color3.fromRGB(99, 255, 75)),
	Rare = ColorSequence.new(Color3.fromRGB(207, 110, 255)),
	Legendary = ColorSequence.new(Color3.fromRGB(255, 183, 101)),
}



-- Variables --

local FeaturedShopItems = {}
local CurrentDailySeed = 0

local OpenTickets = {}
local StupidDebounceTable = {}


-- Functions --

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

local function GetDailyRandomNumber()
	
	local utcTime = os.time()
	
	-- Determine Central Time offset
	local offset = -6 -- Default to CST (UTC -6)
	if os.date("!*t").isdst then
		offset = -5 -- CDT (UTC -5) during daylight savings
	end
	
	-- Convert UTC time to Central Time
	local centralTime = os.date("!*t", utcTime + (offset * 3600))
	
	-- Create a unique "seed" for the day
	local daySeed = string.format("%04d%02d%02d", centralTime.year, centralTime.month, centralTime.day)
	
	-- Seed the random number generator with today's seed
	math.randomseed(tonumber(daySeed))
	
	-- Generate a random number (customize range as needed)
	return math.random(1, 100) -- Returns a number between 1 and 100
	
end

local function Commafy(Amount)
	local FormattedAmount = Amount
	local CharsRemaining = nil
	while true do  
		FormattedAmount, CharsRemaining = string.gsub(FormattedAmount, "^(-?%d+)(%d%d%d)", '%1,%2')
		if CharsRemaining == 0 then
			break
		end
	end
	return FormattedAmount
end

local function UpdateFeaturedShop(DailySeed)
	
	FeaturedShopItems = {}
	
	for i, Value in pairs (GetRandomEntries(DailySeed, FeaturedShopPool.Uncommon, 1)) do
		table.insert(FeaturedShopItems, {ItemName = Value, Rarity = "Uncommon", Price = Commafy(PriceDirectory:GetPrice("FeaturedUncommon"))})
	end
	
	for i, Value in pairs (GetRandomEntries(DailySeed, FeaturedShopPool.Rare, 2)) do
		table.insert(FeaturedShopItems, {ItemName = Value, Rarity = "Rare", Price = Commafy(PriceDirectory:GetPrice("FeaturedRare"))})
	end
	
	for i, Value in pairs (GetRandomEntries(DailySeed, FeaturedShopPool.Legendary, 2)) do
		table.insert(FeaturedShopItems, {ItemName = Value, Rarity = "Legendary", Price = Commafy(PriceDirectory:GetPrice("FeaturedLegendary"))})
	end
	
	UpdateFeaturedShopEvent:FireAllClients(FeaturedShopItems)
	
	for i, FeaturedItemData in pairs (FeaturedShopItems) do
		
		local PedalstoolModel = workspace.FeaturedPedalstools["FeaturedShopPedalstool_" .. i]
		
		if PedalstoolModel:FindFirstChild("SappySeal") then
			PedalstoolModel.SappySeal:Destroy()
		end
		
		local NewSap = script.PedalstoolSeal:Clone()
		NewSap:PivotTo(PedalstoolModel.SealSpawn.CFrame)
		NewSap.Name = "SappySeal"
		
		local ItemType = ItemDirectory[FeaturedItemData.ItemName].ItemType
		
		if ItemType ~= "Trails" then
			ToggleCosmetic(NewSap, FeaturedItemData.ItemName)
		else
			local NewTrail = game.ReplicatedStorage.Cosmetics.Trails[FeaturedItemData.ItemName]:Clone()
			NewTrail.Attachment1 = NewSap.RootPart.TrailAttachment1
			NewTrail.Attachment0 = NewSap.RootPart.TrailAttachment2
			NewTrail.Parent = NewSap
			NewSap.RootPart.SpinScript.Enabled = true
		end
		
		NewSap.Parent = PedalstoolModel
		
		PedalstoolModel.BillboardBrick.BillboardGui.TextLabel.Text = ItemDirectory[FeaturedItemData.ItemName].FlavorText
		PedalstoolModel.BillboardBrick.BillboardGui.TextLabel.UIGradient.Color = GradientColors[ItemDirectory[FeaturedItemData.ItemName].Rarity]
		PedalstoolModel.BillboardBrick.BillboardGui.TimerLabel.UIGradient.Color = GradientColors[ItemDirectory[FeaturedItemData.ItemName].Rarity]
		
		for _, Child in pairs (PedalstoolModel.NeonParts:GetChildren()) do
			Child.Color = PedalstoolColors[ItemDirectory[FeaturedItemData.ItemName].Rarity]
		end
		
		for _, Child in pairs (PedalstoolModel.VFX_Model:GetChildren()) do
			Child.Beam.Color = VFX_Colors[ItemDirectory[FeaturedItemData.ItemName].Rarity]
		end
		
		PedalstoolModel.CurrentItem.Value = FeaturedItemData.ItemName
		
	end
	
end


-- Event Functions --

PurchaseFeaturedItemEvent.OnServerEvent:Connect(function(RequestingPlayer, ItemName)
	
	if StupidDebounceTable[RequestingPlayer] then
		return
	end
	
	-- Make sure the item they're trying to buy is in the Featured Shop
	local ItemFound = false
	for _, FeaturedItemData in pairs (FeaturedShopItems) do
		if ItemName == FeaturedItemData.ItemName then
			ItemFound = true
			break
		end
	end
	
	if not ItemFound then
		return
	end
	
	-- Get their PlayerData
	local PlayerData = game.ReplicatedStorage.PlayerData:FindFirstChild(RequestingPlayer.Name)
	if not PlayerData then
		return
	end
	
	-- Make sure they don't already own the item
	local ItemType = ItemDirectory[ItemName].ItemType
	if PlayerData.Inventory[ItemType]:FindFirstChild(ItemName) then
		return
	end
	
	-- Make sure they don't have an open ticket
	if OpenTickets[RequestingPlayer] then
		return
	end
	
	-- Make a ticket for them
	OpenTickets[RequestingPlayer] = ItemName
	
	-- Get the rarity ourselves instead of trusting the smelly client
	local ItemRarity = ItemDirectory[ItemName].Rarity
	
	-- Fire the PurchaseHandler to handle the transaction
	PurchaseEvent:Fire(RequestingPlayer, "Featured" .. ItemRarity)
	
end)

RequestFeaturedShopDataEvent.OnServerEvent:Connect(function(RequestingPlayer)
	UpdateFeaturedShopEvent:FireClient(RequestingPlayer, FeaturedShopItems)
end)

ProcessFeaturedShopTicketEvent.OnInvoke = function(Player, PurchaseStatus)
	if OpenTickets[Player] then
		
		if PurchaseStatus == "Canceled" then
			OpenTickets[Player] = nil
			return
		end
		
		local PlayerData = game.ReplicatedStorage.PlayerData:FindFirstChild(Player.Name)
		local ItemName = OpenTickets[Player]
		local ItemType = ItemDirectory[ItemName].ItemType
		
		local NewMarker = Instance.new("StringValue")
		NewMarker.Name = ItemName
		NewMarker.Parent = PlayerData.Inventory[ItemType]
		
		-- Increment their cosmetics owned
		PlayerData.CareerStats.TotalCosmeticsOwned.Value = PlayerData.CareerStats.TotalCosmeticsOwned.Value + 1
		
		ShowNewItemEvent:FireClient(Player, ItemName, nil, true)
		
		OpenTickets[Player] = nil
		
		UpdateFeaturedShopEvent:FireClient(Player, FeaturedShopItems)
		
		spawn(function()
			StupidDebounceTable[Player] = true
			wait(3)
			StupidDebounceTable[Player] = nil
		end)
		
		return true
		
	else
		return false
	end
end

PriceDirectory.PriceUpdate.Event:Connect(function()
	UpdateFeaturedShop(CurrentDailySeed)
end)


-- Loops --

while true do
	local DailySeed = GetDailyRandomNumber()
	if CurrentDailySeed ~= DailySeed then
		CurrentDailySeed = DailySeed
		UpdateFeaturedShop(DailySeed)
	end
	wait(60)
end