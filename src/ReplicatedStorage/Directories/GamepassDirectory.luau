
-- Constants --

local GamepassDirectory = {}


-- Directory Info --

GamepassDirectory.ActiveGamepasses = {
	"StarterPack",
	"UltimateStarterPack",
	--"TinyBundle",
	"GalaxyBundle",
	"BeeBundle"
}

GamepassDirectory.StarterPack = {
	IconID = "rbxassetid://96695023541715",
	GamepassID = 1128718679,
	FlavorText = "Starter Pack",
	Benefits = {
		"1,000 COINS",
		"Ski Cap",
		"Pink Ribbon",
		"Ice Trail",
	}
}

GamepassDirectory.UltimateStarterPack = {
	IconID = "rbxassetid://128304338881839",
	GamepassID = 1130333021,
	FlavorText = "ULTIMATE Starter Pack",
	Benefits = {
		"2,000 COINS",
		"Epic Shades",
		"Fat Sign",
		"Golden Beanie",
	}
}

GamepassDirectory.TinyBundle = {
	IconID = "rbxassetid://101447795528039",
	GamepassID = 1132152805,
	FlavorText = "Tiny Bundle",
	Benefits = {
		"Tiny Beret",
		"Tiny Cowboy Hat",
		"Tiny Propeller Hat",
		"Tiny Beanie",
		"Tiny Cap",
	}
}

GamepassDirectory.GalaxyBundle = {
	IconID = "rbxassetid://72639390385624",
	GamepassID = 1240208402,
	FlavorText = "Galaxy Bundle",
	Benefits = {
		"Galaxy Seal",
		"Star Shutters",
		"Galaxy Trail",
	}
}

GamepassDirectory.BeeBundle = {
	IconID = "rbxassetid://95188370316987",
	GamepassID = 1268465087,
	FlavorText = "Bee Bundle",
	Benefits = {
		"Bee Seal",
		"Bee Antennae",
		"Bee Wings",
		"Flower",
		"Flower Trail"
	}
}



-- Setup --

return GamepassDirectory
