
-- Constants --

local ListModifierEvent = game.ReplicatedStorage.Networking.Client.RemoteEvents.ListModifierEvent
local Modifier = {}


-- Variables --

local ModifierOn = false
local TransparencyCache = {}
local BlockySappyCache = {}


-- Module Functions --

Modifier.StartModifier = function()

	-- Make sure this modifier isn't already on
	if ModifierOn then
		return
	end

	for _, Player in pairs (game.Players:GetPlayers()) do
		local PlayerCharacter = Player.Character
		if PlayerCharacter then

			local VisualRoot = PlayerCharacter.Parent:FindFirstChild("VisualRoot")
			if VisualRoot then
				local NewBlockySappy = game.ServerStorage.ModifierAssets.BlockySappy.BlockySappy:Clone()
				-- Position the model at VisualRoot with 180-degree rotation already applied
				NewBlockySappy:PivotTo(VisualRoot.CFrame * CFrame.Angles(0, math.rad(180), 0))
				-- Set up weld with matching rotation
				NewBlockySappy.HumanoidRootPart.VisualRootWeld.C0 = CFrame.new(0, 0, -0.5) * CFrame.Angles(0, math.rad(180), 0)
				NewBlockySappy.HumanoidRootPart.VisualRootWeld.Part1 = VisualRoot
				NewBlockySappy.Parent = PlayerCharacter.Parent
				table.insert(BlockySappyCache, NewBlockySappy)
			end

			local SappySeal = PlayerCharacter.Parent:FindFirstChild("SappySeal")
			TransparencyCache[Player] = {}
			for _, Child in pairs (SappySeal:GetDescendants()) do
				if Child:IsA("BasePart") then
					TransparencyCache[Player][Child] = Child.Transparency
					Child.Transparency = 1
				end
				if Child:IsA("ParticleEmitter") then
					TransparencyCache[Player][Child] = Child.Enabled
					Child.Enabled = false
				end
			end

		end
	end

	ModifierOn = true

	ListModifierEvent:FireAllClients(script.Name)

end

Modifier.StopModifier = function()

	-- Make sure this modifier isn't already off
	if not ModifierOn then
		return
	end

	for PlayerObject, TransparencyData in pairs (TransparencyCache) do
		for Object, OriginalValue in pairs (TransparencyData) do
			if Object:IsA("BasePart") then
				Object.Transparency = OriginalValue
			end
			if Object:IsA("ParticleEmitter") then
				Object.Enabled = OriginalValue
			end
		end
	end

	for _, BlockySappy in pairs (BlockySappyCache) do
		BlockySappy:Destroy()
	end

	TransparencyCache = {}

	ModifierOn = false

end


-- Setup --

return Modifier