
-- Constants --

local ToggleCosmetic = require(game.ReplicatedStorage.HelperModules.ToggleCosmetic)
local DummyDirectory = require(game.ReplicatedStorage.Directories.DummyDirectory)

local DummySpawnFolder = workspace.DummySealSpawns


-- Settings --

local SpawnUsagePercent = 0.70


-- Setup --

local DummySealFolder = Instance.new("Folder")
DummySealFolder.Name = "DummySeals"
DummySealFolder.Parent = workspace

local NumOfDummySpawns = #DummySpawnFolder:GetChildren()
local NumOfSeals = NumOfDummySpawns * SpawnUsagePercent

for i = 1, NumOfSeals do
	
	local SelectedSpawn = DummySpawnFolder:GetChildren()[math.random(1, #DummySpawnFolder:GetChildren())]
	
	local NewSeal = script.DummySeal:Clone()
	NewSeal:PivotTo(SelectedSpawn.SpawnBrick.CFrame)
	
	local NumOfHats = math.random(0,1)
	local NumOfGlasses = math.random(0,1)
	local NumOfShirts = math.random(0,1)
	
	if NumOfHats > 0 then
		ToggleCosmetic(NewSeal, DummyDirectory.Hats[math.random(1, #DummyDirectory.Hats)])
	end
	
	if NumOfGlasses > 0 then
		ToggleCosmetic(NewSeal, DummyDirectory.Glasses[math.random(1, #DummyDirectory.Glasses)])
	end
	
	if NumOfShirts > 0 then
		ToggleCosmetic(NewSeal, DummyDirectory.Shirts[math.random(1, #DummyDirectory.Shirts)])
	end
	
	NewSeal.Parent = DummySealFolder
	
	SelectedSpawn:Destroy()
	
	
end


DummySpawnFolder:Destroy()