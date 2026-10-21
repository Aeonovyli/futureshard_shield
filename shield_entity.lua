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
