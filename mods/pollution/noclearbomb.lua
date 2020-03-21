minetest.register_craft({
	output = "pollution:nuclearbomb",
	recipe = {{"pollution:nuclearbarrel","pollution:nuclearbarrel","pollution:nuclearbarrel"},
		{"pollution:nuclearbarrel","default:steelblock","pollution:nuclearbarrel"},
		{"pollution:nuclearbarrel","pollution:nuclearbarrel","pollution:nuclearbarrel"},
		}})

minetest.register_node("pollution:nuclearbomb", {
	description = "Nuclear bomb",
	tiles = {"pollution_log3.png"},
	groups = {cracky = 1,oddly_breakable_by_hand = 2},
	sounds = default.node_sound_wood_defaults(),
	on_rightclick = function(pos, node, player, itemstack, pointed_thing)
		local meta=minetest.get_meta(pos)
		local name=player:get_player_name() or ""
		if meta:get_int("lock")==0 and (meta:get_string("owner")==name or minetest.check_player_privs(name, {protection_bypass=true})) then
			pollution_ncbform(name,pos)
		end
	end,
	can_dig = function(pos, player)
		local meta=minetest.get_meta(pos)
		local name=player:get_player_name() or ""
		if meta:get_string("owner")==name or minetest.check_player_privs(name, {protection_bypass=true}) then
			return true
		end
	end,
	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		local name=placer:get_player_name() or ""
		meta:set_string("owner",name)
		meta:set_string("infotext", "Nuclear by " .. name)
		local meta=minetest.get_meta(pos)
		meta:set_int("lock",0)
		meta:set_int("time",0)
	end,
	on_timer = function(pos, elapsed)
		local meta=minetest.get_meta(pos)
		local t=meta:get_int("time")-1
		meta:set_int("time",t)
		meta:set_string("infotext", "Nuclear by " .. meta:get_string("owner") .." (" .. t .. ")")
		if t<0 then
			pollution_nitroglycerine.explode(pos,{
				place_chance=100,
				user_name=meta:get_string("owner"),
				set="air",
				radius=35,
				drops=0,
			})
		else
			return true
		end
	end,
})

pollution_ncbform=function(name,pos)
		local gui=""
		.."size[3.5,0.2]"
		.."tooltip[time;Time]"
		.."field[0,0;3,1;time;;15]"
		.."button_exit[2.5,-0.3;1.3,1;set;set]"
		pollution_ncbform_users[name]=pos
		minetest.after((0.1), function(gui)
			return minetest.show_formspec(name, "pollution_ncbform",gui)
		end, gui)
end

minetest.register_on_player_receive_fields(function(player, form, pressed)
	if form=="pollution_ncbform" then
		local n=tonumber(pressed.time)
		if pressed.set and n and n>0 then
			local pos=pollution_ncbform_users[player:get_player_name()]
			local meta=minetest.get_meta(pos)
			meta:set_int("lock",1)
			meta:set_int("time",n)
			minetest.get_node_timer(pos):start(1)
		end
		pollution_ncbform_users[player:get_player_name()]=nil
	end
end)

pollution_ncbform_users={}
pollution_nitroglycerine={}
pollution_nitroglycerine.explode=function(pos,node)
	if not node then node={} end
	node.radius= node.radius or 3
	node.set= node.set or ""
	node.place= node.place or {"fire:basic_flame","air","air","air","air"}
	node.place_chance=node.place_chance or 5
	node.user_name=node.user_name or ""
	node.drops=node.drops or 1
	node.velocity=node.velocity or 1
	node.hurt=node.hurt or 1

	local nodes={}
	if node.set~="" then node.set=minetest.get_content_id(node.set) end

	local nodes_n=0
	for i, v in pairs(node.place) do
		nodes_n=i
		nodes[i]=minetest.get_content_id(v)
	end
	minetest.sound_play("pollution_nitroglycerine_explode", {pos=pos, gain = 0.9, max_hear_distance = node.radius*8})
	local air=minetest.get_content_id("air")
	pos=vector.round(pos)
	local pos1 = vector.subtract(pos, node.radius)
	local pos2 = vector.add(pos, node.radius)
	local vox = minetest.get_voxel_manip()
	local min, max = vox:read_from_map(pos1, pos2)
	local area = VoxelArea:new({MinEdge = min, MaxEdge = max})
	local data = vox:get_data()
	for z = -node.radius, node.radius do
	for y = -node.radius, node.radius do
	for x = -node.radius, node.radius do
		local rad = vector.length(vector.new(x,y,z))
		local v = area:index(pos.x+x,pos.y+y,pos.z+z)
		local p={x=pos.x+x,y=pos.y+y,z=pos.z+z}
		if data[v]~=air and node.radius/rad>=1 and minetest.is_protected(p, node.user_name)==false then
			if node.set~="" then
				data[v]=node.set
			end

			if math.random(1,node.place_chance)==1 then
				data[v]=nodes[math.random(1,nodes_n)]
			end

			if node.drops==1 and data[v]==air and math.random(1,4)==1 then
				local n=minetest.get_node(p)
				for _, item in pairs(minetest.get_node_drops(n.name, "")) do
					if p and item then minetest.add_item(p, item) end
				end
			end
		end
	end
	end
	end
	vox:set_data(data)
	vox:write_to_map()
	vox:update_map()
	vox:update_liquids()


if node.hurt==1 then
	for _, ob in ipairs(minetest.get_objects_inside_radius(pos, node.radius*2)) do
		if not (ob:get_luaentity() and ob:get_luaentity().itemstring) then
			local pos2=ob:getpos()
			local d=math.max(1,vector.distance(pos,pos2))
			local dmg=(8/d)*node.radius
			ob:punch(ob,1,{full_punch_interval=1,damage_groups={fleshy=dmg}},nil)
		else
			ob:get_luaentity().age=890
		end
	end
end
if node.velocity==1 then
	for _, ob in ipairs(minetest.get_objects_inside_radius(pos, node.radius*2)) do
		local pos2=ob:getpos()
		local d=math.max(1,vector.distance(pos,pos2))
		local dmg=(8/d)*node.radius
		if ob:get_luaentity() then
			ob:setvelocity({x=(pos2.x-pos.x)*dmg, y=(pos2.y-pos.y)*dmg, z=(pos2.z-pos.z)*dmg})
		elseif ob:is_player() then
			local d=dmg/4
			local pos3={x=(pos2.x-pos.x)*d, y=(pos2.y-pos.y)*d, z=(pos2.z-pos.z)*d}
			ob:setpos({x=pos.x+pos3.x,y=pos.y+pos3.y,z=pos.z+pos3.z,})
		end
	end
end
end