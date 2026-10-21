core.register_craft({
    output = "futureshard_shield:core",
    recipe = {
        {"mcl_amethyst:amethyst_shard","mcl_core:glass","mcl_amethyst:amethyst_shard"},
        {"mcl_core:lapis","mcl_nether:nether_star","mcl_core:lapis"},
        {"mcl_amethyst:amethyst_shard","mcl_mobitems:flaming_powder","mcl_amethyst:amethyst_shard"}
    }
})

core.register_craft({
    output = "futureshard_shield:frame",
    recipe = {
        {"mcl_core:lapis","","mcl_core:emerald"},
        {"","","mcl_core:lapis"},
        {"mcl_core:lapis","","mcl_core:lapis"}
    }
})

core.register_craft({
    output = "futureshard_shield:sphere",
    recipe = {
        {"mcl_core:iron_ingot","mcl_end:chorus_fruit_popped","mcl_core:iron_ingot"},
        {"futureshard_shield:core","xpanes:bar","mcl_core:goldblock"},
        {"mcl_core:iron_ingot","mcl_nether:ancient_debris","mcl_core:iron_ingot"}
    }
})

core.register_craft({
    type = "shapeless",
    output = "futureshard_shield:shield",
    recipe = {
        "futureshard_shield:core",
        "futureshard_shield:frame",
        "futureshard_shield:sphere"
    }
})
