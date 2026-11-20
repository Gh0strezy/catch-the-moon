local A=require("./architecture")
local C,V,turn=A.C,A.V,A.turn
local orbits=require("./celestial")
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
