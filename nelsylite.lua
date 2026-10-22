nelsylite = {}
nelsylite.modname = minetest.get_current_modname()
nelsylite.modpath = minetest.get_modpath(nelsylite.modname)

local S = minetest.get_translator(nelsylite.modname)

minetest.register_node("futureshard_shield:nelsylite_ore", {
	description = S("Nelsylite Crystal Bud"),
	drawtype = "mesh",
	mesh = "mcl_amethyst_cluster_large.obj",
	tiles = {"nelsylite_bud.png"},
	paramtype = "light",
	paramtype2 = "facedir",
	sunlight_propagates = true,
	light_source = 5,
	groups = {pickaxey = 3, cracky = 2, dig_immediate = 0},
	drop = "futureshard_shield:nelsylite_shard 2",
	selection_box = {
		type = "fixed",
		fixed = {-0.3, -0.5, -0.3, 0.3, 0.1, 0.3}
	},
	sounds = mcl_sounds and mcl_sounds.node_sound_glass_defaults(),
})

minetest.register_craftitem("futureshard_shield:nelsylite_shard", {
	description = S("Nelsylite Shard"),
	inventory_image = "nelsylite_shard.png",
})

local spawn_within = minetest.settings:get("nelsylite.spawn_within") or "mcl_core:stone"
minetest.log("action", "[nelsylite] crystal set to spawn within " .. spawn_within
	.. ", this can be changed with nelsylite.spawn_within setting")

minetest.register_on_mods_loaded(function()
	if minetest.registered_nodes[spawn_within] then
		minetest.register_ore({
			ore_type = "scatter",
			ore = "futureshard_shield:nelsylite_ore",
			wherein = spawn_within,
			clust_scarcity = 30 * 30 * 30,
			clust_num_ores = 1,
			clust_size = 3,
			y_min = -31000,
			y_max = -40,
		})
	else
		minetest.log("warning", "[nelsylite] " .. spawn_within .. " is not a registered node, nelsylite crystal will not spawn")
	end
end)
