-- Place this script in ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local MessagingService = game:GetService("MessagingService") 
local HttpService = game:GetService("HttpService")

--------------------------------------------------
-- CONFIGURATION
--------------------------------------------------
local ADMIN_KEY_NAME = "` (backtick)"  -- Keep this in sync with client script's ADMIN_KEY
local TEST_MODE = false -- Set to false when done testing
local MIN_SHUTDOWN_TIME = 5 -- Minimum shutdown time in seconds (sync with client script)

-- Topic name for messaging service
local SHUTDOWN_TOPIC = "GameServerShutdown"

-- List of authorized admin usernames
local AUTHORIZED_ADMINS = {
	["stormcell"] = true,
	["skill24"] = true
}

-- Create Remote Events for client-server communication
local remotes = Instance.new("Folder")
remotes.Name = "ShutdownRemotes"
remotes.Parent = ReplicatedStorage

local initiateShutdownEvent = Instance.new("RemoteEvent")
initiateShutdownEvent.Name = "InitiateShutdown"
initiateShutdownEvent.Parent = remotes

local updateTimerEvent = Instance.new("RemoteEvent")
updateTimerEvent.Name = "UpdateTimer"
updateTimerEvent.Parent = remotes

-- Variable to track if a shutdown is already in progress
local isShuttingDown = false

--------------------------------------------------
-- UTILITY FUNCTIONS
--------------------------------------------------
-- Function to validate shutdown time
local function validateShutdownTime(seconds)
	-- Debug output to trace the input value
	print("validateShutdownTime received: " .. tostring(seconds) .. " (type: " .. type(seconds) .. ")")

	-- Make sure it's at least the minimum time
	if not seconds or type(seconds) ~= "number" or seconds < MIN_SHUTDOWN_TIME then
		print("Invalid time value. Using minimum: " .. MIN_SHUTDOWN_TIME)
		return MIN_SHUTDOWN_TIME
	end

	print("Validated time: " .. seconds)
	return seconds
end

-- Function to check if a player is authorized
local function isAuthorized(player)
	if TEST_MODE then
		return true -- In test mode, all players are admins
	else
		return AUTHORIZED_ADMINS[player.Name] ~= nil
	end
end

--------------------------------------------------
-- SHUTDOWN SEQUENCE FUNCTIONS
--------------------------------------------------
-- Function to start shutdown sequence on this server
local function startShutdownSequence(seconds, message, adminName)
	-- Ensure the seconds parameter is actually a number
	seconds = tonumber(seconds) or MIN_SHUTDOWN_TIME

	-- Debug output to verify the time value
	print("startShutdownSequence with seconds = " .. tostring(seconds))

	-- Prevent multiple shutdown sequences
	if isShuttingDown then
		print("Shutdown already in progress. Ignoring request.")
		return
	end

	isShuttingDown = true
	print("Starting shutdown sequence initiated by " .. adminName .. " for " .. seconds .. " seconds")

	-- Notify all clients about the shutdown
	updateTimerEvent:FireAllClients(seconds, message)

	-- Start the countdown on the server
	local timeRemaining = seconds

	-- Create a loop to update the timer
	while timeRemaining > 0 do
		wait(1)
		timeRemaining = timeRemaining - 1
		updateTimerEvent:FireAllClients(timeRemaining, message)
	end

	print("Shutdown timer expired, teleporting players to new servers")

	-- Teleport all players to new servers
	local playerArray = Players:GetPlayers()

	-- Create a new access code for a reserved server
	local success, accessCode = pcall(function()
		return TeleportService:ReserveServer(game.PlaceId)
	end)

	if not success then
		print("Failed to reserve server: " .. tostring(accessCode))
		return
	end

	-- Teleport all players to the new reserved server
	for _, playerToTeleport in pairs(playerArray) do
		-- Use pcall to handle any teleport failures
		pcall(function()
			print("Teleporting player: " .. playerToTeleport.Name)
			TeleportService:TeleportToPrivateServer(
				game.PlaceId, 
				accessCode, 
				{playerToTeleport}, 
				nil,  -- No custom teleport data
				nil   -- No teleport options
			)
		end)
	end
end

-- Function to publish shutdown message to all servers
local function broadcastShutdown(player, seconds, message)
	-- Verify the player is authorized
	if not isAuthorized(player) then
		print(player.Name .. " attempted to initiate global shutdown but is not authorized")
		return
	end

	-- Make sure seconds is a number
	seconds = tonumber(seconds)
	if not seconds then
		print("Invalid seconds value in broadcastShutdown: " .. tostring(seconds))
		seconds = MIN_SHUTDOWN_TIME
	end

	print("Authorized admin " .. player.Name .. " initiated global server shutdown with " .. seconds .. " seconds")

	-- Create the message data
	local shutdownData = {
		adminName = player.Name,
		seconds = seconds,
		message = message,
		timestamp = os.time(), -- To prevent replay attacks
		signature = HttpService:GenerateGUID(false) -- Unique signature for this shutdown
	}

	-- Convert to JSON
	local jsonData = HttpService:JSONEncode(shutdownData)

	-- Debug output
	print("Broadcasting shutdown data: " .. jsonData)

	-- Publish to all servers
	local success, error = pcall(function()
		MessagingService:PublishAsync(SHUTDOWN_TOPIC, jsonData)
	end)

	if not success then
		print("Failed to broadcast shutdown: " .. tostring(error))
		-- Start shutdown on this server anyway
		startShutdownSequence(seconds, message, player.Name)
	else
		print("Successfully broadcast shutdown to all servers")
		-- We don't need to call startShutdownSequence here as this server will receive the message too
	end
end

--------------------------------------------------
-- MESSAGE HANDLERS
--------------------------------------------------
-- Function to handle messages from other servers
local function handleShutdownMessage(message)
	-- Decode the message
	local success, shutdownData = pcall(function()
		return HttpService:JSONDecode(message.Data)
	end)

	if not success then
		print("Failed to decode shutdown message")
		return
	end

	-- Debug output
	print("Received shutdown message: " .. message.Data)

	-- Validate the message
	if shutdownData and 
		shutdownData.adminName and 
		shutdownData.seconds and 
		shutdownData.message and
		(TEST_MODE or AUTHORIZED_ADMINS[shutdownData.adminName]) then

		-- Explicitly convert to number
		local seconds = tonumber(shutdownData.seconds)
		if not seconds then
			print("Invalid seconds value in message: " .. tostring(shutdownData.seconds))
			seconds = MIN_SHUTDOWN_TIME
		end

		-- Validate the time (ensure it's at least the minimum)
		if seconds < MIN_SHUTDOWN_TIME then
			print("Time in message below minimum. Using: " .. MIN_SHUTDOWN_TIME)
			seconds = MIN_SHUTDOWN_TIME
		end

		-- Start the shutdown sequence
		startShutdownSequence(
			seconds,
			shutdownData.message,
			shutdownData.adminName
		)
	else
		print("Received invalid shutdown message")
	end
end

-- Function to handle shutdown request from an admin on this server
local function handleShutdownRequest(player, seconds, message)
	-- Debug output to trace the input values
	print("handleShutdownRequest received - Player: " .. player.Name .. 
		", Seconds: " .. tostring(seconds) .. " (type: " .. type(seconds) .. "), Message: " .. tostring(message))

	-- Ensure seconds is a number
	seconds = tonumber(seconds)
	if not seconds then
		print("Invalid seconds value, using minimum: " .. MIN_SHUTDOWN_TIME)
		seconds = MIN_SHUTDOWN_TIME
	end

	-- Ensure it's at least the minimum time
	if seconds < MIN_SHUTDOWN_TIME then
		print("Time below minimum. Using: " .. MIN_SHUTDOWN_TIME)
		seconds = MIN_SHUTDOWN_TIME
	end

	-- This will broadcast to all servers including this one
	broadcastShutdown(player, seconds, message)
end

--------------------------------------------------
-- INITIALIZATION
--------------------------------------------------
-- Connect to MessagingService
local function subscribeToShutdowns()
	local success, connection = pcall(function()
		return MessagingService:SubscribeAsync(SHUTDOWN_TOPIC, handleShutdownMessage)
	end)

	if success then
		--print("Successfully subscribed to shutdown topic")
	else
		print("Failed to subscribe to shutdown topic: " .. tostring(connection))
		-- Try again after a delay
		wait(5)
		subscribeToShutdowns()
	end
end

-- Initialize subscription to shutdown messages
subscribeToShutdowns()

-- Connect the remote event to the handler function
initiateShutdownEvent.OnServerEvent:Connect(handleShutdownRequest)

-- Give the admin console to authorized players when they join
Players.PlayerAdded:Connect(function(player)
	if isAuthorized(player) then
		print("Admin " .. player.Name .. " joined. Giving admin console.")
		-- Create a BoolValue to trigger the client to show the admin GUI
		local isAdmin = Instance.new("BoolValue")
		isAdmin.Name = "IsShutdownAdmin"
		isAdmin.Value = true
		isAdmin.Parent = player
	end
end)

-- Also check existing players when script loads (in case of script reloading)
for _, player in pairs(Players:GetPlayers()) do
	if isAuthorized(player) and not player:FindFirstChild("IsShutdownAdmin") then
		--print("Giving existing admin " .. player.Name .. " the admin console.")
		local isAdmin = Instance.new("BoolValue")
		isAdmin.Name = "IsShutdownAdmin"
		isAdmin.Value = true
		isAdmin.Parent = player
	end
end

--print("Global server shutdown system initialized with MIN_SHUTDOWN_TIME = " .. MIN_SHUTDOWN_TIME)