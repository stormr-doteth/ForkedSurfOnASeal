
-- Constants --

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local UpdateLeaderboardsEvent = game.ReplicatedStorage.Networking.Client.RemoteEvents.WeeklyLeaderboardUpdate
local LeaderboardDataRequestEvent = game.ReplicatedStorage.Networking.Server.RemoteEvents.RequestWeeklyLeaderboardData

local LeaderboardModel = workspace.Lobby.WeeklyLeaderboard
local LeaderDummy = LeaderboardModel["1stPlaceStand"].Dummy


-- Settings --

local EntryListSize = 100
local UpdateInterval = 10


-- Variables --

local DataCache = {}
local UsernameCache = {}
local CurrentWeeklyDatastore = nil
local CurrentWeeklyID = nil


-- Functions --

local function GetWeeklyID()
	
	local now = os.time()
	local t = os.date("*t", now)  -- Use local time; change to "!*t" for UTC
	
	-- Adjust so weeks start on Sunday (Lua wday: Sunday = 1)
	local daysSinceSunday = t.wday - 1  -- Days since last Sunday
	local secondsSinceSunday = ((daysSinceSunday * 86400) + t.hour * 3600 + t.min * 60 + t.sec)
	
	-- Subtract seconds since last Sunday to get the start of the week
	local weekStart = now - secondsSinceSunday
	
	-- Optional: format as YYYY-WW or timestamp
	return os.date("%Y-W%U", weekStart)  -- %U = Sunday-based week number (00–53)
	
end

local function UpdateCurrentDatastore()
	CurrentWeeklyID = GetWeeklyID()
	CurrentWeeklyDatastore = DataStoreService:GetOrderedDataStore("WeeklyWinsLeaderboard_" .. CurrentWeeklyID)
end

-- Utility: Write player wins to DataStore
local function writeAllWinsToDataStore()
	for _, Player in pairs (game.Players:GetPlayers()) do
		if Player.UserId > 0 then
			local PlayerDataFolder = game.ReplicatedStorage.PlayerData:FindFirstChild(Player.Name)
			if PlayerDataFolder then
				if PlayerDataFolder.CareerStats.WeeklyWins:FindFirstChild(CurrentWeeklyID) then
					CurrentWeeklyDatastore:SetAsync(Player.UserId, PlayerDataFolder.CareerStats.WeeklyWins[CurrentWeeklyID].Value)
				end
			end
		end
	end
end

-- Utility: Fetch top N entries
local function getTopLeaders()
	
	local Success, Pages = pcall(function()
		return CurrentWeeklyDatastore:GetSortedAsync(false, EntryListSize)
	end)
	
	if not Success or not Pages then
		return {}
	end
	
	DataCache = {}
	
	for Rank, EntryData in pairs(Pages:GetCurrentPage()) do
		
		local Username = nil
		if UsernameCache[EntryData.key] then
			Username = UsernameCache[EntryData.key]
		else
			local Success, _ = pcall(function()
				Username = game.Players:GetNameFromUserIdAsync(EntryData.key)
			end)
			if not Success then
				Username = ""
			end
		end
		
		table.insert(DataCache, {
			UserID = EntryData.key,
			Username = Username,
			Wins = EntryData.value,
		})
		
	end
	
end

-- Utility: Update all dummies and TextLabels
local function UpdateDummy()
	
	if #DataCache == 0 then
		return
	end
	
	local Success, HumanoidDescription = pcall(function()
		return Players:GetHumanoidDescriptionFromUserId(DataCache[1].UserID)
	end)
	
	if not Success or not HumanoidDescription then
		return
	end
	
	-- Update the dummy
	LeaderDummy.Humanoid:ApplyDescription(HumanoidDescription)
	LeaderDummy.Humanoid.DisplayName = DataCache[1].Username
	
	-- Dance animation
	for _, track in ipairs(LeaderDummy.Humanoid:GetPlayingAnimationTracks()) do
		if track.Name == "FirstPlaceDanceAnim" then
			track:Stop()
			track:Destroy()
		end
	end
	
	local danceIds = {507771019, 507771955, 507772104}
	local animId = danceIds[math.random(1, #danceIds)]
	
	local danceAnim = Instance.new("Animation")
	danceAnim.Name = "FirstPlaceDanceAnim"
	danceAnim.AnimationId = "rbxassetid://" .. animId
	danceAnim.Parent = LeaderDummy.Humanoid
	
	local danceTrack = LeaderDummy.Humanoid:LoadAnimation(danceAnim)
	danceTrack.Looped = true
	danceTrack:Play()
	
	-- Update the TextLabel with the top player's wins
	LeaderboardModel["1stPlaceStand"].Wins.BillboardGui.TextLabel.Text = "Wins: " .. tostring(DataCache[1].Wins)
	
end


-- Event Functions --

LeaderboardDataRequestEvent.OnServerEvent:Connect(function(RequestingPlayer)
	UpdateLeaderboardsEvent:FireClient(RequestingPlayer, DataCache)
end)


-- Loops --

while true do
	
	UpdateCurrentDatastore()
	
	-- Write wins to DataStore
	writeAllWinsToDataStore()
	
	-- Get top leaders
	getTopLeaders()
	
	-- Update the top player dummy
	UpdateDummy()
	
	-- Broadcast to all clients
	UpdateLeaderboardsEvent:FireAllClients(DataCache)
	
	-- Wait
	wait(UpdateInterval)
	
end
