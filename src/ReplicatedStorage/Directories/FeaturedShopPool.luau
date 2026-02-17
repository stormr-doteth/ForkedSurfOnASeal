
-- Constants --

local ItemDirectory = require(script.Parent.ItemDirectory)


-- Settings --

local FeaturedShopPool = {
	
	-- Legendary
	--"Golden_Bowl_Cut",
	--"Laurel",
	--"Golden_Crown",
	--"Halo",
	--"Stupid_Sign",
	--"Chud_Sign",
	--"Noob_Sign",
	
	-- new skins here
	"CowSeal",
	"CheetahSeal",
	"TieDyeSeal",
	"WatermelonSeal",
	-- old skins below
	--"TurdSeal",
	--"StrawberrySeal",
	--"OrangeSeal",
	--"LimeSeal",
	----"LemonSeal",
	--"GrapeSeal",
	--"BlueberrySeal",
	
	-- Rare
	"Black_Frog_Bucket_Hat",
	"Headphones",
	"Bowl_Cut",
	"Bear_Ears",
	"Teddy_Bear_Hat",
	"Security_Camera",
	"Flower_Power",
	"Pink_Derby_Hat",
	
	-- new skins
	"RibbonSeal",
	"GirlSeal",
	
	--old skins
	--"BabyBaikalSeal",
	--"BaikalSeal",
	--"HarpSeal",
	--"CottonCandySeal",
	--"BubblegumSeal",
	
	"LightningTrail",
	"FireTrail",
	"EerieTrail",
	"BlackTrail",
	"WhiteTrail",

	-- Uncommon
	"Bunny_Ears",
	"Kitty_Ears",
	"Mustache",
	--"Tin_Pot",
	"Flower_Crown",
	--"Rubber_Duckie",
	"Question_Mark",
	"Sombrero",
	
	
	
}


-- Variables --

local SortedPool = {}
local FirstSort = false


-- Functions --

local function ReturnFeaturedShopPool()
	
	-- If the SortedPool hasn't been created yet, make one
	if not FirstSort then
		for _, CosmeticName in pairs (FeaturedShopPool) do
			
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

return ReturnFeaturedShopPool
