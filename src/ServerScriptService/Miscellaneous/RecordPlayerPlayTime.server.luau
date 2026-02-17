-- Server: record a JoinTimestamp attribute on each player
local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
	-- os.time() gives seconds since epoch
	player:SetAttribute("JoinTimestamp", os.time())
end)
