
-- Time Trials PlayerDataManager (simplified - no GameStats references)

-- Constants --

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

local IS_STUDIO = game:GetService("RunService"):IsStudio()

local playerDataStore
do
	local ok, store = pcall(function()
		return DataStoreService:GetDataStore("PlayerData")
	end)
	if ok then
		playerDataStore = store
	else
		warn("PlayerDataManager: Could not access DataStore — using template data only. " .. tostring(store))
		playerDataStore = nil
	end
end

local PlayerDataTemplate = script:WaitForChild("PlayerDataTemplate", 60)
local PlayerDataFolders = game.ReplicatedStorage.PlayerData


-- Variables --

local templateTable = nil


-- Settings --

local ALLOW_LOAD_IN_STUDIO = true
local ALLOW_SAVE_IN_STUDIO = false
local ALLOW_LOAD_ONLINE   = true
local ALLOW_SAVE_ONLINE   = true


-- Functions --

local function color3ToTable(color: Color3)
	return { r = color.R, g = color.G, b = color.B }
end

local function tableToColor3(tbl: table)
	return Color3.new(tbl.r, tbl.g, tbl.b)
end

local function folderToTable(folder: Instance): table

	local data = {}

	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("Folder") then
			data[child.Name] = folderToTable(child)
		elseif child:IsA("Color3Value") then
			data[child.Name] = {
				_type = "Color3",
				value = color3ToTable(child.Value)
			}
		elseif child:IsA("ValueBase") then
			data[child.Name] = child.Value
		else
			data[child.Name] = child.Name .. " (Unsupported)"
		end
	end

	return data

end

local function tableToFolder(data: table, folderName: string): Folder

	local newFolder = Instance.new("Folder")
	newFolder.Name = folderName

	for key, value in pairs(data) do
		if type(value) == "table" and value._type == "Color3" and value.value then
			local c3Value = Instance.new("Color3Value")
			c3Value.Name = key
			c3Value.Value = tableToColor3(value.value)
			c3Value.Parent = newFolder
		elseif type(value) == "table" then
			local subFolder = tableToFolder(value, key)
			subFolder.Parent = newFolder
		else
			if type(value) == "number" then
				local numValue = Instance.new("NumberValue")
				numValue.Name = key
				numValue.Value = value
				numValue.Parent = newFolder
			elseif type(value) == "boolean" then
				local boolValue = Instance.new("BoolValue")
				boolValue.Name = key
				boolValue.Value = value
				boolValue.Parent = newFolder
			else
				local strValue = Instance.new("StringValue")
				strValue.Name = key
				strValue.Value = tostring(value)
				strValue.Parent = newFolder
			end
		end
	end

	return newFolder

end

local function reconcileDataWithTemplate(playerData: table, template: table)
	for key, templateValue in pairs(template) do
		local existingValue = playerData[key]
		if existingValue == nil then
			if type(templateValue) == "table" then
				local newSubTable = {}
				reconcileDataWithTemplate(newSubTable, templateValue)
				playerData[key] = newSubTable
			else
				playerData[key] = templateValue
			end

		elseif type(templateValue) == "table" and type(existingValue) == "table" then
			reconcileDataWithTemplate(existingValue, templateValue)
		end
	end
end

local function getTemplateTable()
	if not templateTable then
		templateTable = folderToTable(PlayerDataTemplate)
	end
	return templateTable
end

-- Load the player's data
local function onPlayerAdded(player: Player)

	local userId = player.UserId
	local playerKey = "UserID_" .. tostring(userId) .. "_V2"

	local shouldLoad = false
	if IS_STUDIO then
		shouldLoad = ALLOW_LOAD_IN_STUDIO
	else
		shouldLoad = ALLOW_LOAD_ONLINE
	end

	local decodedTable = nil

	if shouldLoad and playerDataStore then

		local Attempts = 0
		local success = nil
		local savedData = nil

		repeat
			success, savedData = pcall(function()
				return playerDataStore:GetAsync(playerKey)
			end)
			if not success then
				Attempts = Attempts + 1
				wait(3)
			end
		until success or Attempts >= 10

		if not success then
			warn("Failed to load data for " .. player.Name .. ", using template data.")
		end

		if success and savedData then
			local decodeSuccess, decodeResult = pcall(function()
				return HttpService:JSONDecode(savedData)
			end)
			if decodeSuccess and type(decodeResult) == "table" then
				decodedTable = decodeResult
			end
		end
	end

	if not decodedTable then
		decodedTable = folderToTable(PlayerDataTemplate)
	end

	local templateData = getTemplateTable()
	reconcileDataWithTemplate(decodedTable, templateData)

	local playerDataFolder = tableToFolder(decodedTable, player.Name)
	playerDataFolder.Parent = PlayerDataFolders

end

-- Save the player's data
local function onPlayerRemoving(player: Player)

	local userId = player.UserId
	local playerKey = "UserID_" .. tostring(userId) .. "_V2"

	local dataFolder = PlayerDataFolders:FindFirstChild(player.Name)
	if not dataFolder then
		return
	end

	local playerDataTable = folderToTable(dataFolder)

	local shouldSave = false
	if IS_STUDIO then
		shouldSave = ALLOW_SAVE_IN_STUDIO
	else
		shouldSave = ALLOW_SAVE_ONLINE
	end

	if shouldSave and playerDataStore then

		local success, encoded = pcall(function()
			return HttpService:JSONEncode(playerDataTable)
		end)

		if success then

			local Attempts = 0
			local saveSuccess = nil
			local errorMsg = nil

			repeat
				saveSuccess, errorMsg = pcall(function()
					playerDataStore:SetAsync(playerKey, encoded)
				end)
				if not saveSuccess then
					Attempts = Attempts + 1
					wait(3)
				end
			until saveSuccess or Attempts >= 10

			if not saveSuccess then
				warn("Error saving data for " .. player.Name .. ": " .. errorMsg)
			end

		else
			warn("Error encoding data for " .. player.Name)
		end
	end

	dataFolder:Destroy()

end


-- Events --

game:GetService("Players").PlayerAdded:Connect(onPlayerAdded)
game:GetService("Players").PlayerRemoving:Connect(onPlayerRemoving)
