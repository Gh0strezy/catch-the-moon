local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Actions=game:GetService("ContextActionService")
local Prompts=game:GetService("ProximityPromptService")
local Input=game:GetService("UserInputService")
local GuiService=game:GetService("GuiService")
local storage=game:GetService("ReplicatedStorage")
local Catalog=require(storage:WaitForChild("MoonCatalog"))
local player=Players.LocalPlayer
local ui=require(script:WaitForChild("Interface")).new(player:WaitForChild("PlayerGui"))
local scene=require(script:WaitForChild("MoonScene")).new()
local event=storage:WaitForChild("MoonStationEvent")
local encounter
local aim, lastCast, showingFlight=nil,-math.huge,false

Prompts.PromptShown:Connect(function(prompt)
	local owner=prompt:GetAttribute("OwnerId")
	if owner and owner~=player.UserId then prompt.Enabled=false end
end)
Prompts.PromptTriggered:Connect(function(prompt,who)
	local key=prompt:GetAttribute("MoonStation")
	if (who and who~=player) or not key or not ui.data or ui.overlay.Visible or aim or encounter or ui.workout.Visible then return end
	local owner=prompt:GetAttribute("OwnerId")
	if owner and owner~=player.UserId then return end
	event:FireServer("use",key,prompt:GetAttribute("Slot"))
end)

local function cast()
	if not aim then return end
	local now=workspace:GetServerTimeNow()
	if now>=aim.start and now-lastCast>=0.25 then
		lastCast=now
		event:FireServer("cast",aim.id,now)
	end
end
ui.cast.Activated:Connect(cast)
ui.cancel.Activated:Connect(function() event:FireServer("cancel") end)
ui.bag.Activated:Connect(function() if ui.data and not aim and not encounter and not ui.workout.Visible then ui:menu("Bag") end end)
ui.startWorkout.Activated:Connect(function()
	if ui.mode=="Gym" and ui.data.strength<Catalog.StrengthCap then event:FireServer("gymStart") end
end)
ui.stopWorkout.Activated:Connect(function() event:FireServer("gymStop") end)
ui.close.Activated:Connect(function() ui:menu(nil) end)
ui.confirm.Activated:Connect(function()
	if not ui.canConfirm then return end
	if ui.mode=="Display" then event:FireServer("place",ui.slot,"")
	elseif ui.mode=="Luck" or ui.mode=="Speed" then event:FireServer("buy",ui.mode)
	elseif ui.mode=="Gym" then event:FireServer("gymUpgrade") end
end)
for i,row in ipairs(ui.rows) do
	row.button.Activated:Connect(function()
		local id=Catalog.Planets[i].id
		if ui.mode=="Display" and Catalog.inBag(ui.data,id)>0 then event:FireServer("place",ui.slot,id) end
	end)
end
Actions:BindActionAtPriority("CastLasso",function(_,state)
	if not aim or ui.overlay.Visible or Input:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
	if state==Enum.UserInputState.Begin then cast() end
	return Enum.ContextActionResult.Sink
end,false,Enum.ContextActionPriority.High.Value,Enum.KeyCode.Space,Enum.KeyCode.ButtonR2)

RunService.RenderStepped:Connect(function()
	local now=workspace:GetServerTimeNow()
	if aim and ui.data then
		local power=Catalog.aimPower(now-aim.start)
		ui:aim(power,Catalog.reach(ui.data.strength)+Catalog.aimBonus(power))
	elseif encounter then
		local progress=Catalog.flightProgress(now-encounter.castAt,encounter.reach)
		if progress<1 then
			ui:flight(progress,encounter.reach,encounter.luck)
		elseif showingFlight then
			showingFlight=false
			ui:hunt(encounter)
		end
	end
	if ui.overlay.Visible and ui.mode~="Bag" then
		local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local target
		if ui.mode=="Display" then
			local gallery=workspace.Observatory:FindFirstChild("Gallery")
			local plot=gallery and gallery:FindFirstChild("Plot_"..player.UserId)
			target=plot and plot:FindFirstChild("Slot"..ui.slot)
		else target=workspace.Observatory.Stations:FindFirstChild(ui.mode) end
		if not root or not target or (root.Position-target.Position).Magnitude>12 then ui:menu(nil) end
	end
end)

event.OnClientEvent:Connect(function(kind,a,b,c)
	if kind=="profile" then
		local first=ui.data==nil
		ui.data=a
		ui:refresh()
		if first then ui:notice("Поймай планету! Подойди к телескопу в центре.") end
	elseif kind=="aim" then
		aim=a
		if a then ui:menu(nil) else ui:hunt(nil) end
		ui.bag.Visible=not a and not encounter
	elseif kind=="hunt" then
		local new=not encounter or encounter.id~=a.id
		aim=nil
		if new then
			ui:menu(nil)
		end
		encounter=a
		ui.bag.Visible=false
		showingFlight=Catalog.flightProgress(workspace:GetServerTimeNow()-a.castAt,a.reach)<1
		if not showingFlight then ui:hunt(a) end
	elseif kind=="finish" then
		encounter=nil
		showingFlight=false
		ui.bag.Visible=true
		ui:hunt(nil)
		ui:notice(a)
	elseif kind=="lasso" then scene:progress(a,b)
	elseif kind=="lassoEnd" then scene:finish(a,b,c)
	elseif kind=="gym" then
		if a then ui:menu(nil) end
		ui.workout.Visible, ui.bag.Visible = a, not a and not encounter
		if a and Input.PreferredInput==Enum.PreferredInput.Gamepad then
			GuiService.SelectedObject=ui.stopWorkout
		elseif not a and GuiService.SelectedObject==ui.stopWorkout then
			GuiService.SelectedObject=nil
		end
	elseif kind=="menu" then
		ui:menu(a,b)
		if a=="Gym" and Input.PreferredInput==Enum.PreferredInput.Gamepad then GuiService.SelectedObject=ui.startWorkout end
	elseif kind=="notice" then ui:notice(a) end
end)
event:FireServer("sync")
