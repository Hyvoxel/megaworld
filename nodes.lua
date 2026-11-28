local c = {}
megaworld.c = c

local function id(name, fb1, fb2)
	local reg = minetest.registered_nodes
	if reg[name] then return minetest.get_content_id(name) end
	if fb1 and reg[fb1] then return minetest.get_content_id(fb1) end
	if fb2 and reg[fb2] then return minetest.get_content_id(fb2) end
	return minetest.get_content_id("default:stone")
end

local function list(names)
	local t = {}
	for _, n in ipairs(names) do
		if minetest.registered_nodes[n] then
			t[#t + 1] = minetest.get_content_id(n)
		end
	end
	return t
end

c.air = minetest.get_content_id("air")
c.ignore = minetest.CONTENT_IGNORE or 127

c.stone = id("default:stone")
c.dirt = id("default:dirt")
c.grass = id("default:dirt_with_grass", "default:dirt")
c.litter = id("default:dirt_with_rainforest_litter", "default:dirt_with_grass", "default:dirt")
c.drygrass = id("default:dirt_with_dry_grass", "default:dirt_with_grass", "default:dirt")
c.conifer = id("default:dirt_with_coniferous_litter", "default:dirt_with_snow", "default:dirt_with_grass")
c.snowdirt = id("default:dirt_with_snow", "default:dirt_with_grass", "default:dirt")
c.sand = id("default:sand")
c.dsand = id("default:desert_sand", "default:sand")
c.gravel = id("default:gravel", "default:stone")
c.snowblock = id("default:snowblock", "default:stone")
c.water = id("default:water_source")
c.rwater = id("default:river_water_source", "default:water_source")
c.lava = id("default:lava_source", "default:stone")

-- trees
c.jtree = id("default:jungletree", "default:tree")
c.jleaves = id("default:jungleleaves", "default:leaves")
c.tree = id("default:tree")
c.leaves = id("default:leaves")
c.ptree = id("default:pine_tree", "default:tree")
c.pneedles = id("default:pine_needles", "default:leaves")
c.atree = id("default:aspen_tree", "default:tree")
c.aleaves = id("default:aspen_leaves", "default:leaves")
c.actree = id("default:acacia_tree", "default:tree")
c.acleaves = id("default:acacia_leaves", "default:leaves")

-- ground plants
c.grass_plants = list({"default:grass_2", "default:grass_3", "default:grass_4", "default:grass_5"})
c.dry_plants = list({"default:dry_grass_2", "default:dry_grass_3", "default:dry_grass_4", "default:dry_grass_5"})
c.jungle_plants = list({"default:junglegrass", "default:junglegrass", "default:fern_1", "default:fern_2", "default:fern_3"})
c.fern_plants = list({"default:fern_1", "default:fern_2", "default:fern_3", "default:grass_2"})
c.shrub = list({"default:dry_shrub"})
c.flowers = list({"flowers:dandelion_yellow", "flowers:dandelion_white", "flowers:rose",
	"flowers:tulip", "flowers:viola", "flowers:geranium"})

c.soft = {[c.air] = true, [c.ignore] = true}
for _, k in ipairs({"jleaves", "leaves", "pneedles", "aleaves", "acleaves"}) do
	c.soft[c[k]] = true
end
for _, k in ipairs({"grass_plants", "dry_plants", "jungle_plants", "fern_plants", "shrub", "flowers"}) do
	for _, cid in ipairs(c[k]) do c.soft[cid] = true end
end
