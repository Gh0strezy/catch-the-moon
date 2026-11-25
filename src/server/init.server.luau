local Players = game:GetService("Players")
local storage = game:GetService("ReplicatedStorage")
local Catalog = require(storage:WaitForChild("MoonCatalog"))
local Profiles = require(script.ProfileStore)
local Stations = require(script.Stations)
local Gym = require(script.Gym)
local event = Instance.new("RemoteEvent")
event.Name = "MoonStationEvent"
local sessions, hunting, aiming, loading = {}, {}, {}, {}
local rng = Random.new()
local sequence, pending, closing = 0,0,false

local function update(player)
	local s=sessions[player]
	event:FireClient(player,"profile",s.data,s.practice==true)
end
local function message(player,text)
	event:FireClient(player,"notice",text)
end
local function cancelAim(player)
	if not aiming[player] then return end
	aiming[player] = nil
	event:FireClient(player,"aim")
end
local function setSpeed(player)
	local session=sessions[player]
	local humanoid=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if session and humanoid then humanoid.WalkSpeed=Catalog.walkSpeed(session.data.speed) end
end

-- Settle elapsed time at the old rate before changing an exhibit.
local function settle(s)
	local now=os.clock()
	local amount=s.fraction+(now-s.accruedAt)*Catalog.income(s.data)/Catalog.PayPeriod
	local dollars=math.floor(amount)
	s.fraction,s.accruedAt=amount-dollars,now
	s.data.cash+=dollars
	return dollars>0
end
local function endHunt(player,text,index)
	local round=hunting[player]
	hunting[player]=nil
	event:FireClient(player,"finish",text,index)
	if not round.reelStartedAt then event:FireAllClients("lassoEnd",player,round.id) end
end

local function syncLassos(player)
	for owner,round in pairs(hunting) do
		event:FireClient(player,"lasso",owner,round)
	end
end

local function inputGrace(player)
	return math.clamp(player:GetNetworkPing()+0.12,0.16,0.42)
end

local function complete(player,round)
	Catalog.award(sessions[player].data,round.index)
	local planet=Catalog.Planets[round.index]
	update(player)
	endHunt(player,"В рюкзаке теперь "..planet.name.."!   +$"..planet.bounty,round.index)
end

local function load(player)
	if closing or loading[player] or sessions[player] then return end
	loading[player]=true
	pending+=1
	local s=Profiles.open(player)
	if closing or player.Parent~=Players then
		if s then s:save(true) end
	elseif s then
		s.accruedAt,s.fraction,s.lastUse,s.lastSync=os.clock(),0,-10,-10
		sessions[player]=s
		Stations.assign(player)
		Stations.render(player,s.data)
		player.CharacterAdded:Connect(function(char)
			char:WaitForChild("Humanoid",10)
			setSpeed(player)
		end)
		player.CharacterRemoving:Connect(function()
			Gym.stop(player)
			cancelAim(player)
			if hunting[player] then endHunt(player,"Ловля завершена") end
		end)
		setSpeed(player)
		update(player)
		syncLassos(player)
	else
		player:Kick("Коллекция временно недоступна. Зайди через минуту.")
	end
	loading[player]=nil
	pending-=1
end

local function close(player)
	local s=sessions[player]
	Gym.stop(player)
	sessions[player],hunting[player],aiming[player]=nil,nil,nil
	Stations.remove(player)
	if s then
		pending+=1
		settle(s)
		if not s:save(true) then warn("Could not finish saving planet collection",player.UserId) end
		pending-=1
	end
end

local function useStation(player,key,slot)
	if type(key)~="string" or Gym.active(player) or aiming[player] or not Stations.near(player,key,slot) then return end
	if key=="Catch" then
		if hunting[player] then return end
		sequence+=1
		local aim={id=sequence,start=workspace:GetServerTimeNow()+0.2}
		aiming[player]=aim
		event:FireClient(player,"aim",aim)
	elseif not hunting[player] then
		event:FireClient(player,"menu",key,slot)
	end
end

local function startWorkout(player,s)
	if hunting[player] or aiming[player] or not Stations.near(player,"Gym") then return end
	if s.data.strength>=Catalog.StrengthCap then
		message(player,"Сила максимальная")
		return
	end
	local function rep()
		if closing or s.closed or not Stations.near(player,"Gym") then return false end
		local old=s.data.strength
		if not Catalog.train(s.data) then return false end
		update(player)
		if s.data.strength>old then
			message(player,string.format("Сила %d · дальность %g ст.",s.data.strength,Catalog.reach(s.data.strength)))
		end
		return s.data.strength<Catalog.StrengthCap
	end
	if not Gym.start(player,s.data.gymTier,rep,function()
		event:FireClient(player,"gym",true)
	end,function()
		event:FireClient(player,"gym",false)
	end) then message(player,"Тренажёр занят или персонаж уже сидит") end
end

local function cast(player,s,id,pressed)
	local aim=aiming[player]
	if not aim or aim.id~=id or type(pressed)~="number" or pressed~=pressed then return end
	if not Stations.near(player,"Catch") then cancelAim(player) return end
	local now=workspace:GetServerTimeNow()
	if pressed<aim.start or pressed>=aim.start+Catalog.AimTimeout or pressed<now-inputGrace(player) or pressed>now+0.06 then return end
	local root=player.Character:FindFirstChild("HumanoidRootPart")
	aiming[player]=nil
	local reach=Catalog.reach(s.data.strength)+Catalog.aimBonus(Catalog.aimPower(pressed-aim.start))
	local index,chance=Catalog.roll(s.data.level,rng:NextNumber(),reach)
	local round={
		id=aim.id,index=index,castAt=now,heading=root.CFrame.LookVector,
		reach=reach,chance=chance,luck=Catalog.luck(s.data.level),
		reelAt=now+Catalog.CastWindup+Catalog.castTime(reach)+0.65,
	}
	hunting[player]=round
	event:FireClient(player,"hunt",round)
	event:FireAllClients("lasso",player,round)
end

event.OnServerEvent:Connect(function(player,action,a,b)
	local s=sessions[player]
	if not s or s.closed or closing then return end
	if action=="gymStop" then Gym.stop(player) return end
	if action=="cast" then cast(player,s,a,b) return end
	if action=="cancel" then
		cancelAim(player)
		if hunting[player] and not hunting[player].reelStartedAt then endHunt(player,"Ловля отменена") end
		return
	end
	local now=os.clock()
	if action=="sync" then
		if now-s.lastSync<0.5 then return end
		s.lastSync=now
		update(player)
		if hunting[player] then event:FireClient(player,"hunt",hunting[player]) end
		if aiming[player] then event:FireClient(player,"aim",aiming[player]) end
		if Gym.active(player) then event:FireClient(player,"gym",true) end
		syncLassos(player)
		return
	end
	if now-s.lastUse<0.15 then return end
	s.lastUse=now
	if action=="gymStart" then startWorkout(player,s)
	elseif action=="gymUpgrade" and not Gym.active(player) and not hunting[player] and s.data.strength<Catalog.StrengthCap
		and Stations.near(player,"Gym") then
		local paid=settle(s)
		if Catalog.upgradeGym(s.data) then
			update(player)
			message(player,Catalog.GymTiers[s.data.gymTier].name.." · улучшено")
		elseif paid then update(player) end
	elseif action=="use" then useStation(player,a,b)
	elseif action=="buy" and (a=="Luck" or a=="Speed") and Stations.near(player,a) then
		local stat=if a=="Luck" then "level" else "speed"
		if Catalog.buy(s.data,stat) then
			setSpeed(player)
			update(player)
			message(player,if a=="Luck" then "Удача улучшена" else "Скорость бега увеличена")
		else message(player,"Проверь цену и уровень улучшения") end
	elseif action=="place" and type(a)=="number" and Stations.near(player,"Display",a) then
		local paid=settle(s)
		if Catalog.place(s.data,a,b) then
			Stations.render(player,s.data)
			update(player)
			message(player,if b=="" then "Планета возвращена в рюкзак" else "Планета выставлена")
		elseif paid then update(player) end
	end
end)
event.Parent=storage
Players.PlayerAdded:Connect(load)
Players.PlayerRemoving:Connect(close)
for _,player in ipairs(Players:GetPlayers()) do task.spawn(load,player) end

task.spawn(function()
	while not closing do
		task.wait(0.1)
		local now=workspace:GetServerTimeNow()
		for player,aim in pairs(aiming) do
			if now>aim.start+Catalog.AimTimeout or not Stations.near(player,"Catch") then cancelAim(player) end
		end
		for player,round in pairs(hunting) do
			if sessions[player].closed then
				endHunt(player,"Ловля завершена")
			elseif round.reelStartedAt then
				if now>=round.reelStartedAt+Catalog.ReelTime then complete(player,round) end
			elseif not Stations.near(player,"Catch") then
				endHunt(player,"Ловля завершена · вернись к телескопу")
			elseif now>=round.reelAt then
				round.reelStartedAt=now
				event:FireAllClients("lassoEnd",player,round.id,now)
			end
		end
	end
end)

task.spawn(function()
	while not closing do
		task.wait(1)
		for player,s in pairs(sessions) do
			if not s.closed and settle(s) then update(player) end
		end
	end
end)
task.spawn(function()
	while not closing do
		task.wait(50)
		for player,s in pairs(sessions) do
			task.spawn(function()
				if not s:save(false) then
					warn("Could not renew planet collection",player.UserId)
					if s.closed and player.Parent==Players then player:Kick("Коллекция открыта в другой сессии.") end
				end
			end)
		end
	end
end)
game:BindToClose(function()
	closing=true
	for player in pairs(table.clone(sessions)) do task.spawn(close,player) end
	while pending>0 do task.wait(0.1) end
end)
