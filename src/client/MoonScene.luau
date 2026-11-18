local RunService = game:GetService("RunService")
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

local function orbit(model, width, depth, tilt, color, thickness)
	local last
	for i = 0, 48 do
		local a = 2 * math.pi * i / 48
		local v = tilt:PointToWorldSpace(Vector3.new(math.cos(a)*width, 0, math.sin(a)*depth))
		if last then
			local p = part(model, "Orbit", Enum.PartType.Block, Vector3.new(thickness, thickness, (v-last).Magnitude+0.02),
				CFrame.lookAt((v+last)/2, v), color, Enum.Material.Neon)
			p.Transparency = 0.25
		end
		last = v
	end
end

function MoonScene.new()
	local self = setmetatable({pulse = 0, time = 0, elapsed = 0, anchors = {}, beams = {}}, MoonScene)
	for _,x in ipairs({-6,6}) do
		local peg = part(workspace,"TetherOrigin",Enum.PartType.Block,Vector3.one*0.1,
			CFrame.new(x,4.02,6.5),Color3.new(1,1,1))
		peg.Transparency = 1
		local hook = Instance.new("Attachment")
		hook.Parent = peg
		table.insert(self.anchors,hook)
	end
	self:show()
	RunService:BindToRenderStep("LunarObservatoryView", Enum.RenderPriority.Camera.Value+1, function(dt)
		local cam = workspace.CurrentCamera
		if not cam then return end
		cam.CameraType = Enum.CameraType.Scriptable
		cam.FieldOfView = 48
		cam.CFrame = CFrame.lookAt(Vector3.new(0, 13.5, 36), Vector3.new(0, 12.8, 0))
		cam.Focus = CFrame.new(center)
		self.time += dt
		self.elapsed += dt
		self.pulse = math.max(0, self.pulse-dt*3.5)
		if self.elapsed < 1/30 then return end
		self.elapsed = 0
		self.model:PivotTo(CFrame.new(center + Vector3.new(0, math.sin(self.time*1.3)*0.21+self.pulse*0.26,0))
			* CFrame.Angles(0, self.time*0.065, self.pulse*0.029))
	end)
	return self
end

function MoonScene:progress(packet)
	for i, beam in ipairs(self.beams) do
		beam.Enabled = packet.hits > 0 and not packet.paused and (i == 1 or packet.crew > 1)
		beam.CurveSize0 = 3.5 * (1 - packet.hits/packet.goal)
	end
	if packet.hits > 0 then self.pulse = 1 end
end

function MoonScene:show(moon, index)
	if self.model then self.model:Destroy() end
	local model = Instance.new("Model")
	model.Name = "PersonalMoon"
	local tint = Color3.fromHex(if moon then moon.color else "D7E2F3")
	local shade = Color3.fromHex(if moon then moon.dark else "879ABC")
	local ball = part(model, "LunarSurface", Enum.PartType.Ball, Vector3.one*radius*2, CFrame.identity, tint)
	model.PrimaryPart = ball
	table.clear(self.beams)
	for i, hook in ipairs(self.anchors) do
		local endpoint = Instance.new("Attachment")
		endpoint.Position = Vector3.new(if i==1 then -1.9 else 1.9,-3.9,1.8)
		endpoint.Parent = ball
		local beam = Instance.new("Beam")
		beam.Attachment0,beam.Attachment1 = hook,endpoint
		beam.Color = ColorSequence.new(Color3.fromHex("FFCB80"),Color3.fromHex("D9F6FF"))
		beam.Width0,beam.Width1,beam.FaceCamera,beam.LightEmission = 0.13,0.07,true,0.9
		beam.Enabled,beam.Parent = false,ball
		table.insert(self.beams,beam)
	end
	if moon then
		local sparks = Instance.new("ParticleEmitter")
		sparks.Rate, sparks.Lifetime, sparks.Speed = 0,NumberRange.new(0.6,1.15),NumberRange.new(6,13)
		sparks.SpreadAngle = Vector2.new(180,180)
		sparks.Color, sparks.LightEmission = ColorSequence.new(tint),1
		sparks.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0.35),NumberSequenceKeypoint.new(1,0)})
		sparks.Parent = ball
		task.defer(function() if sparks:IsDescendantOf(workspace) then sparks:Emit(28) end end)
	end
	local rng = Random.new(116)
	for i=1,37 do
		local y = 1 - (i-0.5)*2/37
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
	orbit(model,7.2,6.3,tilt,Color3.fromHex("DEB67D"),0.052)
	if index and index >= 3 then
		orbit(model,7.6,7,tilt,tint,0.11)
	end
	if index and index >= 4 then
		part(model,"Satellite",Enum.PartType.Ball,Vector3.one*1.15,tilt*CFrame.new(-7,0,1),shade,Enum.Material.Neon)
	end
	if index == 5 then
		orbit(model,7.5,6.8,CFrame.Angles(0,0,1.12),tint,0.09)
	end
	local glow = Instance.new("PointLight")
	glow.Color, glow.Brightness, glow.Range, glow.Parent = tint, 2, 32, ball
	model:PivotTo(CFrame.new(center))
	model.Parent = workspace
	self.model = model
end

function MoonScene:hitTest(point)
	local cam = workspace.CurrentCamera
	if not cam then return false end
	local ray = cam:ViewportPointToRay(point.X, point.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { self.model }
	return workspace:Raycast(ray.Origin, ray.Direction * 150, params) ~= nil
end

return MoonScene
