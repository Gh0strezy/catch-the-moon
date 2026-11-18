local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Catalog = require(game.ReplicatedStorage.MoonCatalog)

local ProfileStore = {}
ProfileStore.__index = ProfileStore
local LEASE_SECONDS = 180

function ProfileStore.open(player)
	local self = setmetatable({
		data = Catalog.newProfile(), key = "player_" .. player.UserId,
		token = HttpService:GenerateGUID(false), saving = false, closed = false,
	}, ProfileStore)
	-- Studio playtests use isolated session data, even if production API access is enabled.
	if RunService:IsStudio() then
		self.practice = true
		return self
	end
	for attempt = 1, 3 do
		local ok, record = pcall(function()
			self.store = DataStoreService:GetDataStore("CatchTheMoon_v1")
			return self.store:UpdateAsync(self.key, function(old)
				if old and old.version ~= 1 and old.version ~= 2 then return nil end
				if old and old.owner and old.owner ~= self.token and old.expires > os.time() then return nil end
				return { version = 2, data = Catalog.newProfile(old and old.data),
					owner = self.token, expires = os.time() + LEASE_SECONDS }
			end)
		end)
		if ok and record and record.owner == self.token then
			self.data = record.data
			return self
		end
		if attempt < 3 then task.wait(2 * attempt) end
	end
	return nil
end

function ProfileStore:save(release)
	if self.saving and not release then return true end
	while self.saving do task.wait() end
	if self.practice or self.closed then return true end
	self.saving = true
	local snapshot = Catalog.newProfile(self.data)
	local attempts = if release then 3 else 1
	local success = false
	for attempt = 1, attempts do
		local ok, stored = pcall(function()
			return self.store:UpdateAsync(self.key, function(old)
				if not old or old.owner ~= self.token then return nil end
				return { version = 2, data = snapshot, owner = if release then nil else self.token,
					expires = if release then 0 else os.time() + LEASE_SECONDS }
			end)
		end)
		if ok then
			success = stored ~= nil
			self.closed = release or not success
			break
		end
		if attempt < attempts then task.wait(attempt) end
	end
	self.saving = false
	return success
end

return ProfileStore
