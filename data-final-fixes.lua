local packageItem = {
	type = "item-with-tags",
	name = "package",
	stack_size = 1,
	icon = "__packagelogistics__/graphics/icons/package.png",
	icon_size = 64
}

local packingCategory = {
	type = "recipe-category",
	name = "packing"
}

local unpackingCategory = {
	type = "recipe-category",
	name = "unpacking"
}

local packageLogisticsSubgroup = {
	type = "item-subgroup",
	name = "package-logistics",
	order = "zzzzz",
	group = "logistics"
}

-- Generate table of "results" for unpacking recipe
local unpackResults = {}


for name, item in pairs(data.raw["item"]) do
	local result = {type="item", name=name, amount=1, probability=0}
	table.insert(unpackResults,result)
end

local unpackingRecipe = {
	type = "recipe",
	name = "unpack-conversion",
	category = "unpacking",
	icon = packageItem.icon,
	icon_size = 64,
	ingredients = {{type="item", name=packageItem.name, amount=1}},
	results = unpackResults,
	hide_from_player_crafting = true
}

local packer = {
	type = "assembling-machine",
	name = "packer",
	flags = {"placeable-neutral", "player-creation", "get-by-unit-number"},
	result_inventory_size = 1,
	source_inventory_size = 1,
	energy_usage = "60kW",
	crafting_speed = 1,
	crafting_categories = {"packing"},
	energy_source = {type = "electric", usage_priority = "secondary-input"},
	selection_box = {left_top = {-1.5,-1.5}, right_bottom = {1.5,1.5}},
	collision_box = {left_top = {-1.5,-1.5}, right_bottom = {1.5,1.5}}, 
	tile_width = 3,
	tile_height = 3,
	icon = "__packagelogistics__/graphics/icons/packer.png",
	icon_size = 48,
	graphics_set = {
		always_draw_idle_animation = true,
		idle_animation = {
			filename = "__packagelogistics__/graphics/icons/packer.png",
			size = 48,
			scale = 2
		}
	},
	minable = {mining_time = 0.2, result = "packer"},
	subgroup = "package-logistics"
}

local unpacker = {
	type = "assembling-machine",
	name = "unpacker",
	flags = {"placeable-neutral", "player-creation", "get-by-unit-number"},
	result_inventory_size = 1,
	source_inventory_size = 1,
	energy_usage = "60kW",
	crafting_speed = 1,
	crafting_categories = {"unpacking"},
	energy_source = {type = "electric", usage_priority = "secondary-input"},
	selection_box = {left_top = {-1.5,-1.5}, right_bottom = {1.5,1.5}},
	collision_box = {left_top = {-1.5,-1.5}, right_bottom = {1.5,1.5}},
	tile_width = 3,
	tile_height = 3,
	icon = "__packagelogistics__/graphics/icons/unpacker.png",
	icon_size = 48,
	graphics_set = {
		always_draw_idle_animation = true,
		idle_animation = {
			filename = "__packagelogistics__/graphics/icons/unpacker.png",
			size = 48,
			scale = 2
		}
	},
	minable = {mining_time = 0.2, result = "unpacker"},
	subgroup = "package-logistics"
}

local router = {
	type = "container",
	name = "router",
	flags = {"placeable-neutral", "player-creation", "get-by-unit-number"},
	inventory_size = 8,
	inventory_type = "normal",
	draw_copper_wires = false,
	draw_circuit_wires = false,
	circuit_wire_max_distance = 1,
	selection_box = {left_top = {-1,-1}, right_bottom = {1,1}},
	collision_box = {left_top = {-1,-1}, right_bottom = {1,1}},
	tile_width = 2,
	tile_height = 2,
	icon = "__packagelogistics__/graphics/icons/router.png",
	icon_size = 32,
	picture = {
		filename = "__packagelogistics__/graphics/icons/router.png",
		size = 32,
		scale = 2
	},
	minable = {mining_time = 0.2, result = "router"},
	subgroup = "package-logistics"
}

local packerItem = {
	type = "item",
	name = "packer",
	place_result = "packer",
	stack_size = 50,
	icon = packer.icon, -- lazy lmao
	icon_size = packer.icon_size,
	subgroup = "package-logistics"
}

local unpackerItem = {
	type = "item",
	name = "unpacker",
	place_result = "unpacker",
	stack_size = 50,
	icon = unpacker.icon, -- lazy lmao
	icon_size = unpacker.icon_size,
	subgroup = "package-logistics"
}

local routerItem = {
	type = "item",
	name = "router",
	place_result = "router",
	stack_size = 50,
	icon = router.icon, -- lazy lmao
	icon_size = router.icon_size,
	subgroup = "package-logistics"
}

local packageLogisticsTech = {
	type = "technology",
	name = "package-logistics",
	icon = packageItem.icon,
	icon_size = 64,
	unit = {
		count = 75,
		time = 30,
		ingredients = {
			{"automation-science-pack", 1},
			{"logistic-science-pack", 1}
		}
	},
	effects = {
		{
			type = "unlock-recipe",
			recipe = "packer"
		},
		{
			type = "unlock-recipe",
			recipe = "unpacker"
		},
		{
			type = "unlock-recipe",
			recipe = "router"
		}
	},
	prerequisites = {"logistics-2"}
}

local packerRecipe = {
	type = "recipe",
	category = "crafting",
	name = "packer",
	icon = packer.icon,
	icon_size = 48,
	ingredients = {
		{type="item", name="electronic-circuit", amount=2},
		{type="item", name="iron-gear-wheel", amount=3},
		{type="item", name="iron-plate", amount=6}
	},
	results = {{type="item", name="packer", amount=1}},
	subgroup = "package-logistics",
	enabled = false
}

local unpackerRecipe = {
	type = "recipe",
	category = "crafting",
	name = "unpacker",
	icon = unpacker.icon,
	icon_size = 48,
	ingredients = {
		{type="item", name="electronic-circuit", amount=2},
		{type="item", name="iron-gear-wheel", amount=3},
		{type="item", name="iron-plate", amount=6}
	},
	results = {{type="item", name="unpacker", amount=1}},
	subgroup = "package-logistics",
	enabled = false
}

local routerRecipe = {
	type = "recipe",
	category = "crafting",
	name = "router",
	icon = router.icon,
	icon_size = 32,
	ingredients = {
		{type="item", name="electronic-circuit", amount=2},
		{type="item", name="iron-gear-wheel", amount=3},
		{type="item", name="iron-plate", amount=6}
	},
	results = {{type="item", name="router", amount=1}},
	subgroup = "package-logistics",
	enabled = false
}

data:extend({packageItem,
	     packerItem,
	     unpackerItem,
	     routerItem,
	     packingCategory,
	     unpackingCategory,
	     packerRecipe,
	     unpackerRecipe,
	     routerRecipe,
	     unpackingRecipe,
	     packer,
	     unpacker,
	     router,
     	     packageLogisticsTech,
     	     packageLogisticsSubgroup})

for name, item in pairs(data.raw["item"]) do
	local itemToPackageConversion = {
		type = "recipe",
		name = "package-convert-"..item.name,
		category = "packing",
		icon = item.icon,
		icon_size = item.icon_size,
		ingredients = {{type="item", name=item.name, amount=math.ceil(item.stack_size/4)}},
		results = {{type="item", name="package", amount=1}},
		localised_name = {"recipe-name.package-conversion"},
		hidden_in_factoriopedia = true,
		hide_from_player_crafting = true
	}
	data:extend({itemToPackageConversion})
end



