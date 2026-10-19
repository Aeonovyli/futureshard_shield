nelsylite = {}
nelsylite.modname = minetest.get_current_modname()
nelsylite.modpath = minetest.get_modpath(nelsylite.modname)

local S = minetest.get_translator(nelsylite.modname)

minetest.register_node("futureshard_shield:nelsylite_ore", {
	description = S("Nelsylite Ore"),
	tiles = {"nelsylite_ore.png"},
	groups = {stone = 1, cracky = 3, pickaxey = 1},
	drop = "futureshard_shield:nelsylite_shard",
	is_ground_content = true,
})

minetest.register_craftitem("futureshard_shield:nelsylite_shard", {
	description = S("Nelsylite Shard"),
	inventory_image = "nelsylite_shard.png",
})

local spawn_within = minetest.settings:get("nelsylite.spawn_within") or "mcl_core:stone"
minetest.log("action", "[nelsylite] ore set to spawn within " .. spawn_within
	.. ", this can be changed with nelsylite.spawn_within setting")

minetest.register_on_mods_loaded(function()
	if minetest.registered_nodes[spawn_within] then
		minetest.register_ore({
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
		minetest.log("warning", "[nelsylite] " .. spawn_within .. " is not a registered node, nelsylite ore will not spawn")
	end
end)
