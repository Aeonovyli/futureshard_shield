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

        local pos = self.player:get_pos()

          for i = 1, 3 do
            local objs = minetest.get_objects_inside_radius(pos, 3.5)
            for _, obj in ipairs(objs) do
                local name = obj:get_entity_name()
                if name and name:find("vl_projectiles:") then
                    obj:remove()
                end
            end
        end
    end
})

minetest.register_craftitem("futureshard_shield:battery", {
    description = "Futureshard Shield Battery",
    inventory_image = "futureshard_shield_battery.png"
})

minetest.register_craftitem("futureshard_shield:gem", {
    description = "Futureshard Shield Gem",
    inventory_image = "futureshard_shield_gem.png"
})

minetest.register_craftitem("futureshard_shield:power", {
    description = "Futureshard Shield Power",
    inventory_image = "futureshard_shield_power.png"
})

minetest.register_craftitem("futureshard_shield:frame", {
    description = "Futureshard Shield Frame",
    inventory_image = "futureshard_shield_frame.png"
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

            if entity_name ~= "futureshard_shield:shield_entity" and entity_name ~= "__builtin:item" and not blacklist[entity_name] and entity_name ~= "mcl_monsters:wither" then
                if obj.punch then
                    local lua_ent = obj:get_luaentity()
                    local t_pos = obj:get_pos() or target_pos

                    if lua_ent and (lua_ent.is_mob or lua_ent._cmi_is_mob) then
                        if minetest.get_modpath("mcl_util") and mcl_util.deal_damage then
                            mcl_util.deal_damage(obj, 30000, {type = "void", puncher = player})
                        else
                            obj:set_hp(0)
                        end
                    else
                        local old_pos = player:get_pos()
                        local target_pos = obj:get_pos()
                        if target_pos then
                            player:set_pos(target_pos)
                        end
                        obj:punch(player, 1.0, {
                            full_punch_interval = 0.1,
                            damage_groups = {fleshy = 30000}
                        })
                        player:set_pos(old_pos)
                    end

                    for i = 0, 23 do
                        local angle = i * (2 * math.pi / 24)
                        local offset_x = math.cos(angle)
                        local offset_z = math.sin(angle)

                        minetest.add_particle({
                            pos = vector.add(t_pos, vector.new(offset_x * 0.2, 0.5, offset_z * 0.2)),
                            velocity = vector.new(offset_x * 4, 0.2, offset_z * 4),
                            acceleration = vector.new(-offset_x * 1.5, 0, -offset_z * 1.5),
                            expirationtime = 0.8,
                            size = 3.5,
                            collisiondetection = false,
                            vertical = false,
                            texture = "mcl_particles_black_heart.png",
                            glow = 14,
                        })
                    end
                end
            end
        elseif pointed.type == "node" then
            target_pos = pointed.intersection_point or target_pos
            break
        end
    end

        local distance = vector.distance(beam_start_pos, target_pos)
    local steps = math.floor(distance * 8)

    if steps > 0 then
        local look_dir = vector.direction(beam_start_pos, target_pos)

        local up = {x = 0, y = 1, z = 0}
        if math.abs(look_dir.y) > 0.9 then
            up = {x = 1, y = 0, z = 0}
        end

        local right = vector.normalize(vector.cross(look_dir, up))
        local orth_up = vector.normalize(vector.cross(right, look_dir))

        for i = 0, steps do
            local t = i / steps
            local p_center = vector.add(beam_start_pos, vector.multiply(look_dir, distance * t))

            for angle_step = 1, 4 do
                local angle = (angle_step * (2 * math.pi / 4)) + (i * 0.1)
                local radius = 0.15

                local offset = vector.add(
                    vector.multiply(right, math.cos(angle) * radius),
                    vector.multiply(orth_up, math.sin(angle) * radius)
                )

                local p_pos = vector.add(p_center, offset)

                minetest.add_particle({
                    pos = p_pos,
                    velocity = {x = 0, y = 0, z = 0},
                    acceleration = {x = 0, y = 0, z = 0},
                    expirationtime = 0.25,
                    size = 4,
                    collisiondetection = false,
                    vertical = false,
                    texture = "particle.png",
                    glow = 15,
                })
            end
        end
    end
    if minetest.registered_entities["mcl_weather:lightning"] then
        minetest.add_entity(target_pos, "mcl_weather:lightning")
    end
end

minetest.register_tool(SHIELD_NAME, {
    description = "Futureshard Shield",
    inventory_image = "futureshard_shield.png",
    groups = {tool = 1},
    tool_capabilities = {
        full_punch_interval = 0.1,
        max_drop_level = 0,
        groupcaps = {},
        damage_groups = {fleshy = 1},
    }
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
