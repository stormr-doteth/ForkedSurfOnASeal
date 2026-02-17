
-- Constants --

local ItemDirectory = require(game.ReplicatedStorage.Directories.ItemDirectory)


-- Functions --

local function ToggleCosmetic(SappySeal, CosmeticName)
	
	if not SappySeal then
		warn("Cannot apply cosmetic, no sappy seal found!")
		return
	end
	
	-- Get the scale multiplier from the model ONLY if it exists as a NumberValue
	local ScaleMultiplier = 1
	
	if SappySeal:FindFirstChild("ScaleMultiplier") then
		ScaleMultiplier = SappySeal.ScaleMultiplier.Value
	end
	
	local CosmeticType = nil
	local SourceCosmetic = nil
	
	for _, Child in pairs (game.ReplicatedStorage.Cosmetics:GetDescendants()) do
		if Child.Name == CosmeticName then
			CosmeticType = Child.Parent.Name
			SourceCosmetic = Child
		end
	end
	
	if not SourceCosmetic then
		warn("Could not find SourceCosmetic [" .. CosmeticName .. "]")
	end
	
	if CosmeticType ~= "SealSkins" and CosmeticType ~= "Trails" then
		if not SappySeal:FindFirstChild(CosmeticName) then
			
			local NewCosmetic = SourceCosmetic:Clone()
			
			local CosmeticMotor = NewCosmetic:FindFirstChildOfClass("Motor6D")
			
			-- Only scale if ScaleMultiplier is not 1
			if ScaleMultiplier ~= 1 then
				NewCosmetic.Size = NewCosmetic.Size * ScaleMultiplier
				
				local c0Pos = CosmeticMotor.C0.Position
				local c1Pos = CosmeticMotor.C1.Position
				
				CosmeticMotor.C0 = CFrame.new(c0Pos * ScaleMultiplier) * CosmeticMotor.C0.Rotation
				CosmeticMotor.C1 = CFrame.new(c1Pos * ScaleMultiplier) * CosmeticMotor.C1.Rotation
				
			end
			
			CosmeticMotor.Part0 = SappySeal.SealRef
			NewCosmetic.Parent = SappySeal
			
		else
			SappySeal[CosmeticName]:Destroy()
		end
		
		return
			
	end
	
	if CosmeticType == "SealSkins" then
		
		if SappySeal:FindFirstChild("Highlight") then
			SappySeal.Highlight:Destroy()
		end
		
		SappySeal.SealRef.SurfaceAppearance:Destroy()
		
		local NewAppearance = SourceCosmetic:Clone()
		NewAppearance.Name = "SurfaceAppearance"
		NewAppearance.Parent = SappySeal.SealRef
		
		if NewAppearance:FindFirstChildOfClass("Highlight") then
			NewAppearance.Highlight.Parent = SappySeal
		end
		
		return
		
	end
	
	if CosmeticType == "Trails" then
		
		local CurrentTrail = SappySeal.Parent.VisualRoot:FindFirstChildOfClass("Trail")
		
		if CurrentTrail then
			if CurrentTrail.Name ~= CosmeticName then
				
				CurrentTrail:Destroy()
				if SappySeal.Parent.VisualRoot.ParticleAttachment:FindFirstChild("TrailParticles") then
					SappySeal.Parent.VisualRoot.ParticleAttachment.TrailParticles:Destroy()
				end
				
				local NewTrail = game.ReplicatedStorage.Cosmetics.Trails[CosmeticName]:Clone()
				NewTrail.Attachment1 = SappySeal.Parent.VisualRoot.TrailAttachment1
				NewTrail.Attachment0 = SappySeal.Parent.VisualRoot.TrailAttachment2
				NewTrail.Parent = SappySeal.Parent.VisualRoot
				
			else
				
				CurrentTrail:Destroy()
				if SappySeal.Parent.VisualRoot.ParticleAttachment:FindFirstChild("TrailParticles") then
					SappySeal.Parent.VisualRoot.ParticleAttachment.TrailParticles:Destroy()
				end
				
			end
		else
			
			local NewTrail = game.ReplicatedStorage.Cosmetics.Trails[CosmeticName]:Clone()
			NewTrail.Attachment1 = SappySeal.Parent.VisualRoot.TrailAttachment1
			NewTrail.Attachment0 = SappySeal.Parent.VisualRoot.TrailAttachment2
			NewTrail.Parent = SappySeal.Parent.VisualRoot
			
			-- >:(
			local stupidparticles = NewTrail:FindFirstChildOfClass("ParticleEmitter")
			if stupidparticles then
				stupidparticles.Name = "TrailParticles"
				stupidparticles.Parent = SappySeal.Parent.VisualRoot.ParticleAttachment
			end
			
		end
		
	end
	
end

-- Setup --
return ToggleCosmetic