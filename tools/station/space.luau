local K=require("./kit")
local A,C,V=K.A,K.C,K.V
local function stars(parent,normal,index)
	local up=if normal.Y==0 then V(0,1,0) else V(0,0,1)
	local f=A.r.CFrame.lookAt(normal*900,V(0,0,0),up)
	local wall=A.part(parent,"Deep field "..index,V(1801,1801,0.12),f,"111525")
	wall.CastShadow=false
	local gui=A.object("SurfaceGui",wall,"Celestial plate")
	gui.Face,gui.CanvasSize,gui.LightInfluence=A.E.NormalId.Front,A.r.Vector2.new(1536,1536),0
	gui.MaxDistance,gui.Brightness=2400,1
	local field=A.object("Frame",gui,"Star field")
	field.Size,field.BorderSizePixel=A.r.UDim2.fromScale(1,1),0
	local high,low=A.r.Color3.fromHex("0F162B"),A.r.Color3.fromHex("191528")
	field.BackgroundColor3=if normal.Y==1 then high elseif normal.Y==-1 then low else A.r.Color3.new(1,1,1)
	if normal.Y==0 then
		local gradient=A.object("UIGradient",field,"Interstellar colour")
		gradient.Color,gradient.Rotation=A.r.ColorSequence.new(high,low),90
	end
	local seed=9721+index*731
	local function random()
		seed=(seed*48271)%2147483647
		return seed/2147483647
	end
	for i=1,76 do
		local p=A.object("Frame",field,"Star")
		local size=if i%13==0 then 3.4 else 1.15+random()*1.35
		p.Size,p.Position=A.r.UDim2.fromOffset(size,size),A.r.UDim2.fromScale(random(),random())
		p.BorderSizePixel,p.Rotation=0,if i%13==0 then 45 else 0
		p.BackgroundColor3=A.r.Color3.fromHex(if i%7==0 then "D7B4A0" else "C3D6ED")
		p.BackgroundTransparency=0.15+random()*0.45
	end
	if index==1 or index==5 then
		local cloud=A.object("ImageLabel",field,"Diffuse dust cloud")
		cloud.Image="rbxasset://textures/particles/smoke_main.dds"
		cloud.ImageColor3=A.r.Color3.fromHex("847595")
		cloud.BackgroundTransparency,cloud.ImageTransparency,cloud.Rotation=1,0.86,if index==1 then -24 else 17
		cloud.Size,cloud.Position=A.r.UDim2.fromScale(0.45,0.13),A.r.UDim2.fromScale(0.23,0.25)
	end
end
return function(world)
	local space=K.model(world,"SpaceEnvironment")
	for i,n in ipairs({V(1,0,0),V(-1,0,0),V(0,1,0),V(0,-1,0),V(0,0,1),V(0,0,-1)}) do stars(space,n,i) end
	require("../world/celestial")(space)
	local mote=K.marker(space,"Spectrometer dust",C(0,39,16))
	local emitter=A.object("ParticleEmitter",mote,"Dust glints")
	emitter.Texture="rbxasset://textures/particles/sparkles_main.dds"
	emitter.Rate,emitter.Lifetime,emitter.Speed=0.8,A.r.NumberRange.new(2,4),A.r.NumberRange.new(0.25,0.6)
	emitter.Size=A.r.NumberSequence.new(0.14)
	emitter.Transparency=A.r.NumberSequence.new(0.65,1)
end
