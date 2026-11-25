-- Shared architectural kit. All dimensions are studs, all CFrames are world-space.
local r=require("@lune/roblox")
local A={V=r.Vector3.new,C=r.CFrame.new,turn=r.CFrame.Angles,E=r.Enum,r=r}
local V,C=A.V,A.C
A.ink="283344"
A.steel="4A5969"
A.brass="B99664"
A.stone="ABA49C"
A.porcelain="D8CEC1"
A.glass="627F8C"
A.lamp="F4D59C"

function A.object(kind,parent,name)
	local o=r.Instance.new(kind)
	o.Name,o.Parent=name,parent
	return o
end
function A.part(parent,name,size,frame,color,material,solid,kind)
	local p=A.object(kind or "Part",parent,name)
	p.Anchored,p.CanCollide,p.CanTouch,p.CanQuery=true,solid==true,false,solid==true
	p.Size,p.CFrame,p.Color,p.Material=size,frame,r.Color3.fromHex(color),r.Enum.Material[material or "Metal"]
	p.TopSurface,p.BottomSurface=r.Enum.SurfaceType.Smooth,r.Enum.SurfaceType.Smooth
	if material=="Neon" then p.CastShadow=false end
	return p
end
function A.deck(parent,name,frame,diameter,height,color,material,solid)
	local p=A.part(parent,name,V(height,diameter,diameter),frame*A.turn(0,0,math.pi/2),color,material,solid)
	p.Shape=r.Enum.PartType.Cylinder
	return p
end
function A.globe(parent,name,frame,size,color,material)
	local p=A.part(parent,name,size,frame,color,material)
	p.Shape=r.Enum.PartType.Ball
	return p
end
function A.strut(parent,name,start,finish,width,depth,color,material,solid)
	local d=finish-start
	local up=if math.abs(d.Unit.Y)>0.98 then V(0,0,1) else V(0,1,0)
	return A.part(parent,name,V(width,depth,d.Magnitude+0.035),r.CFrame.lookAt((start+finish)/2,finish,up),color,material,solid)
end
function A.arc(parent,name,frame,rx,ry,first,last,count,width,depth,color,mat)
	local function point(i)
		local a=math.rad(first+(last-first)*i/count)
		return frame:PointToWorldSpace(V(rx*math.cos(a),ry*math.sin(a),0))
	end
	for i=1,count do A.strut(parent,name,point(i-1),point(i),width,depth,color,mat) end
end
function A.light(parent,tint,brightness,range)
	local light=A.object("PointLight",parent,"Reflected light")
	light.Color,light.Brightness,light.Range,light.Shadows=r.Color3.fromHex(tint),brightness,range,false
end
function A.plaque(parent,frame,width,caption)
	local p=A.part(parent,"Enamel sign",V(width,1.35,0.20),frame,A.ink)
	local gui=A.object("SurfaceGui",p,"Lettering")
	gui.Face,gui.CanvasSize,gui.LightInfluence=r.Enum.NormalId.Front,r.Vector2.new(width*70,95),0.25
	local label=A.object("TextLabel",gui,"Destination")
	label.Size,label.BackgroundTransparency,label.Text=r.UDim2.fromScale(1,1),1,caption
	label.TextColor3,label.TextScaled=r.Color3.fromHex("F1DDB5"),true
	label.FontFace=r.Font.new("rbxasset://fonts/families/Montserrat.json",r.Enum.FontWeight.Medium,r.Enum.FontStyle.Normal)
end
function A.socket(parent,frame)
	local p=A.part(parent,"Mooring plate",V(6,0.24,5),frame*C(0,0.18,0),A.brass)
	local anchor=A.object("Attachment",p,"TransportSocket")
	anchor.Position=V(0,0.2,0)
end
return A
