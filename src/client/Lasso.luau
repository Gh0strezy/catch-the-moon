local Lasso = {}
Lasso.__index = Lasso

local windup = 0.26
local castTime = 0.46
local reelTime = 0.62
local gold = Color3.fromHex("FFD78A")
local pearl = Color3.fromHex("FFF2D6")
local ropeColor = ColorSequence.new(gold, pearl)

local function ease(t)
	t = math.clamp(t, 0, 1)
	return t*t*(3-2*t)
end

local function beam(parent, from, to, width)
	local line = Instance.new("Beam")
	line.Attachment0, line.Attachment1 = from, to
	line.Width0, line.Width1 = width, width
	line.Color, line.LightEmission = ropeColor, 1
	line.FaceCamera, line.Segments = true, 10
	line.Parent = parent
	return line
end

function Lasso.new(owner, packet, moon)
	local flat = Vector3.new(packet.heading.X, 0, packet.heading.Z)
	local facing = if flat.Magnitude > 0.01 then flat.Unit else -Vector3.zAxis
	local self = setmetatable({
		id = packet.id, owner = owner, moon = moon, castAt = packet.castAt,
		orientation = CFrame.lookAt(Vector3.zero, facing), progress = packet.hits/packet.goal,
		target = packet.hits/packet.goal, pulse = 0, loadedAt = os.clock(),
		nodes = {}, arcs = {},
	}, Lasso)

	local rig = Instance.new("Part")
	rig.Name, rig.Size, rig.Transparency = "LassoLoop", Vector3.one*0.1, 1
	rig.Anchored, rig.CanCollide, rig.CanTouch, rig.CanQuery, rig.CastShadow = true, false, false, false
	self.rig = rig
	for i = 1, 4 do
		local node = Instance.new("Attachment")
		node.Parent = rig
		self.nodes[i] = node
	end
	for i, node in ipairs(self.nodes) do
		self.arcs[i] = beam(rig, node, self.nodes[i%4+1], 0.105)
	end

	local surface = moon.PrimaryPart
	local left, right = Instance.new("Attachment"), Instance.new("Attachment")
	left.Position, right.Position = Vector3.new(-1.1,0,0), Vector3.new(1.1,0,0)
	left.Parent, right.Parent = surface, surface
	local trail = Instance.new("Trail")
	trail.Name, trail.Attachment0, trail.Attachment1 = "Stardust", left, right
	trail.Lifetime, trail.MinLength, trail.FaceCamera, trail.LightEmission = 0.38, 0.06, true, 1
	trail.Color = ColorSequence.new(surface.Color, pearl)
	trail.Transparency = NumberSequence.new(0.3, 1)
	trail.WidthScale = NumberSequence.new(1, 0)
	trail.Parent = surface

	local sparks = Instance.new("ParticleEmitter")
	sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparks.Rate, sparks.Lifetime, sparks.Speed = 0, NumberRange.new(0.25,0.48), NumberRange.new(2,5)
	sparks.Color, sparks.LightEmission, sparks.SpreadAngle = ropeColor, 1, Vector2.new(180,180)
	sparks.Size = NumberSequence.new(0.26, 0)
	sparks.Parent = rig
	self.sparks = sparks
	return self
end

function Lasso:bindHand()
	local char = self.owner.Character
	if not char then return false end
	local hand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
	local root = char:FindFirstChild("HumanoidRootPart")
	if not hand or not root then return false end
	self.character, self.root = char, root
	local grip = Instance.new("Attachment")
	local handle = hand:FindFirstChild("RightGripAttachment")
	grip.Position = if handle then handle.Position else Vector3.new(0,-hand.Size.Y*0.45,0)
	grip.Name, grip.Parent = "LassoGrip", hand
	self.grip = grip
	self.rope = beam(self.rig, grip, self.nodes[1], 0.085)
	local shoulder = char:FindFirstChild("RightShoulder", true) or char:FindFirstChild("Right Shoulder", true)
	if shoulder and shoulder:IsA("Motor6D") then
		self.shoulder, self.rest = shoulder, shoulder.C0
	end
	self.rig.Parent = workspace
	return true
end

function Lasso:setHits(packet)
	local fraction = packet.hits / packet.goal
	if fraction > self.target then
		self.target, self.pulse = fraction, 1
		if self.grip then self.sparks:Emit(6) end
	end
end

function Lasso:finish(caught)
	if self.endedAt then return end
	self.endedAt, self.caught = workspace:GetServerTimeNow(), caught
	self.endPosition = self.position
	self.endScale = self.scale or 0.5
end

function Lasso:step(now, dt)
	if not self.grip and not self:bindHand() then
		return not self.endedAt and os.clock()-self.loadedAt < 8
	end
	if self.owner.Character ~= self.character or not self.grip.Parent or not self.root.Parent then return false end
	local age = math.max(0, now-self.castAt)
	local finishAge = if self.endedAt then now-self.endedAt else 0
	if self.endedAt and finishAge >= (if self.caught then reelTime+0.6 else 0.42) then return false end
	self.progress += (self.target-self.progress)*(1-math.exp(-dt*7))
	self.pulse = math.max(0,self.pulse-dt*3.5)

	local throw = ease((age-windup)/castTime)
	local swing = ease(age/windup)
	local pull = self.progress
	local phase = math.max(0,age-windup-castTime)*1.65
	local aim = CFrame.new(self.root.Position)*self.orientation
	local offset = Vector3.new(math.sin(phase)*(4.8-3.8*pull),
		5.8-2.5*pull+math.sin(phase)*0.95, -10+5*pull+(1-math.cos(phase))*1.25)
	local position = aim:PointToWorldSpace(offset)
	local scale = 0.50-0.24*pull
	local palm = self.grip.WorldPosition
	local reel = if self.endedAt and self.caught then ease(finishAge/reelTime) else 0
	if self.endedAt then
		local start = self.endPosition or position
		if self.caught then
			position = start:Lerp(palm+Vector3.yAxis*0.38, reel) + Vector3.yAxis*math.sin(math.pi*reel)*1.7
			scale = self.endScale+(0.095-self.endScale)*reel
		else
			position = start + aim:VectorToWorldSpace(Vector3.new(1,5,-7))*ease(finishAge/0.42)
			scale = self.endScale*(1-0.92*ease(finishAge/0.42))
		end
	end
	self.position = position
	if not self.scale or math.abs(self.scale-scale)>0.002 then
		self.moon:ScaleTo(scale)
		self.scale = scale
	end
	self.moon:PivotTo(CFrame.new(position)*CFrame.Angles(0,age*0.55,0.12*math.sin(phase)))
	if not self.moon.Parent then self.moon.Parent = workspace end

	local launch = palm + aim:VectorToWorldSpace(Vector3.new(0.15,0.8,-0.24))
	local loop = launch:Lerp(position,throw) + Vector3.yAxis*(math.sin(math.pi*throw)*2.5)
	local radius = (0.22+0.8*swing)*(1-throw) + scale*5.05*throw
	self.rig.CFrame = CFrame.new(loop)*self.orientation*CFrame.Angles(-0.32, (1-throw)*swing*math.pi*2, 0.35)
	local visible = not self.endedAt or (self.caught and reel<0.96)
	for i,node in ipairs(self.nodes) do
		local angle = (i-1)*math.pi/2
		node.Position = Vector3.new(math.sin(angle)*radius, 0, math.cos(angle)*radius)
		node.Axis = Vector3.new(math.cos(angle), 0, -math.sin(angle))
		local arc = self.arcs[i]
		arc.CurveSize0, arc.CurveSize1 = radius*0.552285, radius*0.552285
		arc.Enabled = visible
	end
	self.rope.CurveSize0 = (1-throw)*1.7 + (1-pull)*0.45
	self.rope.CurveSize1 = -self.rope.CurveSize0
	self.rope.Width0, self.rope.Enabled = 0.085+self.pulse*0.065, visible
	if self.shoulder and self.shoulder.Parent then
		local lift = 0.55 + swing*1.55 - throw*1.08 + self.pulse*0.24 + reel*0.35
		self.shoulder.C0 = CFrame.new(self.rest.Position)*CFrame.Angles(lift,0,0.18)*self.rest.Rotation
	end
	if self.caught and reel>=0.96 and not self.flared then
		self.flared = true
		self.sparks:Emit(22)
	end
	return true
end

function Lasso:destroy()
	if self.shoulder and self.shoulder.Parent then self.shoulder.C0 = self.rest end
	if self.grip then self.grip:Destroy() end
	self.rig:Destroy()
	self.moon:Destroy()
end

return Lasso
