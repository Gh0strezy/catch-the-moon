local K=require("./kit")
local A,C,V,R=K.A,K.C,K.V,K.R
local function ring(parent,name,y,radius,width,depth,color,mat,n)
	A.arc(parent,name,C(0,y,0)*R(math.pi/2,0,0),radius,radius,0,360,n or 24,width,depth,color,mat)
end
local function telescope(parent)
	local f=A.r.CFrame.lookAt(V(0,54,1),V(0,69,-27))
	local function tube(name,z,length,radius,tint,mat)
		return A.deck(parent,name,f*C(0,0,z)*R(math.pi/2,0,0),2*radius,length,tint,mat or "Metal")
	end
	A.deck(parent,"Azimuth bearing",C(0,44,0),16,2.4,K.steel,"Metal")
	for _,s in ipairs({-1,1}) do
		A.strut(parent,"Elevation fork",V(s*6,44,1),V(s*6,54,1),2.3,2.5,K.armor)
		A.deck(parent,"Trunnion",C(s*6,54,1)*R(0,0,math.pi/2),5.8,2.1,K.gold,"Metal")
	end
	tube("Spectrograph",8,10,3.3,K.dark)
	tube("Primary barrel",0,14,4.8,K.armor)
	tube("Optical bench",-13,12,3.4,K.ink)
	for i=0,5 do
		local a=math.pi*i/3
		A.strut(parent,"Carbon truss",f:PointToWorldSpace(V(4.5*math.cos(a),4.5*math.sin(a),-5)),f:PointToWorldSpace(V(5.5*math.cos(a+0.4),5.5*math.sin(a+0.4),-21)),0.48,0.48,K.steel)
	end
	tube("Aperture hood",-23,6.8,6.3,K.armor)
	tube("Lens bezel",-26.5,0.65,5.95,K.gold)
	tube("Coated objective",-26.9,0.35,5.4,"76ADC1","Glass")
	tube("Inner optic",-27.13,0.11,3.9,"93BCC8","SmoothPlastic")
end
local function dome(parent)
	for i=0,7 do
		local a=math.pi*i/4+math.pi/8
		local f=R(0,a,0)
		A.strut(parent,"Splayed pier",f:PointToWorldSpace(V(0,1.4,24)),f:PointToWorldSpace(V(0,26,15)),2.2,3,K.armor,"Metal",true)
		A.strut(parent,"Service spine",f:PointToWorldSpace(V(1.5,4,22)),f:PointToWorldSpace(V(1.5,25,15)),0.48,0.55,K.gold)
		K.glassPanel(parent,"Observation window",V(10.8,6.1,0.5),f*C(0,32,14.2))
		A.part(parent,"Mullion",V(0.55,7.2,0.75),f*C(5.45,32,14.1),K.armor)
	end
	for _,d in ipairs({{25,33,2,K.dark},{27,36,1.7,K.armor},{28.3,32,0.6,K.teal},{36,34,1.5,K.dark},{38.5,37,2,K.armor},{41,29,3,K.steel}}) do
		A.deck(parent,"Instrument drum",C(0,d[1],0),d[2],d[3],d[4],if d[4]==K.teal then "Neon" else "Metal")
	end
	for _,z in ipairs({-13,13}) do
		A.part(parent,"Shutter rail",V(57,0.8,1.45),C(0,52,z),K.steel)
		for _,x in ipairs({-17,17}) do
			A.strut(parent,"Rail stanchion",V(x*0.78,38.8,z*0.8),V(x,52,z),1.05,1.25,K.steel)
		end
	end
	local roof=K.model(parent,"RetractableRoof")
	for _,s in ipairs({-1,1}) do
		local leaf=K.model(roof,if s<0 then "PortLeaf" else "StarboardLeaf")
		local spine=A.part(leaf,"Roller carriage",V(8.3,1,31),C(s*12.2,53,0),K.dark)
		leaf.PrimaryPart=spine
		for j=0,2 do
			local p=C(s*(8.9+j*3.1),55.4-j*0.65,0)*R(0,0,-s*0.20)
			A.part(leaf,"Ceramic shutter panel",V(3.35,1,31.4),p,K.armor)
		end
		A.part(leaf,"Running light",V(0.23,0.35,27),C(s*8,55.8,0),K.teal,"Neon")
		leaf:SetAttribute("TravelX",s*10)
	end
	for _,m in ipairs({{-14,-7,17},{14,8,9}}) do
		local x,z,h=unpack(m)
		A.strut(parent,"Telemetry mast",V(x,38,z),V(x,38+h,z),0.45,0.45,K.steel)
		A.globe(parent,"Antenna bead",C(x,38+h,z),V(0.85,0.85,0.85),K.gold,"Neon")
	end
	telescope(K.model(parent,"GreatRefractor"))
end
return function(world)
	local center=K.model(world,"CentralStation")
	local tower=K.model(center,"Observatory")
	local deck=K.model(center,"Concourse")
	for _,d in ipairs({{-10,85,7,K.ink},{-6,113,3.4,K.steel},{-3.5,133,2.2,K.dark},{-1.65,135,1.2,K.armor},{0.23,134,2.38,K.dark}}) do
		A.deck(deck,"Pressure hull",C(0,d[1],0),d[2],d[3],d[4],"Metal",true)
	end
	ring(deck,"Promenade inlay",1.45,48,0.23,0.10,K.steel,"Metal",48)
	for i=1,8 do
		local f=R(0,math.rad(22.5+(i-1)*45),0)
		A.part(deck,"Dock approach",V(10,0.09,16),f*C(0,1.46,58),K.steel,"DiamondPlate")
		for _,x in ipairs({-6.5,6.5}) do
			A.part(deck,"Dock threshold",V(0.38,0.15,9),f*C(x,1.49,62),K.teal,"Neon")
		end
		-- Leave the south gallery axis clear for all existing dynamic exhibits.
		if i~=8 then
			local rail=f*R(0,math.pi/8,0)*C(0,0,64.6)
			K.glassPanel(deck,"Promenade visor",V(24,2.7,0.42),rail*C(0,2.9,0),true)
			A.part(deck,"Promenade rail",V(24.4,0.34,0.65),rail*C(0,4.4,0),K.steel)
		end
	end
	local star=K.model(center,"CentralSpawn")
	local f=C(0,1.53,15)
	A.deck(star,"Navigation medallion",f,14.4,0.16,K.ink,"Metal")
	for i=0,7 do
		local arm=f*R(0,i*math.pi/4,0)*C(0,0.12,0)
		for _,s in ipairs({-1,1}) do
			K.triangle(star,"Compass ray",arm,V(0,0,0),V(s*1.35,0,0),V(0,0,if i%2==0 then 6.6 else 4.5),0.10,if s==1 then K.gold else K.armor,"Metal")
		end
	end
	local spawn=A.object("SpawnLocation",star,"Arrival")
	spawn.Size,spawn.CFrame,spawn.Anchored=V(4,0.2,4),C(0,1.78,15),true
	spawn.CanCollide,spawn.CanTouch,spawn.Transparency,spawn.Neutral,spawn.Duration=false,false,1,true,0
	K.attach(spawn,"SafeReturn",C(0,3,0))
	local fall=K.marker(center,"FallResetZone",C(0,-75,0))
	fall:SetAttribute("TriggerY",-75)
	dome(tower)
	local lamp=A.part(tower,"StatusBeacon",V(1,0.6,1),C(0,38,17),K.teal,"Neon")
	A.light(lamp,"B2E1DF",0.75,14)
end
