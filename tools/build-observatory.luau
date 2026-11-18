-- Run from the repository root with Lune. The resulting model is editable in Studio.
local r = require("@lune/roblox")
local fs = require("@lune/fs")
local V, C, E = r.Vector3.new, r.CFrame, r.Enum
local world = r.Instance.new("Model")
world.Name = "Observatory"
local function group(name)
	local folder = r.Instance.new("Folder")
	folder.Name, folder.Parent = name, world
	return folder
end
local roof, city, sky = group("TelescopeDeck"), group("City"), group("Constellations")
local function part(parent, name, size, frame, color, material, shape)
	local p = r.Instance.new("Part")
	p.Name, p.Size, p.CFrame = name, size, frame
	p.Color, p.Material = r.Color3.fromHex(color), E.Material[material or "SmoothPlastic"]
	p.Anchored = true
	p.CanCollide = parent == roof
	p.CanTouch, p.CastShadow = false, parent == roof
	p.TopSurface, p.BottomSurface = E.SurfaceType.Smooth, E.SurfaceType.Smooth
	if shape then p.Shape = E.PartType[shape] end
	p.Parent = parent
	return p
end
local function rod(parent, name, a, b, diameter, color, material)
	return part(parent, name, V(diameter, diameter, (b-a).Magnitude),
		C.lookAt((a+b)/2, b), color, material)
end
local function disc(name, y, radius, height, color, material)
	return part(roof, name, V(height, radius*2, radius*2), C.new(0,y,0)*C.Angles(0,0,math.pi/2), color, material, "Cylinder")
end

disc("Observatory foundation", -1, 35, 4, "242D49", "Slate")
disc("Brass cornice", 1, 35.2, 0.2, "B79460", "Metal")
disc("Slate deck", 1.25, 34.6, 0.4, "38435E", "Slate")
disc("Telescope base", 1.9, 7.4, 1, "222D47", "Metal")
disc("Azimuth scale", 2.45, 7.55, 0.12, "FFD78F", "Neon")
disc("Rotating plinth", 2.8, 6.8, 0.6, "434C65", "Metal")
for _,x in ipairs({-6,6}) do
	part(roof,"Tether winch",V(1.65,2.4,1.65),C.new(x,2.65,6.5),"576684","Metal")
	part(roof,"Winch lamp",V(1.45,0.19,1.45),C.new(x,3.92,6.5),"F7C780","Neon")
end
for i=0,39 do
	local angle = math.pi*2*i/40
	local x,z = math.sin(angle), math.cos(angle)
	part(roof, "Compass mark", V(0.10,0.08,if i%5==0 then 1.8 else 0.8),
		C.new(x*9,1.49,z*9)*C.Angles(0,angle,0), "CDB487", "Metal")
	if i%2==0 and i~=0 and i~=38 then
		local a, b = V(x*32,4,z*32), V(math.sin(angle+math.pi/10)*32,4,math.cos(angle+math.pi/10)*32)
		part(roof,"Railing post",V(0.38,3.4,0.38),C.new(x*32,3.1,z*32),"515B76","Metal")
		rod(roof,"Top rail",a,b,0.18,"D8B585","Metal")
	end
end
local spawn = r.Instance.new("SpawnLocation")
spawn.Name, spawn.Anchored, spawn.Neutral, spawn.Transparency = "Arrival", true, true, 1
spawn.CanCollide, spawn.Duration, spawn.Size = false, 0, V(14,0.3,5)
spawn.CFrame, spawn.Parent = C.new(0,1.8,15), roof

-- Four different silhouettes make the stations recognizable from the entry deck.
local sites = group("Stations")
local function station(key, x, z, accent)
	local base = part(sites,key,V(0.58,7,7),C.new(x,1.74,z)*C.Angles(0,0,math.pi/2),"26344C","Metal","Cylinder")
	base.CanCollide=true
	part(sites,key.."Trim",V(0.12,6.5,6.5),C.new(x,2.08,z)*C.Angles(0,0,math.pi/2),accent,"Neon","Cylinder")
end
station("Catch",0,-6,"EAC787")
station("Luck",-21,5,"87D6C9")
station("Speed",21,5,"F6AD78")
station("Gym",16,-17,"A7ACFF")
-- Brass telescope on a tripod, a mechanical orrery, sprint gates and a training bar.
local lens = V(0,7.2,-9)
for _,foot in ipairs({V(-2.4,2.1,-4),V(2.4,2.1,-4),V(0,2.1,-8.4)}) do
	rod(sites,"Tripod",foot,V(0,5.9,-6),0.26,"B49665","Metal")
end
rod(sites,"Telescope barrel",V(0,4.9,-3.3),lens,1.45,"A78858","Metal")
part(sites,"Telescope lens",V(1.55,1.55,1.55),C.new(lens),"93CFD9","Glass","Ball")
part(sites,"Orrery sun",V(2,2,2),C.new(-21,5.0,5),"9CF5D6","Neon","Ball")
for i=0,23 do
	local function orbitPoint(k)
		local a = k*math.pi/12
		return V(-21+2.7*math.cos(a),5+0.8*math.cos(a),5+2*math.sin(a))
	end
	rod(sites,"Orrery ring",orbitPoint(i),orbitPoint(i+1),0.13,"B3976F","Metal")
end
for _,x in ipairs({18.8,23.2}) do
	part(sites,"Sprint gate",V(0.45,4.8,0.65),C.new(x,4.3,5),"67514A","Metal")
	part(sites,"Gate light",V(0.48,1.5,0.7),C.new(x,5.6,5),"FFAD76","Neon")
end
rod(sites,"Lift bar",V(13,4.3,-17),V(19,4.3,-17),0.25,"D1D8DA","Metal")
for _,x in ipairs({13.8,14.3,17.7,18.2}) do
	part(sites,"Weight plate",V(0.4,2,2),C.new(x,4.3,-17),"7884B4","Metal","Cylinder")
end
for _,x in ipairs({14.5,17.5}) do
	part(sites,"Bar rack",V(0.45,2.5,0.6),C.new(x,3.2,-17),"545D7E","Metal")
end
for _,path in ipairs({{-20,5,"87D6C9"},{20,5,"F6AD78"},{16,-17,"A7ACFF"},{0,32,"C9AB77"}}) do
	local target=V(path[1],1.49,path[2])
	local origin=V(0,1.49,12)
	for n=1,5 do
		local pos=origin:Lerp(target,n/6)
		part(sites,"Wayfinding inlay",V(0.25,0.06,1.6),C.lookAt(pos,target),path[3],"Neon")
	end
end

-- Sunset-lit windows and roof silhouettes are fixed across clients.
math.randomseed(12937)
for row=1,2 do
	for i=-8,8 do
		local x, z = i*11 + math.random(-3,3), -27-row*23-math.random(0,13)
		local w,d,top = math.random(6,12), math.random(7,13), math.random(0,13)
		local tone = if row==1 then "35405C" else "28334F"
		part(city,"Townhouse",V(w,40,d),C.new(x,top-20,z),tone,"Slate")
		part(city,"Cornice",V(w+0.5,0.45,d+0.4),C.new(x,top,z),"535F79","Metal")
		part(city,"Chimney",V(1.2,2.7,1.4),C.new(x+w*0.28,top+1.3,z),tone)
		for floor=1,4 do
			for col=-1,1 do
				if math.random()<0.65 then
					part(city,"Window",V(0.9,1.25,0.12),C.new(x+col*w/3.5,top-floor*2.8,z+d/2),
						if math.random()<0.75 then "EDBC84" else "97B7C9","Neon")
				end
			end
		end
	end
end
for i=1,155 do
	local x,y,z = math.random(-200,200),math.random(9,115),math.random(-155,-110)
	local s = math.random(12,34)/100
	part(sky,"Star",V(s,s,s),C.new(x,y,z),if i%4==0 then "FBD6A1" else "BECEE9","Neon","Ball")
end
local previousStar
for _,point in ipairs({{-52,30},{-46,34},{-40,29},{-35,37},{-27,36}}) do
	local pos=V(point[1],point[2],-73)
	part(sky, "Guide star",V(0.5,0.5,0.5),C.new(pos),"FFE4BC","Neon","Ball")
	if previousStar then
		rod(sky,"Star chart line",previousStar,pos,0.09,"788DA8","SmoothPlastic")
	end
	previousStar=pos
end
if not fs.isDir("world") then fs.writeDir("world") end
fs.writeFile("world/Observatory.rbxmx",r.serializeModel({world},true))
