-- Studio bake input. This function runs once on a temporary blank place.
return function(terrain, zones)
	local function mix(a,b,t) return a+(b-a)*t end
	local function smooth(a,b,x)
		local t=math.clamp((x-a)/(b-a),0,1)
		return t*t*(3-2*t)
	end
	local function crater(x,z,c)
		local r=math.sqrt(((x-c[1])/c[3])^2+((z-c[2])/c[4])^2)
		local lip=c[6]*math.exp(-((r-1)/0.18)^2)
		return lip-c[5]*(1-smooth(0.15,1,r)),lip
	end
	local craters={
		{0,-106,55,43,18,10},{-60,-175,24,17,9,6},{74,84,21,17,6,4},
		{-111,49,15,12,5,3},{188,-65,20,16,7,4},{-215,-72,29,21,10,5},
		{25,-196,13,9,6,3},{97,198,37,25,13,6},{-83,210,26,21,9,4},
		{215,175,31,24,9,5},{-250,132,20,17,9,4},{94,-170,12,11,6,3},
	}
	-- The trail grade is continuous at shared waypoints. The cut/fill shoulder blends into the regolith.
	local routes={
		{{-61,-4,0},{-96,-4,-33},{-113,0,-80},{-148,3,-146}},
		{{61,-4,0},{95,-4,-27},{106,0,-80},{154,1,-142}},
		{{-113,0,-80},{-75,2,-107},{-46,5,-143},{0,6,-150},{44,4,-141},{78,1,-111},{106,0,-80}},
		{{-96,-4,-33},{-149,-5,-15},{-205,-3,5},{-257,-2,4}},
		{{95,-4,-27},{154,-5,-13},{202,-4,4},{257,-3,2}},
		{{-61,-4,0},{-79,-5,52},{-116,-5,87},{-144,-5,124}},
		{{61,-4,0},{84,-5,57},{122,-5,95},{145,-5,126}},
	}
	local colors={
		Slate="666878",Rock="8D8999",Basalt="45465B",Ground="A49EA3",Sandstone="B8A294",Sand="AAA1A4",
	}
	for name,hex in pairs(colors) do terrain:SetMaterialColor(Enum.Material[name],Color3.fromHex(hex)) end
	local function sample(x,z)
		local radial=math.sqrt((x/370)^2+((z+15)/265)^2)
		local grain=math.noise(x/47,z/47,8.3)
		local edge=radial+0.037*math.noise(x/50,z/50)
		local rim=smooth(0.80,0.99,edge)*(18+13*math.noise(x/43,z/43,2))
		local mountains=41*math.exp(-((z+220+12*math.sin(x/36))/26)^2)*(0.75+0.30*math.sin(x/23))
		local y=-8+grain*9+math.noise(x/14,z/14)*2+rim+mountains
		local exposed=rim+mountains
		for _,c in ipairs(craters) do
			local delta,lip=crater(x,z,c)
			y+=delta
			exposed=math.max(exposed,lip)
		end
		local mat=if exposed>16 then Enum.Material.Basalt elseif exposed>5 then Enum.Material.Slate elseif grain>0.19 then Enum.Material.Rock else Enum.Material.Ground
		local near,grade=math.huge,0
		for _,route in ipairs(routes) do
			for i=2,#route do
				local a,b=route[i-1],route[i]
				local dx,dz=b[1]-a[1],b[3]-a[3]
				local t=math.clamp(((x-a[1])*dx+(z-a[3])*dz)/(dx*dx+dz*dz),0,1)
				local d=math.sqrt((x-a[1]-dx*t)^2+(z-a[3]-dz*t)^2)
				if d<near then near,grade=d,mix(a[2],b[2],t) end
			end
		end
		y=mix(grade,y,smooth(5,15,near))
		if near<5+grain then mat=Enum.Material.Sandstone end
		for _,parcel in ipairs(zones) do
			local p,s=parcel.center,parcel.size
			local outside=math.max(math.abs(x-p[1])-s[1]/2,math.abs(z-p[3])-s[2]/2)
			y=mix(p[2],y,smooth(-1,12,outside))
			if outside<0 then mat=Enum.Material.Ground end
		end
		if math.abs(x)<26 and z>24 then y=math.min(y,-6) end
		y-=smooth(0.97,1.11,edge)*63
		return y,mat
	end
	-- Four-stud native voxels, written in 64-stud strips to bound peak memory.
	for x0=-416,415,64 do
		local mats,occ={},{}
		local lo,hi=-80,80
		for i=1,16 do
			mats[i],occ[i]={},{}
			for j=1,(hi-lo)/4 do mats[i][j],occ[i][j]={},{} end
			for k=1,160 do
				local top,material=sample(x0+4*i-2,-320+4*k-2)
				for j=1,(hi-lo)/4 do
					local fill=math.clamp((top-(lo+4*(j-1)))/4,0,1)
					occ[i][j][k]=fill
					mats[i][j][k]=if fill==0 then Enum.Material.Air else material
				end
			end
		end
		terrain:WriteVoxels(Region3.new(Vector3.new(x0,lo,-320),Vector3.new(x0+64,hi,320)),4,mats,occ)
	end
end
