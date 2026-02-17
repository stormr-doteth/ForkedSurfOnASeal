
-- Constants --

local TeleportCharacter = require(game.ServerScriptService.HelperModules.TeleportCharacter)
local ToggleCosmetic = require(game.ReplicatedStorage.HelperModules.ToggleCosmetic)


-- Event Functions --

game.Players.PlayerAdded:Connect(function(NewPlayer)
	NewPlayer.CharacterAppearanceLoaded:Connect(function(Character)
		
		for _, Child in pairs (Character:GetDescendants()) do
			if Child:IsA("BasePart") then
				Child.Massless = true
				Child.CollisionGroup = "VisualCollision"
			end
		end
		
		local NewModel = Instance.new("Model")
		NewModel.Name = NewPlayer.Name
		
		Character.Parent = NewModel
		
		local NewSealRoot = script.SealRoot:Clone()
		NewSealRoot:PivotTo(Character.HumanoidRootPart.CFrame)
		NewSealRoot.Parent = NewModel
		
		local NewSappySeal = script.SappySeal:Clone()
		NewSappySeal.SealOwner.Value = NewPlayer
		NewSappySeal.Parent = NewModel
		
		local NewVisualRoot = script.VisualRoot:Clone()
		NewVisualRoot.HRP_Motor.Part0 = Character.HumanoidRootPart
		NewVisualRoot.VisualRootWeld.Part1 = NewSappySeal.RootPart
		NewVisualRoot.AlignPosition.Attachment1 = NewSealRoot.VisualAttachment
		NewVisualRoot.Parent = NewModel
		
		-- Set up them cosmetics
		local PlayerData = game.ReplicatedStorage.PlayerData:WaitForChild(NewPlayer.Name, 60)
		if not PlayerData then
			return
		end
		
		-- Get the accessories
		for _, EquippedItem in pairs (PlayerData.Equipped.Accessories:GetChildren()) do
			ToggleCosmetic(NewSappySeal, EquippedItem.Name)
		end
		
		-- Get the skin
		ToggleCosmetic(NewSappySeal, PlayerData.Equipped.SealSkin.Value)
		
		-- Get the trail if they have one
		if PlayerData.Equipped.Trail.Value ~= "None" then
			ToggleCosmetic(NewSappySeal, PlayerData.Equipped.Trail.Value)
		end
		
		NewModel.Parent = workspace
		
		Character:WaitForChild("Humanoid", 60).PlatformStand = true
		
		repeat task.wait() until Character.Parent
		repeat task.wait() until NewSealRoot:IsDescendantOf(workspace)
		
		NewSealRoot:SetNetworkOwner(NewPlayer)
		NewVisualRoot:SetNetworkOwner(NewPlayer)
		
		-- giga cursed
		Character.AncestryChanged:Connect(function()
			NewModel:Destroy()
		end)
		
		
		wait(.1)
		local PlayerGameStatsFolder = game.ReplicatedStorage.GameStats.Players:FindFirstChild(NewPlayer.Name)
		if PlayerGameStatsFolder.CurrentCheckpoint.Value then
			print(PlayerGameStatsFolder.CurrentCheckpoint.Value)
			TeleportCharacter(NewPlayer, PlayerGameStatsFolder.CurrentCheckpoint.Value, true)
		end
		
	end)
end)