local c, B = megaworld.c, megaworld.B
local N, N3 = megaworld.N, megaworld.N3
local WATER = megaworld.WATER
local rnd = megaworld.rnd
local column = megaworld.column
local floor = math.floor

local M = 14
local CAVE_BOTTOM = megaworld.cave_bottom
local LAVA = megaworld.lava_level
local USE_CAVES = megaworld.caves

local names2d = {"cont", "hills", "mmask", "mrid", "riv1", "riv2", "temp", "humid", "forest", "detail"}
local cache2d, cache3d = {}, {}

local function get2d(W)
	local m = cache2d[W]
	if not m then
		m = {map = {}, buf = {}}
		local size = {x = W, y = W, z = W}
		for _, n in ipairs(names2d) do
			m.map[n] = minetest.get_perlin_map(N[n], size)
			m.buf[n] = {}
		end
		cache2d[W] = m
	end
	return m
end

local function get3d(nx, ny, nz)
	local key = nx .. "," .. ny .. "," .. nz
	local m = cache3d[key]
	if not m then
		m = {}
		local size = {x = nx, y = ny, z = nz}
		for _, n in ipairs({"cavern", "tun1", "tun2"}) do
			m[n] = {map = minetest.get_perlin_map(N3[n], size), buf = {}}
		end
		cache3d[key] = m
	end
	return m
end

local Hg, Bg, Rg = {}, {}, {}
local dbuf = {}

local function surface(b, h)
	if h <= WATER then
		if h > -30 then return c.sand, c.sand, 3 end
		return c.gravel, c.stone, 2
	end
	if b == B.BEACH then return c.sand, c.sand, 3
	elseif b == B.RAIN then return c.litter, c.dirt, 4
	elseif b == B.TEMP then return c.grass, c.dirt, 4
	elseif b == B.TAIGA then return c.conifer, c.dirt, 4
	elseif b == B.SAV then return c.drygrass, c.dirt, 3
	elseif b == B.DES then return c.dsand, c.dsand, 4
	elseif b == B.TUNDRA then return c.snowdirt, c.dirt, 3
	elseif b == B.PEAK then return c.snowblock, c.snowblock, 2
	end
	return c.stone, c.stone, 1
end

minetest.register_on_generated(function(minp, maxp, blockseed)
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local nx = maxp.x - minp.x + 1
	local ny = maxp.y - minp.y + 1
	local W = nx + 2 * M
	local xmin, zmin = minp.x - M, minp.z - M

	-- 2D noise over chunk + margin
	local m = get2d(W)
	local origin = {x = xmin, y = zmin}
	local v = {}
	for _, n in ipairs(names2d) do
		v[n] = m.map[n]:get_2d_map_flat(origin, m.buf[n])
	end
	local cont, hills, mmask, mrid = v.cont, v.hills, v.mmask, v.mrid
	local riv1, riv2, temp, humid, detail, forest = v.riv1, v.riv2, v.temp, v.humid, v.detail, v.forest

	for i = 1, W * W do
		Hg[i], Bg[i], Rg[i] = column(cont[i], hills[i], mmask[i], mrid[i],
			riv1[i], riv2[i], temp[i], humid[i], detail[i])
	end

	local hmax = -31000
	for z = minp.z, maxp.z do
		local zi0 = (z - zmin) * W
		for x = minp.x, maxp.x do
			local h = Hg[zi0 + (x - xmin) + 1]
			if h > hmax then hmax = h end
		end
	end
	local top = hmax
	if top < WATER then top = WATER end
	if minp.y > top + 56 then return end -- pure sky chunk

	local need3d = USE_CAVES and minp.y <= hmax and maxp.y > CAVE_BOTTOM
	local n1, n2, nc
	if need3d then
		local m3 = get3d(nx, ny, maxp.z - minp.z + 1)
		n1 = m3.tun1.map:get_3d_map_flat(minp, m3.tun1.buf)
		n2 = m3.tun2.map:get_3d_map_flat(minp, m3.tun2.buf)
		nc = m3.cavern.map:get_3d_map_flat(minp, m3.cavern.buf)
	end

	local data = vm:get_data(dbuf)
	local area = VoxelArea:new({MinEdge = emin, MaxEdge = emax})
	local ys, zs = area.ystride, area.zstride
	local air, stone, lava = c.air, c.stone, c.lava

	-- terrain
	for z = minp.z, maxp.z do
		local zi0 = (z - zmin) * W
		local nzb = (z - minp.z) * ny * nx
		for x = minp.x, maxp.x do
			local i = zi0 + (x - xmin) + 1
			local h = Hg[i]
			local ytop = h
			if ytop < WATER then ytop = WATER end
			if ytop > maxp.y then ytop = maxp.y end
			if ytop >= minp.y then
				local isr = Rg[i]
				local ctop, cfill, fd = surface(Bg[i], h)
				local wid = isr and c.rwater or c.water
				local vb = (z - emin.z) * zs + (x - emin.x) + 1 - emin.y * ys
				local nb = nzb + (x - minp.x) + 1 - minp.y * nx
				local pmin
				if h < WATER + 6 then pmin = 10 elseif h > 90 then pmin = 1 else pmin = 5 end
				for y = minp.y, ytop do
					local id
					if y <= h then
						if y == h then id = ctop
						elseif y > h - fd then id = cfill
						else id = stone end
						if need3d and y > CAVE_BOTTOM then
							local depth = h - y
							if depth >= pmin then
								local ni = nb + y * nx
								local dfac = depth / 300
								if dfac > 1 then dfac = 1 end
								local w = 0.05 + 0.07 * dfac
								local a1 = n1[ni]
								local carve = false
								if a1 > -w and a1 < w then
									local a2 = n2[ni]
									if a2 > -w and a2 < w then carve = true end
								end
								if not carve and depth > 20 and nc[ni] > 0.58 - 0.16 * dfac then
									carve = true
								end
								if carve then
									if y <= LAVA then id = lava else id = air end
								end
							end
						end
					else
						id = wid
					end
					data[vb + y * ys] = id
				end
			end
		end
	end

	megaworld.trees_begin(data, area, emin, emax)
	megaworld.place_trees(emin, emax, W, xmin, zmin, Hg, Bg, Rg, forest)

	-- ground plants and flowers
	for z = minp.z, maxp.z do
		local zi0 = (z - zmin) * W
		for x = minp.x, maxp.x do
			local i = zi0 + (x - xmin) + 1
			local h = Hg[i]
			if h > WATER and h >= minp.y and h < maxp.y and not Rg[i] then
				local b = Bg[i]
				local list, chance
				if b == B.RAIN then list, chance = c.jungle_plants, 0.45
				elseif b == B.TEMP then list, chance = c.grass_plants, 0.25
				elseif b == B.TAIGA then list, chance = c.fern_plants, 0.12
				elseif b == B.SAV then list, chance = c.dry_plants, 0.2
				elseif b == B.DES then list, chance = c.shrub, 0.01
				end
				if list and #list > 0 then
					local r = rnd(x, z, 7)
					local vi = area:index(x, h + 1, z)
					if data[vi] == air then
						if r < chance then
							data[vi] = list[floor(rnd(x, z, 8) * #list) + 1]
						elseif b == B.TEMP and r > 0.985 and #c.flowers > 0 then
							data[vi] = c.flowers[floor(rnd(x, z, 9) * #c.flowers) + 1]
						end
					end
				end
			end
		end
	end

	vm:set_data(data)
	pcall(minetest.generate_ores, vm, minp, maxp)
	vm:set_lighting({day = 0, night = 0})
	vm:calc_lighting()
	vm:update_liquids()
	vm:write_to_map()
end)
