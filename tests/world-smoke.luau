-- Run with Studio CLI RunScript on a temporary local copy of the rebuilt place.
local world=workspace.World
local function floorHeight(x,z)
	local corner=Vector3.new(math.floor(x/4)*4,-64,math.floor(z/4)*4)
	local _,occupancy=workspace.Terrain:ReadVoxels(Region3.new(corner,corner+Vector3.new(4,144,4)),4)
	for j=#occupancy[1],1,-1 do
		local fill=occupancy[1][j][1]
		if fill>0 then return corner.Y+(j-1+fill)*4 end
	end
end
local parcels, sockets, partCount, lights={},0,0,0
for _,object in ipairs(world:GetDescendants()) do
	if object:IsA("BasePart") then
		assert(object.Anchored and not object.CanTouch,object:GetFullName())
		partCount+=1
	elseif object:IsA("Light") then lights+=1 end
	local id=object:GetAttribute("ZoneId")
	if id then
		assert(not parcels[id] and object.Name:sub(1,#id)==id,id)
		parcels[id]=object
		local center=object:GetAttribute("ZoneCenter")
		local size=object:GetAttribute("ZoneSize")
		assert(size.X>0 and size.Y>0 and object:GetAttribute("ZoneDescription")~="",id)
		for _,factor in ipairs({Vector2.zero,Vector2.new(-0.36,-0.36),Vector2.new(0.36,0.36)}) do
			local p=center+Vector3.new(size.X*factor.X,60,size.Y*factor.Y)
			local ground=floorHeight(p.X,p.Z)
			assert(ground and math.abs(ground-center.Y)<2.2,id.." terrain")
		end
		if object:GetAttribute("ZoneStatus")=="Dormant" then
			assert(object:FindFirstChild("TransportSocket",true),id.." dock")
			sockets+=1
		end
	end
end
for i=1,8 do assert(parcels[string.format("SPACE-%02d",i)]) end
assert(sockets==4)
-- Check continuous native terrain and grade from each pavilion to all six outer parcels.
local routes={
	{{-61,0},{-96,-33},{-113,-80},{-148,-146}},{{61,0},{95,-27},{106,-80},{154,-142}},
	{{-113,-80},{-75,-107},{-46,-143},{0,-150},{44,-141},{78,-111},{106,-80}},
	{{-96,-33},{-149,-15},{-205,5},{-257,4}},{{95,-27},{154,-13},{202,4},{257,2}},
	{{-61,0},{-79,52},{-116,87},{-144,124}},{{61,0},{84,57},{122,95},{145,126}},
}
for _,route in ipairs(routes) do
	for i=2,#route do
		local a,b=route[i-1],route[i]
		local length=Vector2.new(a[1]-b[1],a[2]-b[2]).Magnitude
		local previous
		local steps=math.ceil(length/3)
		for j=0,steps do
			local t=j/steps
			local probe=Vector3.new(a[1]+(b[1]-a[1])*t,50,a[2]+(b[2]-a[2])*t)
			local ground=floorHeight(probe.X,probe.Z)
			assert(ground,"Gap in surface at "..tostring(probe))
			assert(not previous or math.abs(previous-ground)<1.8,"Steep grade at "..tostring(probe))
			previous=ground
		end
	end
end
print(string.format("Survey passed: 8 parcels, 4 sockets, 7 trails, %d anchored environment parts, %d local lights",partCount,lights))
local event=Instance.new("RemoteEvent")
event.Name,event.Parent="WorldSmokeResult",game.ReplicatedStorage
local observer=Instance.new("Script")
observer.Source=[=[
local test=game:GetService("StudioTestService")
game.ReplicatedStorage.WorldSmokeResult.OnServerEvent:Connect(function(_,result) test:EndTest(result) end)
task.delay(75,function() test:EndTest("FAIL: walk timeout") end)
]=]
observer.Parent=game.ServerScriptService
local driver=Instance.new("LocalScript")
driver.Source=[=[
local ok,result=pcall(function()
	local player=game.Players.LocalPlayer
	local char=player.Character or player.CharacterAdded:Wait()
	local root=char:WaitForChild("HumanoidRootPart")
	local human=char:WaitForChild("Humanoid")
	local panel=player:WaitForChild("PlayerGui"):WaitForChild("MoonStation",20):WaitForChild("Capture")
	task.wait(1)
	assert((root.Position-workspace.Observatory.TelescopeDeck.Arrival.Position).Magnitude<10,"roof arrival")
	local function walk(x,y,z)
		human:MoveTo(Vector3.new(x,y,z))
		assert(human.MoveToFinished:Wait(),"Blocked at "..tostring(root.Position).." on way to "..x..","..z)
	end
	walk(0,4,-2)
	local q=workspace.Observatory.Stations.Catch:FindFirstChildWhichIsA("ProximityPrompt",true)
	q:InputHoldBegin()
	task.wait(0.12)
	q:InputHoldEnd()
	task.wait(0.8)
	assert(panel.Visible and panel.Target.Text~="","telescope response")
	walk(12,3,1)
	walk(31,3,0)
	walk(51,-2,0)
	walk(60,-1,3)
	walk(60,-1,23)
	local only=RaycastParams.new()
	only.FilterType=Enum.RaycastFilterType.Include
	only.FilterDescendantsInstances={workspace.Terrain}
	assert(workspace:Raycast(root.Position,Vector3.new(0,-9,0),only),"terrain footing after east ramp")
	walk(60,-1,3)
	walk(51,-2,0)
	walk(31,3,0)
	walk(0,4,7)
	walk(-31,3,0)
	walk(-51,-2,0)
	walk(-58,-1,4)
	assert(human.Health>0)
	return "PASS: spawn, telescope prompt, both hub ramps and pavilion entrances"
end)
game.ReplicatedStorage.WorldSmokeResult:FireServer(if ok then result else "FAIL: "..tostring(result))
]=]
driver.Parent=game.StarterPlayer.StarterPlayerScripts
-- Allow the CLI place-idle transition to finish before starting a second DataModel.
task.wait(2)
local outcome=game:GetService("StudioTestService"):ExecutePlayModeAsync("WorldSurvey")
print(outcome)
assert(type(outcome)=="string" and outcome:sub(1,4)=="PASS",tostring(outcome))
