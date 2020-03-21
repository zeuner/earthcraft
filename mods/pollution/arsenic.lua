pollution_arsenic=function(a)
	local o
	if a then
		o=io.open(minetest.get_worldpath() .. "/pollution_arsenic", "w")
		o:write("true")
		o:close()
		print("pollution: toxic water takes full effect after a restart")
	else
		o=io.open(minetest.get_worldpath() .. "/pollution_arsenic", "r")
		if o then
			o:close()
			local a={"default:water_source","default:water_flowing","default:river_water_source","default:river_water_flowing"}
			for i=1,#a,1 do
				minetest.override_item(a[i], {
					light_source = 5,
					damage_per_second=1,
					groups = {water = 3,lava=3,liquid=2,igniter=1},
				})
			end
			print("pollution: toxic water is enabled")
			print("pollution: remove 'pollution_arsenic' in the world folder to disable it")
		end
	end
end
minetest.after(0, function()
	pollution_arsenic()
end)

minetest.register_node("pollution:arsenicbarrel", {
	description = "Arsenic barrel (put into water and punch)",
	drawtype = "mesh",
	mesh = "pollution_barrel.obj",
	paramtype2 = "facedir",
	wield_scale = {x=1, y=1, z=1},
selection_box = {
		type = "fixed",
		fixed = {-0.4, -0.5, -0.4, 0.4,  0.9, 0.4}
	},
collision_box = {
		type = "fixed",
		fixed = {{-0.4, -0.5, -0.4, 0.4,  0.9, 0.4},}},
	tiles = {"pollution_barr.png^[colorize:#c6c6c6ff","pollution_barr.png^[colorize:#c6c6c6ff^pollution_log5.png"},
	groups = {barrel=1,cracky = 1, level = 2, not_in_creative_inventory=0},
	sounds = default.node_sound_stone_defaults(),
	paramtype = "light",
	sunlight_propagates = true,
	is_ground_content = false,
	light_source = LIGHT_MAX,
	on_punch = function(pos, node, puncher, pointed_thing)
		pollution_sound_punsh(pos)
		if math.random (5)==1 and minetest.is_protected(pos,puncher:get_player_name())==false then
			local w=minetest.find_node_near(pos, 2,{"group:water"})
			if w then
				pollution_arsenic(true)
				pollution_arsenic()
				pollution_sound_pff(pos)
				minetest.set_node(pos,{name="pollution:arsenicbarrel2"})
			end
		end
	end,
})

minetest.register_node("pollution:arsenicbarrel2", {
	description = "Arsenic barrel (empty)",
	drawtype = "mesh",
	mesh = "pollution_barrel.obj",
	paramtype2 = "facedir",
	wield_scale = {x=1, y=1, z=1},
selection_box = {
		type = "fixed",
		fixed = {-0.4, -0.5, -0.4, 0.4,  0.8, 0.4}
	},
collision_box = {
		type = "fixed",
		fixed = {{-0.4, -0.5, -0.4, 0.4,  0.8, 0.4},}},
	tiles = {"pollution_barr.png^[colorize:#c6c6c6ff","pollution_barr.png^[colorize:#c6c6c6ff^pollution_log5.png","pollution_barr.png^[colorize:#c6c6c6ff","pollution_barr.png^[colorize:#c6c6c6ff","pollution_black.png","pollution_barr.png^[colorize:#c6c6c6ff^pollution_log2.png"},
	groups = {barrel=1,cracky = 1, level = 2, not_in_creative_inventory=1},
	sounds = default.node_sound_stone_defaults(),
	paramtype = "light",
	sunlight_propagates = true,
	is_ground_content = false,
})