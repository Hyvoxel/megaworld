megaworld = {}

local modname = minetest.get_current_modname()
local path = minetest.get_modpath(modname)
local S = minetest.settings

megaworld.WATER = 1

local function num(name, def)
	local v = tonumber(S:get(name))
	if v == nil then return def end
	return v
end

megaworld.scale = num("megaworld_scale", 1.0)
if megaworld.scale < 0.25 then megaworld.scale = 0.25 end
if megaworld.scale > 4 then megaworld.scale = 4 end
megaworld.sea_bias = num("megaworld_sea_bias", 0.1)
megaworld.cave_bottom = num("megaworld_cave_bottom", -900)
megaworld.lava_level = -500

local caves = S:get("megaworld_caves")
megaworld.caves = not (caves == "false")

minetest.set_mapgen_setting("mg_name", "singlenode", true)
minetest.set_mapgen_setting("water_level", tostring(megaworld.WATER), true)

dofile(path .. "/nodes.lua")
dofile(path .. "/noise.lua")
dofile(path .. "/trees.lua")
dofile(path .. "/mapgen.lua")
dofile(path .. "/spawn.lua")
