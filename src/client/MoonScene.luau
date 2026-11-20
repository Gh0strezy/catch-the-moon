local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Catalog = require(game.ReplicatedStorage:WaitForChild("MoonCatalog"))
local Lasso = require(script.Parent:WaitForChild("Lasso"))
local MoonScene = {}
MoonScene.__index = MoonScene

local center = Vector3.new(0, 16, 0)
local radius = 4.8
local function part(model, name, shape, size, frame, color, material)
	local p = Instance.new("Part")
	p.Name, p.Shape, p.Size, p.CFrame = name, shape, size, frame
	p.Anchored, p.CanCollide, p.CanTouch, p.CastShadow = true, false, false, false
	p.CanQuery = name == "LunarSurface"
	p.Material, p.Color, p.Parent = material or Enum.Material.SmoothPlastic, color, model
	return p
end

local function orbit(model, width, depth, tilt, color, thickness, segments)
	local last
	for i = 0, segments do
		local a = 2 * math.pi * i / segments
		local v = tilt:PointToWorldSpace(Vector3.new(math.cos(a)*width, 0, math.sin(a)*depth))
		if last then
			local p = part(model, "Orbit", Enum.PartType.Block, Vector3.new(thickness, thickness, (v-last).Magnitude+0.02),
				CFrame.lookAt((v+last)/2, v), color, Enum.Material.Neon)
			p.Transparency = 0.25
		end
		last = v
	end
end

local function makeMoon(moon, index, compact)
	local model = Instance.new("Model")
	model.Name = if moon then "LassoMoon" else "PersonalMoon"
	local tint = Color3.fromHex(if moon then moon.color else "D7E2F3")
	local shade = Color3.fromHex(if moon then moon.dark else "879ABC")
	local ball = part(model, "LunarSurface", Enum.PartType.Ball, Vector3.one*radius*2, CFrame.identity, tint)
	model.PrimaryPart = ball
	local rng = Random.new(116)
	local craterCount = if compact then 9 else 37
	for i=1,craterCount do
		local y = 1 - (i-0.5)*2/craterCount
		local a = i*2.39996
		local n = Vector3.new(math.sqrt(1-y*y)*math.cos(a), y, math.sqrt(1-y*y)*math.sin(a))
		local tangent = n:Cross(Vector3.yAxis).Unit
		local size = rng:NextNumber(0.48,1.52)
		local surface = CFrame.fromMatrix(n*(radius-0.025), n, tangent)
		part(model,"Crater rim",Enum.PartType.Cylinder,Vector3.new(0.07,size,size*0.91),surface,tint:Lerp(shade,0.26))
		part(model,"Crater floor",Enum.PartType.Cylinder,Vector3.new(0.08,size*0.75,size*0.70),
			surface*CFrame.new(0.028,size*0.03,0),tint:Lerp(shade,0.55))
	end
	local tilt = CFrame.Angles(math.rad(-12),0,math.rad(-19))
	local segments = if compact then 20 else 48
	orbit(model,7.2,6.3,tilt,Color3.fromHex("DEB67D"),0.052,segments)
	if index and index >= 3 then
		orbit(model,7.6,7,tilt,tint,0.11,segments)
	end
	if index and index >= 4 then
		part(model,"Satellite",Enum.PartType.Ball,Vector3.one*1.15,tilt*CFrame.new(-7,0,1),shade,Enum.Material.Neon)
	end
	if index == 5 then
		orbit(model,7.5,6.8,CFrame.Angles(0,0,1.12),tint,0.09,segments)
	end
	local glow = Instance.new("PointLight")
	glow.Color, glow.Brightness, glow.Range, glow.Parent = tint, 2, 32, ball
	return model
end

function MoonScene.new()
	local self = setmetatable({active = {}, idle = makeMoon(), elapsed = 0, time = 0}, MoonScene)
	RunService:BindToRenderStep("LunarObservatoryView", Enum.RenderPriority.Camera.Value+1, function(dt)
		self.elapsed += dt
		if self.elapsed < 1/30 then return end
		dt, self.elapsed = self.elapsed, 0
		self.time += dt
		local now = workspace:GetServerTimeNow()
		for owner,lasso in pairs(self.active) do
			if not lasso:step(now,dt) then self:remove(owner) end
		end
		if next(self.active) == nil then
			self.idle:PivotTo(CFrame.new(center + Vector3.yAxis*math.sin(self.time*1.3)*0.21)
				* CFrame.Angles(0,self.time*0.065,0))
			if not self.idle.Parent then self.idle.Parent = workspace end
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
		lasso:setHits(packet)
		return
	end
	self:remove(owner)
	self.idle.Parent = nil
	local moon = makeMoon(Catalog.Moons[packet.index], packet.index, owner~=Players.LocalPlayer)
	moon:SetAttribute("OwnerId", owner.UserId)
	self.active[owner] = Lasso.new(owner, packet, moon)
end

function MoonScene:finish(owner, id, caught, escaped)
	local lasso = self.active[owner]
	if lasso and lasso.id == id then lasso:finish(caught,escaped) end
end

return MoonScene
