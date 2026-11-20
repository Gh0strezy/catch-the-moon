local Debris = game:GetService("Debris")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")

local Impact = {}
local gold = Color3.fromHex("FFD260")
local white = Color3.fromHex("FFFFED")
local cyan = Color3.fromHex("65F4F7")
local red = Color3.fromHex("FF5866")
local violet = Color3.fromHex("AD7BFF")
local ink = Color3.fromHex("262143")

-- Length is in studs. Each beat has its own silhouette and timing.
local beats = {
	cast = {color=cyan, accent=violet, rays=9, length=3.4, time=0.37},
	hit = {color=gold, accent=cyan, rays=13, length=5.1, time=0.34},
	miss = {color=red, accent=violet, rays=8, length=4.6, time=0.43},
	catch = {color=white, accent=gold, rays=18, length=5.6, time=0.49},
	escape = {color=violet, accent=red, rays=12, length=6.5, time=0.48},
}

local function animate(item, time, properties)
	TweenService:Create(item,TweenInfo.new(time,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),properties):Play()
end

local function effectPart(parent, name, frame)
	local p = Instance.new("Part")
	p.Name, p.CFrame, p.Size, p.Transparency = name, frame, Vector3.one*0.1, 1
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = true,false,false,false,false
	p.Parent = parent
	return p
end

local function node(parent, pos, axis)
	local a = Instance.new("Attachment")
	a.Position, a.Axis, a.Parent = pos, axis, parent
	return a
end

local function stroke(parent, a, b, width, tip, color)
	local line = Instance.new("Beam")
	line.Attachment0, line.Attachment1 = a, b
	line.Width0, line.Width1 = width, tip
	line.Color, line.LightEmission = ColorSequence.new(color), 0.9
	line.FaceCamera, line.Segments, line.Parent = true, 8, parent
	return line
end

-- Two tapered semicircles read as brush strokes, even edge-on to the player.
local function shockRing(root, beat, radius, tilt)
	local frame = CFrame.Angles(tilt,0,0.3)
	local axis = frame.YVector
	local left = node(root, -frame.XVector*radius, axis)
	local right = node(root, frame.XVector*radius, -axis)
	local outer = radius*2.5
	animate(left,beat.time,{Position=-frame.XVector*outer})
	animate(right,beat.time,{Position=frame.XVector*outer})
	for side=1,2 do
		local a,b = left,right
		if side==2 then a,b=right,left end
		local line = stroke(root,a,b,0.22,0.025,if side==1 then beat.color else beat.accent)
		line.CurveSize0, line.CurveSize1 = radius*4/3, radius*4/3
		animate(line,beat.time,{CurveSize0=outer*4/3,CurveSize1=outer*4/3,Width0=0,Width1=0})
	end
end

function Impact.burst(parent, kind, position)
	local beat = beats[kind]
	local camera = workspace.CurrentCamera
	local frame = if camera then CFrame.new(position)*camera.CFrame.Rotation else CFrame.new(position)
	local root = effectPart(parent, "LassoImpact_"..kind, frame)
	Debris:AddItem(root,beat.time+0.08)
	local broken = kind=="miss" or kind=="escape"
	if not broken then shockRing(root,beat,beat.length*0.34,0.48) end
	if kind=="catch" then shockRing(root,beat,1.15,-0.95) end
	for i=1,beat.rays do
		local angle = 2*math.pi*i/beat.rays + math.sin(i*2.4)*0.12
		local direction = Vector3.new(math.cos(angle),math.sin(angle),0)
		local across = Vector3.new(-direction.Y,direction.X,0)
		local length = beat.length*(0.72 + 0.28*math.cos(i*1.4))
		local base = node(root,direction*length*0.22,direction)
		local tip = node(root,direction*length*0.65,direction)
		local color = if i%3==0 then beat.accent else beat.color
		local line = stroke(root,base,tip,if i%3==0 then 0.28 else 0.15,0.015,color)
		local bend = if broken then across*length*0.28 else Vector3.zero
		if broken then
			local elbow = node(root,direction*length*0.43+bend,direction)
			line.Attachment1 = elbow
			local shard = stroke(root,elbow,tip,0.13,0.015,color)
			animate(shard,beat.time,{Width0=0,Width1=0})
			animate(elbow,beat.time,{Position=direction*length+bend})
		end
		animate(base,beat.time,{Position=direction*length*0.82})
		animate(tip,beat.time,{Position=direction*length*1.3})
		animate(line,beat.time,{Width0=0,Width1=0})
	end
end

function Impact.echo(parent, position, diameter, color)
	local ghost = effectPart(parent,"LassoAfterimage",CFrame.new(position))
	ghost.Shape, ghost.Material, ghost.Color = Enum.PartType.Ball,Enum.Material.Neon,color
	ghost.Size, ghost.Transparency = Vector3.one*diameter,0.76
	animate(ghost,0.18,{Size=Vector3.one*diameter*0.78,Transparency=1})
	Debris:AddItem(ghost,0.22)
end

-- Keep the centre of the screen and the timing bar clear throughout the impact.
function Impact.screen(gui, kind)
	if not gui or GuiService.ReducedMotionEnabled then return end
	local camera = workspace.CurrentCamera
	if not camera then return end
	local size,beat = camera.ViewportSize,beats[kind]
	local group = Instance.new("Frame")
	group.Name,group.BackgroundTransparency,group.Size = "ImpactLines",1,UDim2.fromScale(1,1)
	group.ClipsDescendants,group.Parent = true,gui
	Debris:AddItem(group,beat.time+0.04)
	for i=1,20 do
		local angle = i*math.pi/10+0.08
		local x,y = math.cos(angle), math.sin(angle)
		local boundary = math.min(size.X/(2*math.abs(x)),size.Y/(2*math.abs(y)))
		local length = math.min(boundary*0.4,120)*(0.63+0.37*math.abs(math.sin(i*2)))
		local line = Instance.new("Frame")
		line.AnchorPoint, line.Rotation = Vector2.new(0.5,0.5), math.deg(angle)
		line.Position = UDim2.fromOffset(size.X/2+x*(boundary-length*0.38),size.Y/2+y*(boundary-length*0.38))
		line.Size, line.BorderSizePixel = UDim2.fromOffset(length,if i%3==0 then 5 else 2),0
		line.BackgroundColor3 = if i%4==0 then ink elseif i%3==0 then beat.accent else beat.color
		local gradient = Instance.new("UIGradient")
		gradient.Transparency,gradient.Parent = NumberSequence.new(1,0.12),line
		line.Parent = group
		animate(line,beat.time,{Position=UDim2.fromOffset(size.X/2+x*boundary,size.Y/2+y*boundary),BackgroundTransparency=1})
	end
end

return Impact
