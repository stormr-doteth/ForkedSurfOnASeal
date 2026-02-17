
-- Directory Info --

local PriceDirectory = {}

PriceDirectory.PriceTable = {}


-- Functions --

function PriceDirectory:GetPrice(ProductName)
	return PriceDirectory.PriceTable[ProductName] or 9999999
end


-- Setup --

PriceDirectory.PriceUpdate = Instance.new("BindableEvent")

return PriceDirectory
