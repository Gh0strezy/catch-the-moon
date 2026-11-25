-- Use Studio CLI RunScript on an unsaved copy. Only the test can move its player between landmarks.
local service=game:GetService("StudioTestService")
local catalog = require(game.ReplicatedStorage.MoonCatalog)
local models = require(game.ReplicatedStorage.PlanetModel)
local signatures = {
	mercury="CraterFloor", mars="PolarCap", venus="Band", earth="Antarctica",
	uranus="Ring", jupiter="Marking", saturn="Ring", neptune="Marking",
}
for _, planet in ipairs(catalog.Planets) do
	for _, radius in ipairs({1.35,4.8}) do
		local model = models.new(planet.appearance,radius)
		assert(model:FindFirstChild(signatures[planet.id]),planet.id)
		assert(math.abs(model.PrimaryPart.Size.X - 2*radius)<0.001)
		model:Destroy()
	end
end
local uiModule = game.StarterPlayer.StarterPlayerScripts.LunarStation.Interface
local preview = require(uiModule).new(game:GetService("CoreGui"))
preview.data = catalog.newProfile({level=4})
preview:menu("Bag")
local function checkList(width,height)
	preview.overlay.Size=UDim2.fromOffset(width,height)
	task.wait(0.15)
	local list=preview.list
	local odds=catalog.chances(preview.data.level)
	for i,planet in ipairs(catalog.Planets) do
		local row=list[planet.id]
		assert(row.Detail.Text:find(string.format("%.2f%%",odds[i]*100),1,true))
		assert(row.Detail.TextFits and row.AbsoluteSize.Y>=44, "phone row "..planet.id)
	end
	list.CanvasPosition=Vector2.new(0,list.AbsoluteCanvasSize.Y)
	task.wait()
	local last=list.neptune
	assert(list.CanvasPosition.Y>0 and last.AbsolutePosition.Y>=list.AbsolutePosition.Y)
	assert(last.AbsolutePosition.Y+last.AbsoluteSize.Y<=list.AbsolutePosition.Y+list.AbsoluteWindowSize.Y+1)
end
checkList(320,568)
checkList(360,640)
checkList(640,320)
preview.overlay.Parent:Destroy()
print("PASS: all eight models at two scales; phone backpack odds, text and final row at 320x568, 360x640 and 640x320")

game.StarterPlayer.LoadCharacterAppearance = false
local bridge=Instance.new("RemoteEvent")
bridge.Name,bridge.Parent="ExpeditionTest",game.ReplicatedStorage
local server=Instance.new("Script")
server.Source=[=[
local test=game.ReplicatedStorage.ExpeditionTest
test.OnServerEvent:Connect(function(p,action,value)
	if action=="finish" then game:GetService("StudioTestService"):EndTest(value) return end
	local hub=workspace.Observatory
	local spot=if value=="Display" then hub.Gallery["Plot_"..p.UserId].Slot1 else hub.Stations[value]
	local root=p.Character.HumanoidRootPart
	root:SetNetworkOwner(nil)
	p.Character:PivotTo(CFrame.new(spot.Position+Vector3.new(0,4,4)))
	root.AssemblyLinearVelocity=Vector3.zero
	root.AssemblyAngularVelocity=Vector3.zero
	task.wait(0.25)
	root:SetNetworkOwnershipAuto()
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
	local d,hunt,lastCatch,moved,menu,aim
	local function waitFor(label,check)
		local limit=os.clock()+14
		while not check() and os.clock()<limit do task.wait(0.04) end
		assert(check(),label)
	end
	event.OnClientEvent:Connect(function(k,a,b)
		if k=="profile" then d=a elseif k=="hunt" then hunt=a elseif k=="finish" then hunt=nil; lastCatch=b
		elseif k=="menu" then menu=a elseif k=="aim" then aim=a end
	end)
	bridge.OnClientEvent:Connect(function(_,key) moved=key end)
	local function move(key)
		moved=nil
		bridge:FireServer("move",key)
		waitFor("move to "..key,function() return moved==key end)
		task.wait(0.35)
		if key~="Display" then
			local distance=(player.Character.HumanoidRootPart.Position-workspace.Observatory.Stations[key].Position).Magnitude
			assert(distance<=12 and player.Character.Humanoid.Health>0,string.format("arrived at %s (%.1f studs)",key,distance))
		end
	end
	task.wait(1)
	event:FireServer("sync")
	waitFor("profile and character",function() return d and player.Character and player.Character:FindFirstChild("HumanoidRootPart") end)
	assert(ui and workspace.CurrentCamera.CameraType~=Enum.CameraType.Scriptable)
	assert(player.Character.Humanoid.WalkSpeed==16)
	move("Gym")
	event:FireServer("use","Gym")
	waitFor("gym menu",function() return menu=="Gym" and ui.Backdrop.Visible end)
	task.wait(0.2)
	event:FireServer("gymStart")
	waitFor("workout HUD",function() return ui.Workout.Visible and player.Character.Humanoid.Sit end)
	waitFor("strength",function() return d.strength==1 end)
	event:FireServer("gymStop")
	waitFor("stopped workout",function() return not ui.Workout.Visible and not player.Character.Humanoid.Sit end)
	task.wait(1.3)
	assert(d.strength==1 and d.reps==0, "stop prevents additional XP")
	local function cast()
		aim=nil
		event:FireServer("use","Catch")
		waitFor("aim meter",function() return aim and ui.Capture.Cast.Visible end)
		task.wait(math.max(0,aim.start+catalog.AimPeriod/2-workspace:GetServerTimeNow()))
		local now=workspace:GetServerTimeNow()
		local reach=catalog.reach(d.strength)+catalog.aimBonus(catalog.aimPower(now-aim.start))
		event:FireServer("cast",aim.id,now)
		waitFor("encounter",function() return hunt~=nil end)
		assert(hunt.reach==reach and reach>catalog.reach(d.strength))
		waitFor("flight luck",function() return ui.Capture.Hint.Text:find("Удача",1,true) end)
		assert(not ui.Capture.Cast.Visible, "the cast button hides during flight")
	end
	local function catch()
		lastCatch=nil
		cast()
		local planet=catalog.Planets[hunt.index]
		assert(hunt.chance==catalog.chances(d.level,hunt.reach)[hunt.index])
		local count, balance = d.counts[planet.id], d.cash
		local model=assert(workspace:WaitForChild("LassoPlanet",5))
		local loop=assert(workspace:WaitForChild("LassoLoop",5))
		local source=require(game.ReplicatedStorage.PlanetModel).new(planet.appearance,1)
		assert(model:GetAttribute("OwnerId")==player.UserId and model.PrimaryPart.Color==source.PrimaryPart.Color)
		for _,piece in ipairs(source:GetChildren()) do
			assert(model:FindFirstChild(piece.Name),planet.id.." missing "..piece.Name)
		end
		source:Destroy()
		waitFor("lasso lands around the planet",function()
			return (loop.Position-model:GetPivot().Position).Magnitude<0.25 and model.PrimaryPart.Size.X>4
		end)
		local grip=assert(player.Character:FindFirstChild("LassoGrip",true))
		local front=assert(player.Character:FindFirstChild("LassoFrontGrip",true))
		waitFor("lasso passes through both palms",function()
			for _,line in ipairs(loop:GetChildren()) do
				if line:IsA("Beam") and line.Enabled and line.Attachment0==grip and line.Attachment1==front then return true end
			end
			return false
		end)
		waitFor("automatic reel HUD",function() return ui.Capture.Hint.Text:find("Подтягиваем",1,true) end)
		assert(not ui.Capture.Cast.Visible and not ui.Capture.Track.Visible)
		waitFor("miniature reaches the palm",function()
			return model.Parent and model.PrimaryPart.Size.X<1
				and (model:GetPivot().Position-grip.WorldPosition).Magnitude<1
		end)
		waitFor("lasso cleanup",function() return not model.Parent and not grip.Parent and not loop.Parent end)
		assert(workspace.CurrentCamera.CameraType~=Enum.CameraType.Scriptable)
		assert(catalog.Planets[lastCatch]==planet)
		assert(d.counts[planet.id]==count+1 and d.cash==balance+planet.bounty)
		return planet
	end
	move("Catch")
	cast()
	local preCancelBalance=d.cash
	event:FireServer("cancel")
	waitFor("cancelled cast cleans up",function() return not hunt and not workspace:FindFirstChild("LassoLoop") end)
	task.wait(2)
	assert(not lastCatch and d.cash==preCancelBalance)
	local first=catch()
	local input=assert(game:GetService("UserInputService"):CreateVirtualInput(), "virtual input unavailable")
	local function click(button)
		local pos=button.AbsolutePosition+button.AbsoluteSize/2+game:GetService("GuiService"):GetGuiInset()
		input:SendMousePosition(pos)
		input:SendMouseButton(pos,Enum.UserInputType.MouseButton1,true,0)
		task.wait(0.1)
		input:SendMouseButton(pos,Enum.UserInputType.MouseButton1,false,0)
	end
	click(ui.Bag)
	local sheet=ui.Backdrop.Sheet
	waitFor("backpack opened",function() return ui.Backdrop.Visible and sheet.Title.Text=="Рюкзак планет" end)
	assert(sheet.Items[first.id].Quantity.Text=="×1")
	click(sheet.Close)
	waitFor("backpack closed",function() return not ui.Backdrop.Visible end)
	move("Display")
	event:FireServer("use","Display",1)
	waitFor("exhibit menu",function() return menu=="Display" end)
	task.wait(0.22)
	local row=sheet.Items[first.id]
	sheet.Items.CanvasPosition=Vector2.new(0,row.Position.Y.Offset)
	task.wait(0.15)
	click(row)
	waitFor("placed planet",function() return d.slots[1]==first.id end)
	local pad=workspace.Observatory.Gallery["Plot_"..player.UserId].Slot1
	assert(pad:WaitForChild("Exhibit",5):WaitForChild("Surface",5))
	local balance=d.cash
	waitFor("passive dollars",function() return d.cash>balance end)
	event:FireServer("place",1,"")
	waitFor("returned item",function() return d.slots[1]=="" end)
	assert(catalog.inBag(d,first.id)==1)
	move("Catch")
	while d.cash<44 do catch(); task.wait(0.2) end
	move("Luck")
	event:FireServer("buy","Luck")
	waitFor("bought luck",function() return d.level==1 end)
	move("Speed")
	event:FireServer("buy","Speed")
	waitFor("bought speed",function() return d.speed==1 and player.Character.Humanoid.WalkSpeed==18 end)
	return "PASS: gym, charged cast, flight luck, cancellation, automatic hand catch and reward, backpack, showcase and upgrades"
end)
game.ReplicatedStorage.ExpeditionTest:FireServer("finish",if ok then result else "FAIL: "..tostring(result))
]=]
driver.Parent=game.StarterPlayer.StarterPlayerScripts
task.wait(2)
local result=service:ExecuteMultiplayerTestAsync(1,"Observatory")
print(tostring(result))
assert(type(result)=="string" and result:sub(1,4)=="PASS",tostring(result))
