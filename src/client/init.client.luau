local Players = game:GetService("Players")
local Input = game:GetService("UserInputService")
local Actions = game:GetService("ContextActionService")
local storage = game:GetService("ReplicatedStorage")
local Catalog = require(storage:WaitForChild("MoonCatalog"))
local Interface = require(script:WaitForChild("Interface"))
local MoonScene = require(script:WaitForChild("MoonScene"))

local event = storage:WaitForChild("MoonStationEvent")
local ui = Interface.new(Players.LocalPlayer:WaitForChild("PlayerGui"))
local moon = MoonScene.new()
local round, ready = nil, false
local lastTap = -math.huge

local function tap()
	if not ready or not round or round.paused or ui.overlay.Visible then return end
	local now = os.clock()
	if now-lastTap < 0.095 then return end
	lastTap = now
	moon.pulse = 1
	event:FireServer("tap", round.id)
end
ui.tap.Activated:Connect(tap)
ui.upgrade.Activated:Connect(function()
	if ui.canUpgrade then event:FireServer("upgrade") end
end)
Input.InputBegan:Connect(function(input, handled)
	if not handled and input.UserInputType == Enum.UserInputType.MouseButton1 and moon:hitTest(input.Position) then tap() end
end)
Input.TouchTapInWorld:Connect(function(point, handled)
	if not handled and moon:hitTest(point) then tap() end
end)
Actions:BindActionAtPriority("CatchMoon",function(_,state)
	if Input:GetFocusedTextBox() or ui.overlay.Visible then return Enum.ContextActionResult.Pass end
	if state == Enum.UserInputState.Begin then tap() end
	return Enum.ContextActionResult.Sink
end,false,Enum.ContextActionPriority.High.Value,Enum.KeyCode.Space,Enum.KeyCode.ButtonR2)

event.OnClientEvent:Connect(function(action, data, practice)
	if action == "profile" then
		ui:profile(data, practice)
		ready = true
	elseif action == "round" then
		if round and round.id ~= data.id then moon:show() end
		round = data
		moon:progress(data)
		ui:progress(data)
	elseif action == "catch" then
		local caught = Catalog.Moons[data]
		moon:show(caught, data)
		ui:reveal(caught)
	end
end)
event:FireServer("sync")
