local Catalog = {MaxLevel=12, SpeedCap=10, StrengthCap=10, Slots=3, PayPeriod=5}
Catalog.Moons = {
	{ id="chalk", name="Меловая", rarity="Обычная", weight=58, hits=2, bounty=8, rent=1, color="D7DDE5", dark="838BA8" },
	{ id="tidal", name="Приливная", rarity="Необычная", weight=27, hits=3, bounty=15, rent=3, color="79E4D6", dark="368A9B" },
	{ id="orchid", name="Орхидея", rarity="Редкая", weight=11, hits=4, bounty=32, rent=7, color="C1A3FF", dark="7955BA" },
	{ id="ember", name="Янтарная", rarity="Эпическая", weight=3.5, hits=5, bounty=70, rent=15, color="FFC377", dark="CD764C" },
	{ id="corona", name="Корона", rarity="Легендарная", weight=0.5, hits=6, bounty=150, rent=32, color="FFE7A1", dark="D9924E" },
}
Catalog.ById = {}
for _,moon in ipairs(Catalog.Moons) do Catalog.ById[moon.id] = moon end

function Catalog.luck(level) return 1 + level * 0.25 end
function Catalog.walkSpeed(level) return 16 + 2 * level end
function Catalog.window(strength) return 0.16 + 0.022 * strength end
function Catalog.repsNeeded(strength) return 3 + strength end

function Catalog.price(stat, level)
	if stat == "level" then return 24 + 18*level + 10*level*level end
	return 20 + 12*level + 8*level*level
end

function Catalog.chances(level)
	local chances = {}
	local weight, previous = 0, 0
	for i,moon in ipairs(Catalog.Moons) do
		weight += moon.weight
		local cumulative = (weight/100)^Catalog.luck(level)
		chances[i] = cumulative - previous
		previous = cumulative
	end
	return chances
end

function Catalog.roll(level, sample)
	local sum = 0
	for i,chance in ipairs(Catalog.chances(level)) do
		sum += chance
		if sample < sum then return i end
	end
	return #Catalog.Moons
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
		counts = {}, slots = table.create(Catalog.Slots,""),
	}
	data.reps = integer(old.reps,Catalog.repsNeeded(data.strength)-1)
	for _,moon in ipairs(Catalog.Moons) do
		data.counts[moon.id] = integer((old.counts or {})[moon.id])
	end
	for i=1,Catalog.Slots do
		local id = (old.slots or {})[i]
		if Catalog.ById[id] and Catalog.inBag(data,id)>0 then data.slots[i]=id end
	end
	return data
end

function Catalog.income(data)
	local total = 0
	for _,id in ipairs(data.slots) do
		local moon = Catalog.ById[id]
		if moon then total += moon.rent end
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
	data.reps+=1
	if data.reps>=Catalog.repsNeeded(data.strength) then
		data.strength+=1
		data.reps=0
	end
	return true
end

function Catalog.award(data,index)
	local moon=Catalog.Moons[index]
	data.counts[moon.id]=(data.counts[moon.id] or 0)+1
	data.cash+=moon.bounty
end

return Catalog
