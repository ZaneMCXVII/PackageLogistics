local router_funcs = {}

local routerLanePositionOffsets = {
	{-1.5,-0.5},
	{-1.5,0.5},
	{-0.5,1.5},
	{0.5,1.5},
	{1.5,0.5},
	{1.5,-0.5},
	{0.5,-1.5},
	{-0.5,-1.5}
}

function router_funcs.getRouterLaneBelt(router, lane)
	local position = router.position
	local newPosition = {position.x + routerLanePositionOffsets[lane][1], position.y + routerLanePositionOffsets[lane][2]}

	--game.print(serpent.line(newPosition))

	local belts = router.surface.find_entities_filtered({position = newPosition, type = "transport-belt"})
	return belts[1]
end

function router_funcs.beltFacingTowardsRouter(lane,direction)
	if lane == 1 or lane == 2 then
		return direction == defines.direction.east
	elseif lane == 3 or lane == 4 then
		return direction == defines.direction.north
	elseif lane == 5 or lane == 6 then
		return direction == defines.direction.west
	elseif lane == 7 or lane == 8 then
		return direction == defines.direction.south
	else
		error("Invalid lane")
	end
end

return router_funcs
