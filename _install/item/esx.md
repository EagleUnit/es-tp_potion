# If you're using ox_inventory, add the following to your data/items.lua:
```lua
["potion"] = {
		label = "Potion",
		weight = 0.2,
		stack = true,
		close = true,
		description = "A potion.",
		client = {
			image = "potion.png",
		}
	},
```
# Make sure potion.png is placed in your ox_inventory/web/images/ directory.

# If using ESX and MySQL
OPTION 1 - Manual Insert:
```lua
INSERT INTO `items` (`name`, `label`, `weight`, `rare`, `can_remove`) VALUES
('potion', 'Potion', 0.2, 0, 1);
```
OPTION 2 – Use the provided SQL file:
# Import the esx_item.sql file included in this resource directly into your database.