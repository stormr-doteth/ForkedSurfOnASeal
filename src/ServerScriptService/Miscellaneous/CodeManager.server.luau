
-- Constants --

local AnalyticsService = game:GetService("AnalyticsService")
local PolicyService = game:GetService("PolicyService")
local DataStoreService = game:GetService("DataStoreService")

local GetPolicyInfoRemote = game.ReplicatedStorage.Networking.Server.RemoteFunctions.GetPolicyInfo
local RedeemCodeRemote = game.ReplicatedStorage.Networking.Server.RemoteFunctions.RedeemCode


-- Settings --

local ActiveCodes = {
	test1 = false,
	prevatic = true,
	tiktokgubby = true,
	["2mil"] = true,
	seal360 = true,
	sappytg = true,
	sappyberet = true,
	sappyarrow = true,


}


-- Functions --

local function AlreadyUsedCode(TargetPlayer, CodeName)
	
	local PlayerDataFolder = game.ReplicatedStorage.PlayerData:FindFirstChild(TargetPlayer.Name)
	if not PlayerDataFolder then
		return
	end
	
	if PlayerDataFolder.DataFlags.UsedCodes:FindFirstChild(CodeName) then
		return true
	end
	
end

local function MarkUsedCode(TargetPlayer, CodeName)
	
	local PlayerDataFolder = game.ReplicatedStorage.PlayerData:FindFirstChild(TargetPlayer.Name)
	if not PlayerDataFolder then
		return
	end
	
	local NewMarker = Instance.new("StringValue")
	NewMarker.Name = CodeName
	NewMarker.Parent = PlayerDataFolder.DataFlags.UsedCodes
	
end


-- Code Functions --

-----------------> always make the function names LOWERCASE <--------------
local CodeFunctions = {
	
	--[[test1 = function(RequestingPlayer, CodeName)
		
		-- Check to see if they've already used the code
		if AlreadyUsedCode(RequestingPlayer, CodeName) then
			return "Code already used!"
		end
		
		local PlayerDataFolder = game.ReplicatedStorage.PlayerData:FindFirstChild(RequestingPlayer.Name)
		if not PlayerDataFolder then
			return
		end
		
		-- Give them the stuff
		local NewMarker = Instance.new("StringValue")
		NewMarker.Name = "Test1"
		NewMarker.Parent = PlayerDataFolder.Inventory.Trails
		
		-- Mark the code as used in their data
		MarkUsedCode(RequestingPlayer, CodeName)
		
		return "Success!"
		
	end,]]
	
	prevatic = function(RequestingPlayer, CodeName)
		
		-- Check to see if they've already used the code
		if AlreadyUsedCode(RequestingPlayer, CodeName) then
			return "Code already used!"
		end
		
		local PlayerDataFolder = game.ReplicatedStorage.PlayerData:FindFirstChild(RequestingPlayer.Name)
		if not PlayerDataFolder then
			return
		end
		
		-- Give them the stuff
		local NewMarker = Instance.new("StringValue")
		NewMarker.Name = "PrevHat"
		NewMarker.Parent = PlayerDataFolder.Inventory.Accessory
		
		-- Show the notification
		game.ReplicatedStorage.Networking.Client.RemoteEvents.ShowNewItem:FireClient(RequestingPlayer, "PrevHat", nil, true)
		
		-- Mark the code as used in their data
		MarkUsedCode(RequestingPlayer, CodeName)
		
		-- Increment datastore key thing
		local CodeDataStore = DataStoreService:GetDataStore("Code_Prev")
		CodeDataStore:IncrementAsync("TotalUses", 1)
		
		return "Success!"
		
	end,
	
	tiktokgubby = function(RequestingPlayer, CodeName)

		-- Check to see if they've already used the code
		if AlreadyUsedCode(RequestingPlayer, CodeName) then
			return "Code already used!"
		end

		local PlayerDataFolder = game.ReplicatedStorage.PlayerData:FindFirstChild(RequestingPlayer.Name)
		if not PlayerDataFolder then
			return
		end

		-- Give them the stuff
		local NewMarker = Instance.new("StringValue")
		NewMarker.Name = "TailGubby"
		NewMarker.Parent = PlayerDataFolder.Inventory.Accessory

		-- Show the notification
		game.ReplicatedStorage.Networking.Client.RemoteEvents.ShowNewItem:FireClient(RequestingPlayer, "TailGubby", nil, true)

		-- Mark the code as used in their data
		MarkUsedCode(RequestingPlayer, CodeName)
		
		-- Increment datastore key thing
		local CodeDataStore = DataStoreService:GetDataStore("Code_TiktokGubby")
		CodeDataStore:IncrementAsync("TotalUses", 1)

		return "Success!"

	end,
	
	["2mil"] = function(RequestingPlayer, CodeName)
		
		-- Check to see if they've already used the code
		if AlreadyUsedCode(RequestingPlayer, CodeName) then
			return "Code already used!"
		end
		
		local PlayerDataFolder = game.ReplicatedStorage.PlayerData:FindFirstChild(RequestingPlayer.Name)
		if not PlayerDataFolder then
			return
		end
		
		-- for skilly (when you copy and paste this so you dont have to change the value in 3 places)
		local AmountIncrease = 100
		
		-- Give them the stuff
		PlayerDataFolder.Economy.Coins.Value = PlayerDataFolder.Economy.Coins.Value + AmountIncrease
		
		-- Log how many coins they got
		AnalyticsService:LogEconomyEvent(
			RequestingPlayer,
			Enum.AnalyticsEconomyFlowType.Source,
			"Coins",
			AmountIncrease, -- Amount earned
			PlayerDataFolder.Economy.Coins.Value, -- Current balance
			Enum.AnalyticsEconomyTransactionType.Onboarding.Name, -- Transaction type
			"Code Redeem"
		)
		
		-- Show the notification
		game.ReplicatedStorage.Networking.Client.RemoteEvents.ShowNewItem:FireClient(RequestingPlayer, "Coins", AmountIncrease .. " COINS")
		
		-- Mark the code as used in their data
		MarkUsedCode(RequestingPlayer, CodeName)
		
		-- Increment datastore key thing
		local CodeDataStore = DataStoreService:GetDataStore("Code_Prev")
		CodeDataStore:IncrementAsync("TotalUses", 1)
		
		return "Success!"
		
	end,
	
	seal360 = function(RequestingPlayer, CodeName)
		
		-- Check to see if they've already used the code
		if AlreadyUsedCode(RequestingPlayer, CodeName) then
			return "Code already used!"
		end
		
		local PlayerDataFolder = game.ReplicatedStorage.PlayerData:FindFirstChild(RequestingPlayer.Name)
		if not PlayerDataFolder then
			return
		end
		
		-- Give them the stuff
		local NewMarker = Instance.new("StringValue")
		NewMarker.Name = "EmoteSpin"
		NewMarker.Parent = PlayerDataFolder.Inventory.Emotes
		
		-- Show the notification
		game.ReplicatedStorage.Networking.Client.RemoteEvents.ShowNewItem:FireClient(RequestingPlayer, "EmoteSpin", nil, true)
		
		-- Mark the code as used in their data
		MarkUsedCode(RequestingPlayer, CodeName)
		
		-- Increment datastore key thing
		local CodeDataStore = DataStoreService:GetDataStore("Code_Seal360")
		CodeDataStore:IncrementAsync("TotalUses", 1)
		
		return "Success!"
		
	end,
	
	sappytg = function(RequestingPlayer, CodeName)

		-- Check to see if they've already used the code
		if AlreadyUsedCode(RequestingPlayer, CodeName) then
			return "Code already used!"
		end

		local PlayerDataFolder = game.ReplicatedStorage.PlayerData:FindFirstChild(RequestingPlayer.Name)
		if not PlayerDataFolder then
			return
		end

		-- Give them the stuff
		local NewMarker = Instance.new("StringValue")
		NewMarker.Name = "CoinTrail"
		NewMarker.Parent = PlayerDataFolder.Inventory.Trails

		-- Show the notification
		game.ReplicatedStorage.Networking.Client.RemoteEvents.ShowNewItem:FireClient(RequestingPlayer, "CoinTrail", nil, true)

		-- Mark the code as used in their data
		MarkUsedCode(RequestingPlayer, CodeName)

		-- Increment datastore key thing
		local CodeDataStore = DataStoreService:GetDataStore("Code_SAPPYTG")
		CodeDataStore:IncrementAsync("TotalUses", 1)

		return "Success!"

	end,
	
	sappyberet = function(RequestingPlayer, CodeName)

		-- Check to see if they've already used the code
		if AlreadyUsedCode(RequestingPlayer, CodeName) then
			return "Code already used!"
		end

		local PlayerDataFolder = game.ReplicatedStorage.PlayerData:FindFirstChild(RequestingPlayer.Name)
		if not PlayerDataFolder then
			return
		end
		
		
		if not PlayerDataFolder.Inventory.Accessory:FindFirstChild("Beret") then
			-- Give them the stuff
			local NewMarker = Instance.new("StringValue")
			NewMarker.Name = "Beret"
			NewMarker.Parent = PlayerDataFolder.Inventory.Accessory
		else
			return "already owned item"
		end

		-- Show the notification
		game.ReplicatedStorage.Networking.Client.RemoteEvents.ShowNewItem:FireClient(RequestingPlayer, "Beret", nil, true)


		-- Mark the code as used in their data
		MarkUsedCode(RequestingPlayer, CodeName)

		-- Increment datastore key thing
		local CodeDataStore = DataStoreService:GetDataStore("Code_sappyberet")
		CodeDataStore:IncrementAsync("TotalUses", 1)

		return "Success!"

	end,
	
	sappyarrow = function(RequestingPlayer, CodeName)

		-- Check to see if they've already used the code
		if AlreadyUsedCode(RequestingPlayer, CodeName) then
			return "Code already used!"
		end

		local PlayerDataFolder = game.ReplicatedStorage.PlayerData:FindFirstChild(RequestingPlayer.Name)
		if not PlayerDataFolder then
			return
		end
		
		if not PlayerDataFolder.Inventory.Accessory:FindFirstChild("ArrowHead") then
			-- Give them the stuff
			local NewMarker = Instance.new("StringValue")
			NewMarker.Name = "Arrowhead"
			NewMarker.Parent = PlayerDataFolder.Inventory.Accessory
		else
			return "already owned item"
		end

		-- Show the notification
		game.ReplicatedStorage.Networking.Client.RemoteEvents.ShowNewItem:FireClient(RequestingPlayer, "Arrowhead", nil, true)

		-- Mark the code as used in their data
		MarkUsedCode(RequestingPlayer, CodeName)

		-- Increment datastore key thing
		local CodeDataStore = DataStoreService:GetDataStore("Code_sappyarrow")
		CodeDataStore:IncrementAsync("TotalUses", 1)

		return "Success!"

	end,
	
}


-- Callback Functions --

GetPolicyInfoRemote.OnServerInvoke = function(RequestingPlayer)
	
	local PolicyInfo = PolicyService:GetPolicyInfoForPlayerAsync(RequestingPlayer)
	
	local X_Found = false
	for _, SocialName in pairs (PolicyInfo.AllowedExternalLinkReferences) do
		if SocialName == "X" then
			X_Found = true
			break
		end
	end
	
	return X_Found
	
end

RedeemCodeRemote.OnServerInvoke = function(RequestingPlayer, SubmittedCode)
	if CodeFunctions[string.lower(SubmittedCode)] and ActiveCodes[string.lower(SubmittedCode)] then
		local ReturnMessage = CodeFunctions[string.lower(SubmittedCode)](RequestingPlayer, SubmittedCode)
		return ReturnMessage
	end
	return "Invalid code!"
end