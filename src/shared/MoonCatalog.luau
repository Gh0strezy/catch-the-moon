local Catalog = {MaxLevel=12, SpeedCap=10, StrengthCap=10, Slots=3, PayPeriod=5}
Catalog.Sets = { solar = "Солнечная система" }
Catalog.Rarities = {
	{ name="Обычная", weight=58, bounty=8, rent=1 },
	{ name="Необычная", weight=27, bounty=15, rent=3 },
	{ name="Редкая", weight=11, bounty=32, rent=7 },
	{ name="Эпическая", weight=3.5, bounty=70, rent=15 },
	{ name="Легендарная", weight=0.5, bounty=150, rent=32 },
}

-- Geometry uses body radii, degrees of latitude/longitude, and hex colours.
Catalog.Planets = {
	{ id="mercury", name="Меркурий", set="solar", tier=1, appearance={
		color="ADB0B4", craters={count=28, seed=11, rim="C9C8C3", floor="75777F"},
	} },
	{ id="mars", name="Марс", set="solar", tier=1, appearance={
		color="CB6242", craters={count=16, seed=38, rim="B85234", floor="99452F"},
		parts={{name="PolarCap", shape="Ball", size={0.72,0.20,0.68}, position={0,0.92,0}, color="F4DDCB"}},
		patches={{-10,12,0.65,0.14,"873F30"},{-7,39,0.34,0.10,"954532"}},
	} },
	{ id="venus", name="Венера", set="solar", tier=2, appearance={
		color="E6B36F", tilt=14, bands={{42,0.13,"F8D798"},{19,0.09,"DFA361"},
			{8,0.18,"F2CA89"},{-18,0.12,"CC955E"},{-39,0.16,"F1C588"}},
	} },
	{ id="earth", name="Земля", set="solar", tier=2, appearance={
		color="286BB0", parts={
			{name="Arctic", shape="Ball", size={0.74,0.23,0.79}, position={0,0.9,0}, color="E8F5EE"},
			{name="Antarctica", shape="Ball", size={0.88,0.27,0.83}, position={0,-0.88,0}, color="D7ECE8"},
		},
		-- Overlapping landforms trace Africa, Europe, Asia, the Americas and Australia.
		patches={{13,0,0.69,0.51,"69914B"},{-6,12,0.43,0.63,"729951"},
			{-22,16,0.24,0.40,"80A458"},{45,14,0.53,0.31,"779850"},
			{46,54,0.78,0.45,"7D9A57"},{50,91,0.83,0.51,"759253"},
			{26,75,0.30,0.47,"9BA660"},{31,107,0.59,0.49,"6A904C"},
			{49,-103,0.79,0.66,"74934F"},{26,-99,0.31,0.43,"8AA15A"},
			{13,-84,0.24,0.18,"78964D"},{-8,-56,0.54,0.66,"528A53"},
			{-35,-66,0.23,0.52,"7F9B59"},{-25,134,0.51,0.38,"B39B61"},
			{72,-42,0.35,0.36,"D5EAE4"},{-19,47,0.09,0.20,"85A45C"}},
	} },
	{ id="uranus", name="Уран", set="solar", tier=3, appearance={
		color="8DDCD9", tilt=70, bands={{36,0.10,"ADE9E2"},{-17,0.08,"77C9CD"}},
		rings={{inner=1.32,outer=1.35,color="B4DAD6"}},
	} },
	{ id="jupiter", name="Юпитер", set="solar", tier=3, appearance={
		color="E9C99F", bands={{54,0.13,"B99477"},{37,0.13,"F7DFB9"},
			{20,0.19,"B77652"},{6,0.10,"F6DDB1"},{-17,0.20,"C68A63"},
			{-36,0.12,"F5DDB3"},{-51,0.13,"AE836D"}},
		patches={{-18,8,0.54,0.30,"F3C796"},{-18,8,0.43,0.23,"B24D37",0.025}},
	} },
	{ id="saturn", name="Сатурн", set="solar", tier=4, appearance={
		color="E4C590", tilt=23, bands={{27,0.14,"EED6A4"},{-14,0.15,"C6A374"}},
		rings={{inner=1.20,outer=1.46,color="B69978"},{inner=1.46,outer=1.72,color="ECD5A4"},
			{inner=1.77,outer=1.92,color="C8AC86"}},
	} },
	{ id="neptune", name="Нептун", set="solar", tier=5, appearance={
		color="3858C7", tilt=-12, bands={{24,0.08,"6182E1"},{-31,0.10,"2949AE"}},
		patches={{-19,4,0.42,0.22,"253788"},{-8,17,0.49,0.07,"B1CEFA"}},
	} },
}

local legacyIds = {chalk="mercury", tidal="venus", orchid="uranus", ember="saturn", corona="neptune"}
Catalog.ById = {}
local tierSizes = {}
for _, planet in ipairs(Catalog.Planets) do
	local rarity = Catalog.Rarities[planet.tier]
	planet.rarity, planet.bounty, planet.rent = rarity.name, rarity.bounty, rarity.rent
	Catalog.ById[planet.id] = planet
	tierSizes[planet.tier] = (tierSizes[planet.tier] or 0) + 1
end

function Catalog.luck(level) return 1 + level * 0.25 end
function Catalog.walkSpeed(level) return 16 + 2 * level end
function Catalog.repsNeeded(strength) return 3 + strength end
local baseReach = 10
function Catalog.reach(strength) return baseReach + 1.5 * strength end
Catalog.CastWindup = 0.26
Catalog.ReelTime = 1.22
Catalog.AimPeriod = 1.6
Catalog.AimTimeout = 15
local sectors = {
	{name = "Ближняя орбита", from = 0, bonus = 0, color = "A7ACFF"},
	{name = "Пояс астероидов", from = 14, bonus = 0.20, color = "76E4D9"},
	{name = "Внешняя орбита", from = 20, bonus = 0.48, color = "FFD391"},
	{name = "Дальний космос", from = 26, bonus = 0.85, color = "FFA8D4"},
}
function Catalog.sector(reach)
	for index = #sectors, 2, -1 do
		if reach >= sectors[index].from then return sectors[index] end
	end
	return sectors[1]
end
function Catalog.aimPower(elapsed)
	local phase = math.max(0, elapsed) % Catalog.AimPeriod / Catalog.AimPeriod
	return 1 - math.abs(2 * phase - 1)
end
function Catalog.aimBonus(power) return math.floor(5 * power + 0.5) end
function Catalog.castTime(reach) return 0.46 + (reach - baseReach) * 0.035 end
function Catalog.flightProgress(elapsed, reach)
	local phase = math.clamp((elapsed-Catalog.CastWindup)/Catalog.castTime(reach),0,1)
	return phase * phase * (3 - 2 * phase)
end
function Catalog.distanceLuck(reach)
	return 1 + math.max(0,reach-baseReach)/baseReach + Catalog.sector(reach).bonus
end

Catalog.GymTiers = {
	{name = "Тренажёр «Старт»", xp = 1, price = 0, color = "A7ACFF"},
	{name = "Тренажёр «Импульс»", xp = 2, price = 30, color = "76E4D9"},
	{name = "Тренажёр «Орбита»", xp = 3, price = 100, color = "FFD391"},
}

function Catalog.upgradeGym(data)
	local nextTier = Catalog.GymTiers[data.gymTier + 1]
	if not nextTier or data.cash < nextTier.price then return false end
	data.cash -= nextTier.price
	data.gymTier += 1
	return true
end

function Catalog.price(stat, level)
	if stat == "level" then return 24 + 18*level + 10*level*level end
	return 20 + 12*level + 8*level*level
end

function Catalog.rarityChances(level, reach)
	local result = {}
	local weight, previous = 0, 0
	local luck = Catalog.luck(level) * Catalog.distanceLuck(reach or baseReach)
	for tier, rarity in ipairs(Catalog.Rarities) do
		weight += rarity.weight
		local cumulative = (weight / 100) ^ luck
		result[tier] = cumulative - previous
		previous = cumulative
	end
	return result
end

function Catalog.chances(level, reach)
	local tiers = Catalog.rarityChances(level, reach)
	local chances = {}
	for i, planet in ipairs(Catalog.Planets) do
		chances[i] = tiers[planet.tier] / tierSizes[planet.tier]
	end
	return chances
end

function Catalog.roll(level, sample, reach)
	local chances = Catalog.chances(level, reach)
	local sum = 0
	for i,chance in ipairs(chances) do
		sum += chance
		if sample < sum then return i, chance end
	end
	return #chances, chances[#chances]
end

local function integer(value, maximum)
	if type(value) ~= "number" or value ~= value then return 0 end
	return math.clamp(math.floor(value), 0, maximum or 1e12)
end

function Catalog.inBag(data, id)
	local available = data.counts[id] or 0
	for _,item in ipairs(data.slots) do
		if item == id then available -= 1 end
	end
	return available
end

function Catalog.newProfile(old)
	old = old or {}
	local data = {
		cash = integer(old.cash or old.dust), level = integer(old.level,Catalog.MaxLevel),
		speed = integer(old.speed,Catalog.SpeedCap), strength = integer(old.strength,Catalog.StrengthCap),
		gymTier = math.max(1, integer(old.gymTier, #Catalog.GymTiers)),
		counts = {}, slots = table.create(Catalog.Slots,""),
	}
	data.reps = integer(old.reps,Catalog.repsNeeded(data.strength)-1)
	for _, planet in ipairs(Catalog.Planets) do
		data.counts[planet.id] = 0
	end
	for savedId, count in pairs(old.counts or {}) do
		local id = legacyIds[savedId] or savedId
		if Catalog.ById[id] then data.counts[id] += integer(count) end
	end
	for i=1,Catalog.Slots do
		local savedId = (old.slots or {})[i]
		local id = legacyIds[savedId] or savedId
		if Catalog.ById[id] and Catalog.inBag(data,id)>0 then data.slots[i]=id end
	end
	return data
end

function Catalog.income(data)
	local total = 0
	for _,id in ipairs(data.slots) do
		local planet = Catalog.ById[id]
		if planet then total += planet.rent end
	end
	return total
end

function Catalog.place(data, slot, id)
	if type(slot)~="number" or slot%1~=0 or slot<1 or slot>Catalog.Slots then return false end
	if id~="" and (type(id)~="string" or not Catalog.ById[id] or Catalog.inBag(data,id)<1) then return false end
	if data.slots[slot]==id then return false end
	data.slots[slot]=id
	return true
end

function Catalog.buy(data, stat)
	local cap = if stat=="level" then Catalog.MaxLevel elseif stat=="speed" then Catalog.SpeedCap else nil
	if not cap or data[stat]>=cap then return false end
	local price = Catalog.price(stat,data[stat])
	if data.cash<price then return false end
	data.cash-=price
	data[stat]+=1
	return true
end

function Catalog.train(data)
	if data.strength>=Catalog.StrengthCap then return false end
	data.reps += Catalog.GymTiers[data.gymTier].xp
	local needed = Catalog.repsNeeded(data.strength)
	if data.reps >= needed then
		data.strength += 1
		data.reps = if data.strength == Catalog.StrengthCap then 0 else data.reps - needed
	end
	return true
end

function Catalog.award(data,index)
	local planet=Catalog.Planets[index]
	data.counts[planet.id]=(data.counts[planet.id] or 0)+1
	data.cash+=planet.bounty
end

return Catalog
