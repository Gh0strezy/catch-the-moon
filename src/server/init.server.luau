local Players = game:GetService("Players")
local storage = game:GetService("ReplicatedStorage")
local Catalog = require(storage:WaitForChild("MoonCatalog"))
local Profiles = require(script.ProfileStore)
local Round = require(script.Round)
local Stations = require(script.Stations)
local event = Instance.new("RemoteEvent")
event.Name = "MoonStationEvent"
local sessions, hunting, loading = {}, {}, {}
local rng = Random.new()
local sequence, pending, closing = 0,0,false

local function update(player)
	local s=sessions[player]
	event:FireClient(player,"profile",s.data,s.practice==true)
end
local function message(player,text)
	event:FireClient(player,"notice",text)
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
	hunting[player]=nil
	event:FireClient(player,"finish",text,index)
end
local function complete(player,round)
	Catalog.award(sessions[player].data,round.index)
	local moon=Catalog.Moons[round.index]
	update(player)
	endHunt(player,moon.name.." в рюкзаке   +$"..moon.bounty,round.index)
end

local function load(player)
	if closing or loading[player] or sessions[player] then return end
	loading[player]=true
	pending+=1
	local s=Profiles.open(player)
	if closing or player.Parent~=Players then
		if s then s:save(true) end
	elseif s then
		s.accruedAt,s.fraction,s.lastUse,s.lastTrain,s.lastSync=os.clock(),0,-10,-10,-10
		sessions[player]=s
		Stations.assign(player)
		Stations.render(player,s.data)
		player.CharacterAdded:Connect(function(char)
			char:WaitForChild("Humanoid",10)
			setSpeed(player)
		end)
		setSpeed(player)
		update(player)
	else
		player:Kick("Коллекция временно недоступна. Зайди через минуту.")
	end
	loading[player]=nil
	pending-=1
end

local function close(player)
	local s=sessions[player]
	sessions[player],hunting[player]=nil,nil
	Stations.remove(player)
	if s then
		pending+=1
		settle(s)
		if not s:save(true) then warn("Could not finish saving lunar collection",player.UserId) end
		pending-=1
	end
end

local function useStation(player,s,key,slot)
	if type(key)~="string" or not Stations.near(player,key,slot) then return end
	if key=="Catch" then
		if hunting[player] then return end
		sequence+=1
		local index=Catalog.roll(s.data.level,rng:NextNumber())
		local round=Round.new(sequence,index,Catalog.Moons[index],Catalog.window(s.data.strength),rng,workspace:GetServerTimeNow())
		hunting[player]=round
		event:FireClient(player,"hunt",round:packet())
	elseif key=="Gym" then
		if os.clock()-s.lastTrain<0.85 then return end
		s.lastTrain=os.clock()
		local old=s.data.strength
		if not Catalog.train(s.data) then message(player,"Сила максимальная") return end
		update(player)
		if s.data.strength>old then
			message(player,string.format("Сила %d · окно теперь %.1f%%",s.data.strength,100*Catalog.window(s.data.strength)))
		else
			message(player,string.format("Подъём штанги   %d / %d",s.data.reps,Catalog.repsNeeded(old)))
		end
	else
		event:FireClient(player,"menu",key,slot)
	end
end

local function strike(player,roundId,step,pressed)
	local round=hunting[player]
	if not round or round.id~=roundId then return end
	if not Stations.near(player,"Catch") then endHunt(player,"Ловля завершена · ты отошёл от телескопа") return end
	local now=workspace:GetServerTimeNow()
	local hit=round:judge(step,pressed,now,math.clamp(player:GetNetworkPing()+0.12,0.16,0.42))
	if hit==nil then return end
	if round.mistakes>=3 then endHunt(player,"Планета ушла с орбиты. Можно искать следующую.") return end
	if round.hits>=round.goal then complete(player,round)
	else event:FireClient(player,"hunt",round:packet(if hit then "Идеально!" else "Мимо")) end
	if hit then
		-- A nearby friend's precise hit helps after your first personal success.
		for friend,other in pairs(hunting) do
			if friend~=player and other.ownHit and now<=other.expires and Stations.near(friend,"Catch") then
				other.hits+=1
				if other.hits>=other.goal then complete(friend,other)
				else event:FireClient(friend,"hunt",other:packet("Помощь напарника")) end
			end
		end
	end
end

event.OnServerEvent:Connect(function(player,action,a,b,c)
	local s=sessions[player]
	if not s or s.closed or closing then return end
	if action=="strike" then strike(player,a,b,c) return end
	if action=="cancel" then
		if hunting[player] then endHunt(player,"Ловля завершена") end
		return
	end
	local now=os.clock()
	if action=="sync" then
		if now-s.lastSync<0.5 then return end
		s.lastSync=now
		update(player)
		if hunting[player] then event:FireClient(player,"hunt",hunting[player]:packet()) end
		return
	end
	if now-s.lastUse<0.15 then return end
	s.lastUse=now
	if action=="use" then useStation(player,s,a,b)
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
		task.wait(1)
		for player,s in pairs(sessions) do
			if not s.closed and settle(s) then update(player) end
			local round=hunting[player]
			if round and (workspace:GetServerTimeNow()>round.expires or not Stations.near(player,"Catch")) then
				endHunt(player,"Ловля завершена · вернись к телескопу")
			end
		end
	end
end)
task.spawn(function()
	while not closing do
		task.wait(50)
		for player,s in pairs(sessions) do
			task.spawn(function()
				if not s:save(false) then
					warn("Could not renew lunar collection",player.UserId)
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
