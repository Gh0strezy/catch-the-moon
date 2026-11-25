-- Run the production login/save callbacks against a serialized, in-memory DataStore.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local serde = require("@lune/serde")
local Catalog = require("../src/shared/MoonCatalog")

local key = "player_42"
local records = {}
local store = {}
function store:UpdateAsync(requestKey, transform)
	assert(requestKey == key)
	local old = records[key] and serde.decode("json", records[key])
	local updated = transform(old)
	if updated then
		records[key] = serde.encode("json", updated)
		return serde.decode("json", records[key])
	end
end
local nextToken = 0
local services = {
	DataStoreService = {GetDataStore = function(_, name)
		assert(name == "CatchTheMoon_v1")
		return store
	end},
	HttpService = {GenerateGUID = function()
		nextToken += 1
		return tostring(nextToken)
	end},
	RunService = {IsStudio = function() return false end},
}
local game = {ReplicatedStorage = {MoonCatalog = Catalog}}
function game:GetService(name) return assert(services[name]) end
local Profiles = luau.load(fs.readFile("src/server/ProfileStore.luau"), {
	environment = {game = game, require = function(module) return module end},
})()

for _, version in ipairs({1, 2}) do
	records[key] = serde.encode("json", {version=version, data={
		dust=187, level=4, speed=3, strength=2, reps=1,
		counts={chalk=2, tidal=3, orchid=1, ember=2, corona=1},
		slots={"corona", "tidal", "ember"},
	}})
	for login=1,3 do
		local session = assert(Profiles.open({UserId=42}))
		local data = session.data
		assert(data.level==4 and data.speed==3 and data.strength==2 and data.reps==1)
		assert(data.slots[1]=="neptune" and data.slots[2]=="venus" and data.slots[3]=="saturn")
		assert(data.counts.mercury==2 and data.counts.venus==3 and data.counts.uranus==1)
		assert(data.counts.saturn==2 and data.counts.neptune==1 and data.counts.chalk==nil)
		assert(data.counts.mars==0 and data.counts.jupiter==0 and Catalog.income(data)==50)
		assert(data.cash==(if login==1 then 187 else 202))
		assert(data.counts.earth==(if login==1 then 0 else 1))
		if login==1 then
			for index, planet in ipairs(Catalog.Planets) do
				if planet.id=="earth" then Catalog.award(data,index) end
			end
		end
		assert(session:save(false) and session:save(true))
		local record = serde.decode("json", records[key])
		assert(record.version==3 and record.owner==nil and record.expires==0)
	end
end
print("PASS: v1/v2 login, autosave, release, two rejoins and post-migration catch")
