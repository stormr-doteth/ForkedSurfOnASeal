
-- Constants --

local ItemDirectory = require(game.ReplicatedStorage.Directories.ItemDirectory)
local ToggleCosmetic = require(game.ReplicatedStorage.HelperModules.ToggleCosmetic)
local EquipItemEvent = game.ReplicatedStorage.Networking.Server.RemoteEvents.EquipItem


-- Event Functions --

EquipItemEvent.OnServerEvent:Connect(function(RequestingPlayer, ItemName, SlotName)
	
	local PlayerData = game.ReplicatedStorage.PlayerData:FindFirstChild(RequestingPlayer.Name)
	if not PlayerData then
		return
	end
	
	-- Make sure the item exists
	local ItemData = ItemDirectory[ItemName]
	if not ItemData then
		return
	end
	
	local Character = RequestingPlayer.Character
	if not Character then
		return
	end
	
	local SappySeal = Character.Parent:FindFirstChild("SappySeal")
	if not SappySeal then
		return
	end
	
	-- Check to see if this is a skin
	if ItemData.ItemType == "SealSkins" then
		PlayerData.Equipped.SealSkin.Value = ItemName
		ToggleCosmetic(SappySeal, ItemName)
		return
	end
	
	-- Check to see if this is a trail
	if ItemData.ItemType == "Trails" then
		if PlayerData.Equipped.Trail.Value ~= ItemName then
			PlayerData.Equipped.Trail.Value = ItemName
		else
			PlayerData.Equipped.Trail.Value = "None"
		end
		ToggleCosmetic(SappySeal, ItemName)
		return
	end
	
	-- Check to see if this is an emote
	if ItemData.ItemType == "Emotes" then
				
		local TargetEmoteSlot = PlayerData.Equipped.Emotes:FindFirstChild(SlotName)
		if not TargetEmoteSlot then
			return
		end
		
		for _, EmoteSlot in pairs (PlayerData.Equipped.Emotes:GetChildren()) do
			if EmoteSlot.Value == ItemName then
				EmoteSlot.Value = ""
			end
		end
		
		TargetEmoteSlot.Value = ItemName
		
		return
			
	end
	
	-- Handle accessories
	if PlayerData.Equipped.Accessories:FindFirstChild(ItemName) then
		
		-- Delete the marker
		PlayerData.Equipped.Accessories[ItemName]:Destroy()
		
		-- Take off the stuff
		ToggleCosmetic(SappySeal, ItemName)
		
	else
		
		-- Make sure they own the item
		if not PlayerData.Inventory[ItemData.ItemType]:FindFirstChild(ItemName) then
			return
		end
		
		-- Make sure they don't have too many items equipped
		if #PlayerData.Equipped.Accessories:GetChildren() >= 5 then
			return
		end
		
		game.ReplicatedStorage.Networking.Server.BindableEvents.RecordAnalytic:Fire(RequestingPlayer, "MySeal Depth", 3)
		
		-- Add the tag
		local NewTag = Instance.new("StringValue")
		NewTag.Name = ItemName
		NewTag.Parent = PlayerData.Equipped.Accessories
		
		-- Equip their stuff
		ToggleCosmetic(SappySeal, ItemName)
		
	end
	
end)