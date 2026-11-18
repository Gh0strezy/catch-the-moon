local A=require("./architecture")
local C,V,turn=A.C,A.V,A.turn
local function bridge(parent,side)
	local a,b=V(30*side,1.42,0),V(50*side,-3.65,0)
	A.strut(parent,"Basalt ramp",a-V(0,0.35,0),b-V(0,0.35,0),11,0.7,A.stone,"Concrete",true)
	for _,z in ipairs({-5.15,5.15}) do
		local offset=V(0,0.18,z)
		A.strut(parent,"Bronze curb",a+offset,b+offset,0.32,0.33,A.brass)
		for i=0,2 do
			local p=a:Lerp(b,i/2)+V(0,0,z)
			A.part(parent,"Newel",V(0.48,2.1,0.48),C(p+V(0,1,0)),A.steel)
		end
		A.strut(parent,"Handrail",a+V(0,2,z),b+V(0,2,z),0.21,0.24,A.brass)
	end
	local sign=C(b+V(0,2,-6.6))*turn(0,if side>0 then math.pi/2 else -math.pi/2,0)
	A.plaque(parent,sign,8,if side>0 then "КАРТОГРАФ  •  ПРИЗМЫ" else "ПАССАЖ  •  БУХТА")
	A.part(parent,"Guide post",V(0.45,2.3,0.45),sign*C(0,-1.2,0),A.steel)
end
local function meridian(parent)
	local frame=C(0,1.4,-22)
	for _,x in ipairs({-18,18}) do
		A.part(parent,"Ashlar footing",V(5,2.8,5.5),frame*C(x,1,0),A.stone,"Limestone",true)
		A.part(parent,"Cast shoe",V(3.9,1.1,4.2),frame*C(x,2.4,0),A.ink)
		A.deck(parent,"Bearing",frame*C(x,3.2,0)*turn(math.pi/2,0,0),3.5,4,A.brass,"Metal")
	end
	local base=frame*C(0,3.2,0)
	A.arc(parent,"Porcelain meridian",base,18,19,0,180,18,1.3,1.4,A.porcelain,"Limestone")
	A.arc(parent,"Bronze limb",base*C(0,0,1),18.3,19.3,0,180,18,0.38,0.42,A.brass)
	A.arc(parent,"Recessed scale",base*C(0,0,0.77),16.9,17.9,12,168,14,0.21,0.21,A.ink)
	for i=1,11 do
		local a=math.pi*i/12
		A.part(parent,"Hour index",V(0.15,if i%3==0 then 1.15 else 0.6,0.18),
			base*C(17.6*math.cos(a),18.6*math.sin(a),0.84)*turn(0,0,a-math.pi/2),A.brass)
	end
	A.globe(parent,"Zenith sight",base*C(0,20.25,0),V(1.3,1.3,1.3),A.lamp,"Neon")
end
local function exchange(parent,f)
	A.part(parent,"Terrazzo terrace",V(32,0.8,33),f*C(0,-0.03,0),A.stone,"Limestone",true)
	-- A clerestory separates two pitched roof leaves. The eastern aisle is open to the ramp.
	for _,z in ipairs({-11,0,11}) do
		for _,x in ipairs({-12,0}) do
			A.part(parent,"Fluted column",V(0.9,9,0.9),f*C(x,4.9,z),A.ink,"Metal",true)
			A.part(parent,"Column capital",V(1.7,0.6,1.7),f*C(x,9.15,z),A.brass)
		end
		A.strut(parent,"Roof truss",f:PointToWorldSpace(V(-14,10,z)),f:PointToWorldSpace(V(2,9.2,z)),0.5,0.6,A.steel)
	end
	for _,leaf in ipairs({{-11,9.9,7.8,-7},{-2,9.7,8.4,9}}) do
		local roof=f*C(leaf[1],leaf[2],0)*turn(0,0,math.rad(leaf[4]))
		A.part(parent,"Folded zinc roof",V(leaf[3],0.55,29),roof,A.steel)
		A.part(parent,"Bronze fascia",V(leaf[3],0.38,0.22),roof*C(0,-0.14,14.4),A.brass)
	end
	A.part(parent,"Archive wall",V(0.85,7.8,23),f*C(-13,4.2,0),A.porcelain,"Limestone",true)
	for _,z in ipairs({-7,5}) do
		A.part(parent,"Exhibition counter",V(3.7,2.3,6.4),f*C(-9,1.55,z),A.steel,"Metal",true)
		A.part(parent,"Stone counter top",V(4,0.34,6.8),f*C(-9,2.85,z),A.stone,"Marble")
	end
	A.plaque(parent,f*C(-4,8,12.3)*turn(0,math.pi,0),12,"ПАССАЖ  /  СИРЕНА")
	local lamp=A.part(parent,"Amber soffit",V(0.34,0.16,19),f*C(-6,9,0),A.lamp,"Neon")
	A.light(lamp,A.lamp,1,17)
end
local function office(parent,f)
	A.deck(parent,"Survey rotunda",f*C(0,-0.18,0),32,1,A.stone,"Limestone",true)
	-- An open crescent in plan leaves the desk visible from the observatory.
	for i=-3,3 do
		local a=math.rad(i*22)
		local bay=f*C(12*math.cos(a),0,12*math.sin(a))*turn(0,-a,0)
		A.part(parent,"Masonry parapet",V(1.2,2.6,4.8),bay*C(0,1.55,0),A.porcelain,"Limestone",true)
		A.part(parent,"Window mullion",V(0.35,4.6,0.35),bay*C(0,5.1,-2.2),A.brass)
		local glass=A.part(parent,"Smoked glazing",V(0.24,4.3,4.6),bay*C(0,5.05,0),A.glass,"Glass",true)
		glass.Transparency=0.35
		A.part(parent,"Cantilevered cornice",V(6,0.65,5.7),bay*C(-1.7,7.55,0),A.steel)
	end
	A.deck(parent,"Survey desk",f*C(5,1.65,0),5,2.5,A.ink,"Metal",true)
	A.deck(parent,"Chart table",f*C(5,3,0),6.1,0.35,A.brass,"Metal")
	A.globe(parent,"Cartographer globe",f*C(5,4.35,0),V(2.5,2.5,2.5),A.glass,"Glass")
	A.arc(parent,"Globe meridian",f*C(5,4.35,0)*turn(0,0,-0.25),1.6,1.6,-180,125,12,0.13,0.13,A.brass)
	A.plaque(parent,f*C(8,6.8,4)*turn(0,math.pi/2,0),6,"КАРТОГРАФ")
end
return {build=function(hub)
	local main=A.object("Model",hub,"MeridianObservatory")
	meridian(main)
	bridge(main,-1)
	bridge(main,1)
	for _,d in ipairs({{66,-4.5,7,A.ink},{68,-7.8,1.2,A.brass},{71,-9.1,2,A.stone}}) do
		A.deck(main,"Foundation drum",C(0,d[2],0),d[1],d[3],d[4],"Slate",true)
	end
end,Exchange=exchange,FieldOffice=office}
