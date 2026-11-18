local catalog = require("../src/shared/MoonCatalog")
local Round = require("../src/server/Round")

local previous
for level = 0, catalog.MaxLevel do
	local odds = catalog.chances(level)
	local cumulative = 0
	for index, chance in ipairs(odds) do
		assert(chance > 0)
		if level == 0 then assert(math.abs(chance*100 - catalog.Moons[index].weight) < 1e-9) end
		assert(catalog.roll(level, cumulative + chance/2) == index)
		cumulative += chance
	end
	assert(math.abs(cumulative-1) < 1e-12)
	local tail, oldTail = 0, 0
	if previous then
		for i = #odds, 2, -1 do
			tail += odds[i]
			oldTail += previous[i]
			assert(tail > oldTail, "Each rarity threshold must improve with luck")
		end
	end
	previous = odds
end

local a, b = catalog.newProfile(), catalog.newProfile()
assert(not catalog.upgrade(a) and a.level == 0 and a.dust == 0)
for _=1,3 do catalog.award(a,1) end
assert(a.counts.chalk == 3 and b.counts.chalk == nil)
assert(catalog.upgrade(a) and a.level == 1 and a.dust == 0)
a.dust = 100000
while a.level < catalog.MaxLevel do assert(catalog.upgrade(a)) end
local before = a.dust
assert(not catalog.upgrade(a) and a.dust == before)

local round = Round.new(catalog.Taps)
assert(not round:tap("one",0,0))
assert(round:tap("one",1,0))
assert(not round:tap("one",1,0.025))
assert(round:tap("two",1,0.03))
assert(round:packet().crew == 2)
for i=3,catalog.Taps do assert(round:tap("one",1,i)) end
assert(round.paused and not round:tap("two",1,60))
round:remove("two")
assert(round:packet().crew == 1)
round:restart()
assert(not round.paused and round.id == 2 and round.hits == 0 and round:packet().crew == 0)
assert(not round:tap("one",1,80))
assert(round:tap("one",2,80))
print("PASS: odds, upgrades, inventory, shared catch, input cooldown and round rollover")
