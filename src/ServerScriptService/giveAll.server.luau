
local itemthing = require(game.ReplicatedStorage.Directories.ItemDirectory)


wait(5)

for Key, data in pairs (itemthing) do
	if data.ItemType ~= "Miscellaneous" then
		local a = Instance.new("StringValue")
		a.Name = Key
		a.Parent = game.ReplicatedStorage.PlayerData.Stormcell.Inventory[data.ItemType]
	end
end