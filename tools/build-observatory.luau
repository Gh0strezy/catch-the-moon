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
	if i%2==0 then
		local a, b = V(x*32,4,z*32), V(math.sin(angle+math.pi/10)*32,4,math.cos(angle+math.pi/10)*32)
		part(roof,"Railing post",V(0.38,3.4,0.38),C.new(x*32,3.1,z*32),"515B76","Metal")
		rod(roof,"Top rail",a,b,0.18,"D8B585","Metal")
	end
end
local spawn = r.Instance.new("SpawnLocation")
spawn.Name, spawn.Anchored, spawn.Neutral, spawn.Transparency = "Arrival", true, true, 1
spawn.CanCollide, spawn.Duration, spawn.Size = false, 0, V(14,0.3,5)
spawn.CFrame, spawn.Parent = C.new(0,1.8,9)*C.Angles(0,math.pi,0), roof

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
