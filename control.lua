-- VVVV this is outdated (except for lane struct)
-- packerProductsFinished = entity unit number -> number
-- unpackerProductsFinished = entity unit number -> number
-- unpackerCurrentUnpacking = entity unit number -> SimpleItemStack
-- routerConfigurations = entity unit number -> router configuration struct 
-- router config struct = lane number -> lane struct (+ maybe circuit net and logistic system configurations?)
-- lane struct = {"direction" -> "input" | "output", "labels" -> {string}}

local routerFunctions = require("__packagelogistics__/router-functions")
local function starts_with(str, start)
   return str:sub(1, #start) == start
end

local routerArrowSprites = {
	{input = "utility/hint_arrow_right", output = "utility/hint_arrow_left", none = "utility/rail_path_not_possible"},
	{input = "utility/hint_arrow_right", output = "utility/hint_arrow_left", none = "utility/rail_path_not_possible"},
	{input = "utility/hint_arrow_up", output = "utility/hint_arrow_down", none = "utility/rail_path_not_possible"},
	{input = "utility/hint_arrow_up", output = "utility/hint_arrow_down", none = "utility/rail_path_not_possible"},
	{input = "utility/hint_arrow_left", output = "utility/hint_arrow_right", none = "utility/rail_path_not_possible"},
	{input = "utility/hint_arrow_left", output = "utility/hint_arrow_right", none = "utility/rail_path_not_possible"},
	{input = "utility/hint_arrow_down", output = "utility/hint_arrow_up", none = "utility/rail_path_not_possible"},
	{input = "utility/hint_arrow_down", output = "utility/hint_arrow_up", none = "utility/rail_path_not_possible"}
}	

local directionToSelection = {
	none = 1,
	input = 2,
	output = 3
}

local selectionToDirection = {
	"none",
	"input",
	"output"
}

local function has_value(tab, val)
	for k, v in pairs(tab) do
		if v == val then return true end
	end

	return false
end

script.on_init(function()
	storage.packers = {} -- [unit number] -> {products_finished=number,current_label=string}
	storage.unpackers = {} -- [unit number] -> {products_finished,currently_unpacking=SimpleItemStack?}
	storage.routers = {} -- [unit number] -> {lanes={*lane struct*},size=number?}   ---- Size is optional for later routers (eg. 1x1 router, 3x3 router, 4x4 router? Who knows? Tho thatd be a pain for gui design)
	storage.routerGuis = {} -- [player index] -> {[every gui element and thing lol (eg. lane buttons)]}
	storage.packerGuis = {} -- [player index] -> {gui elements}
end)

script.on_event({
	defines.events.on_built_entity,
	defines.events.on_robot_built_entity,
}, function(event) 
	if event.entity.name == "packer" then
		local packer = event.entity
		storage.packers[packer.unit_number] = {products_finished=packer.products_finished,current_label=""}
		packer.active = false
	elseif event.entity.name == "unpacker" then
		local unpacker = event.entity
		storage.unpackers[unpacker.unit_number] = {products_finished=unpacker.products_finished,currently_unpacking=nil}
	elseif event.entity.name == "router" then
		local router = event.entity
		storage.routers[router.unit_number] = {lanes={
			{direction="none",labels={}},
			{direction="none",labels={}},
			{direction="none",labels={}},
			{direction="none",labels={}},
			{direction="none",labels={}},
			{direction="none",labels={}},	
			{direction="none",labels={}},
			{direction="none",labels={}},
		}} -- lolololololololololololololololol
	end
end)

script.on_event({
	defines.events.on_player_mined_entity,
	defines.events.on_robot_mined_entity,
	defines.events.on_entity_died
}, function(event)
	if event.entity.name == "packer" then
		game.print("packer destroyed")
		storage.packers[event.entity.unit_number] = nil
		for playerIndex, v in pairs(storage.packerGuis) do
			if v.packerNumber == event.entity.unit_number then
				v.topFrame.destroy()
				storage.packerGuis[playerIndex] = nil
			end
		end
	elseif event.entity.name == "unpacker" then
		storage.unpackers[event.entity.unit_number] = nil
	elseif event.entity.name == "router" then
		storage.routers[event.entity.unit_number] = nil
		for playerIndex, v in pairs(storage.routerGuis) do
			if v.routerNumber == event.entity.unit_number then
				v.topFrame.destroy()
				storage.routerGuis[playerIndex] = nil
			end
		end
	end
end)
	
-- lolololololololololololol
script.on_event(defines.events.on_tick, function(event)
	-- packing time
	for unitNumber, data in pairs(storage.packers) do
		local packer = game.get_entity_by_unit_number(unitNumber)
		if not packer then goto continuelol end
		if storage.packers[unitNumber].products_finished < packer.products_finished then
			-- Packer finished recipe
			game.print("Packer "..tostring(unitNumber).." finished packing!")
			storage.packers[unitNumber].products_finished = packer.products_finished
			local recipe = packer.get_recipe()
			local inventory = packer.get_output_inventory()
			inventory[1].set_tag("packagedItem", recipe.ingredients[1].name)
			inventory[1].set_tag("packagedAmount", recipe.ingredients[1].amount)
			inventory[1].set_tag("shippingLabel", storage.packers[unitNumber].current_label)
			inventory[1].custom_description = {"", "Package contents: ", tostring(recipe.ingredients[1].amount).."x ".."[item="..recipe.ingredients[1].name.."]", "\n", "Shipping label: ", storage.packers[unitNumber].current_label}
		end
		::continuelol:: -- great label
	end

	-- unpacking time
	for unitNumber, data in pairs(storage.unpackers) do
		local unpacker = game.get_entity_by_unit_number(unitNumber)
		if not unpacker then goto continuelolunpack end
		local inventory = unpacker.get_inventory(defines.inventory.assembling_machine_input)
		if unpacker.get_recipe() ~= nil and inventory[1].valid_for_read then
			storage.unpackers[unitNumber].currently_unpacking = {item = inventory[1].get_tag("packagedItem"), amount = inventory[1].get_tag("packagedAmount")}	
		end
		if storage.unpackers[unitNumber].products_finished < unpacker.products_finished then
			-- Unpacker finished unpacking
			game.print("Unpacker "..tostring(unitNumber).." finished unpacking!")
			storage.unpackers[unitNumber].products_finished = unpacker.products_finished
			local currentlyUnpackingInfo = storage.unpackers[unitNumber].currently_unpacking
			local inventory = unpacker.get_output_inventory()
			inventory.insert({name=currentlyUnpackinInfo.item,count=currentlyUnpackingInfo.amount})
		end
		::continuelolunpack::
	end
	
	-- routing time
	for unitNumber, data in pairs(storage.routers) do
		local router = game.get_entity_by_unit_number(unitNumber)
		if not router then goto continuelolrouter end
		--router.get_inventory(defines.inventory.chest).set_bar(1)
		for lane = 1,8 do
			belt = routerFunctions.getRouterLaneBelt(router, lane)
			if not belt then game.print("no belt") goto continue end
			if routerFunctions.beltFacingTowardsRouter(lane,belt.direction) then
				if storage.routers[unitNumber].lanes[lane].direction ~= "input" then goto continue end
				for lineIndex = 1,belt.get_max_transport_line_index() do
					local line = belt.get_transport_line(lineIndex)
					game.print(#line ~= 0)
					if #line ~= 0 then
						if line[1].valid_for_read then
							if line[1].name == "package" then
								game.print(router.can_insert(line[1]))
								local result = router.insert(line[1])
								if result then line[1].clear() end
							end
						end
						
					end
				end 
			else
				if not storage.routers[unitNumber].lanes[lane].direction == "output" then goto continue end
				local routerInventory = router.get_inventory(defines.inventory.chest)
				for slotIndex = 1, #routerInventory do
					if routerInventory[slotIndex].valid_for_read then
						if routerInventory[slotIndex].name ~= "package" then goto continue2 end
						if has_value(storage.routers[unitNumber].lanes[lane].labels, routerInventory[slotIndex].get_tag("shippingLabel")) then
							for lineIndex = 1,belt.get_max_transport_line_index() do
								local line = belt.get_transport_line(lineIndex)
								local result = line.insert_at_back(routerInventory[slotIndex])
								if result then
									routerInventory[slotIndex].clear()
									break
								end
							end
						end
					end
					::continue2::
				end
			end
			
			::continue::
		end
		--belt = getRouterLaneBelt(router, 2)
		--if not belt then game.print("no belt") return end
		--local line = belt.get_transport_line(1)
		--line.insert_at_back({name="iron-plate", count=1},1)
		::continuelolrouter::
	end
end)

script.on_event(defines.events.on_gui_opened, function(event)
	if event.gui_type == defines.gui_type.entity and event.entity.name == "router" then
		local player = game.get_player(event.player_index)
		-- Make frame
		local frame = player.gui.screen.add({type="frame",caption={"entity-name.router"},name="router_main"})
		frame.auto_center = true
		frame.style.size = {500,500}

		--Build main UI
		local mainFrame = frame.add({type="frame",style="inside_shallow_frame_with_padding_and_vertical_spacing",direction="vertical"})
		mainFrame.style.vertically_stretchable = true
		mainFrame.style.horizontally_stretchable = true
		
		local laneButtons = {}

		local topFlow = mainFrame.add({type="flow",name="router_top_flow",direction="horizontal"})
		topFlow.style.left_margin = 163

		laneButtons[8] = topFlow.add({type="sprite-button",name="router_lane8",sprite="item/iron-plate"})
		laneButtons[7] = topFlow.add({type="sprite-button",name="router_lane7",sprite="item/iron-plate"})
		laneButtons[7].style.left_margin = 30
		
		local middleFlow = mainFrame.add({type="flow",name="router_middle_flow",direction="horizontal"})
		middleFlow.style.left_margin = 100

		local middleLeftButtonFlow = middleFlow.add({type="flow",name="router_middle_left_flow",direction="vertical"})
		middleLeftButtonFlow.style.top_margin = 18
		laneButtons[1] = middleLeftButtonFlow.add({type="sprite-button",name="router_lane1",sprite="item/iron-plate"})
		laneButtons[2] = middleLeftButtonFlow.add({type="sprite-button",name="router_lane2",sprite="item/iron-plate"})
		laneButtons[2].style.top_margin = 30


		local sprite = middleFlow.add({type="sprite",name="router_image",sprite="entity/router",resize_to_sprite=false})
		sprite.style.size = {150,150}
		sprite.style.left_margin = 0
		sprite.style.top_margin = 0

		local middleRightButtonFlow = middleFlow.add({type="flow",name="router_middle_right_flow",direction="vertical"})
		middleRightButtonFlow.style.top_margin = 18

		laneButtons[6] = middleRightButtonFlow.add({type="sprite-button",name="router_lane6",sprite="item/iron-plate"})
		laneButtons[5] = middleRightButtonFlow.add({type="sprite-button",name="router_lane5",sprite="item/iron-plate"})
		laneButtons[5].style.top_margin = 30
		
		local bottomButtonFlow = mainFrame.add({type="flow",name="router_bottom_flow",direction="horizontal"})
		bottomButtonFlow.style.left_margin = 163

		laneButtons[3] = bottomButtonFlow.add({type="sprite-button",name="router_lane3",sprite="item/iron-plate"})
		laneButtons[4] = bottomButtonFlow.add({type="sprite-button",name="router_lane4",sprite="item/iron-plate"})	
		laneButtons[4].style.left_margin = 30
		
		local dropDownFlow = mainFrame.add({type="flow",name="router_dropdown_flow",direction="horizontal"})
		dropDownFlow.style.left_margin = 110
		
		local dropDownLabel = dropDownFlow.add({type="label",name="router_dropdown_label",caption="Lane direction "})
		dropDownLabel.style.font = "default-bold"
		dropDownLabel.style.top_margin = 4
		local dropDown = dropDownFlow.add({type="drop-down",name="router_direction_dropdown",items={"None","Input","Output"},selected_index=1})
		dropDown.enabled = false
		
		local shippingLabelsLabel = mainFrame.add({type="label",caption="Shipping labels to output "})
		shippingLabelsLabel.style.font = "default-bold"	

		local shippingLabelFlow1 = mainFrame.add({type="flow",direction="horizontal",name="shippingLabelFlow1"})

		local shippingLabelBoxes = {}

		shippingLabelBoxes[1] = shippingLabelFlow1.add({type="textfield",name="shippingLabelBox1"})
		shippingLabelBoxes[1].enabled = false

		shippingLabelBoxes[2] = shippingLabelFlow1.add({type="textfield",name="shippingLabelBox2"})
		shippingLabelBoxes[2].enabled = false

		local shippingLabelFlow2 = mainFrame.add({type="flow",direction="horizontal",name="shippingLabelFlow2"})

		shippingLabelBoxes[3] = shippingLabelFlow2.add({type="textfield",name="shippingLabelBox3"})
		shippingLabelBoxes[3].enabled = false

		shippingLabelBoxes[4] = shippingLabelFlow2.add({type="textfield",name="shippingLabelBox4"})
		shippingLabelBoxes[4].enabled = false

		local shippingLabelFlow3 = mainFrame.add({type="flow",direction="horizontal",name="shippingLabelFlow3"})

		shippingLabelBoxes[5] = shippingLabelFlow3.add({type="textfield",name="shippingLabelBox5"})
		shippingLabelBoxes[5].enabled = false

		shippingLabelBoxes[6] = shippingLabelFlow3.add({type="textfield",name="shippingLabelBox6"})
		shippingLabelBoxes[6].enabled = false

		local closeButton = mainFrame.add({type="button",caption={"gui.getmeout"},name="router_close"})

		storage.routerGuis[event.player_index] = {}
		storage.routerGuis[event.player_index].topFrame = frame
		storage.routerGuis[event.player_index].laneButtons = laneButtons
		storage.routerGuis[event.player_index].dropDown = dropDown
		storage.routerGuis[event.player_index].routerNumber = event.entity.unit_number
		storage.routerGuis[event.player_index].selectedLane = -1
		storage.routerGuis[event.player_index].closeButton = closeButton
		storage.routerGuis[event.player_index].shippingLabelBoxes = shippingLabelBoxes

		-- load config
		local config = storage.routers[event.entity.unit_number].lanes

		for lane=1,8 do
			laneButtons[lane].sprite = routerArrowSprites[lane][config[lane].direction]
		end

		player.opened = frame
	elseif event.gui_type == defines.gui_type.entity and event.entity.name == "packer" then
		local unitNumber = event.entity.unit_number
		local player = game.get_player(event.player_index)
		local anchor = {gui=defines.relative_gui_type.assembling_machine_gui, position=defines.relative_gui_position.right}
		local frame = player.gui.relative.add({type="frame",caption={"gui.packing-settings"},anchor=anchor,direction="vertical",name="packer_settings"})

		local labelFlow = frame.add({type="flow",direction="horizontal",name="textbox_flow"})
		local label = labelFlow.add({type="label",caption={"gui.shipping-label"}})
		local textbox = labelFlow.add({type="textfield",name="packer_label_textbox"})
		label.style.font = "default-bold"
		label.style.top_margin = 5

		textbox.text = storage.packers[unitNumber].current_label 
		

		local errorLabel = frame.add({type="label",caption={"gui.no-shipping-label"}})
		errorLabel.style.font = "default-bold"
		errorLabel.style.font_color = {0.709803, 0.07843137, 0.07843137}
		errorLabel.visible = storage.packers[unitNumber].current_label == ""

		storage.packerGuis[event.player_index] = {}
		storage.packerGuis[event.player_index].label_textbox = textbox
		storage.packerGuis[event.player_index].errorLabel = errorLabel
		storage.packerGuis[event.player_index].packerNumber = event.entity.unit_number
		storage.packerGuis[event.player_index].topFrame = frame
	end
end)

script.on_event(defines.events.on_gui_closed, function(event)
	if event.gui_type == defines.gui_type.entity and event.entity.name == "packer" then
		local player = game.get_player(event.player_index)
		player.gui.relative.packer_settings.destroy()
		storage.packerGuis[event.player_index] = nil -- clean up gui object references in storage
	end
end)

script.on_event(defines.events.on_gui_click, function(event)
	if starts_with(event.element.name, "router") then
		game.print(event.element.name)
		if starts_with(event.element.name, "router_lane") then
			local lane = tonumber(event.element.name:sub(12,13))
			local gui = storage.routerGuis[event.player_index]
			local router = gui.routerNumber
			local config = storage.routers[router].lanes
			
			--game.print("SELECTED LANE IS NOW "..gui.selectedLane)

			if gui.selectedLane ~= -1 then gui.laneButtons[gui.selectedLane].toggled = false end
			gui.laneButtons[lane].toggled = true
			gui.dropDown.enabled = true
			gui.dropDown.selected_index = directionToSelection[config[lane].direction]
			
			if storage.routers[router].lanes[lane].direction == "output" then
				for box = 1, 6 do
					gui.shippingLabelBoxes[box].text = storage.routers[router].lanes[lane].labels[box] or ""
					gui.shippingLabelBoxes[box].enabled = true
				end
			else
				for box = 1, 6 do
					gui.shippingLabelBoxes[box].text = ""
					gui.shippingLabelBoxes[box].enabled = false
				end
			end


			gui.selectedLane = lane
			--game.print("SELECTED LANE IS "..tostring(gui.selectedLane))
		elseif event.element.name == "router_close" then
			local gui = storage.routerGuis[event.player_index]
			local player = game.get_player(event.player_index)

			player.gui.screen.router_main.destroy()
			storage.routerGuis[event.player_index] = nil
		end
	end
end)

script.on_event(defines.events.on_gui_selection_state_changed, function(event)
	if event.element.name == "router_direction_dropdown" then
		local gui = storage.routerGuis[event.player_index]
		local lane = gui.selectedLane
		local router = storage.routers[gui.routerNumber]
		
		router.lanes[lane].direction = selectionToDirection[event.element.selected_index]
		gui.laneButtons[lane].sprite = routerArrowSprites[lane][selectionToDirection[event.element.selected_index]]

		if router.lanes[lane].direction == "output" then
			for box = 1, 6 do
				gui.shippingLabelBoxes[box].text = router.lanes[lane].labels[box] or ""
				gui.shippingLabelBoxes[box].enabled = true
			end
		else
			for box = 1, 6 do
				gui.shippingLabelBoxes[box].text = ""
				gui.shippingLabelBoxes[box].enabled = false
			end
		end
	end
end)


script.on_event(defines.events.on_gui_text_changed, function(event)
	local player = game.get_player(event.player_index)
	if event.element.name == "packer_label_textbox" then
		local packer = game.get_entity_by_unit_number(storage.packerGuis[event.player_index].packerNumber)
		if event.element.text == "" then
			storage.packerGuis[event.player_index].errorLabel.visible = true
			storage.packers[packer.unit_number].current_label = ""
			packer.active = false
		else
			storage.packerGuis[event.player_index].errorLabel.visible = false	
			storage.packers[packer.unit_number].current_label = event.element.text
			packer.active = true
		end
	elseif starts_with(event.element.name,"shippingLabelBox") then
		local boxNumber = tonumber(event.element.name:sub(17,17))
		local router = storage.routerGuis[event.player_index].routerNumber
		local lane = storage.routerGuis[event.player_index].selectedLane
		game.print(router)
		storage.routers[router].lanes[lane].labels[boxNumber] = event.element.text
	end
end)

-- no breaking save files lol
--[[script.on_configuration_changed(function(config_changed_data)
    if config_changed_data.mod_changes["packagelogistics"] then
        for _, player in pairs(game.players) do
            local main_frame = player.gui.screen.main_frame
            if main_frame ~= nil then toggle_interface(player) end
        end
    end
end)]]--
