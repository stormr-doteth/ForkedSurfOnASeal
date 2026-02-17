
-- Constants --

local BadgeService = game:GetService("BadgeService")
local PlayerDataContainer = game.ReplicatedStorage.PlayerData


-- Variables --

local ClickCache = {}
local BadgeOwnershipCache = {}


-- Settings --

local BadgeIDs = {
	
	["1 WIN"] = 4159804259907903,
	["10 WINS"] = 3713259034320101,
	["50 WINS"] = 294829037538113,
	["100 WINS"] = 757888818593990,
	["200 WINS"] = 2692202506980208,
	["500 WINS"] = 1161654818064959,
	["1,000 WINS"] = 972173572933323,
	["2,000 WINS"] = 925766321034537,
	["5,000 WINS"] = 340263242666072,
	["10,000 WINS"] = 2610275838297409,
	
	["100 COINS"] = 1639237565365368,
	["1,000 COINS"] = 2599982254572928,
	["5,000 COINS"] = 3577648747480970,
	["15,000 COINS"] = 1501496048167234,
	["50,000 COINS"] = 714361033144259,
	["100,000 COINS"] = 2745436998654486,
	["1,000,000 COINS"] = 4485882377317006,
	
}


-- Functions --

local function CheckTotalCoins(PlayerData, Player)
	if PlayerData.CareerStats.TotalCoinsCollected.Value >= 100 then
		if not BadgeOwnershipCache["100 COINS"].Player then
			if not BadgeService:UserHasBadgeAsync(Player.UserId, BadgeIDs["100 COINS"]) then
				BadgeService:AwardBadge(Player.UserId, BadgeIDs["100 COINS"])
			end
			BadgeOwnershipCache["100 COINS"].Player = true
		end
	end
	if PlayerData.CareerStats.TotalCoinsCollected.Value >= 1000 then
		if not BadgeOwnershipCache["1,000 COINS"].Player then
			if not BadgeService:UserHasBadgeAsync(Player.UserId, BadgeIDs["1,000 COINS"]) then
				BadgeService:AwardBadge(Player.UserId, BadgeIDs["1,000 COINS"])
			end
			BadgeOwnershipCache["1,000 COINS"].Player = true
		end
	end
	if PlayerData.CareerStats.TotalCoinsCollected.Value >= 5000 then
		if not BadgeOwnershipCache["5,000 COINS"].Player then
			if not BadgeService:UserHasBadgeAsync(Player.UserId, BadgeIDs["5,000 COINS"]) then
				BadgeService:AwardBadge(Player.UserId, BadgeIDs["5,000 COINS"])
			end
			BadgeOwnershipCache["5,000 COINS"].Player = true
		end
	end
	if PlayerData.CareerStats.TotalCoinsCollected.Value >= 15000 then
		if not BadgeOwnershipCache["15,000 COINS"].Player then
			if not BadgeService:UserHasBadgeAsync(Player.UserId, BadgeIDs["15,000 COINS"]) then
				BadgeService:AwardBadge(Player.UserId, BadgeIDs["15,000 COINS"])
			end
			BadgeOwnershipCache["15,000 COINS"].Player = true
		end
	end
	if PlayerData.CareerStats.TotalCoinsCollected.Value >= 50000 then
		if not BadgeOwnershipCache["50,000 COINS"].Player then
			if not BadgeService:UserHasBadgeAsync(Player.UserId, BadgeIDs["50,000 COINS"]) then
				BadgeService:AwardBadge(Player.UserId, BadgeIDs["50,000 COINS"])
			end
			BadgeOwnershipCache["50,000 COINS"].Player = true
		end
	end
	if PlayerData.CareerStats.TotalCoinsCollected.Value >= 100000 then
		if not BadgeOwnershipCache["100,000 COINS"].Player then
			if not BadgeService:UserHasBadgeAsync(Player.UserId, BadgeIDs["100,000 COINS"]) then
				BadgeService:AwardBadge(Player.UserId, BadgeIDs["100,000 COINS"])
			end
			BadgeOwnershipCache["100,000 COINS"].Player = true
		end
	end
	if PlayerData.CareerStats.TotalCoinsCollected.Value >= 1000000 then
		if not BadgeOwnershipCache["1,000,000 COINS"].Player then
			if not BadgeService:UserHasBadgeAsync(Player.UserId, BadgeIDs["1,000,000 COINS"]) then
				BadgeService:AwardBadge(Player.UserId, BadgeIDs["1,000,000 COINS"])
			end
			BadgeOwnershipCache["1,000,000 COINS"].Player = true
		end
	end
end

local function CheckTotalWins(PlayerData, Player)
	if PlayerData.CareerStats.TotalWins.Value >= 1 then
		if not BadgeOwnershipCache["1 WIN"].Player then
			if not BadgeService:UserHasBadgeAsync(Player.UserId, BadgeIDs["1 WIN"]) then
				BadgeService:AwardBadge(Player.UserId, BadgeIDs["1 WIN"])
			end
			BadgeOwnershipCache["1 WIN"].Player = true
		end
	end
	if PlayerData.CareerStats.TotalWins.Value >= 10 then
		if not BadgeOwnershipCache["10 WINS"].Player then
			if not BadgeService:UserHasBadgeAsync(Player.UserId, BadgeIDs["10 WINS"]) then
				BadgeService:AwardBadge(Player.UserId, BadgeIDs["10 WINS"])
			end
			BadgeOwnershipCache["10 WINS"].Player = true
		end
	end
	if PlayerData.CareerStats.TotalWins.Value >= 50 then
		if not BadgeOwnershipCache["50 WINS"].Player then
			if not BadgeService:UserHasBadgeAsync(Player.UserId, BadgeIDs["50 WINS"]) then
				BadgeService:AwardBadge(Player.UserId, BadgeIDs["50 WINS"])
			end
			BadgeOwnershipCache["50 WINS"].Player = true
		end
	end
	if PlayerData.CareerStats.TotalWins.Value >= 100 then
		if not BadgeOwnershipCache["100 WINS"].Player then
			if not BadgeService:UserHasBadgeAsync(Player.UserId, BadgeIDs["100 WINS"]) then
				BadgeService:AwardBadge(Player.UserId, BadgeIDs["100 WINS"])
			end
			BadgeOwnershipCache["100 WINS"].Player = true
		end
	end
	if PlayerData.CareerStats.TotalWins.Value >= 200 then
		if not BadgeOwnershipCache["200 WINS"].Player then
			if not BadgeService:UserHasBadgeAsync(Player.UserId, BadgeIDs["200 WINS"]) then
				BadgeService:AwardBadge(Player.UserId, BadgeIDs["200 WINS"])
			end
			BadgeOwnershipCache["200 WINS"].Player = true
		end
	end
	if PlayerData.CareerStats.TotalWins.Value >= 500 then
		if not BadgeOwnershipCache["500 WINS"].Player then
			if not BadgeService:UserHasBadgeAsync(Player.UserId, BadgeIDs["500 WINS"]) then
				BadgeService:AwardBadge(Player.UserId, BadgeIDs["500 WINS"])
			end
			BadgeOwnershipCache["500 WINS"].Player = true
		end
	end
	if PlayerData.CareerStats.TotalWins.Value >= 1000 then
		if not BadgeOwnershipCache["1,000 WINS"].Player then
			if not BadgeService:UserHasBadgeAsync(Player.UserId, BadgeIDs["1,000 WINS"]) then
				BadgeService:AwardBadge(Player.UserId, BadgeIDs["1,000 WINS"])
			end
			BadgeOwnershipCache["1,000 WINS"].Player = true
		end
	end
	if PlayerData.CareerStats.TotalWins.Value >= 2000 then
		if not BadgeOwnershipCache["2,000 WINS"].Player then
			if not BadgeService:UserHasBadgeAsync(Player.UserId, BadgeIDs["2,000 WINS"]) then
				BadgeService:AwardBadge(Player.UserId, BadgeIDs["2,000 WINS"])
			end
			BadgeOwnershipCache["2,000 WINS"].Player = true
		end
	end
	if PlayerData.CareerStats.TotalWins.Value >= 5000 then
		if not BadgeOwnershipCache["5,000 WINS"].Player then
			if not BadgeService:UserHasBadgeAsync(Player.UserId, BadgeIDs["5,000 WINS"]) then
				BadgeService:AwardBadge(Player.UserId, BadgeIDs["5,000 WINS"])
			end
			BadgeOwnershipCache["5,000 WINS"].Player = true
		end
	end
	if PlayerData.CareerStats.TotalWins.Value >= 10000 then
		if not BadgeOwnershipCache["10,000 WINS"].Player then
			if not BadgeService:UserHasBadgeAsync(Player.UserId, BadgeIDs["10,000 WINS"]) then
				BadgeService:AwardBadge(Player.UserId, BadgeIDs["10,000 WINS"])
			end
			BadgeOwnershipCache["10,000 WINS"].Player = true
		end
	end
end

--[[local function CheckTotalChests(PlayerData, Player)
	if PlayerData.CareerStats.TotalChestsOpened.Value >= 100 then
		if not BadgeService:UserHasBadgeAsync(Player.UserId, BadgeIDs["ChestExample"]) then
			BadgeService:AwardBadge(Player.UserId, BadgeIDs["ChestExample"])
		end
	end
end

local function CheckTotalCosmetics(PlayerData, Player)
	if PlayerData.CareerStats.TotalCosmeticsOwned.Value >= 100 then
		if not BadgeService:UserHasBadgeAsync(Player.UserId, BadgeIDs["CosmeticsExample"]) then
			BadgeService:AwardBadge(Player.UserId, BadgeIDs["CosmeticsExample"])
		end
	end
end]]


-- Event Functions --

-- When a new playerdata folder is added, connect to it
PlayerDataContainer.ChildAdded:Connect(function(NewPlayerData)
	
	-- Find the player associated with the folder
	local Player = game.Players:FindFirstChild(NewPlayerData.Name)
	if not Player then
		return
	end
	
	-- Best time badges
	--[[NewPlayerData.CareerStats.BestTime.Changed:Connect(function()
		CheckBestTime(NewPlayerData, Player)
	end)
	CheckBestTime(NewPlayerData, Player)]]
	
	-- Total coin badges
	NewPlayerData.CareerStats.TotalCoinsCollected.Changed:Connect(function()
		CheckTotalCoins(NewPlayerData, Player)
	end)
	CheckTotalCoins(NewPlayerData, Player)
	
	-- Total wins badges
	NewPlayerData.CareerStats.TotalWins.Changed:Connect(function()
		CheckTotalWins(NewPlayerData, Player)
	end)
	CheckTotalWins(NewPlayerData, Player)
	
	-- Total chests badges
	--[[NewPlayerData.CareerStats.TotalChestsOpened.Changed:Connect(function()
		CheckTotalChests(NewPlayerData, Player)
	end)
	CheckTotalChests(NewPlayerData, Player)]]
	
	-- Total cosmetic badges
	--[[NewPlayerData.CareerStats.TotalCosmeticsOwned.Changed:Connect(function()
		CheckTotalCosmetics(NewPlayerData, Player)
	end)
	CheckTotalCosmetics(NewPlayerData, Player)]]
	
end)

game.ReplicatedStorage.Networking.Server.RemoteEvents.ClickTheSap.OnServerEvent:Connect(function(RequestingPlayer)
	if not ClickCache[RequestingPlayer] then
		if not BadgeService:UserHasBadgeAsync(RequestingPlayer.UserId, 2699364937907738) then
			BadgeService:AwardBadge(RequestingPlayer.UserId, 2699364937907738)
		end
		ClickCache[RequestingPlayer] = true
	end
end)

game.Players.PlayerRemoving:Connect(function(RemovingPlayer)
	ClickCache[RemovingPlayer] = nil
	for _, CachedPlayers in pairs (BadgeOwnershipCache) do
		CachedPlayers[RemovingPlayer] = nil
	end
end)


-- Setup --

for BadgeName, _ in pairs (BadgeIDs) do
	BadgeOwnershipCache[BadgeName] = {}
end