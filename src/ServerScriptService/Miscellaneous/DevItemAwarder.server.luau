
-- Constants --

local ItemDirectory = require(game.ReplicatedStorage.Directories.ItemDirectory)
local DevAwardEvent = game.ReplicatedStorage.Networking.Server.RemoteEvents.DevAwardEvent


-- Event Functions --

DevAwardEvent.OnServerEvent:Connect(function(RequestingPlayer, TargetItemName, TargetPlayerName)
	
	-- no touchy
	if RequestingPlayer.UserId ~= 1170122 and RequestingPlayer.UserId ~= 3401001 then
		return
	end
	
	local TargetPlayerData = game.ReplicatedStorage.PlayerData:FindFirstChild(TargetPlayerName)
	if not TargetPlayerData then
		return
	end
	
	local SourceData = ItemDirectory[TargetItemName]
	if not SourceData then
		return
	end
	
	local ItemType = SourceData.ItemType
	
	local NewMarker = Instance.new("StringValue")
	NewMarker.Name = TargetItemName
	NewMarker.Parent = TargetPlayerData.Inventory[ItemType]
	
	local TargetPlayer = game.Players[TargetPlayerName]
	game.ReplicatedStorage.Networking.Client.RemoteEvents.ShowNewItem:FireClient(TargetPlayer, TargetItemName, nil, true)
	
end)