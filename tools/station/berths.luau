local K=require("./kit")
local A,C,V,R=K.A,K.C,K.V,K.R
local B={}
function B.bridge(parent,f,i)
	local b=K.model(parent,string.format("Bridge_%02d",i))
	b:SetAttribute("BaseIndex",i)
	local start,finish=66,K.radius-22
	local span=finish-start
	local center=(start+finish)/2
	A.part(b,"Service keel",V(8,3.1,span),f*C(0,-1.1,center),K.ink)
	A.part(b,"Walkway",V(14,1.1,span),f*C(0,K.deckY-0.55,center),K.steel,"DiamondPlate",true)
	for _,s in ipairs({-1,1}) do
		A.part(b,"Edge beam",V(0.9,2.1,span),f*C(s*7,-0.1,center),K.armor)
		A.part(b,"Guide strip",V(0.24,0.08,span-2),f*C(s*6.15,K.deckY+0.05,center),K.teal,"Neon")
		A.part(b,"Guard cap",V(0.42,0.42,span),f*C(s*6.85,4.8,center),K.steel,"Metal",true)
		for j=0,2 do
			local z=start+(j+0.5)*span/3
			K.glassPanel(b,"Guard glass",V(0.25,2.7,span/3-0.6),f*C(s*6.85,3.05,z),true)
			A.part(b,"Rail shoe",V(0.72,3.4,0.75),f*C(s*6.85,3.1,z-span/6+0.3),K.armor)
			A.strut(b,"Keel diagonal",f:PointToWorldSpace(V(s*7,-0.8,z-span/6)),f:PointToWorldSpace(V(s*3,-3,z+span/6)),0.65,0.65,K.steel)
		end
	end
	A.plaque(b,f*C(5.3,3.1,start+2),3.4,string.format("%02d",i))
end
local function floorDeck(floor,f)
	local function plate(x,z,w,d)
		A.part(floor,"Pressure deck",V(w,1,d),f*C(x,-0.5,z),K.dark,"Metal",true)
	end
	plate(0,-17.5,56,11)
	plate(0,2.5,56,17)
	plate(-26.5,-9,3,6)
	plate(4.5,-9,47,6)
	for _,s in ipairs({-1,1}) do
		K.triangle(floor,"Prow deck",f*C(0,-0.5,0),V(0,0,11),V(s*28,0,11),V(0,0,33),1,K.dark,"Metal",true)
	end
end
local function slot(parent,f,i)
	local m=K.model(parent,string.format("PlanetSlot_%02d",i))
	local open=i%2==1
	m:SetAttribute("SlotIndex",i)
	m:SetAttribute("Unlocked",open)
	local plinth=A.deck(m,"Bearing",f*C(0,0.29,0),5.4,0.58,K.ink,"Metal",true)
	m.PrimaryPart=plinth
	A.deck(m,"Halo",f*C(0,0.61,0),4.95,0.18,if open then K.teal else K.steel,if open then "Neon" else "Metal")
	local face=A.deck(m,"Emitter",f*C(0,0.73,0),4.42,0.15,if open then K.glass else K.dark,"Metal")
	local latch=A.part(m,"LockBar",V(3.2,0.16,0.55),f*C(0,0.87,0)*R(0,0.45,0),K.gold)
	latch.Transparency=if open then 1 else 0
	-- Disc CFrames use the Roblox cylinder X axis. Cancel its basis for an upright socket.
	K.attach(face,"PlanetAnchor",face.CFrame:ToObjectSpace(f*C(0,3.3,0)))
end
function B.floor(parent,name,f)
	local floor=K.model(parent,name)
	local datum=K.marker(floor,"FloorOrigin",f)
	floor.PrimaryPart=datum
	floor:SetAttribute("FloorIndex",1)
	floor:SetAttribute("FloorPitch",K.pitch)
	floorDeck(floor,f)
	local slots=A.object("Folder",floor,"PlanetSlots")
	for row=0,4 do
		for col=0,1 do
			local x=if col==0 then -13 else 13
			slot(slots,f*C(x,0,-16+row*7),row*2+col+1)
		end
	end
	local expansion=A.object("Folder",floor,"ExpansionPoints")
	local mount=K.marker(expansion,"StackDatum",f)
	K.attach(mount,"NextFloor",C(0,K.pitch,0))
	local access=K.model(floor,"VerticalAccess")
	local truss=A.part(access,"ClimbRail",V(2,K.pitch,2),f*C(-24,K.pitch/2,-9),K.steel,"Metal",true,"TrussPart")
	K.attach(truss,"Landing",C(3,K.pitch/2+2.6,0))
	for _,s in ipairs({-1,1}) do
		for _,z in ipairs({-19,8}) do
			A.part(floor,"Stack column",V(1.4,K.pitch,1.45),f*C(s*25,K.pitch/2,z),K.armor,"Metal",true)
			A.part(floor,"Column coupling",V(2.1,1.05,2.2),f*C(s*25,K.pitch-0.7,z),K.steel)
		end
		A.part(floor,"Composite lintel",V(1.4,1.2,30),f*C(s*25,K.pitch-0.65,-5.5),K.steel)
		A.part(floor,"Interdeck light",V(0.24,0.22,26),f*C(s*24.25,K.pitch-0.75,-5.5),K.violet,"Neon")
		K.glassPanel(floor,"Side screen",V(0.32,3.6,25),f*C(s*27.6,1.9,-5.5),true)
	end
	return floor
end
function B.base(parent,axis,i)
	local f=axis*C(0,K.deckY,K.radius)
	local base=K.model(parent,string.format("Base_%02d",i))
	base.PrimaryPart=K.marker(base,"BaseOrigin",f)
	base:SetAttribute("BaseIndex",i)
	base:SetAttribute("ZoneId",string.format("SPACE-%02d",i+8))
	base:SetAttribute("ZoneStatus","Prepared")
	base:SetAttribute("ZoneName",string.format("Орбитальный причал %02d",i))
	local keel=K.model(base,"LowerHull")
	K.hull(keel,f,1,-2.1,2.1,K.armor)
	K.hull(keel,f,0.92,-4.25,2.3,K.ink)
	K.hull(keel,f,0.74,-6.35,2.1,K.steel)
	for _,s in ipairs({-1,1}) do
		A.strut(keel,"Load spreader",f:PointToWorldSpace(V(s*23,-3,8)),f:PointToWorldSpace(V(s*10,-9,-9)),2.3,2.6,K.armor)
		local a,b=f:PointToWorldSpace(V(s*27.8,-1.45,11)),f:PointToWorldSpace(V(0,-1.45,32.8))
		A.strut(keel,"Prow pinstripe",a,b,0.45,0.3,K.violet,"Neon")
	end
	B.floor(A.object("Folder",base,"Floors"),"Floor_01",f)
	local catch=K.model(base,"CatchZone")
	local pad=A.deck(catch,"Casting apron",f*C(0,-0.48,32),17,0.96,K.steel,"DiamondPlate",true)
	catch.PrimaryPart=pad
	K.attach(pad,"CastOrigin",pad.CFrame:ToObjectSpace(f*C(0,3,35)*R(0,math.pi,0)))
	for _,s in ipairs({-1,1}) do
		A.strut(catch,"Induction rail",f:PointToWorldSpace(V(s*6.8,0.24,28)),f:PointToWorldSpace(V(s*6.8,0.24,36)),0.48,0.36,K.gold,"Neon")
		A.part(catch,"Field coil",V(1.4,2,2.3),f*C(s*7.6,1,32),K.dark)
	end
	local npc=K.model(base,"NPCPoints")
	local origin=K.marker(npc,"RouteDatum",f)
	for _,entry in ipairs({{"NPCSpawn",6,-20},{"NPCVisitorPoint",5,-6},{"NPCEvaluationPoint",5,10}}) do
		K.attach(origin,entry[1],C(entry[2],2.8,entry[3]))
	end
	A.part(npc,"Assay desk",V(4.3,2.8,2),f*C(7.8,1.4,15),K.steel,"Metal",true)
	A.part(npc,"Assay readout",V(3.7,0.24,1.6),f*C(7.8,2.95,15)*R(-0.12,0,0),K.glass)
	A.plaque(npc,f*C(7.8,2,13.94),3.9,"ОЦЕНКА")
	return base
end
return B
