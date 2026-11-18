local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Actions=game:GetService("ContextActionService")
local Prompts=game:GetService("ProximityPromptService")
local Input=game:GetService("UserInputService")
local storage=game:GetService("ReplicatedStorage")
local Catalog=require(storage:WaitForChild("MoonCatalog"))
local player=Players.LocalPlayer
local ui=require(script:WaitForChild("Interface")).new(player:WaitForChild("PlayerGui"))
local scene=require(script:WaitForChild("MoonScene")).new()
local event=storage:WaitForChild("MoonStationEvent")
local encounter, sentStep, sentAt=nil,nil,0
local revealId=0

Prompts.PromptShown:Connect(function(prompt)
	local owner=prompt:GetAttribute("OwnerId")
	if owner and owner~=player.UserId then prompt.Enabled=false end
end)
Prompts.PromptTriggered:Connect(function(prompt,who)
	local key=prompt:GetAttribute("MoonStation")
	if (who and who~=player) or not key or not ui.data or ui.overlay.Visible then return end
	local owner=prompt:GetAttribute("OwnerId")
	if owner and owner~=player.UserId then return end
	event:FireServer("use",key,prompt:GetAttribute("Slot"))
end)

local function hit()
	if not encounter or ui.overlay.Visible or not ui.data then return end
	local now=workspace:GetServerTimeNow()
	if now<encounter.start or (sentStep==encounter.step and now-sentAt<0.8) then return end
	sentStep,sentAt=encounter.step,now
	event:FireServer("strike",encounter.id,encounter.step,now)
end
ui.hit.Activated:Connect(hit)
ui.cancel.Activated:Connect(function() event:FireServer("cancel") end)
ui.bag.Activated:Connect(function() if ui.data and not encounter then ui:menu("Bag") end end)
ui.close.Activated:Connect(function() ui:menu(nil) end)
ui.confirm.Activated:Connect(function()
	if not ui.canConfirm then return end
	if ui.mode=="Display" then event:FireServer("place",ui.slot,"")
	elseif ui.mode=="Luck" or ui.mode=="Speed" then event:FireServer("buy",ui.mode) end
end)
for i,row in ipairs(ui.rows) do
	row.button.Activated:Connect(function()
		local id=Catalog.Moons[i].id
		if ui.mode=="Display" and Catalog.inBag(ui.data,id)>0 then event:FireServer("place",ui.slot,id) end
	end)
end
Actions:BindActionAtPriority("AlignOrbit",function(_,state)
	if not encounter or ui.overlay.Visible or Input:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
	if state==Enum.UserInputState.Begin then hit() end
	return Enum.ContextActionResult.Sink
end,false,Enum.ContextActionPriority.High.Value,Enum.KeyCode.Space,Enum.KeyCode.ButtonR2)

RunService.RenderStepped:Connect(function()
	if encounter then
		local elapsed=math.max(0,workspace:GetServerTimeNow()-encounter.start)
		ui.marker.Position=UDim2.fromScale((elapsed/encounter.period)%1,0.5)
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

event.OnClientEvent:Connect(function(kind,a,b)
	if kind=="profile" then
		local first=ui.data==nil
		ui.data=a
		ui:refresh()
		if first then ui:notice("Подойди к телескопу в центре обсерватории") end
	elseif kind=="hunt" then
		local new=not encounter or encounter.id~=a.id
		if new then
			revealId+=1
			ui:menu(nil)
			scene:show(Catalog.Moons[a.index],a.index)
			sentStep=nil
		end
		encounter=a
		ui.bag.Visible=false
		ui:hunt(a)
		scene:progress(a)
	elseif kind=="finish" then
		encounter=nil
		ui.bag.Visible=true
		ui:hunt(nil)
		scene:progress(nil)
		ui:notice(a)
		revealId+=1
		local id=revealId
		task.delay(if b then 2.5 else 0,function() if revealId==id then scene:show() end end)
	elseif kind=="menu" then ui:menu(a,b)
	elseif kind=="notice" then ui:notice(a) end
end)
event:FireServer("sync")
