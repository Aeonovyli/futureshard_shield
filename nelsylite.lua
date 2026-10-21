nelsylite = {}
nelsylite.modname = core.get_current_modname()
nelsylite.modpath = core.get_modpath(nelsylite.modname)

local S = core.get_translator(nelsylite.modname)

core.register_node("futureshard_shield:nelsylite_ore", {
	description = S("Nelsylite Ore"),
	tiles = {"nelsylite_ore.png"},
	groups = {stone = 1, cracky = 3, pickaxey = 1},
	drop = "futureshard_shield:nelsylite_shard",
	is_ground_content = true,
})

core.register_craftitem("futureshard_shield:nelsylite_shard", {
	description = S("Nelsylite Shard"),
	inventory_image = "nelsylite_shard.png",
})

local spawn_within = core.settings:get("nelsylite.spawn_within") or "mcl_core:stone"
core.log("action", "[nelsylite] ore set to spawn within " .. spawn_within
	.. ", this can be changed with nelsylite.spawn_within setting")

core.register_on_mods_loaded(function()
	if core.registered_nodes[spawn_within] then
		core.register_ore({
			ore_type = "scatter",
			ore = "futureshard_shield:nelsylite_ore",
			wherein = spawn_within,
			clust_scarcity = 25 * 25 * 25,
			clust_num_ores = 2,
			clust_size = 5,
			y_min = -31000,
			y_max = -16,
		})
	else
		core.log("warning", "[nelsylite] " .. spawn_within .. " is not a registered node, nelsylite ore will not spawn")
	end
end)
