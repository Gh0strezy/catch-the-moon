local C=require("../src/shared/MoonCatalog")
local expected = {
	{"mercury", 1, 29, 8, 1}, {"mars", 1, 29, 8, 1},
	{"venus", 2, 13.5, 15, 3}, {"earth", 2, 13.5, 15, 3},
	{"uranus", 3, 5.5, 32, 7}, {"jupiter", 3, 5.5, 32, 7},
	{"saturn", 4, 3.5, 70, 15}, {"neptune", 5, 0.5, 150, 32},
}
assert(#C.Planets == #expected)
local base = C.chances(0)
for i, values in ipairs(expected) do
	local id, tier, chance, bounty, rent = table.unpack(values)
	local planet = C.Planets[i]
	assert(planet.id == id and C.ById[id] == planet and planet.tier == tier)
	assert(planet.set == "solar" and C.Sets[planet.set] == "Солнечная система")
	assert(planet.bounty == bounty and planet.rent == rent)
	assert(math.abs(100*base[i] - chance) < 1e-10)
	local caught = C.newProfile()
	C.award(caught, i)
	assert(caught.cash == bounty and C.inBag(caught, id) == 1)
	assert(C.place(caught, 2, id) and C.income(caught) == rent)
	local reloaded = C.newProfile(caught)
	assert(reloaded.cash == bounty and reloaded.slots[2] == id and C.inBag(reloaded, id) == 0)
end

for legacy, id in pairs({chalk="mercury", tidal="venus", orchid="uranus", ember="saturn", corona="neptune"}) do
	local profile = C.newProfile({
		dust=80, level=4, speed=5, strength=3, reps=2,
		counts={[legacy]=2, [id]=1, earth=4}, slots={legacy,id,legacy},
	})
	for _=1,3 do
		assert(profile.cash==80 and profile.level==4 and profile.speed==5 and profile.strength==3 and profile.reps==2)
		assert(profile.counts[id]==3 and profile.counts.earth==4 and profile.counts[legacy]==nil)
		assert(C.inBag(profile,id)==0 and C.income(profile)==3*C.ById[id].rent)
		for slot=1,C.Slots do assert(profile.slots[slot]==id) end
		profile=C.newProfile(profile)
	end
end
local old=C.newProfile({cash=53,dust=80,counts={chalk=1,tidal=2}})
assert(old.cash==53)
assert(C.place(old,1,"mercury") and C.inBag(old,"mercury")==0 and C.income(old)==1)
assert(not C.place(old,2,"mercury") and not C.place(old,4,"venus") and not C.place(old,1,"missing"))
assert(C.place(old,1,"venus") and C.inBag(old,"mercury")==1)
assert(C.place(old,2,"venus") and C.income(old)==6 and C.inBag(old,"venus")==0)
local copy=C.newProfile(old)
assert(C.place(copy,1,"") and C.income(copy)==3 and C.income(old)==6)
assert(C.newProfile({slots={"corona","neptune","corona"},counts={corona=1}}).slots[2]=="")
local d=C.newProfile()
assert(not C.buy(d,"level"))
C.award(d,1)
assert(d.cash==8 and d.counts.mercury==1)
d.cash=44
assert(C.buy(d,"level") and C.buy(d,"speed") and d.cash==0)
assert(C.walkSpeed(d.speed)==18 and C.luck(d.level)==1.25)
for _=1,3 do assert(C.train(d)) end
assert(d.strength==1 and d.reps==0 and C.reach(1)>C.reach(0))
assert(d.gymTier==1 and not C.upgradeGym(d))
local trained=C.newProfile({cash=30,reps=2})
assert(C.upgradeGym(trained) and trained.cash==0 and C.train(trained))
assert(trained.strength==1 and trained.reps==1 and C.newProfile(trained).gymTier==2)
for _,stat in ipairs({"speed","level"}) do
	d.cash=1e9
	while C.buy(d,stat) do end
	assert(d[stat]==(if stat=="speed" then C.SpeedCap else C.MaxLevel))
end
local previous
for level=0,C.MaxLevel do
	local odds=C.chances(level)
	local sum, byTier, share=0, {}, {}
	for i,chance in ipairs(odds) do
		local tier=C.Planets[i].tier
		assert(chance>0 and C.roll(level,sum+1e-12)==i and C.roll(level,sum+chance-1e-12)==i)
		if share[tier] then assert(share[tier]==chance) end
		share[tier]=chance
		byTier[tier]=(byTier[tier] or 0)+chance
		sum+=chance
	end
	assert(math.abs(sum-1)<1e-10)
	local tail, prevTail=0,0
	for tier=#C.Rarities,2,-1 do
		assert(math.abs(byTier[tier]-C.rarityChances(level)[tier])<1e-10)
		tail+=byTier[tier]
		if previous then prevTail+=previous[tier]; assert(tail>prevTail) end
	end
	previous=byTier
	local close, far = C.rarityChances(level,C.reach(0)), C.rarityChances(level,C.reach(C.StrengthCap))
	local closeTail, farTail = 0, 0
	for tier=#C.Rarities,2,-1 do
		closeTail+=close[tier]
		farTail+=far[tier]
		assert(farTail>closeTail)
	end
end
assert(C.reach(0)==10 and C.reach(C.StrengthCap)==25)
assert(C.aimBonus(C.aimPower(0))==0 and C.aimBonus(C.aimPower(C.AimPeriod/2))==5)
assert(C.sector(C.reach(0))~=C.sector(C.reach(0)+C.aimBonus(1)))
assert(C.flightProgress(C.CastWindup,30)==0 and C.flightProgress(C.CastWindup+C.castTime(30)+0.01,30)==1)
assert(C.roll(0,0.99,C.reach(0))<#C.Planets and C.roll(0,0.99,C.reach(C.StrengthCap))==#C.Planets)
print("PASS: migration, inventory ownership, rentals, economy, strength, rarity and throw timing")
