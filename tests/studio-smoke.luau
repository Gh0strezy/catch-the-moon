-- Run with the Studio CLI on a local place. Test-only instances live in the unsaved session.
local controller = game:GetService("StudioTestService")
local bridge = Instance.new("RemoteEvent")
bridge.Name, bridge.Parent = "MoonSmokeResult",game.ReplicatedStorage
local observer = Instance.new("Script")
observer.Source = [=[
local testing = game:GetService("StudioTestService")
game.ReplicatedStorage.MoonSmokeResult.OnServerEvent:Connect(function(_, message)
	testing:EndTest(message)
end)
task.delay(65,function() testing:EndTest("FAIL: client did not finish") end)
]=]
observer.Parent = game.ServerScriptService
local driver = Instance.new("LocalScript")
driver.Source = [=[
local ok, outcome = pcall(function()
	local storage = game:GetService("ReplicatedStorage")
	local player = game.Players.LocalPlayer
	local ui = assert(player:WaitForChild("PlayerGui"):WaitForChild("MoonStation",15), "HUD missing")
	assert(workspace:WaitForChild("PersonalMoon",10), "3D moon missing")
	local event = storage:WaitForChild("MoonStationEvent")
	local packet, profile, caught = nil,nil,0
	event.OnClientEvent:Connect(function(kind, data)
		if kind == "round" then packet = data
		elseif kind == "profile" then profile = data
		elseif kind == "catch" then caught += 1 end
	end)
	task.wait(1.1)
	event:FireServer("sync")
	local function untilReady(check)
		local start = os.clock()
		repeat task.wait(0.04) until check() or os.clock()-start > 10
		assert(check(), "timed out waiting for server state")
	end
	untilReady(function() return packet and profile end)
	for n=1,3 do
		untilReady(function() return not packet.paused end)
		local id = packet.id
		for _=1,packet.goal+3 do
			if packet.paused then break end
			event:FireServer("tap",id)
			task.wait(0.14)
		end
		untilReady(function() return caught == n end)
	end
	local count = 0
	for _,value in pairs(profile.counts) do count += value end
	assert(count == 3 and profile.dust >= 24, "bad rewards")
	local initial = profile.dust
	event:FireServer("upgrade")
	untilReady(function() return profile.level == 1 end)
	assert(profile.dust == initial-24)
	assert(ui.Status.Resources.Text:find("1.25",1,true), "luck HUD did not refresh")
	return "PASS: Studio client/server, three catches and a luck upgrade"
end)
game.ReplicatedStorage.MoonSmokeResult:FireServer(if ok then outcome else "FAIL: "..tostring(outcome))
]=]
driver.Parent = game.StarterPlayer.StarterPlayerScripts
task.wait(2)
local result = controller:ExecutePlayModeAsync("MoonSmoke")
print(tostring(result))
assert(type(result) == "string" and result:sub(1,4)=="PASS", tostring(result))
