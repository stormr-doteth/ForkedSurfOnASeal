
-- Constants --

local PlayersFolder = game.ReplicatedStorage.GameStats.Players
local IncrementStatEvent = game.ReplicatedStorage.Networking.Server.RemoteEvents.IncrementGameStat


-- Settings --

local PlayerChangableValues = {
	["TreesHit"] = true,
	["RocksSmashed"] = true,
	["WallsCrushed"] = true,
	["PostsSmashed"] = true,
	["LogsHit"] = true,
	["SignsSmashed"] = true,
}


-- Event Functions --

game.Players.PlayerAdded:Connect(function(NewPlayer)
	local NewPlayerGameStatsFolder = script.PlayerGameStatsTemplate:Clone()
	NewPlayerGameStatsFolder.Name = NewPlayer.Name
	NewPlayerGameStatsFolder.Parent = PlayersFolder
end)

game.Players.PlayerRemoving:Connect(function(RemovingPlayer)
	local RemovingPlayerGameStatsFolder = PlayersFolder:FindFirstChild(RemovingPlayer.Name)
	if RemovingPlayerGameStatsFolder then
		RemovingPlayerGameStatsFolder:Destroy()
	end
end)

IncrementStatEvent.OnServerEvent:Connect(function(RequestingPlayer, GameStat, Stunned)
	
	local PlayerGameStatsFolder = PlayersFolder:FindFirstChild(RequestingPlayer.Name)
	if not PlayerGameStatsFolder then
		return
	end
	
	if not PlayerChangableValues[GameStat] then
		return
	end
	
	local PlayerData = game.ReplicatedStorage.PlayerData:FindFirstChild(RequestingPlayer.Name, 60)
	if not PlayerData then
		return
	end
	
	if Stunned then
		PlayerData.CareerStats.ObstaclesHit.Value = PlayerData.CareerStats.ObstaclesHit.Value + 1
	else
		PlayerData.CareerStats.ObstaclesSmashed.Value = PlayerData.CareerStats.ObstaclesSmashed.Value + 1
	end
	
	PlayerGameStatsFolder[GameStat].Value = PlayerGameStatsFolder[GameStat].Value + 1
	
end)