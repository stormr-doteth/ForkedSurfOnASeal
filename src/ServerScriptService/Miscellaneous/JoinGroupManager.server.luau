-- Server script for Sappy Friend - Put this in ServerScriptService
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Ensure the RemoteEvent exists
local awardEvent = ReplicatedStorage.Networking.Server.RemoteEvents:FindFirstChild("AwardSappyFriend")
if not awardEvent then
	awardEvent = Instance.new("RemoteEvent")
	awardEvent.Name = "AwardSappyFriend"
	awardEvent.Parent = ReplicatedStorage.Networking.Server.RemoteEvents
	print("Created AwardSappyFriend RemoteEvent")
end

-- Handle award requests
awardEvent.OnServerEvent:Connect(function(player)
	print("AwardSappyFriend event received from: " .. player.Name)

	-- Verify the player is in the group
	if not player:IsInGroup(35583238) then
		print(player.Name .. " is not in the group")
		return
	end

	-- Get player data
	local PlayerData = ReplicatedStorage.PlayerData:FindFirstChild(player.Name)
	if not PlayerData then
		print("PlayerData not found for " .. player.Name)
		return
	end

	-- Check if they already have the item
	if PlayerData.Inventory.Accessory:FindFirstChild("SappyFriend") then
		print(player.Name .. " already has SappyFriend")
		return
	end

	-- Award the item
	local NewMarker = Instance.new("StringValue")
	NewMarker.Name = "SappyFriend"
	NewMarker.Parent = PlayerData.Inventory.Accessory
	--print("Awarded SappyFriend to " .. player.Name)

	-- Notify the player
	ReplicatedStorage.Networking.Client.RemoteEvents.ShowNewItem:FireClient(player, "SappyFriend", nil, true)
	--print("Notification sent to " .. player.Name)
end)

--print("Sappy Friend award server script loaded!")