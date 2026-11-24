local RunService = game:GetService("RunService")

local PullPose = {}
PullPose.__index = PullPose

local function smooth(x)
	x = math.clamp(x,0,1)
	return x*x*(3-2*x)
end

-- The hands reach first. The hips take the load, then the elbows travel past the ribs.
-- Columns: seconds, draw towards hip, knee compression, shoulder turn, forward-hand travel.
local haul = {
	{0,    0.02, 0.42,  0.06, 0.00},
	{0.16,-0.82, 0.80, -0.30, 0.25},
	{0.32,-0.73, 1.00, -0.22, 0.28},
	{0.49, 0.72, 0.73,  0.76, 0.03},
	{0.61, 1.00, 0.52,  1.00, 0.00},
	{0.76, 0.89, 0.60,  0.83, 0.04},
	{1.04, 0.12, 0.42,  0.12, 0.08},
}

local function sample(keys,t)
	for i=2,#keys do
		local a,b = keys[i-1],keys[i]
		if t<=b[1] then
			local w=smooth((t-a[1])/(b[1]-a[1]))
			return a[2]+(b[2]-a[2])*w, a[3]+(b[3]-a[3])*w,
				a[4]+(b[4]-a[4])*w, a[5]+(b[5]-a[5])*w
		end
	end
	local last=keys[#keys]
	return last[2],last[3],last[4],last[5]
end

local function unit(v,fallback)
	return if v.Magnitude>0.0001 then v.Unit else fallback
end

-- Swing a bone from its own bind direction. Avatar packages use different joint axes.
local function align(rotation, localBone, direction)
	local from=rotation:VectorToWorldSpace(unit(localBone,-Vector3.yAxis))
	local to=unit(direction,from)
	local axis=from:Cross(to)
	if axis.Magnitude>0.0001 then
		return CFrame.fromAxisAngle(axis.Unit,math.atan2(axis.Magnitude,from:Dot(to)))*rotation
	end
	if from:Dot(to)<0 then
		return CFrame.fromAxisAngle(unit(from:Cross(Vector3.xAxis),Vector3.zAxis),math.pi)*rotation
	end
	return rotation
end

local function isJoint(j)
	return j:IsA("Motor6D") or j:IsA("AnimationConstraint")
end

function PullPose:restore()
	for joint,original in pairs(self.originals) do
		if joint.Parent then joint.Transform=original end
	end
	table.clear(self.originals)
end

function PullPose:bind()
	local joints={}
	for _,joint in self.char:GetDescendants() do
		if isJoint(joint) and joint.Part0 and joint.Part1 and joint.Part0.Parent==self.char and joint.Part1.Parent==self.char then
			joints[joint.Part1.Name]=joint
		end
	end
	self.joints=joints
	self.torso=joints.LowerTorso or joints.Torso
	self.r15=joints.LowerTorso~=nil
	self.rest={[self.root]=CFrame.identity}
	local function restFrame(j)
		local cached=self.rest[j.Part1]
		if cached then return cached end
		local parent=self.rest[j.Part0]
		if not parent then
			local ancestor=joints[j.Part0.Name]
			if not ancestor then return self.root.CFrame:ToObjectSpace(j.Part1.CFrame) end
			parent=restFrame(ancestor)
		end
		local cf=parent*j.C0*j.C1:Inverse()
		self.rest[j.Part1]=cf
		return cf
	end
	for _,j in pairs(joints) do restFrame(j) end
end

-- All desired frames are in root space. Compose through the evaluated parent so IK
-- accounts for the lean already applied to the pelvis and rib cage in this frame.
function PullPose:write(j, desired, weight)
	local parent=self.frames[j.Part0] or self.rest[j.Part0]
	if not parent then return end
	local origin=parent*j.C0
	local base=j.Transform
	self.originals[j]=base
	local result=base:Lerp(origin:ToObjectSpace(desired*j.C1),weight)
	j.Transform=result
	self.frames[j.Part1]=origin*result*j.C1:Inverse()
end

function PullPose:pivot(j,rotation,offset,weight)
	if not j then return end
	local parent=self.frames[j.Part0] or self.rest[j.Part0]
	if not parent then return end
	local socket=parent*j.C0
	local neutral=socket*j.C1:Inverse()
	local rotated=parent.Rotation*rotation*parent.Rotation:Inverse()*neutral.Rotation
	local cf=CFrame.new(socket.Position+offset)*rotated*CFrame.new(-j.C1.Position)
	self:write(j,cf,weight)
end

function PullPose:chain(upper,lower,tip,contact,target,tipRotation,pole,weight)
	if not upper then return end
	local parent=self.frames[upper.Part0] or self.rest[upper.Part0]
	if not parent then return end
	local socket=parent*upper.C0
	local start=socket.Position
	local restRotation=(socket*upper.C1:Inverse()).Rotation
	if not lower or not tip then
		-- An R6 limb is a single rigid segment.
		local rot=align(restRotation,contact-upper.C1.Position,target-start)
		self:write(upper,CFrame.new(start)*rot*CFrame.new(-upper.C1.Position),weight)
		return
	end
	local upperBone=lower.C0.Position-upper.C1.Position
	local lowerBone=tip.C0.Position-lower.C1.Position
	local a,b=upperBone.Magnitude,lowerBone.Magnitude
	if math.min(a,b)<0.01 then return end
	local wrist=target+tipRotation:VectorToWorldSpace(tip.C1.Position-contact)
	local axis=unit(wrist-start,-Vector3.zAxis)
	local length=math.clamp((wrist-start).Magnitude,math.abs(a-b)+0.001,a+b-0.001)
	local along=(a*a-b*b+length*length)/(2*length)
	local outward=pole-start
	local bend=unit(outward-axis*outward:Dot(axis),unit(axis:Cross(Vector3.xAxis),Vector3.zAxis))
	local elbow=start+axis*along+bend*math.sqrt(math.max(0,a*a-along*along))
	local rot=align(restRotation,upperBone,elbow-start)
	self:write(upper,CFrame.new(start)*rot*CFrame.new(-upper.C1.Position),weight)
	local hinge=self.frames[upper.Part1]*lower.C0
	local forearm=align((hinge*lower.C1:Inverse()).Rotation,lowerBone,start+axis*length-hinge.Position)
	self:write(lower,CFrame.new(hinge.Position)*forearm*CFrame.new(-lower.C1.Position),weight)
	local wristFrame=self.frames[lower.Part1]*tip.C0
	self:write(tip,CFrame.new(wristFrame.Position)*tipRotation*CFrame.new(-tip.C1.Position),weight)
end

function PullPose:legs(facing,weight)
	local j=self.joints
	for _,side in {"Left","Right"} do
		local sign=if side=="Left" then -1 else 1
		local hip=j[side.."UpperLeg"] or j[side.." Leg"]
		local knee,ankle=j[side.."LowerLeg"],j[side.."Foot"]
		if not hip then continue end
		local foot=if ankle then ankle.Part1 else hip.Part1
		local sole=Vector3.new(0,-foot.Size.Y*0.5,0)
		local standing=self.rest[foot]:PointToWorldSpace(sole)
		local target=facing:PointToWorldSpace(standing+Vector3.new(sign*0.22,0,sign*0.42)*self.size)
		local kneePole=facing:PointToWorldSpace(Vector3.new(sign*0.85,-1.4,-2)*self.size)
		self:chain(hip,knee,ankle,sole,target,facing*CFrame.Angles(0,-sign*0.13,0),kneePole,weight)
	end
end

-- Grip attachments sit near the fingers. Leave room for the palm and sleeve as
-- the chest rotates over the belt, particularly on broad layered-clothing avatars.
function PullPose:clearPalm(target,handRotation,grip)
	local palm=target-handRotation:VectorToWorldSpace(grip.Position)
	for _,name in if self.r15 then {"UpperTorso","LowerTorso"} else {"Torso"} do
		local joint=self.joints[name]
		local frame=joint and self.frames[joint.Part1]
		if not frame then continue end
		local v=frame:PointToObjectSpace(palm)
		local half=joint.Part1.Size*0.5
		local margin=self.size*0.27
		if math.abs(v.X)<half.X+margin and math.abs(v.Y)<half.Y+margin then
			local push=frame.LookVector*math.max(0,v.Z+half.Z+margin)
			target+=push
			palm+=push
		end
	end
	return target
end

function PullPose:step(dt)
	if self.dirty then self.dirty=false; self:bind() end
	local l,root=self.lasso,self.root
	if not self.torso or not root.Parent or l.owner.Character~=self.char then return end
	local now=workspace:GetServerTimeNow()
	local age=math.max(0,now-l.castAt)
	local ending=if l.endedAt then now-l.endedAt else 0
	local release=if l.caught then smooth((ending-1.48)/0.38) else smooth(ending/0.38)
	local weight=smooth(age/0.15)*(1-release)
	if weight<=0 then return end
	local look=root.CFrame:VectorToObjectSpace(l.orientation.LookVector)
	local yaw=math.atan2(-look.X,-look.Z)
	self.yaw+=math.atan2(math.sin(yaw-self.yaw),math.cos(yaw-self.yaw))*(1-math.exp(-dt*12))
	local facing=CFrame.Angles(0,self.yaw,0)
	local velocity=root.AssemblyLinearVelocity
	local planted=self.humanoid.FloorMaterial~=Enum.Material.Air and Vector3.new(velocity.X,0,velocity.Z).Magnitude<3.2
	self.stance+=((if planted then 1 else 0)-self.stance)*(1-math.exp(-dt*12))

	local cycle=age*4.15
	local draw=0.12+0.22*math.sin(cycle)
	local compression=0.44+0.08*math.cos(cycle)
	local turn=0.12+0.15*math.sin(cycle-0.3)
	local slide=0.14+0.13*math.cos(cycle)
	local tugAge=if l.caught then ending*0.93 elseif l.pullAt then now-l.pullAt else math.huge
	if tugAge<1.04 or l.caught then
		draw,compression,turn,slide=sample(haul,tugAge)
		if l.caught then draw*=1.17 end
	end
	local slip=if l.missAt and not l.endedAt then now-l.missAt else math.huge
	local jerk=smooth(slip/0.14)*(1-smooth((slip-0.17)/0.55))
	draw,compression,turn=draw-1.0*jerk,compression+0.33*jerk,turn-0.5*jerk
	-- A new input can arrive during a regrip or an assisted pull. Keep the current
	-- posture as the starting point instead of snapping back to the first key.
	local blend=1-math.exp(-dt*29)
	self.draw+=(draw-self.draw)*blend
	self.compression+=(compression-self.compression)*blend
	self.turn+=(turn-self.turn)*blend
	self.slide+=(slide-self.slide)*blend
	draw,compression,turn,slide=self.draw,self.compression,self.turn,self.slide
	local latched=smooth((age-0.35)/0.39)
	local received=if l.caught then smooth((ending-0.76)/0.42) else 0
	local body=latched*(1-received*0.68)
	local tremor=(math.sin(age*43)+0.38*math.sin(age*67))*0.014*body*(0.45+compression)
	local scale=self.size
	local hips=facing:VectorToWorldSpace(Vector3.new(0.11*turn,-compression*(if self.r15 then 0.53 else 0.19),0.23+0.36*draw)*scale)*self.stance*body
	local lean=math.rad(12+23*draw)*body
	table.clear(self.frames)
	self.frames[root]=CFrame.identity
	local pelvis=facing*CFrame.Angles(lean*(if self.r15 then 0.58 else 1),-0.26*turn*body,0.07*turn*body)
	self:pivot(self.torso,pelvis,hips,weight)
	self:pivot(self.joints.UpperTorso,CFrame.Angles(lean*0.54+tremor,-0.28*turn*body,0.05*turn*body),Vector3.zero,weight)
	self:pivot(self.joints.Head,CFrame.Angles(0.09-lean*0.76,0.34*turn*body,0.04*turn),Vector3.zero,weight*0.86)
	if self.stance>0.01 then self:legs(facing,weight*self.stance*latched) end

	local shoulder=self.joints.RightUpperArm or self.joints["Right Arm"]
	if not shoulder then return end
	local chest=self.frames[shoulder.Part0]
	if not chest then return end
	local height=(chest*shoulder.C0).Position.Y
	local other=self.joints.LeftUpperArm or self.joints["Left Arm"]
	local shoulderLine=if other then (shoulder.C0.Position+other.C0.Position)*0.5 else Vector3.new(0,shoulder.C0.Y,0)
	local shoulders=chest:PointToWorldSpace(shoulderLine)
	local rear=shoulders+chest:VectorToWorldSpace(Vector3.new(0.12+0.57*draw,-0.44-0.43*draw,-1.19+0.25*draw)*scale)
	local aim=if l.position then root.CFrame:PointToObjectSpace(l.position) else facing:PointToWorldSpace(Vector3.new(0,5,-10))
	local rope=unit(aim-rear,facing.LookVector)
	local front=rear+rope*(0.44+slide*0.85)*scale
	-- Bring the extended hand across the sternum and the rear hand to the belt.
	local gather=shoulders+facing:VectorToWorldSpace(Vector3.new(0.31,-0.32,-0.88)*scale)
	rear=rear:Lerp(gather,received)
	front=front:Lerp(gather+facing:VectorToWorldSpace(Vector3.new(-0.42,-0.08,0.03)*scale),received)
	for _,side in {"Right","Left"} do
		local right=side=="Right"
		local sign=if right then 1 else -1
		local grip=if right then l.grip else l.leftGrip
		if not grip then continue end
		local arm=self.joints[side.."UpperArm"] or self.joints[side.." Arm"]
		local elbow,wrist=self.joints[side.."LowerArm"],self.joints[side.."Hand"]
		local wind=smooth(age/0.25)
		local cast=if right then Vector3.new(0.90+0.32*wind,height/scale+0.91*wind,-0.48+0.85*wind)
			else Vector3.new(-0.69,height/scale-0.69,-0.41)
		local target=facing:PointToWorldSpace(cast*scale):Lerp(if right then rear else front,latched)
		local pole=shoulders+facing:VectorToWorldSpace(Vector3.new(sign*(1.40+0.24*draw),-0.85,0.68+0.76*draw)*scale)
		local handRotation=facing*CFrame.Angles(1.22+0.19*draw,-sign*0.32,-sign*(0.47+0.35*received))
		local clear=self:clearPalm(target,handRotation,grip)
		self:chain(arm,elbow,wrist,grip.Position,target:Lerp(clear,latched),handRotation,pole,weight)
	end
end

function PullPose.new(lasso,humanoid)
	local self=setmetatable({lasso=lasso,char=lasso.character,root=lasso.root,humanoid=humanoid,
		size=lasso.root.Size.Y/2,stance=0,yaw=0,draw=0,compression=0.4,turn=0,slide=0,
		originals={},frames={},dirty=true},PullPose)
	self.added=self.char.DescendantAdded:Connect(function(item) if isJoint(item) then self.dirty=true end end)
	self.removing=self.char.DescendantRemoving:Connect(function(item) if isJoint(item) then self.dirty=true end end)
	-- Let Animate produce a clean base first, then pose both legacy and upgraded joints.
	self.before=RunService.PreAnimation:Connect(function() self:restore() end)
	self.after=RunService.PreSimulation:Connect(function(dt) self:step(dt) end)
	return self
end

function PullPose:destroy()
	self.before:Disconnect()
	self.after:Disconnect()
	self.added:Disconnect()
	self.removing:Disconnect()
	self:restore()
end

return PullPose
