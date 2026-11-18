local Catalog = {}

Catalog.Taps = 18
Catalog.RevealTime = 3
Catalog.MaxLevel = 12
Catalog.Moons = {
	{ id = "chalk", name = "Меловая", rarity = "Обычная", weight = 58, dust = 8, color = "D7DDE5", dark = "838BA8" },
	{ id = "tidal", name = "Приливная", rarity = "Необычная", weight = 27, dust = 16, color = "79E4D6", dark = "368A9B" },
	{ id = "orchid", name = "Орхидея", rarity = "Редкая", weight = 11, dust = 36, color = "C1A3FF", dark = "7955BA" },
	{ id = "ember", name = "Янтарная", rarity = "Эпическая", weight = 3.5, dust = 80, color = "FFC377", dark = "CD764C" },
	{ id = "corona", name = "Корона", rarity = "Легендарная", weight = 0.5, dust = 200, color = "FFE7A1", dark = "D9924E" },
}

function Catalog.luck(level)
	return 1 + level * 0.25
end

function Catalog.price(level)
	return 24 + 12 * level + 4 * level * level
end

-- The same cumulative boundaries drive the server roll and the percentages in the atlas.
function Catalog.chances(level)
	local chances = {}
	local weight, previous = 0, 0
	for index, moon in ipairs(Catalog.Moons) do
		weight += moon.weight
		local cumulative = (weight / 100) ^ Catalog.luck(level)
		chances[index] = cumulative - previous
		previous = cumulative
	end
	return chances
end

function Catalog.roll(level, sample)
	local total = 0
	for index, probability in ipairs(Catalog.chances(level)) do
		total += probability
		if sample < total then return index end
	end
	return #Catalog.Moons
end

function Catalog.newProfile()
	return { dust = 0, level = 0, counts = {} }
end

function Catalog.upgrade(profile)
	if profile.level >= Catalog.MaxLevel then return false end
	local price = Catalog.price(profile.level)
	if profile.dust < price then return false end
	profile.dust -= price
	profile.level += 1
	return true
end

function Catalog.award(profile, index)
	local moon = Catalog.Moons[index]
	profile.counts[moon.id] = (profile.counts[moon.id] or 0) + 1
	profile.dust += moon.dust
end

return Catalog
