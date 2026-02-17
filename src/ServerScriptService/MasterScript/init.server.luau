
-- Constants --

local AnalyticsService = game:GetService("AnalyticsService")

local TeleportCharacter = require(game.ServerScriptService.HelperModules.TeleportCharacter)
local ModifierDirectory = require(game.ReplicatedStorage.Directories.ModifierDirectory)

local UpdateProgressBarEvent = game.ReplicatedStorage.Networking.Client.RemoteEvents.UpdateProgessBar
local RequestTrackDataRemote = game.ReplicatedStorage.Networking.Server.RemoteEvents.RequestTrackData
local SendNotificationEvent = game.ReplicatedStorage.Networking.Client.RemoteEvents.SendNotification
local PromptFriendInviteEvent = game.ReplicatedStorage.Networking.Client.RemoteEvents.PromptFriendInvite
local ClientCleanupEvent = game.ReplicatedStorage.Networking.Client.RemoteEvents.ClientCleanup

local ShowNewItemEvent = game.ReplicatedStorage.Networking.Client.RemoteEvents.ShowNewItem
local ShowModifiersEvent = game.ReplicatedStorage.Networking.Client.RemoteEvents.ShowModifiersEvent
local RaceStartEvent = game.ReplicatedStorage.Networking.Client.RemoteEvents.RaceStartEvent
local RaceFinishEvent = game.ReplicatedStorage.Networking.Client.RemoteEvents.RaceFinishEvent

local GameStats = game.ReplicatedStorage.GameStats
local RoundTimer = GameStats.RoundTimer
local TimerPrefix = GameStats.TimerPrefix
local TimerMultiplier = GameStats.TimerMultiplier


-- Settings --

local IntermissionTime = 40 -- 40
local RoundTime = 360 -- 360
local TrackSegments = 20 -- 20
local SegmentWaitTime = 1 -- 1

local PlacementCoinAwards = {
	["1"] = 50,
	["2"] = 35,
	["3"] = 25,
	["TheRest"] = 10,
}

local PlacementCoinAwardsPro = {
	["1"] = 75,
	["2"] = 50,
	["3"] = 40,
	["TheRest"] = 20,
}



-- Variables --

local LastSegment = workspace.GamePieces.StartingPlatform
local TrackData = {}
local TotalDistance = 0
local CompletedPlayers = {}
local NumCompletedPlayers = 0

local ItemNotificationQueue = {}
local ActiveModifiers = {}
local PlacementData = {}

local RaceStartTime = 0

--[[local PlacementData = {
	[1] = {PlayerName = "Stormcell", Time = "0:00:01", CoinIncrease = 300},
	[2] = {PlayerName = "skill24", Time = "0:00:02", CoinIncrease = 200},
	[3] = {PlayerName = "restartedwiz", Time = "0:00:03", CoinIncrease = 50},
	[4] = {PlayerName = "prev", Time = "0:00:04", CoinIncrease = 25},
	[5] = {PlayerName = "na_fam", Time = "0:00:05", CoinIncrease = 10},
	[6] = {PlayerName = "al", Time = "0:00:06", CoinIncrease = 0},
	[7] = {PlayerName = "zookie", Time = "0:00:07", CoinIncrease = 0},
	[8] = {PlayerName = "lily", Time = "0:00:08", CoinIncrease = 0},
	[9] = {PlayerName = "telamon", Time = "13:33:37", CoinIncrease = 0},
}]]


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

local function SortTableByValue(inputTable)
	local sortedArray = {}

	-- Convert Key-Value pairs into an array
	for key, value in pairs(inputTable) do
		table.insert(sortedArray, {Key = key, Value = value})
	end

	-- Sort the array by Value (ascending order)
	table.sort(sortedArray, function(a, b)
		return a.Value > b.Value
	end)

	return sortedArray
end

-- Teleport characters back to the lobby, but only if they're not already in the lobby :)
local function TeleportOutstandingPlayers()
	for _, Player in pairs (game.Players:GetPlayers()) do
		local Character = Player.Character
		if Character then
			local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
			if HumanoidRootPart then
				if HumanoidRootPart.Position.Z < 5 then
					TeleportCharacter(Player, workspace.GamePieces.WorldStart, true)
				end
			end
		end
	end
end

-- Cleanup function
local function CleanUp()
	
	local otherplacementdatalol = PlacementData
	
	for _, Player in pairs (game.Players:GetPlayers()) do
		if not CompletedPlayers[Player.Name] then
			table.insert(otherplacementdatalol, {Placement = "-", PlayerName = Player.Name, DisplayName = Player.DisplayName, Time = "--:--:--", CoinIncrease = 0})
		end
	end
	
	-- Prompt the end game screen for those who did not finish in time
	for _, Player in pairs (game.Players:GetPlayers()) do
		local Success, Message = pcall(function()
			
			local PlayerGameStatsFolder = game.ReplicatedStorage.GameStats.Players:FindFirstChild(Player.Name)
			
			local StatTable = {}
			for _, GameStatValue in pairs (PlayerGameStatsFolder:GetChildren()) do
				if GameStatValue.Name ~= "CurrentCheckpoint" then
					StatTable[GameStatValue.Name] = GameStatValue.Value
				end
			end
			
			local SortedArray = SortTableByValue(StatTable)
			
			local StuffTable = {}
			
			StuffTable[SortedArray[1].Key] = SortedArray[1].Value
			StuffTable[SortedArray[2].Key] = SortedArray[2].Value
			StuffTable[SortedArray[3].Key] = SortedArray[3].Value
			StuffTable[SortedArray[4].Key] = SortedArray[4].Value
			
			game.ReplicatedStorage.Networking.Client.RemoteEvents.ShowEndGameScreen:FireClient(Player, otherplacementdatalol, StuffTable)
			
			if ItemNotificationQueue[Player.Name] then
				ShowNewItemEvent:FireClient(Player, ItemNotificationQueue[Player.Name], nil, false, true)
				ItemNotificationQueue[Player.Name] = nil
			end
			
		end)
		if not Success then
			pcall(function()
				warn("RaceEndErrorInMasterScript: " .. Message)
			end)
		end
	end
	
	-- Close the starting door
	workspace.GamePieces.StartingDoor.CanCollide = true
	workspace.GamePieces.StartingDoor.Transparency = 0.5
	
	-- Reset variables
	LastSegment = workspace.GamePieces.StartingPlatform
	TrackData = {}
	TotalDistance = 0
	CompletedPlayers = {}
	NumCompletedPlayers = 0
	TimerMultiplier.Value = 0
	
	-- Get rid of the current map
	workspace.CurrentMap:ClearAllChildren()
	
	-- Log all the Coins picked up before it's reset
	for _, PlayerGameStatFolder in pairs (game.ReplicatedStorage.GameStats.Players:GetChildren()) do
		
		local LoggingPlayer = game.Players:FindFirstChild(PlayerGameStatFolder.Name)
		local PlayerData = game.ReplicatedStorage.PlayerData:FindFirstChild(PlayerGameStatFolder.Name)
		local CoinsCollected = PlayerGameStatFolder.CoinsCollected.Value
		
		-- Only log if above 0, negatives are used to denote that it's already been logged lol
		if LoggingPlayer and PlayerData and CoinsCollected >= 0 then
			
			AnalyticsService:LogEconomyEvent(
				LoggingPlayer,
				Enum.AnalyticsEconomyFlowType.Source,
				"Coins",
				CoinsCollected, -- Amount collected
				PlayerData.Economy.Coins.Value, -- Current balance
				Enum.AnalyticsEconomyTransactionType.Gameplay.Name, -- Transaction type
				"Track Pickups"
			)
			
		end
		
	end
	
	
	-- Reset all the PlayerGameStatsFolders
	for _, PlayerGameStatFolder in pairs (game.ReplicatedStorage.GameStats.Players:GetChildren()) do
		for _, Child in pairs (PlayerGameStatFolder:GetChildren()) do
			if Child.Name ~= "CurrentCheckpoint" then
				Child.Value = 0
			else
				Child.Value = nil
			end
		end
	end
	
	-- Reset player boosts
	game.ReplicatedStorage.Networking.Client.RemoteEvents.ResetBoostInventory:FireAllClients()
	
	-- Notify players that the round ended
	for _, Player in pairs(game.Players:GetPlayers()) do
		SendNotificationEvent:FireClient(Player, "Round ended! Starting new round...", Color3.fromRGB(255, 230, 44))
	end
	
	TeleportOutstandingPlayers()
	
	for _, Player in pairs (game.Players:GetPlayers()) do
		local PlayerData = game.ReplicatedStorage.PlayerData:FindFirstChild(Player.Name)
		if PlayerData then
			if PlayerData.Settings.FriendPromptEnabled.Value then
				PromptFriendInviteEvent:FireClient(Player)
			end
		end
	end
	
	-- Turn off any modifiers
	for _, ModifierModule in pairs (script.Modifiers:GetChildren()) do
		require(ModifierModule).StopModifier()
	end
	
	-- Release any modifier locks
	game.ReplicatedStorage.Networking.Server.BindableEvents.ReleaseModiferLock:Fire()
	
	PlacementData = {}
	
	ClientCleanupEvent:FireAllClients()
	
end

-- Used for getting a nice variety of track segments
local function SelectItemsWeighted(items, numSelections)
	if #items == 0 then return {} end -- Return empty if no items provided

	local selectedItems = {} -- Store selected items
	local weights = {} -- Store item weights
	local lastPicked = nil -- Track last picked item

	-- Initialize weights (start all equal)
	for i = 1, #items do
		weights[i] = 1
	end
	
	math.randomseed(os.time())
	
	for _ = 1, numSelections do
		-- Create a weighted pool (ignoring last picked)
		local totalWeight = 0
		for i, weight in ipairs(weights) do
			if i ~= lastPicked then
				totalWeight = totalWeight + weight
			end
		end

		-- Pick a weighted random item
		local rand = math.random() * totalWeight
		local cumulative = 0
		local chosenIndex = nil

		for i, weight in ipairs(weights) do
			if i ~= lastPicked then
				cumulative = cumulative + weight
				if rand <= cumulative then
					chosenIndex = i
					break
				end
			end
		end

		-- Store selection
		table.insert(selectedItems, items[chosenIndex])
		lastPicked = chosenIndex

		-- Reduce weight of chosen item, increase others slightly
		for i = 1, #weights do
			if i == chosenIndex then
				weights[i] = weights[i] * 0.5 -- Reduce weight of selected
			else
				weights[i] = weights[i] + 0.1 -- Slightly boost others
			end
		end
	end

	return selectedItems
end

-- Builds the track with respect to the settings above
local function BuildTrack()
	
	-- Get a list of the segments to be cloned
	local SelectedSegments = SelectItemsWeighted(game.ServerStorage.TrackSegments:GetChildren(), TrackSegments)
	
	-- Build TrackData ahead of time to keep plebs from giga-lagging
	for i, RandomSegment in pairs (SelectedSegments) do
		
		-- Build the TrackData used for the client's progress bars
		local SegmentDistance = RandomSegment.TrackLength.Value
		table.insert(TrackData, SegmentDistance)
		
		-- Increment total distance
		TotalDistance = TotalDistance + SegmentDistance
		
	end
	
	-- Send off the track data
	UpdateProgressBarEvent:FireAllClients(TrackData, TotalDistance)
	
	-- Begin building the track
	for i, RandomSegment in pairs (SelectedSegments) do
		
		-- Create the new segment and set it up
		local NewSegment = RandomSegment:Clone()
		NewSegment:PivotTo(LastSegment.TrackEnd.CFrame)
		NewSegment.TrackStart.Transparency = 1
		NewSegment.TrackEnd.Transparency = 1
		
		if i == 1 then
			NewSegment.CheckpointArch:Destroy()
		end
		
		NewSegment.SegmentNumber.Value = i
		
		NewSegment.Parent = workspace.CurrentMap
		
		-- Set LastSegment so that the next loop can use it
		LastSegment = NewSegment
		
		-- Turn TrackStart and TrackEnd invisible
		NewSegment.TrackStart.Transparency = 1
		NewSegment.TrackEnd.Transparency = 1
		
		if SegmentWaitTime > 0 then
			wait(SegmentWaitTime)
		end
		
	end
	
	-- Put the end platform at the end
	local NewEndPlatform = game.ServerStorage.EndPlatform:Clone()
	NewEndPlatform:PivotTo(LastSegment.TrackEnd.CFrame)
	NewEndPlatform.Parent = workspace.CurrentMap
	
end

local function FormatTime(seconds)
	local minutes = math.floor(seconds / 60) -- Get whole minutes
	local secs = seconds % 60 -- Get remaining seconds
	return string.format("%02d:%02d", minutes, secs) -- Format as MM:SS
end

--[[local function FormatPlacement(Placement)
	if Placement == 1 then
		return "1st"
	elseif Placement == 2 then
		return "2nd"
	elseif Placement == 3 then
		return "3rd"
	else
		return Placement .. "th"
	end
end]]

local function GenerateNewModifiers()
	
	ActiveModifiers = {}
	
	math.randomseed(os.time())
	
	for i = 1, 3 do
		local SelectedModifier = nil
		repeat
			SelectedModifier = ModifierDirectory.ActiveModifiers[math.random(1, #ModifierDirectory.ActiveModifiers)]
		until ActiveModifiers[SelectedModifier] == nil
		ActiveModifiers[SelectedModifier] = true
	end
	
end


-- Event Functions --

script.QueueItemNotification.Event:Connect(function(Player, ItemName)
	ItemNotificationQueue[Player.Name] = ItemName
end)

script.PlayerCompleted.Event:Connect(function(CompletedPlayer)
	
	if CompletedPlayers[CompletedPlayer.Name] then
		return
	end
	
	CompletedPlayers[CompletedPlayer.Name] = true
	NumCompletedPlayers = NumCompletedPlayers + 1
	TimerMultiplier.Value = NumCompletedPlayers + 1
	
	local PlayerData = game.ReplicatedStorage.PlayerData:FindFirstChild(CompletedPlayer.Name)
	
	local CoinAward = 0
	if game.PlaceId == 113818546781660 or game.PlaceId == 133336354844478 then -- the normal servers
		CoinAward = PlacementCoinAwards[tostring(NumCompletedPlayers)]
		if not CoinAward then
			CoinAward = PlacementCoinAwards["TheRest"]
		end
	else
		CoinAward = PlacementCoinAwardsPro[tostring(NumCompletedPlayers)]
		if not CoinAward then
			CoinAward = PlacementCoinAwardsPro["TheRest"]
		end
	end
	
	
	local WeeklyID = GetWeeklyID()
	if not PlayerData.CareerStats.WeeklyWins:FindFirstChild(WeeklyID) then
		local NewMarker = Instance.new("IntValue")
		NewMarker.Name = WeeklyID
		NewMarker.Parent = PlayerData.CareerStats.WeeklyWins
	end
	
	PlayerData.CareerStats.WeeklyWins[WeeklyID].Value = PlayerData.CareerStats.WeeklyWins[WeeklyID].Value + 1

	PlayerData.CareerStats.TotalWins.Value = PlayerData.CareerStats.TotalWins.Value + 1
	PlayerData.Economy.Coins.Value = PlayerData.Economy.Coins.Value + CoinAward
	PlayerData.CareerStats.TotalCoinsCollected.Value = PlayerData.CareerStats.TotalCoinsCollected.Value + CoinAward
	
	-- Log coins earned from placement
	AnalyticsService:LogEconomyEvent(
		CompletedPlayer,
		Enum.AnalyticsEconomyFlowType.Source,
		"Coins",
		CoinAward, -- Amount earned
		PlayerData.Economy.Coins.Value, -- Current balance
		Enum.AnalyticsEconomyTransactionType.Gameplay.Name, -- Transaction type
		"Placement Awards"
	)
	
	-- Log how many coins they picked up (and set it to -1 so it's not logged again in CleanUp() lol)
	local PlayerGameStatsFolder = game.ReplicatedStorage.GameStats.Players:FindFirstChild(CompletedPlayer.Name)
	if PlayerGameStatsFolder and PlayerGameStatsFolder.CoinsCollected.Value >= 0 then
		AnalyticsService:LogEconomyEvent(
			CompletedPlayer,
			Enum.AnalyticsEconomyFlowType.Source,
			"Coins",
			PlayerGameStatsFolder.CoinsCollected.Value, -- Amount collected
			PlayerData.Economy.Coins.Value, -- Current balance
			Enum.AnalyticsEconomyTransactionType.Gameplay.Name, -- Transaction type
			"Track Pickups"
		)
		PlayerGameStatsFolder.CoinsCollected.Value = -1 -- Turn it to -1 so CleanUp() won't log this info twice lol
	end
	
	
	local TimeTaken = os.clock() - RaceStartTime
	if TimeTaken < PlayerData.CareerStats.BestTime.Value then
		PlayerData.CareerStats.BestTime.Value = TimeTaken
		SendNotificationEvent:FireClient(CompletedPlayer, "NEW BEST TIME!! (" .. FormatTime(TimeTaken) .. ")" , Color3.fromRGB(255, 230, 44))
	end
	
	CompletedPlayer.leaderstats.Wins.Value = PlayerData.CareerStats.TotalWins.Value
	
	-- Write them to PlacementData
	table.insert(PlacementData, {Placement = NumCompletedPlayers, PlayerName = CompletedPlayer.Name, DisplayName = CompletedPlayer.DisplayName, Time = FormatTime(TimeTaken), CoinIncrease = CoinAward})
	
	RaceFinishEvent:FireClient(CompletedPlayer, NumCompletedPlayers)
	
	--[[[local PlayerGameStatsFolder = game.ReplicatedStorage.GameStats.Players:FindFirstChild(CompletedPlayer.Name)
	
	local StatTable = {}
	for _, GameStatValue in pairs (PlayerGameStatsFolder:GetChildren()) do
		StatTable[GameStatValue.Name] = GameStatValue.Value
	end
	
	local SortedArray = SortTableByValue(StatTable)
	
	local StuffTable = {}
	
	StuffTable[SortedArray[1].Key] = SortedArray[1].Value
	StuffTable[SortedArray[2].Key] = SortedArray[2].Value
	StuffTable[SortedArray[3].Key] = SortedArray[3].Value
	StuffTable[SortedArray[4].Key] = SortedArray[4].Value
		
	local HeaderText = "You got " .. FormatPlacement(NumCompletedPlayers) .. " place!"
	local TimeText = "You completed the race in " .. FormatTime(TimeTaken) .. "!"
	
	game.ReplicatedStorage.Networking.Client.RemoteEvents.ShowEndGameScreen:FireClient(CompletedPlayer, HeaderText, TimeText, CoinAward, StuffTable)
	]]
	if ItemNotificationQueue[CompletedPlayer.Name] then
		ShowNewItemEvent:FireClient(CompletedPlayer, ItemNotificationQueue[CompletedPlayer.Name], nil, false, true)
		ItemNotificationQueue[CompletedPlayer.Name] = nil
	end
	
	--TeleportCharacter(CompletedPlayer, workspace.GamePieces.WorldStart, false)
	
	for _, Player in pairs (game.Players:GetPlayers()) do
		if Player ~= CompletedPlayer then
			SendNotificationEvent:FireClient(Player, CompletedPlayer.DisplayName .. " has completed the run! Time speeding up!", Color3.fromRGB(255, 79, 82))
		end
	end
	
end)

-- Send the most recent TrackData to whichever client requests it (players who join mid-match)
RequestTrackDataRemote.OnServerEvent:Connect(function(RequestingPlayer)
	if TrackData then
		UpdateProgressBarEvent:FireClient(RequestingPlayer, TrackData, TotalDistance)
	end
end)


-- Main Loop --

-- Vijamo games
while true do
	
	-- Generate a new map
	spawn(BuildTrack)
	
	-- Change the timer prefix
	TimerPrefix.Value = "Intermission: "
	
	-- Generate some new run modifiers
	GenerateNewModifiers()
	
	-- Wait for intermission
	for i = (IntermissionTime), 1, -1 do
		RoundTimer.Value = i
		if i == 20 then
			ShowModifiersEvent:FireAllClients(ActiveModifiers)
		end
		if i == 10 then
			RaceStartEvent:FireAllClients()
		end
		if i == 5 then
			TeleportOutstandingPlayers() -- make sure no one is being naughty
		end
		wait(1)
	end
	
	-- Change the timer prefix
	TimerPrefix.Value = "Time Left: "
	
	-- Open the starting door
	workspace.GamePieces.StartingDoor.CanCollide = false
	workspace.GamePieces.StartingDoor.Transparency = 1
	
	-- Log when the race started
	RaceStartTime = os.clock()
	
	-- Wait lol
	for i = RoundTime - 1, 0, -1 do
		RoundTimer.Value = i
		wait(1 / (1 + NumCompletedPlayers))
	end
	
	-- Cleanup the old round
	CleanUp()
	
end



-- Debug lol --

--[[for _, Track in pairs (game.ServerStorage.TrackSegments:GetChildren()) do
	local a = Instance.new("IntValue")
	a.Value = Track.TrackStart.Position.Z - Track.TrackEnd.Position.Z
	a.Name = "TrackLength"
	a.Parent = Track
end

for _, Track in pairs (game.ServerStorage.TrackSegments:GetChildren()) do
	if Track:FindFirstChild("TrackLength") then
		Track.TrackLength:Destroy()
	end
end
]]