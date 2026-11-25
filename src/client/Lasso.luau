local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local VRService = game:GetService("VRService")
local Impact = require(script.Parent:WaitForChild("LassoImpact"))
local PullPose = require(script.Parent:WaitForChild("PullPose"))
local Lasso = {}
Lasso.__index = Lasso

local Catalog = require(game.ReplicatedStorage:WaitForChild("MoonCatalog"))
local windup = Catalog.CastWindup
local reelTime = Catalog.ReelTime
local catchDuration = 1.9
local gold = Color3.fromHex("FFD78A")
local pearl = Color3.fromHex("FFF2D6")
local ropeColor = ColorSequence.new(gold, pearl)
local cold = Color3.fromHex("69F4FF")

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
		id = packet.id, owner = owner, moon = moon, castAt = packet.castAt, baseScale = moon:GetScale(),
		orientation = CFrame.lookAt(Vector3.zero, facing), reelStartedAt = packet.reelStartedAt,
		loadedAt = os.clock(), nextEcho = 0, reach = packet.reach, castTime = Catalog.castTime(packet.reach),
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
	local outline = Instance.new("Highlight")
	outline.Name, outline.Adornee, outline.DepthMode = "InkOutline",moon,Enum.HighlightDepthMode.Occluded
	outline.FillTransparency, outline.OutlineTransparency = 1,0.14
	outline.OutlineColor, outline.Parent = Color3.fromHex("493D66"),moon
	self.outline = outline
	local left, right = Instance.new("Attachment"), Instance.new("Attachment")
	left.Position, right.Position = Vector3.new(-1.1,0,0), Vector3.new(1.1,0,0)
	left.Parent, right.Parent = surface, surface
	local trail = Instance.new("Trail")
	trail.Name, trail.Attachment0, trail.Attachment1 = "Stardust", left, right
	trail.Lifetime, trail.MinLength, trail.FaceCamera, trail.LightEmission = 0.48, 0.06, true, 1
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
	local comet = Instance.new("Part")
	comet.Name, comet.Material, comet.Color = "LassoComet", Enum.Material.Neon, cold
	comet.Anchored,comet.CanCollide,comet.CanQuery,comet.CanTouch,comet.CastShadow = true,false,false,false,false
	comet.Size,comet.Transparency,comet.Parent = Vector3.new(0.18,0.18,1.4),1,rig
	self.comet = comet
	if owner==Players.LocalPlayer then
		local gui = Instance.new("ScreenGui")
		gui.Name,gui.DisplayOrder,gui.IgnoreGuiInset,gui.ResetOnSpawn = "LassoSpeedLines",2,true,false
		gui.Parent = owner:FindFirstChildOfClass("PlayerGui")
		self.gui = gui
	end
	return self
end

function Lasso:bindHand()
	local char = self.owner.Character
	if not char then return false end
	local hand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
	local root = char:FindFirstChild("HumanoidRootPart")
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not hand or not root or not humanoid then return false end
	self.character, self.root = char, root
	local grip = Instance.new("Attachment")
	local handle = hand:FindFirstChild("RightGripAttachment")
	grip.Position = if handle then handle.Position else Vector3.new(0,-hand.Size.Y*0.45,0)
	grip.Name, grip.Parent = "LassoGrip", hand
	self.grip = grip
	self.rope = beam(self.rig, grip, self.nodes[1], 0.085)
	local function bindLeft()
		local left = char:FindFirstChild("LeftHand") or char:FindFirstChild("Left Arm")
		if self.leftGrip or not left then return end
		local handle = left:FindFirstChild("LeftGripAttachment")
		local contact = Instance.new("Attachment")
		contact.Position = if handle then handle.Position else Vector3.new(0,-left.Size.Y*0.45,0)
		contact.Name,contact.Parent = "LassoFrontGrip",left
		self.leftGrip = contact
		self.between = beam(self.rig,grip,contact,0.085)
		self.between.Enabled = false
	end
	bindLeft()
	self.handAdded = char.ChildAdded:Connect(bindLeft)
	self.pose = PullPose.new(self,humanoid)
	self.rig.Parent = workspace
	return true
end

function Lasso:impact(kind,position)
	Impact.burst(self.rig,kind,position)
	Impact.screen(self.gui,kind)
end

function Lasso:finish(reelStartedAt)
	if self.endedAt then return end
	self.endedAt, self.caught = reelStartedAt or workspace:GetServerTimeNow(), reelStartedAt~=nil
	self.endPosition = self.position
	self.endScale = self.scale or 0.5
	local camera = workspace.CurrentCamera
	if self.caught and self.gui and self.root and camera and camera.CameraType==Enum.CameraType.Custom
		and not GuiService.ReducedMotionEnabled and not VRService.VREnabled then
		self.camera,self.wide,self.focus = camera,camera.CFrame,camera.Focus
		self.cameraOrigin = self.root.Position
		self.cameraFilter = RaycastParams.new()
		self.cameraFilter.FilterDescendantsInstances = {self.character,self.moon,self.rig}
		camera.CameraType = Enum.CameraType.Scriptable
	end
end

function Lasso:updateCloseup(palm,elapsed)
	local camera = self.camera
	if not camera or camera~=workspace.CurrentCamera or camera.CameraType~=Enum.CameraType.Scriptable then return end
	local offset = self.root.Position-self.cameraOrigin
	local wide = self.wide+offset
	local release = ease((elapsed-0.75)/0.5)
	local focus = self.root.Position:Lerp(palm,0.34+0.5*release)+Vector3.yAxis*(0.45-0.34*release)
	local shoulderSide = if (wide.Position-focus):Dot(self.orientation.RightVector)<-1 then -1 else 1
	local lens = self.orientation:VectorToWorldSpace(Vector3.new(shoulderSide*(6.0-2.4*release),1.4, -2.7))
	local wall = workspace:Raycast(focus,lens,self.cameraFilter)
	if wall then lens = lens.Unit*math.max(0.1,wall.Distance-0.2) end
	local close = CFrame.lookAt(focus+lens,focus)
	local weight = ease(elapsed/0.32)*(1-ease((elapsed-1.46)/0.4))
	-- Orbit round the subject instead of cutting through the body on a reverse angle.
	local wideLens=wide.Position-focus
	local blendDir=wideLens:Lerp(lens,weight)
	if blendDir.Magnitude>0.05 and wideLens.Magnitude>0.1 then
		local position=focus+blendDir.Unit*(wideLens.Magnitude+(lens.Magnitude-wideLens.Magnitude)*weight)
		local occluder=workspace:Raycast(focus,position-focus,self.cameraFilter)
		if occluder then position=focus+blendDir.Unit*math.max(0.1,occluder.Distance-0.2) end
		close=CFrame.new(position)*wide.Rotation:Lerp(close.Rotation,weight)
	else close=wide:Lerp(close,weight) end
	camera.CFrame = close
	camera.Focus = (self.focus+offset):Lerp(CFrame.new(focus),weight)
end

function Lasso:step(now)
	if not self.grip and not self:bindHand() then
		return not self.endedAt and os.clock()-self.loadedAt < 8
	end
	if self.owner.Character ~= self.character or not self.grip.Parent or not self.root.Parent then return false end
	if self.reelStartedAt and not self.endedAt then self:finish(self.reelStartedAt) end
	local age = math.max(0, now-self.castAt)
	local finishAge = if self.endedAt then math.max(0,now-self.endedAt) else 0
	if self.endedAt and finishAge >= (if self.caught then catchDuration else 0.42) then return false end
	local throw = Catalog.flightProgress(age,self.reach)
	local swing = ease(age/windup)
	local phase = math.max(0,age-windup-self.castTime)*1.65
	local aim = CFrame.new(self.root.Position)*self.orientation
	local offset = Vector3.new(math.sin(phase)*4.8, 5.8+math.sin(phase)*0.95, -self.reach+(1-math.cos(phase))*1.25)
	local position = aim:PointToWorldSpace(offset)
	local scale = 0.50
	local palm = self.grip.WorldPosition
	if self.camera then self:updateCloseup(palm,finishAge) end
	local reel = if self.endedAt and self.caught then ease((finishAge-0.34)/(reelTime-0.34)) else 0
	if self.endedAt then
		local start = self.endPosition or position
		if self.caught then
			local resistance=math.sin(math.pi*ease(finishAge/0.43))*0.58
			position = start:Lerp(palm+Vector3.yAxis*0.38, reel) + Vector3.yAxis*math.sin(math.pi*reel)*1.7
				+ aim.LookVector*resistance
			scale = self.endScale+(0.095-self.endScale)*reel
		else
			position = start + aim:VectorToWorldSpace(Vector3.new(1,5,-7))*ease(finishAge/0.42)
			scale = self.endScale*(1-0.92*ease(finishAge/0.42))
		end
	end
	self.position = position
	if not self.scale or math.abs(self.scale-scale)>0.002 then
		self.moon:ScaleTo(self.baseScale * scale)
		self.scale = scale
	end
	self.moon:PivotTo(CFrame.new(position)*CFrame.Angles(0,age*0.55,0.12*math.sin(phase)))
	if throw>=1 and not self.moon.Parent and (not self.endedAt or self.caught) then
		self.moon.Parent = workspace
		if not self.endedAt then
			self:impact("hit",position)
			self.sparks:Emit(12)
		end
	end

	local launch = palm + aim:VectorToWorldSpace(Vector3.new(0.15,0.8,-0.24))
	if not self.castShown and age>=windup then
		self.castShown=true
		if age<windup+self.castTime and not self.endedAt then self:impact("cast",launch) end
	end
	local loop = launch:Lerp(position,throw) + Vector3.yAxis*(math.sin(math.pi*throw)*2.5)
	local radius = (0.22+0.8*swing)*(1-throw) + scale*5.05*throw
	self.rig.CFrame = CFrame.new(loop)*self.orientation*CFrame.Angles(-0.32, (1-throw)*swing*math.pi*2, 0.35)
	local visible = not self.endedAt or (self.caught and reel<0.96)
	local accent = if self.caught then gold else cold
	local intensity = if self.caught then 1-reel else 0
	self.outline.OutlineColor = Color3.fromHex("493D66"):Lerp(accent,intensity)
	self.outline.FillColor, self.outline.FillTransparency = accent,1-0.42*intensity
	for i,node in ipairs(self.nodes) do
		local angle = (i-1)*math.pi/2
		node.Position = Vector3.new(math.sin(angle)*radius, 0, math.cos(angle)*radius)
		node.Axis = Vector3.new(math.cos(angle), 0, -math.sin(angle))
		local arc = self.arcs[i]
		arc.Width0 = 0.105+intensity*0.13
		arc.CurveSize0, arc.CurveSize1 = radius*0.552285, radius*0.552285
		arc.Enabled = visible
	end
	local twoHands = self.leftGrip and self.leftGrip.Parent and age>=windup+self.castTime-0.03 and reel<0.77
	self.rope.Attachment0 = if twoHands then self.leftGrip else self.grip
	if self.between then
		self.between.Enabled = visible and twoHands==true
	end
	self.rope.CurveSize0 = (1-throw)*1.7 + 0.12
	self.rope.CurveSize1 = -self.rope.CurveSize0
	self.rope.Width0, self.rope.Enabled = 0.085+intensity*0.065, visible
	if throw>0 and throw<1 and visible and (position-palm).Magnitude>0.1 then
		self.comet.CFrame = CFrame.lookAlong(loop,(position-palm).Unit)*CFrame.Angles(0,0,math.pi/4)
		self.comet.Color,self.comet.Transparency = accent,0.04
	else
		self.comet.Transparency = 1
	end
	if now>=self.nextEcho and reel>0.08 and reel<0.91 then
		self.nextEcho=now+0.075
		Impact.echo(self.rig,position,scale*9.6,accent)
	end
	if self.caught and reel>=0.96 and not self.flared then
		self.flared = true
		self:impact("catch",position)
		self.sparks:Emit(22)
	end
	return true
end

function Lasso:destroy()
	if self.camera and self.camera==workspace.CurrentCamera and self.camera.CameraType==Enum.CameraType.Scriptable then
		local shift = if self.root.Parent then self.root.Position-self.cameraOrigin else Vector3.zero
		self.camera.CFrame,self.camera.Focus = self.wide+shift,self.focus+shift
		self.camera.CameraType = Enum.CameraType.Custom
	end
	if self.handAdded then self.handAdded:Disconnect() end
	if self.pose then self.pose:destroy() end
	if self.leftGrip then self.leftGrip:Destroy() end
	if self.gui then self.gui:Destroy() end
	if self.grip then self.grip:Destroy() end
	self.rig:Destroy()
	self.moon:Destroy()
end

return Lasso
