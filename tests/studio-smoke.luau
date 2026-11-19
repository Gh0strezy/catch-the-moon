-- Use Studio CLI RunScript on an unsaved copy. Only the test can move its player between landmarks.
local service=game:GetService("StudioTestService")
local bridge=Instance.new("RemoteEvent")
bridge.Name,bridge.Parent="ExpeditionTest",game.ReplicatedStorage
local server=Instance.new("Script")
server.Source=[=[
local test=game.ReplicatedStorage.ExpeditionTest
test.OnServerEvent:Connect(function(p,action,value)
	if action=="finish" then game:GetService("StudioTestService"):EndTest(value) return end
	local hub=workspace.Observatory
	local spot=if value=="Display" then hub.Gallery["Plot_"..p.UserId].Slot1 else hub.Stations[value]
	p.Character:PivotTo(CFrame.new(spot.Position+Vector3.new(0,4,4)))
	test:FireClient(p,"moved",value)
end)
task.delay(140,function() game:GetService("StudioTestService"):EndTest("FAIL: timeout") end)
]=]
server.Parent=game.ServerScriptService
local driver=Instance.new("LocalScript")
driver.Source=[=[
local ok,result=pcall(function()
	local player=game.Players.LocalPlayer
	local ui=player:WaitForChild("PlayerGui"):WaitForChild("MoonStation",20)
	local event=game.ReplicatedStorage:WaitForChild("MoonStationEvent")
	local bridge=game.ReplicatedStorage.ExpeditionTest
	local catalog=require(game.ReplicatedStorage.MoonCatalog)
	local d,hunt,lastCatch,moved,menu
	local function waitFor(label,check)
		local limit=os.clock()+14
		while not check() and os.clock()<limit do task.wait(0.04) end
		assert(check(),label)
	end
	event.OnClientEvent:Connect(function(k,a,b)
		if k=="profile" then d=a elseif k=="hunt" then hunt=a elseif k=="finish" then hunt=nil; lastCatch=b
		elseif k=="menu" then menu=a end
	end)
	bridge.OnClientEvent:Connect(function(_,key) moved=key end)
	local function move(key)
		moved=nil
		bridge:FireServer("move",key)
		waitFor("move to "..key,function() return moved==key end)
		task.wait(0.35)
	end
	task.wait(1)
	event:FireServer("sync")
	waitFor("profile and character",function() return d and player.Character and player.Character:FindFirstChild("HumanoidRootPart") end)
	assert(ui and workspace.CurrentCamera.CameraType~=Enum.CameraType.Scriptable)
	assert(player.Character.Humanoid.WalkSpeed==16)
	move("Gym")
	for i=1,3 do
		event:FireServer("use","Gym")
		task.wait(0.98)
	end
	waitFor("strength",function() return d.strength==1 end)
	local function catch(auto)
		lastCatch=nil
		if not auto then event:FireServer("use","Catch") end
		waitFor("encounter",function() return hunt~=nil end)
		assert(hunt.width==catalog.window(1) and hunt.goal==catalog.Moons[hunt.index].hits)
		local moon=workspace:WaitForChild("LassoMoon",5)
		local loop=workspace:WaitForChild("LassoLoop",5)
		assert(moon and loop and moon:GetAttribute("OwnerId")==player.UserId)
		waitFor("loop lands on planet",function()
			return (loop.Position-moon:GetPivot().Position).Magnitude<0.25
		end)
		while hunt do
			local h=hunt
			local target=h.start+h.period*h.center
			while target<workspace:GetServerTimeNow()+0.02 do target+=h.period end
			repeat task.wait() until workspace:GetServerTimeNow()>=target
			event:FireServer("strike",h.id,h.step,workspace:GetServerTimeNow())
			waitFor("server advances timing",function() return not hunt or hunt.step~=h.step end)
			if hunt and hunt.hits==1 then
				waitFor("first hit pulls the moon closer",function() return moon:GetScale()<0.49 end)
			end
		end
		assert(lastCatch,"capture failed")
		local grip=player.Character:FindFirstChild("LassoGrip",true)
		waitFor("miniature in hand",function()
			return moon.Parent and moon:GetScale()<0.102 and (moon:GetPivot().Position-grip.WorldPosition).Magnitude<1
		end)
		waitFor("lasso cleanup",function() return not moon.Parent and not grip.Parent and not loop.Parent end)
		return catalog.Moons[lastCatch]
	end
	move("Catch")
	waitFor("circle starts hunt on entry",function() return hunt and workspace:FindFirstChild("LassoLoop") end)
	event:FireServer("cancel")
	waitFor("cancel removes rope",function() return not hunt and not workspace:FindFirstChild("LassoLoop") end)
	task.wait(0.3)
	assert(not hunt,"standing in the circle restarted a cancelled hunt")
	move("Gym")
	move("Catch")
	local first=catch(true)
	move("Display")
	event:FireServer("use","Display",1)
	waitFor("exhibit menu",function() return menu=="Display" end)
	task.wait(0.22)
	event:FireServer("place",1,first.id)
	waitFor("placed planet",function() return d.slots[1]==first.id end)
	local pad=workspace.Observatory.Gallery["Plot_"..player.UserId].Slot1
	assert(pad:WaitForChild("Exhibit",5))
	local balance=d.cash
	waitFor("passive dollars",function() return d.cash>balance end)
	event:FireServer("place",1,"")
	waitFor("returned item",function() return d.slots[1]=="" end)
	assert(catalog.inBag(d,first.id)==1)
	move("Catch")
	while d.cash<44 do catch(hunt~=nil); task.wait(0.2) end
	move("Luck")
	event:FireServer("buy","Luck")
	waitFor("bought luck",function() return d.level==1 end)
	move("Speed")
	event:FireServer("buy","Speed")
	waitFor("bought speed",function() return d.speed==1 and player.Character.Humanoid.WalkSpeed==18 end)
	return "PASS: circle entry, cancel and re-entry, lasso cast, reel, hand catch, cleanup, free camera, training, showcase, income and upgrades"
end)
game.ReplicatedStorage.ExpeditionTest:FireServer("finish",if ok then result else "FAIL: "..tostring(result))
]=]
driver.Parent=game.StarterPlayer.StarterPlayerScripts
task.wait(2)
local result=service:ExecutePlayModeAsync("Observatory")
print(tostring(result))
assert(type(result)=="string" and result:sub(1,4)=="PASS",tostring(result))
