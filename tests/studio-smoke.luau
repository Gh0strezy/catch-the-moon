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
	waitFor("profile and character",function()
		local char=player.Character
		return d and char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChildOfClass("Humanoid")
	end)
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
			while workspace:GetServerTimeNow()<target and hunt==h do task.wait() end
			if hunt==h then event:FireServer("strike",h.id,h.step,workspace:GetServerTimeNow()) end
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
		assert(workspace.CurrentCamera.CameraType~=Enum.CameraType.Scriptable,"close-up held the camera")
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
	waitFor("new hunt after re-entry",function() return hunt~=nil end)
	local missedMoon=workspace:WaitForChild("LassoMoon",5)
	local missedLoop=workspace:WaitForChild("LassoLoop",5)
	local firstPass=hunt
	local target=firstPass.start+firstPass.period*firstPass.center
	repeat task.wait() until workspace:GetServerTimeNow()>=target
	event:FireServer("strike",firstPass.id,firstPass.step,workspace:GetServerTimeNow())
	waitFor("perfect hit",function() return hunt and hunt.hits==1 end)
	-- Read the rendered character, including upgraded R15 AnimationConstraints.
	local char=player.Character
	local root=char.HumanoidRootPart
	local back=char:FindFirstChild("LassoGrip",true)
	local front=char:FindFirstChild("LassoFrontGrip",true)
	assert(back and front,"two hand contacts")
	local function sampleGrip()
		return root.CFrame:PointToObjectSpace(back.WorldPosition),root.CFrame:PointToObjectSpace(front.WorldPosition)
	end
	local began=os.clock()
	repeat game:GetService("RunService").RenderStepped:Wait() until os.clock()-began>=0.23
	local extendedRight,extendedLeft=sampleGrip()
	local foot=char:FindFirstChild("LeftFoot")
	local planted=foot and foot.Position
	waitFor("gold impact",function() return missedLoop:FindFirstChild("LassoImpact_hit") end)
	repeat game:GetService("RunService").RenderStepped:Wait() until os.clock()-began>=0.60
	local pulledRight,pulledLeft=sampleGrip()
	local size=root.Size.Y/2
	assert((pulledRight-extendedRight).Magnitude>0.65*size and (pulledLeft-extendedLeft).Magnitude>0.65*size,
		"both hands must travel on the character during the haul")
	if foot and root.AssemblyLinearVelocity.Magnitude<1 then
		assert((foot.Position-planted).Magnitude<0.42*size,"support foot slid during the pull")
	end
	local frontLine,backLine=false,false
	for _,line in missedLoop:GetChildren() do
		if line:IsA("Beam") and line.Enabled then
			frontLine=frontLine or line.Attachment0==front
			backLine=backLine or (line.Attachment0==back and line.Attachment1==front)
		end
	end
	assert(frontLine and backLine,"rope must pass through both palms")
	local skipped=hunt
	waitFor("unanswered pass loses progress",function() return hunt and hunt.mistakes==1 and hunt.hits==0 end)
	waitFor("miss draws broken strokes",function() return missedLoop:FindFirstChild("LassoImpact_miss") end)
	event:FireServer("strike",skipped.id,skipped.step,workspace:GetServerTimeNow())
	local second=hunt
	repeat task.wait() until workspace:GetServerTimeNow()>=second.start+0.06
	event:FireServer("strike",second.id,second.step,workspace:GetServerTimeNow())
	waitFor("second miss survives",function() return hunt and hunt.mistakes==2 and hunt.hits==0 end)
	waitFor("recoil leaves afterimages",function() return missedLoop:FindFirstChild("LassoAfterimage") end)
	waitFor("third miss frees moon",function() return not hunt and not lastCatch end)
	waitFor("escape impact",function() return missedLoop:FindFirstChild("LassoImpact_escape") end)
	waitFor("escape cleanup",function() return not missedMoon.Parent and not missedLoop.Parent end)
	local first=catch(false)
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
	return "PASS: timeout and manual misses, lost progress, two surviving misses, escape, anime impacts, hand catch, restored camera, economy and stations"
end)
game.ReplicatedStorage.ExpeditionTest:FireServer("finish",if ok then result else "FAIL: "..tostring(result))
]=]
driver.Parent=game.StarterPlayer.StarterPlayerScripts
task.wait(2)
local result=service:ExecutePlayModeAsync("Observatory")
print(tostring(result))
assert(type(result)=="string" and result:sub(1,4)=="PASS",tostring(result))
