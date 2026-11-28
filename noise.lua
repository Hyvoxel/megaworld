local sc = megaworld.scale

local function np2(offset, scale, spread, seed, oct, pers)
	return {
		offset = offset, scale = scale,
		spread = {x = spread * sc, y = spread * sc, z = spread * sc},
		seed = seed, octaves = oct, persist = pers,
		lacunarity = 2.0, flags = "defaults",
	}
end

local function np3(offset, scale, sx, sy, sz, seed, oct, pers)
	return {
		offset = offset, scale = scale,
		spread = {x = sx, y = sy, z = sz},
		seed = seed, octaves = oct, persist = pers,
		lacunarity = 2.0, flags = "defaults",
	}
end

megaworld.N = {
	cont   = np2(megaworld.sea_bias, 1.7, 3600, 1101, 4, 0.5), -- continents / oceans
	hills  = np2(0, 1, 380, 2202, 4, 0.55),
	mmask  = np2(0, 1.7, 1900, 3303, 3, 0.5),  -- where mountain ranges are
	mrid   = np2(0, 1, 650, 4404, 4, 0.55),    -- ridge lines
	riv1   = np2(0, 1, 1500, 5505, 3, 0.5),    -- giant rivers
	riv2   = np2(0, 1, 700, 6606, 3, 0.5),     -- tributaries
	temp   = np2(0, 1.6, 2800, 7707, 3, 0.5),
	humid  = np2(0, 1.6, 2100, 8808, 3, 0.5),
	forest = np2(0, 1.7, 800, 9909, 3, 0.55),
	detail = np2(0, 1, 45, 1212, 3, 0.55),
}

megaworld.N3 = {
	cavern = np3(0, 1, 240, 110, 240, 2020, 3, 0.5),
	tun1   = np3(0, 1, 150, 90, 150, 2121, 3, 0.5),
	tun2   = np3(0, 1, 150, 90, 150, 2222, 3, 0.5),
}

local B = {OCEAN = 1, BEACH = 2, RAIN = 3, SAV = 4, DES = 5, TEMP = 6,
	TAIGA = 7, TUNDRA = 8, ROCK = 9, PEAK = 10}
megaworld.B = B

local function smooth(e0, e1, x)
	local t = (x - e0) / (e1 - e0)
	if t < 0 then t = 0 elseif t > 1 then t = 1 end
	return t * t * (3 - 2 * t)
end
megaworld.smooth = smooth

local floor, abs, max = math.floor, math.abs, math.max

function megaworld.column(cont, hills, mmask, mrid, riv1, riv2, temp, humid, detail)
	local c = cont
	if c < -1.4 then c = -1.4 end

	local h
	if c < 0 then h = 2 + c * 110 else h = 2 + c * 18 end

	local landf = smooth(0, 0.3, c)
	h = h + hills * 32 * landf

	local mm = smooth(0.12, 0.7, mmask) * smooth(0.04, 0.35, c)
	local ridge = 1 - abs(mrid) * 2.2
	if ridge < 0 then ridge = 0 end
	h = h + mm * (50 + 430 * ridge * ridge)
	h = h + detail * (2 + 12 * mm) * landf

	local isriver = false
	if c > -0.02 then
		local rl = smooth(-0.02, 0.05, c) * (1 - 0.9 * mm)
		local a1, a2 = abs(riv1), abs(riv2)
		local v = max(1 - smooth(0, 0.117, a1), 1 - smooth(0, 0.056, a2))
		v = v * v * rl
		local ch = max(1 - smooth(0.013, 0.026, a1), 1 - smooth(0.008, 0.016, a2)) * rl
		if h > 3 then h = h + (3 - h) * v end
		if ch > 0 then
			h = h + (-5 - h) * ch
			if ch > 0.02 then isriver = true end
		end
	end

	local hi = floor(h + 0.5)
	local te = temp - max(0, h - 90) / 240
	local b
	if hi <= 1 then
		b = B.OCEAN
	elseif hi >= 330 or te < -1.2 then
		b = B.PEAK
	elseif hi >= 190 then
		if te < -0.3 then b = B.PEAK else b = B.ROCK end
	elseif hi <= 3 and c < 0.12 then
		b = B.BEACH
	elseif te > 0.05 then
		if humid > -0.05 then b = B.RAIN
		elseif humid > -0.5 then b = B.SAV
		else b = B.DES end
	elseif te > -0.35 then
		if humid < -0.7 then b = B.SAV else b = B.TEMP end
	elseif te > -0.75 then
		b = B.TAIGA
	else
		b = B.TUNDRA
	end
	return hi, b, isriver
end
