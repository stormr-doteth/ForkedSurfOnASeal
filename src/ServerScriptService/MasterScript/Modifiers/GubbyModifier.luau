
-- Constants --

local ListModifierEvent = game.ReplicatedStorage.Networking.Client.RemoteEvents.ListModifierEvent
local Modifier = {}


-- Variables --

local ModifierOn = false
local TransparencyCache = {}
local GubbyCache = {}


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
				local NewGubby = game.ServerStorage.ModifierAssets.Gubby.Gubby:Clone()
				NewGubby.Torso.VisualRootWeld.Part1 = VisualRoot
				NewGubby.Parent = PlayerCharacter.Parent
				table.insert(GubbyCache, NewGubby)
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
	
	for _, Gubby in pairs (GubbyCache) do
		Gubby:Destroy()
	end
	
	TransparencyCache = {}
	
	ModifierOn = false
	
end


-- Setup --

return Modifier