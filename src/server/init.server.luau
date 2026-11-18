local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalog = require(ReplicatedStorage:WaitForChild("MoonCatalog"))
local ProfileStore = require(script.ProfileStore)
local Round = require(script.Round)

local event = Instance.new("RemoteEvent")
event.Name = "MoonStationEvent"
local round = Round.new(Catalog.Taps)
local random = Random.new()
local profiles, loading, lastSync = {}, {}, {}
local closing, pending = false, 0
local lastHit = 0

local function sendProfile(player, profile)
	event:FireClient(player, "profile", profile.data, profile.practice == true)
end

local function load(player)
	if closing or loading[player] or profiles[player] then return end
	loading[player] = true
	pending += 1
	local profile = ProfileStore.open(player)
	if closing or player.Parent ~= Players then
		if profile then profile:save(true) end
	elseif profile then
		profiles[player] = profile
		sendProfile(player, profile)
		event:FireClient(player, "round", round:packet())
	else
		player:Kick("Коллекция занята или временно недоступна. Зайди через минуту.")
	end
	loading[player] = nil
	pending -= 1
end

local function close(player)
	local profile = profiles[player]
	profiles[player] = nil
	lastSync[player] = nil
	round:remove(player)
	if profile then
		pending += 1
		if not profile:save(true) then warn("Could not finish saving lunar collection", player.UserId) end
		pending -= 1
	end
end

event.OnServerEvent:Connect(function(player, action, roundId)
	local profile = profiles[player]
	if closing or not profile or profile.closed then return end
	local now = os.clock()
	if action == "sync" then
		if lastSync[player] and now - lastSync[player] < 1 then return end
		lastSync[player] = now
		sendProfile(player, profile)
		event:FireClient(player, "round", round:packet())
	elseif action == "upgrade" then
		if Catalog.upgrade(profile.data) then sendProfile(player, profile) end
	elseif action == "tap" and round:tap(player, roundId, now) then
		lastHit = now
		event:FireAllClients("round", round:packet())
		if not round.paused then return end
		for member in pairs(round.contributors) do
			local session = profiles[member]
			if session and not session.closed then
				local index = Catalog.roll(session.data.level, random:NextNumber())
				Catalog.award(session.data, index)
				sendProfile(member, session)
				event:FireClient(member, "catch", index)
			end
		end
		task.delay(Catalog.RevealTime, function()
			round:restart()
			event:FireAllClients("round", round:packet())
		end)
	end
end)

event.Parent = ReplicatedStorage
Players.PlayerAdded:Connect(load)
Players.PlayerRemoving:Connect(close)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(load, player) end

task.spawn(function()
	while not closing do
		task.wait(5)
		if round.hits > 0 and not round.paused and os.clock() - lastHit > 45 then
			round:restart()
			event:FireAllClients("round", round:packet())
		end
	end
end)

task.spawn(function()
	while not closing do
		task.wait(50)
		for player, profile in pairs(profiles) do
			task.spawn(function()
				if not profile:save(false) then
					warn("Could not renew lunar collection", player.UserId)
					if profile.closed and player.Parent == Players then player:Kick("Коллекция открыта в другой сессии.") end
				end
			end)
		end
	end
end)

game:BindToClose(function()
	closing = true
	for player in pairs(table.clone(profiles)) do task.spawn(close, player) end
	while pending > 0 do task.wait(0.1) end
end)
