local c = megaworld.c
local B = megaworld.B
local smooth = megaworld.smooth
local WATER = megaworld.WATER
local floor, sin, cos = math.floor, math.sin, math.cos

local function rnd(x, z, k)
	local v = sin(x * 12.9898 + z * 78.233 + k * 37.719) * 43758.5453
	return v - floor(v)
end
megaworld.rnd = rnd

local D, A, X0, X1, Y0, Y1, Z0, Z1
local air, ignore, soft = c.air, c.ignore, c.soft

function megaworld.trees_begin(data, area, emin, emax)
	D, A = data, area
	X0, X1, Y0, Y1, Z0, Z1 = emin.x, emax.x, emin.y, emax.y, emin.z, emax.z
end

local function put_leaf(x, y, z, id)
	if x < X0 or x > X1 or y < Y0 or y > Y1 or z < Z0 or z > Z1 then return end
	local vi = A:index(x, y, z)
	local n = D[vi]
	if n == air or n == ignore then D[vi] = id end
end

local function put_trunk(x, y, z, id)
	if x < X0 or x > X1 or y < Y0 or y > Y1 or z < Z0 or z > Z1 then return end
	local vi = A:index(x, y, z)
	if soft[D[vi]] then D[vi] = id end
end

local function blob(cx, cy, cz, rx, ry, rz, id, density)
	for dy = -ry, ry do
		for dz = -rz, rz do
			for dx = -rx, rx do
				local d = (dx * dx) / (rx * rx) + (dy * dy) / (ry * ry) + (dz * dz) / (rz * rz)
				if d <= 1.0 and (d < 0.55 or rnd(cx + dx, cz + dz, cy + dy) < density) then
					put_leaf(cx + dx, cy + dy, cz + dz, id)
				end
			end
		end
	end
end

local function trunk(x, y, z, h, id)
	for t = 1, h do put_trunk(x, y + t, z, id) end
end

local function giant_jungle(x, y, z)
	local H = 30 + floor(rnd(x, z, 31) * 18)
	local R = 8 + floor(rnd(x, z, 32) * 3)
	for t = 1, H do
		put_trunk(x, y + t, z, c.jtree)
		put_trunk(x + 1, y + t, z, c.jtree)
		put_trunk(x, y + t, z + 1, c.jtree)
		put_trunk(x + 1, y + t, z + 1, c.jtree)
	end
	local roots = {{-1, 0}, {-1, 1}, {2, 0}, {2, 1}, {0, -1}, {1, -1}, {0, 2}, {1, 2}}
	for i, r in ipairs(roots) do
		if rnd(x + i, z, 33) < 0.75 then
			local rh = 2 + floor(rnd(x, z + i, 34) * 3)
			for t = 0, rh do put_trunk(x + r[1], y + t, z + r[2], c.jtree) end
		end
	end
	local nb = 3 + floor(rnd(x, z, 35) * 3)
	for i = 1, nb do
		local ang = rnd(x, z, 40 + i) * 6.2832
		local by = y + floor(H * (0.55 + 0.3 * rnd(x, z, 50 + i)))
		local len = 5 + floor(rnd(x, z, 60 + i) * 4)
		local dx, dz = cos(ang), sin(ang)
		local px, py, pz = x, by, z
		for s = 1, len do
			px = x + floor(dx * s + 0.5)
			pz = z + floor(dz * s + 0.5)
			py = by + floor(s / 3)
			put_trunk(px, py, pz, c.jtree)
		end
		blob(px, py + 1, pz, 4, 2, 4, c.jleaves, 0.85)
	end
	blob(x, y + H, z, R, 3, R, c.jleaves, 0.85)
	blob(x, y + H + 2, z, R - 3, 2, R - 3, c.jleaves, 0.9)
end

local function jungle_medium(x, y, z)
	local H = 9 + floor(rnd(x, z, 71) * 9)
	local R = 3 + floor(rnd(x, z, 72) * 2)
	trunk(x, y, z, H, c.jtree)
	blob(x, y + H, z, R, 3, R, c.jleaves, 0.85)
	blob(x, y + H + 3, z, R - 1, 1, R - 1, c.jleaves, 0.9)
end

local function bush(x, y, z)
	put_trunk(x, y + 1, z, c.jtree)
	blob(x, y + 2, z, 2, 1, 2, c.jleaves, 0.8)
end

local function oak(x, y, z)
	local r1, r2 = rnd(x, z, 81), rnd(x, z, 82)
	if r2 < 0.2 then
		local H = 10 + floor(r1 * 5)
		trunk(x, y, z, H, c.tree)
		blob(x, y + H, z, 5, 4, 5, c.leaves, 0.85)
	else
		local H = 4 + floor(r1 * 4)
		trunk(x, y, z, H, c.tree)
		blob(x, y + H, z, 3, 2, 3, c.leaves, 0.85)
		blob(x, y + H + 2, z, 2, 1, 2, c.leaves, 0.9)
	end
end

local function aspen(x, y, z)
	local H = 8 + floor(rnd(x, z, 85) * 6)
	trunk(x, y, z, H, c.atree)
	blob(x, y + H - 1, z, 2, 4, 2, c.aleaves, 0.85)
end

local function pine(x, y, z, big)
	local H
	if big then H = 18 + floor(rnd(x, z, 91) * 10) else H = 8 + floor(rnd(x, z, 91) * 8) end
	trunk(x, y, z, H, c.ptree)
	put_leaf(x, y + H + 1, z, c.pneedles)
	local cap = big and 6 or 4
	local k = big and 0.28 or 0.32
	for l = 0, H - 3 do
		local rad = floor(l * k) + (l % 2)
		if rad > cap then rad = cap end
		local ly = y + H - l
		for dz = -rad, rad do
			for dx = -rad, rad do
				if dx * dx + dz * dz <= rad * rad + 1 then
					put_leaf(x + dx, ly, z + dz, c.pneedles)
				end
			end
		end
	end
end

local function acacia(x, y, z)
	local H = 5 + floor(rnd(x, z, 95) * 4)
	trunk(x, y, z, H, c.actree)
	blob(x, y + H, z, 5, 1, 5, c.acleaves, 0.8)
	blob(x, y + H + 1, z, 3, 1, 3, c.acleaves, 0.9)
end

local function dens(b, f)
	if b == B.RAIN then return 0.6 + 0.4 * smooth(-1.0, -0.2, f)
	elseif b == B.TEMP then return 0.9 * smooth(-0.1, 0.5, f)
	elseif b == B.TAIGA then return 0.9 * smooth(-0.3, 0.4, f)
	elseif b == B.TUNDRA then return 0.08
	elseif b == B.SAV then return 0.05 + 0.2 * smooth(0.1, 0.8, f)
	end
	return 0
end

function megaworld.place_trees(emin, emax, W, xmin, zmin, Hg, Bg, Rg, Fg)
	local x0, x1 = xmin, xmin + W - 1
	local z0, z1 = zmin, zmin + W - 1

	local function each(cell, k, maxh, fn)
		for cx = floor(x0 / cell), floor(x1 / cell) do
			for cz = floor(z0 / cell), floor(z1 / cell) do
				local x = cx * cell + floor(rnd(cx, cz, k) * cell)
				local z = cz * cell + floor(rnd(cx, cz, k + 1) * cell)
				if x >= x0 and x <= x1 and z >= z0 and z <= z1 then
					local i = (z - z0) * W + (x - x0) + 1
					local h = Hg[i]
					if h > WATER and h + maxh >= emin.y and h <= emax.y and not Rg[i] and h < 170 then
						fn(x, h, z, Bg[i], Fg[i], rnd(cx, cz, k + 2))
					end
				end
			end
		end
	end

	each(12, 100, 54, function(x, h, z, b, f, r)
		if b == B.RAIN and r < 0.75 * dens(b, f) then giant_jungle(x, h, z) end
	end)
	each(4, 120, 24, function(x, h, z, b, f, r)
		if b == B.RAIN and r < 0.8 * dens(b, f) then jungle_medium(x, h, z) end
	end)
	each(3, 140, 5, function(x, h, z, b, f, r)
		if b == B.RAIN and r < 0.5 * dens(b, f) then bush(x, h, z) end
	end)
	-- temperate forest
	each(5, 160, 18, function(x, h, z, b, f, r)
		if b == B.TEMP and r < 0.6 * dens(b, f) then
			if rnd(x, z, 5) < 0.25 then aspen(x, h, z) else oak(x, h, z) end
		end
	end)
	-- taiga / tundra
	each(4, 180, 34, function(x, h, z, b, f, r)
		if (b == B.TAIGA or b == B.TUNDRA) and r < 0.65 * dens(b, f) then
			pine(x, h, z, rnd(x, z, 6) < 0.18)
		end
	end)
	-- savanna
	each(14, 200, 14, function(x, h, z, b, f, r)
		if b == B.SAV and r < 2.5 * dens(b, f) then acacia(x, h, z) end
	end)
end
