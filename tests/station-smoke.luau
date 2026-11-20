-- Run using Studio CLI RunScript on a scratch copy. All test actors are transient.
local world=workspace.World
local kit=game.ServerStorage.StationKit
local paint=require(kit.SlotAppearance)
local function close(a,b) return (a-b).Magnitude<0.025 end
assert(#world.Bridges:GetChildren()==8 and #world.PlayerBases:GetChildren()==8)
local parts,lights,emitters,spawns=0,0,0,0
for _,v in workspace:GetDescendants() do
	if v:IsA("BasePart") and not v:IsA("Terrain") then
		assert(v.Anchored,v:GetFullName())
		parts+=1
	elseif v:IsA("Light") then lights+=1
	elseif v:IsA("ParticleEmitter") then emitters+=1 end
	if v:IsA("SpawnLocation") then spawns+=1 end
end
assert(spawns==1 and lights<=4 and emitters<=3)
for i=1,8 do
	local base=world.PlayerBases[string.format("Base_%02d",i)]
	local bridge=world.Bridges[string.format("Bridge_%02d",i)]
	local a=math.rad(22.5+(i-1)*45)
	local axis=Vector3.new(math.sin(a),0,math.cos(a))
	assert(close(base:GetPivot().Position,axis*174+Vector3.yAxis*1.45))
	assert(bridge:GetAttribute("BaseIndex")==i and bridge.Walkway.Size.X>=12)
	local floor=base.Floors.Floor_01
	local slots=floor.PlanetSlots
	assert(#slots:GetChildren()==10 and #base.Floors:GetChildren()==1)
	local count=0
	for j=1,10 do
		local s=slots[string.format("PlanetSlot_%02d",j)]
		assert(s.Emitter.PlanetAnchor:IsA("Attachment"))
		if s:GetAttribute("Unlocked") then count+=1 end
	end
	assert(count==5)
	local socket=floor.ExpansionPoints.StackDatum.NextFloor.WorldCFrame
	local nextFloor=kit.FloorTemplate:Clone()
	nextFloor:PivotTo(socket)
	nextFloor.Parent=base.Floors
	assert(close(nextFloor:GetPivot().Position-floor:GetPivot().Position,Vector3.yAxis*16))
	for _,s in slots:GetChildren() do
		assert(close(nextFloor.PlanetSlots[s.Name].Emitter.PlanetAnchor.WorldPosition-s.Emitter.PlanetAnchor.WorldPosition,Vector3.yAxis*16))
	end
	local s=nextFloor.PlanetSlots.PlanetSlot_02
	paint.setUnlocked(s,true)
	assert(s.Halo.Material==Enum.Material.Neon and s.LockBar.Transparency==1)
	paint.setUnlocked(s,false)
	assert(s.Halo.Material==Enum.Material.Metal and s.LockBar.Transparency==0)
	nextFloor:Destroy()
	for _,key in {"NPCSpawn","NPCVisitorPoint","NPCEvaluationPoint"} do assert(base.NPCPoints.RouteDatum[key]:IsA("Attachment")) end
	assert(base.CatchZone["Casting apron"].CastOrigin.WorldCFrame.LookVector:Dot(axis)>0.999)
end
print(string.format("STRUCTURE PASS: 8 bridges/bases, 80 slots, stacking and independent states; %d static parts, %d local lights, %d emitters",parts,lights,emitters))
local event=Instance.new("RemoteEvent")
event.Name,event.Parent="StationReview",game.ReplicatedStorage
local observer=Instance.new("Script")
observer.Source=[=[
local event=game.ReplicatedStorage.StationReview
event.OnServerEvent:Connect(function(p,action,i)
	if action=="finish" then game:GetService("StudioTestService"):EndTest(i); return end
	local a=math.rad(22.5+(i-1)*45)
	p.Character:PivotTo(CFrame.new(63*math.sin(a),5,63*math.cos(a)))
	event:FireClient(p,i)
end)
task.delay(190,function() game:GetService("StudioTestService"):EndTest("FAIL: traversal timeout") end)
]=]
observer.Parent=game.ServerScriptService
local driver=Instance.new("LocalScript")
driver.Source=[=[
local ok,result=pcall(function()
	local player=game.Players.LocalPlayer
	local char=player.Character or player.CharacterAdded:Wait()
	local hum=char:WaitForChild("Humanoid",25)
	local root=char:WaitForChild("HumanoidRootPart",25)
	local world=workspace.World
	local event=game.ReplicatedStorage.StationReview
	local landed
	event.OnClientEvent:Connect(function(i) landed=i end)
	task.wait(1)
	assert((root.Position-world.CentralStation.CentralSpawn.Arrival.Position).Magnitude<9,"arrival")
	local roof=world.CentralStation.Observatory.RetractableRoof
	local start=roof.PortLeaf.PrimaryPart.Position.X
	local starboard=roof.StarboardLeaf.PrimaryPart.Position.X
	local function walk(point)
		hum:MoveTo(point)
		assert(hum.MoveToFinished:Wait(),"Walk blocked at "..tostring(root.Position).." heading to "..tostring(point))
	end
	for i=1,8 do
		local a=math.rad(22.5+(i-1)*45)
		local dir=Vector3.new(math.sin(a),0,math.cos(a))
		event:FireServer("dock",i)
		local limit=os.clock()+8
		repeat task.wait() until landed==i or os.clock()>limit
		assert(landed==i)
		for _,distance in {90,124,153,178,205} do walk(dir*distance+Vector3.yAxis*3) end
		assert(hum.Health>0)
		if i==1 then
			local moved=false
			for n=1,22 do
				local dx=roof.PortLeaf.PrimaryPart.Position.X-start
				local dx2=roof.StarboardLeaf.PrimaryPart.Position.X-starboard
				if math.abs(dx)>0.25 and math.abs(dx+dx2)<0.15 then moved=true; break end
				task.wait(0.5)
			end
			assert(moved,"Shutters did not travel in opposite directions")
		end
	end
	local ground=workspace:Raycast(Vector3.new(85,0,0),Vector3.new(0,-400,0))
	assert(not ground,"Unexpected floor in the void")
	return "PASS: central spawn, eight traversable bridges and casting decks, animated shutters and open void"
end)
game.ReplicatedStorage.StationReview:FireServer("finish",if ok then result else "FAIL: "..tostring(result))
]=]
driver.Parent=game.StarterPlayer.StarterPlayerScripts
task.wait(3)
local result=game:GetService("StudioTestService"):ExecutePlayModeAsync("StationSurvey")
print(result)
assert(type(result)=="string" and result:sub(1,4)=="PASS",tostring(result))
