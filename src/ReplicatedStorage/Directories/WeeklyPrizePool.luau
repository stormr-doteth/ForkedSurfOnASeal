
-- Constants --

local ItemDirectory = require(script.Parent.ItemDirectory)


-- Settings --

local WeeklyPrizePool = {
	
	--Legendary
	"Dunce_Hat",
	"Arrowhead",
	"Ice_Crown",
	"WcDonaldsCap",
	
	-- moved from the robux prize thing
	"Golden_Bowl_Cut",
	"Laurel",
	"Golden_Crown",
	"Halo",
	"Stupid_Sign",
	"Chud_Sign",
	"Noob_Sign",
-------------------	

	-- Rare
	"404_Vr",
	"Noise_Vr",
	"SealAntlers",
	"Mushroom",
	"Carti",
	"Black_Ninja_Headband",
	"Red_Ninja_Headband",
	"Pink_Banded_Top_Hat",
	"BlueBandedTophat",
	"Pirate_Hat",
	--"Propeller_Beanie",
	
	"BeachTrail",
	"CloudyTrail",
	"CoinTrail",
	"RobuxTrail",
	"TixTrail",
	"WatermelonTrail",
	
	-- Uncommon
	"Beret",
	"Cheese",
	"Ice_Cream",
	"MooseAntlers",
	"Pink_Heart_Shutter_Shades",
	"Fedora",
	--"Nerd_Glasses",
	"Traffic_Cone",
	"Whipped_Cream_Hat",
	"Firefighter_Helmet",
	"Black_Bucket_Hat",
	"Black_Sunglasses",
	"SealCowboyHat",
	
	"BlueTrail",
	"GreenTrail",
	"OrangeTrail",
	"PinkTrail",
	"PurpleTrail",
	"RedTrail",
	"ToothpasteTrail",
	"YellowTrail",
	
	-- Common
	--"Blue_Cap",
	"Red_Winter_Cap",
	"Pink_Winter_Cap",
	"Orange_Winter_Cap",
	--"Green_Shutter_Shades",
	"BlueWinterCap",
	"BlackWinterCap",
	"Ushanka",
	--"Black_Cap",
	--"Blue_Ribbon",
	--"Black_Durag",
	--"Red_Ribbon",
	--"Yellow_Ribbon",
	--"Black_Ribbon",
	--"Pink_Durag",
	--"Blue_Durag",
	--"Red_Durag",
	--"Orange_Durag",
	--"Purple_Shutter_Shades",
	--"Red_Shutter_Shades",
	--"Blue_Shutter_Shades",
	--"Pink_Cap",
	--"Green_Cap",
	--"Red_Cap",

}


-- Variables --

local SortedPool = {}
local FirstSort = false


-- Functions --

local function ReturnWeeklyPrizePool()
	
	-- If the SortedPool hasn't been created yet, make one
	if not FirstSort then
		for _, CosmeticName in pairs (WeeklyPrizePool) do
			
			-- Get the ItemEntry from ItemDirectory, and warn if it could not be found instead of exploding
			local ItemEntry = ItemDirectory[CosmeticName]
			if ItemEntry then
				
				-- If no table exists for the rarity, then create one
				if not SortedPool[ItemEntry.Rarity] then
					SortedPool[ItemEntry.Rarity] = {}
				end
				
				-- Categorize the CosmeticName under it's respective rarity
				table.insert(SortedPool[ItemEntry.Rarity], CosmeticName)
				
			else
				warn("WARNING! [" .. CosmeticName .. "] does not have an ItemEntry!")
			end
			
		end
	end
	
	return SortedPool
	
end




-- Setup --

return ReturnWeeklyPrizePool
