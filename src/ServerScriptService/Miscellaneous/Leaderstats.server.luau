
-- Constants --


-- Event Functions --

game.Players.PlayerAdded:Connect(function(NewPlayer)
	
	local PlayerData = game.ReplicatedStorage.PlayerData:WaitForChild(NewPlayer.Name, 60)
	if not PlayerData then
		return
	end
	
	local NewLeaderstatsFolder = Instance.new("Folder")
	NewLeaderstatsFolder.Name = "leaderstats"
	
	local WinStat = Instance.new("IntValue")
	WinStat.Name = "Wins"
	WinStat.Value = PlayerData.CareerStats.TotalWins.Value
	WinStat.Parent = NewLeaderstatsFolder
	
	local CoinStat = Instance.new("IntValue")
	CoinStat.Name = "Coins"
	CoinStat.Value = PlayerData.Economy.Coins.Value
	CoinStat.Parent = NewLeaderstatsFolder
	
	NewLeaderstatsFolder.Parent = NewPlayer
	
	-- Cursed
	PlayerData.Economy.Coins.Changed:Connect(function()
		CoinStat.Value = PlayerData.Economy.Coins.Value
	end)
	
end)

