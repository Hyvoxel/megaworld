local B = megaworld.B
local N = megaworld.N
local WATER = megaworld.WATER
local floor = math.floor

local names = {"cont", "hills", "mmask", "mrid", "riv1", "riv2", "temp", "humid", "detail"}
local pm, pbuf = nil, {}

local function init_maps()
	pm = {}
	for _, n in ipairs(names) do
		pm[n] = minetest.get_perlin_map(N[n], {x = 1, y = 1, z = 1})
		pbuf[n] = {}
	end
end

local function sample(x, z)
	if not pm then init_maps() end
	local p = {x = x, y = z}
	local v = {}
	for _, n in ipairs(names) do
		v[n] = pm[n]:get_2d_map_flat(p, pbuf[n])[1]
	end
	return megaworld.column(v.cont, v.hills, v.mmask, v.mrid, v.riv1, v.riv2,
		v.temp, v.humid, v.detail)
end
megaworld.sample = sample

local function find(pred, ox, oz, maxr)
	for r = 0, maxr, 64 do
		local n = 1
		if r > 0 then n = math.max(8, floor(2 * math.pi * r / 80)) end
		for k = 0, n - 1 do
			local a = (k / n) * 2 * math.pi
			local x = floor(ox + math.cos(a) * r)
			local z = floor(oz + math.sin(a) * r)
			local h, b, isr = sample(x, z)
			if pred(h, b, isr) then return x, z, h end
		end
	end
end

local targets = {
	rainforest = function(h, b) return b == B.RAIN and h > 4 and h < 80 end,
	temperate = function(h, b) return b == B.TEMP and h > 4 and h < 80 end,
	taiga = function(h, b) return b == B.TAIGA and h > 4 and h < 120 end,
	savanna = function(h, b) return b == B.SAV and h > 4 and h < 80 end,
	desert = function(h, b) return b == B.DES and h > 4 end,
	tundra = function(h, b) return b == B.TUNDRA and h > 4 end,
	mountain = function(h) return h >= 190 end,
	ocean = function(h) return h < -60 end,
	beach = function(h, b) return b == B.BEACH end,
	river = function(h, b, r) return r and h < 0 end,
}

local function teleport(name, x, z, h)
	local y = math.max(h, WATER)
	local p1 = {x = x - 20, y = y - 16, z = z - 20}
	local p2 = {x = x + 20, y = y + 40, z = z + 20}
	minetest.emerge_area(p1, p2, function(bp, action, remaining)
		if remaining > 0 then return end
		local pl = minetest.get_player_by_name(name)
		if not pl then return end
		local ty = y + 2
		for dy = 1, 14 do
			local a = minetest.get_node({x = x, y = y + dy, z = z}).name
			local b = minetest.get_node({x = x, y = y + dy + 1, z = z}).name
			if a == "air" and b == "air" then ty = y + dy break end
		end
		pl:set_pos({x = x + 0.5, y = ty, z = z + 0.5})
	end)
end

local spawn
local function get_spawn()
	if spawn then return spawn end
	local x, z, h = find(function(hh, b) return b == B.BEACH and hh >= 2 end, 0, 0, 4000)
	if not x then
		x, z, h = find(function(hh, b, r)
			return not r and hh > 4 and hh < 70 and (b == B.TEMP or b == B.RAIN or b == B.SAV)
		end, 0, 0, 4000)
	end
	if not x then
		x, z, h = 0, 0, 20
	end
	spawn = {x = x, z = z, h = h}
	return spawn
end

minetest.register_on_newplayer(function(player)
	local s = get_spawn()
	teleport(player:get_player_name(), s.x, s.z, s.h)
end)

minetest.register_on_respawnplayer(function(player)
	local s = get_spawn()
	teleport(player:get_player_name(), s.x, s.z, s.h)
	return true
end)

minetest.register_chatcommand("mwtp", {
	params = "<rainforest|temperate|taiga|savanna|desert|tundra|mountain|ocean|beach|river>",
	description = "Teleport to the nearest megaworld biome or feature",
	privs = {teleport = true},
	func = function(name, param)
		local pred = targets[param]
		if not pred then
			return false, "Use: rainforest, temperate, taiga, savanna, desert, tundra, mountain, ocean, beach, river"
		end
		local player = minetest.get_player_by_name(name)
		if not player then return false, "Player not found" end
		local pos = player:get_pos()
		local x, z, h = find(pred, floor(pos.x), floor(pos.z), 8000)
		if not x then return false, "Nothing found within 8000 nodes" end
		teleport(name, x, z, h)
		return true, "Teleporting to " .. param .. " at " .. x .. ", " .. z .. " ..."
	end,
})
