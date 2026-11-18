local A=require("./architecture")
local C,V,turn=A.C,A.V,A.turn
local function orbits(parent)
	-- Ringed primary seen beyond the western receiver, clear of the player's capture target.
	local frame=C(-217,117,-362)*turn(0,0,-0.28)
	A.globe(parent,"Ochre primary",frame,V(76,76,76),"C0A18A","SmoothPlastic")
	for _,belt in ipairs({{-11,3.6,"AB8B7A"},{-6,1.4,"D3B7A0"},{9,2,"A88E85"},{14,1.2,"D7BC9D"}}) do
		local diameter=2*math.sqrt(38^2-belt[1]^2)+0.55
		A.deck(parent,"Latitude band",frame*C(0,belt[1],0),diameter,belt[2],belt[3],"SmoothPlastic")
	end
	local rings=frame*turn(math.rad(72),0,0)
	A.arc(parent,"Broad particulate ring",rings,59,59,0,360,40,2.5,2.7,"BBAD99")
	A.arc(parent,"Outer braided ring",rings,63.5,63.5,0,360,40,0.67,0.67,"D2C7B8")
	A.globe(parent,"Shepherd moon",frame*C(73,9,7),V(5,5,5),"BFB5A9","Slate")
	A.globe(parent,"Umbra primary",C(-383,65,159),V(63,63,63),"555365","Slate")
	A.arc(parent,"Crescent limb",C(-383,65,159)*turn(0,1.3,-0.4),32.3,32.3,38,167,15,0.65,0.7,"CFADA1")

	-- Positions follow a single inclined orbital belt; each boulder has two fractured faces.
	for i=1,15 do
		local a=math.rad(i*8-61)
		local p=C(352+24*math.cos(i*1.7),36+0.28*i*4+8*math.sin(a),-15+122*math.sin(a))
		local scale=2.2+(i*7%10)*0.65
		for j=1,2 do
			A.part(parent,"Belt fragment",V(scale*(1+j*0.2),scale,scale*1.4),p*turn(i*0.3,j*1.9,i*0.6),
				if j==1 then "797784" else "8B8390","Slate",false,"WedgePart")
		end
	end
end
local function bluff(parent,x,y,z,s,yaw)
	local base=C(x,y,z)*turn(0,yaw,0)
	for _,slab in ipairs({{0,0,0,12,4,8},{1,2.7,0.6,10,3.1,7},{2.1,4.9,0.8,6.5,2,6}}) do
		local frame=base*C(slab[1]*s,slab[2]*s,slab[3]*s)*turn(0,0,-0.055)
		local size=V(slab[4]*s,slab[5]*s,slab[6]*s)
		A.part(parent,"Fractured basalt bed",size,frame,"656475","Basalt",true,"WedgePart")
		A.part(parent,"Exposed bedding plane",V(size.X,0.25*s,size.Z*0.52),frame*C(0,-size.Y*0.4,0),"908695","Slate")
	end
end
return function(surface,sky)
	orbits(sky)
	-- Set outcrops into the outer edges of graded parcels, away from the approach routes.
	for _,v in ipairs({{-191,3,-177,1.35,0.5},{-186,3,-182,0.9,0.35},{192,1,-177,1.55,1.6},
		{294,-3,43,1.9,2.2},{-294,-2,43,1.3,0.2},{-192,-5,154,0.9,2.2},{192,-5,157,1.4,1.3}}) do bluff(surface,unpack(v)) end
	local overlook=A.object("Model",surface,"RimBelvedere")
	local f=C(0,6,-150)
	A.deck(overlook,"Rim terrace",f,16,1.2,A.stone,"Limestone",true)
	for _,x in ipairs({-5,5}) do
		A.part(overlook,"Map rail pier",V(0.65,3.2,0.65),f*C(x,1.6,4),A.steel,"Metal",true)
	end
	A.part(overlook,"Panorama rail",V(11,0.35,0.55),f*C(0,3.2,4),A.brass)
	A.plaque(overlook,f*C(0,2.3,4),8,"МОРЕ ТЕНИ")
end
