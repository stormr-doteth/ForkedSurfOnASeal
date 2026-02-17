
-- Constants --

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local WinsDataStore = DataStoreService:GetOrderedDataStore("GlobalWinsLeaderboard_Cured")
local UpdateLeaderboardsEvent = game.ReplicatedStorage.Networking.Client.RemoteEvents.GlobalLeaderboardUpdate
local LeaderboardDataRequestEvent = game.ReplicatedStorage.Networking.Server.RemoteEvents.RequestLeaderboardData

local LeaderboardModel = workspace.Lobby.GlobalLeaderboard
local LeaderDummy = LeaderboardModel["1stPlaceStand"].Dummy


-- Settings --

local EntryListSize = 100
local UpdateInterval = 60


-- Variables --

local DataCache = {}
local UsernameCache = {}


-- Functions --

-- Utility: Write player wins to DataStore
local function writeAllWinsToDataStore()
	for _, Player in pairs (game.Players:GetPlayers()) do
		if Player.UserId > 0 then
			local PlayerDataFolder = game.ReplicatedStorage.PlayerData:FindFirstChild(Player.Name)
			if PlayerDataFolder then
				WinsDataStore:SetAsync(Player.UserId, PlayerDataFolder.CareerStats.TotalWins.Value)
			end
		end
	end
end

-- Utility: Fetch top N entries
local function getTopLeaders()
	
	local Success, Pages = pcall(function()
		return WinsDataStore:GetSortedAsync(false, EntryListSize)
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
local function UpdateDummy(poop)
	
	local LeaderDummy = poop["1stPlaceStand"].Dummy
	
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
	poop["1stPlaceStand"].Wins.BillboardGui.TextLabel.Text = "Wins: " .. tostring(DataCache[1].Wins)
	
end


-- Event Functions --

LeaderboardDataRequestEvent.OnServerEvent:Connect(function(RequestingPlayer)
	UpdateLeaderboardsEvent:FireClient(RequestingPlayer, DataCache)
end)


-- Loops --

while true do
	
	-- Write wins to DataStore
	writeAllWinsToDataStore()
	
	-- Get top leaders
	getTopLeaders()
	
	-- Update the top player dummy
	UpdateDummy(LeaderboardModel)
	
	if workspace.CurrentMap:FindFirstChild("EndPlatform") then
		UpdateDummy(workspace.CurrentMap.EndPlatform.GlobalLeaderboard)
	end
	
	-- Broadcast to all clients
	UpdateLeaderboardsEvent:FireAllClients(DataCache)
	
	-- Wait
	wait(UpdateInterval)
	
end
