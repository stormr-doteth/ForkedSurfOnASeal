
-- Constants --

local AnalyticsService = game:GetService("AnalyticsService")


-- Variables --

local AnalyticsCache = {}


-- Settings --

local AnalyticLimits = {
	["Shop Depth"] = {"Player Joined", "Opened UI", "Went to New Page", "Made purchase"},
	["Gift Depth"] = {"Player Joined", "Opened UI", "1st Gift", "2nd Gift", "3rd Gift", "4th Gift", "5th Gift", "6th Gift", "7th Gift", "8th Gift", "9th Gift"},
	["MySeal Depth"] = {"Player Joined", "Opened UI", "Equipped Item"},
	["Prize Depth"] = {"Player Joined", "1st Prize", "2nd Prize", "3rd Prize", "4th Prize", "5th Prize", "6th Prize", "7th Prize", "8th Prize", "9th Prize", "10th Prize", "11th Prize"},
	["Invite Depth"] = {"Player Joined", "Opened UI", "Invited a Friend"},
	["Daily Depth"] = {"Player Joined", "Day 1", "Day 2", "Day 3", "Day 4", "Day 5", "Day 6", "Day 7"},
}


-- Functions --

local function RecordAnalytic(Player, AnalyticName, StepNum, FunnelSessionID)
	
	if not AnalyticLimits[AnalyticName] then
		return
	end

	if StepNum > #AnalyticLimits[AnalyticName] then
		return
	end
	
	if not AnalyticsCache[Player] then
		AnalyticsCache[Player] = {}
	end
	
	if not AnalyticsCache[Player][AnalyticName] then
		AnalyticsCache[Player][AnalyticName] = {}
	end
	
	-- Make sure this step hasn't already been triggered this session to reduce spam
	if AnalyticsCache[Player][AnalyticName][tostring(StepNum)] then
		return
	end
	
	AnalyticsCache[Player][AnalyticName][tostring(StepNum)] = true
	
	--print(AnalyticName, StepNum, FunnelSessionID)
	
	AnalyticsService:LogFunnelStepEvent(
		Player,
		AnalyticName,
		FunnelSessionID or "",
		StepNum,
		AnalyticLimits[AnalyticName][StepNum]
	)
	
end


-- Event Functions --

game.ReplicatedStorage.Networking.Server.RemoteEvents.RecordAnalytic.OnServerEvent:Connect(RecordAnalytic)
game.ReplicatedStorage.Networking.Server.BindableEvents.RecordAnalytic.Event:Connect(RecordAnalytic)


-- Start funnels for new players
game.Players.PlayerAdded:Connect(function(NewPlayer)
	
	AnalyticsService:LogOnboardingFunnelStepEvent(
		NewPlayer,
		1,
		"Player Joined"
	)
	wait(1)
	AnalyticsService:LogFunnelStepEvent(
		NewPlayer,
		"Shop Depth",
		"",
		1,
		AnalyticLimits["Shop Depth"][1]
	)
	wait(1)
	AnalyticsService:LogFunnelStepEvent(
		NewPlayer,
		"Gift Depth",
		"",
		1,
		AnalyticLimits["Gift Depth"][1]
	)
	wait(1)
	AnalyticsService:LogFunnelStepEvent(
		NewPlayer,
		"MySeal Depth",
		"",
		1,
		AnalyticLimits["MySeal Depth"][1]
	)
	wait(1)
	AnalyticsService:LogFunnelStepEvent(
		NewPlayer,
		"Invite Depth",
		"",
		1,
		AnalyticLimits["Invite Depth"][1]
	)
	wait(1)
	AnalyticsService:LogFunnelStepEvent(
		NewPlayer,
		"Prize Depth",
		"",
		1,
		AnalyticLimits["Prize Depth"][1]
	)
	wait(1)
	
	local PlayerData = game.ReplicatedStorage.PlayerData:WaitForChild(NewPlayer.Name, 60)
	local WeekID = PlayerData.Miscellaneous.DailyRewardInfo.WeekID.Value
	--print(WeekID)
	AnalyticsService:LogFunnelStepEvent(
		NewPlayer,
		"Daily Depth",
		WeekID,
		1,
		AnalyticLimits["Daily Depth"][1]
	)
	
end)

game.Players.PlayerRemoving:Connect(function(RemovingPlayer)
	AnalyticsCache[RemovingPlayer] = nil
end)