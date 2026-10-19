local SHIELD_NAME = "futureshard_shield:shield"
local SHARD_ITEM  = "futureshard_shield:nelsylite_shard"
local SHIELD_STATE = {}
local shard_seconds = 3
local COOLDOWN_TIME = 2.0

local blacklist = {}
local blacklist_path = minetest.get_modpath("futureshard_shield") .. "/blacklist.conf"

local function load_blacklist()
    local file = io.open(blacklist_path, "r")
    if not file then return end
    for line in file:lines() do
        line = line:match("^%s*(.-)%s*$")
        if line and line:sub(1,1) ~= "#" and line ~= "" then
            blacklist[line] = true
        end
    end
    file:close()
end

load_blacklist()

minetest.register_on_punchplayer(function(player)
    local pname = player:get_player_name()
    local state = SHIELD_STATE[pname]
    if state and state.entity and state.entity:get_luaentity() then
        return true
    end
end)

minetest.register_entity("futureshard_shield:shield_entity", {
    initial_properties = {
        physical = false,
        collide_with_objects = false,
        collisionbox = {0,0,0, 0,0,0},
        visual = "mesh",
        mesh = "futureshard_shield_sphere.obj",
    },
    player = nil,
    on_step = function(self, dtime)
        if not self.player or not self.player:is_player() then
            self.object:remove()
            return
        end
    end
})

minetest.register_craftitem("futureshard_shield:core", {
    description = "This strange, glowing sphere pulses with energy",
    inventory_image = "futureshard_shield_core.png"
})

minetest.register_craftitem("futureshard_shield:frame", {
    description = "This metal frame is oddly cool, and your fingers tingle when you touch it",
    inventory_image = "futureshard_shield_frame.png"
})

minetest.register_craftitem("futureshard_shield:sphere", {
    description = "This light casts eerie reflections from odd objects, like the nodes that surround you",
    inventory_image = "futureshard_shield_sphere.png"
})

local function stop_shield(pname)
    local state = SHIELD_STATE[pname]
    if not state then return end
    if state.entity and state.entity:get_luaentity() then
        state.entity:remove()
    end
    local player = minetest.get_player_by_name(pname)
    if player then
        player:set_armor_groups({fleshy = 100})
    end
    SHIELD_STATE[pname] = nil
end

local function fire_lightning(player)
    local eye_pos = player:get_pos()
    eye_pos.y = eye_pos.y + (player:get_properties().eye_height or 1.5)
    local dir = player:get_look_dir()

    local beam_start_pos = vector.add(eye_pos, vector.multiply(dir, 2))
    local target_pos = vector.add(eye_pos, vector.multiply(dir, 60))

    local ray = minetest.raycast(eye_pos, target_pos, true, false)
    while true do
        local pointed = ray:next()
        if not pointed then break end

        if pointed.type == "object" and pointed.ref ~= player then
            local obj = pointed.ref
            local lua_ent = obj:get_luaentity()
            local entity_name = lua_ent and lua_ent.name or (obj.get_name and obj:get_name() or "unknown")

            if entity_name ~= "futureshard_shield:shield_entity" and not blacklist[entity_name] and not entity_name:find("wither") then
                if obj.punch then
                    obj:punch(player, 1.0, {damage_groups = {fleshy = 30000}})
                end
            end
        elseif pointed.type == "node" then
            target_pos = pointed.intersection_point or target_pos
            break
        end
    end

    local distance = vector.distance(beam_start_pos, target_pos)
    local steps = math.floor(distance * 4)

    if steps > 0 then
        for i = 0, steps do
            local t = i / steps
            local p_pos = vector.add(beam_start_pos, vector.multiply(vector.direction(beam_start_pos, target_pos), distance * t))

            minetest.add_particle({
                pos = p_pos,
                velocity = {x=0, y=0, z=0},
                acceleration = {x=0, y=0, z=0},
                expirationtime = 0.3,
                size = 2,
                collisiondetection = false,
                vertical = false,
                texture = "particle.png",
                glow = 14,
            })
        end
    end

    if minetest.registered_entities["mcl_weather:lightning"] then
        minetest.add_entity(target_pos, "mcl_weather:lightning")
    end
end

minetest.register_tool(SHIELD_NAME, {
    description = "Amethyst Sphere Shield",
    inventory_image = "futureshard_shield.png",
    groups = {tool = 1}
})

minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        local pname = player:get_player_name()
        local wield = player:get_wielded_item()

        if wield:get_name() ~= SHIELD_NAME then
            stop_shield(pname)
        else
            local state = SHIELD_STATE[pname]

            if not state then
                local inv = player:get_inventory()
                if inv:contains_item("main", SHARD_ITEM) then
                    local obj = minetest.add_entity(player:get_pos(), "futureshard_shield:shield_entity")
                    if obj then
                        obj:set_attach(player, "", {x=0, y=1.2, z=0}, {x=0, y=0, z=0})
                        local ent = obj:get_luaentity()
                        ent.player = player
                        SHIELD_STATE[pname] = {
                            entity = obj,
                            inv = inv,
                            time = 0,
                            cooldown = 0,
                            click_released = true,
                            last_dist = {}
                        }
                        state = SHIELD_STATE[pname]
                        player:set_armor_groups({fleshy = 0})
                    end
                end
            end

            if state then
                if state.cooldown > 0 then
                    state.cooldown = state.cooldown - dtime
                end

                local controls = player:get_player_control()
                if controls.dig then
                    if state.click_released and state.cooldown <= 0 then
                        fire_lightning(player)
                        state.cooldown = COOLDOWN_TIME
                        state.click_released = false
                    end
                else
                    state.click_released = true
                end

                state.time = state.time + dtime
                if state.time >= shard_seconds then
                    state.time = state.time - shard_seconds
                    if state.inv:contains_item("main", SHARD_ITEM) then
                        state.inv:remove_item("main", SHARD_ITEM)
                    else
                        stop_shield(pname)
                        state = nil
                    end
                end

                if state then
                    player:set_armor_groups({fleshy = 0})

                    local pos = player:get_pos()
                    local objs = minetest.get_objects_inside_radius(pos, 3.5)

                    for _, obj in ipairs(objs) do
                        if not obj:is_player() then
                            local lua_ent = obj:get_luaentity()
                            local entity_name = "unknown"

                            if lua_ent and lua_ent.name then
                                entity_name = lua_ent.name
                            elseif obj.get_name then
                                entity_name = obj:get_name()
                            end

                            if entity_name ~= "futureshard_shield:shield_entity" and not blacklist[entity_name] then
                                if not entity_name:find("wither") then
                                    if obj.punch then
                                        obj:punch(player, 1.0, {damage_groups = {fleshy = 10000}})
                                    end
                                end
                            end
                        end
                    end

                    for _, obj in ipairs(objs) do
                        local ent = obj:get_luaentity()
                        if ent and ent.groups and (ent.groups.hostile or ent.groups.monster) then
                            local mob_pos = obj:get_pos()
                            local dist = vector.distance(mob_pos, pos)
                            local key = tostring(obj)
                            local prev = state.last_dist[key]
                            if prev and prev - dist > 0.3 then
                                player:set_hp(player:get_hp() + 1)
                            end
                            state.last_dist[key] = dist
                        end
                    end
                end
            end
        end
    end
end)

minetest.register_on_leaveplayer(function(player)
    local pname = player:get_player_name()
    stop_shield(pname)
end)

minetest.register_on_dieplayer(function(player)
    local pname = player:get_player_name()
    stop_shield(pname)
end)
