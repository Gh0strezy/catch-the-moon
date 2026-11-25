local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Catalog = require(game.ReplicatedStorage:WaitForChild("MoonCatalog"))
local PlanetModel = require(game.ReplicatedStorage:WaitForChild("PlanetModel"))
local Lasso = require(script.Parent:WaitForChild("Lasso"))
local MoonScene = {}
MoonScene.__index = MoonScene

local center = Vector3.new(0, 16, 0)
local radius = 4.8

local function makePlanet(planet, name)
	local model = PlanetModel.new(planet.appearance, radius)
	model.Name = name
	local surface = model.PrimaryPart
	local glow = Instance.new("PointLight")
	glow.Color, glow.Brightness, glow.Range, glow.Parent = surface.Color, 2, 32, surface
	return model
end

function MoonScene.new()
	local idle = makePlanet(Catalog.Planets[1], "PersonalPlanet")
	local camera = workspace.CurrentCamera
	local direction = if camera then camera.CFrame.Position - center else Vector3.zAxis
	local yaw = math.atan2(direction.X, direction.Z)
	local self = setmetatable({active = {}, idle = idle, elapsed = 0, time = 0}, MoonScene)
	RunService:BindToRenderStep("LunarObservatoryView", Enum.RenderPriority.Camera.Value+1, function(dt)
		self.elapsed += dt
		if not self.active[Players.LocalPlayer] and self.elapsed < 1/30 then return end
		dt, self.elapsed = self.elapsed, 0
		self.time += dt
		local now = workspace:GetServerTimeNow()
		for owner, lasso in pairs(self.active) do
			if not lasso:step(now) then self:remove(owner) end
		end
		if next(self.active) == nil then
			idle:PivotTo(CFrame.new(center + Vector3.yAxis*math.sin(self.time*1.3)*0.21)
				* CFrame.Angles(0, yaw+self.time*0.065, 0))
			if not idle.Parent then idle.Parent = workspace end
		end
	end)
	Players.PlayerRemoving:Connect(function(owner) self:remove(owner) end)
	return self
end

function MoonScene:remove(owner)
	local lasso = self.active[owner]
	if lasso then
		lasso:destroy()
		self.active[owner] = nil
	end
end

function MoonScene:progress(owner, packet)
	if not owner then return end
	local lasso = self.active[owner]
	if lasso and lasso.id == packet.id then
		lasso.reelStartedAt = packet.reelStartedAt or lasso.reelStartedAt
		return
	end
	self:remove(owner)
	self.idle.Parent = nil
	local planet = makePlanet(Catalog.Planets[packet.index], "LassoPlanet")
	planet:SetAttribute("OwnerId", owner.UserId)
	self.active[owner] = Lasso.new(owner, packet, planet)
end

function MoonScene:finish(owner, id, reelStartedAt)
	local lasso = self.active[owner]
	if lasso and lasso.id == id then lasso:finish(reelStartedAt) end
end

return MoonScene
