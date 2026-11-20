local A=require("./architecture")
local C,V,turn=A.C,A.V,A.turn
local function spiral(parent)
	-- Two diffuse tidal arms run along opposing cubic curves above the western receiver.
	local axis=A.r.CFrame.lookAt(V(-307,88,-334),V(0,5,0))*turn(0,0,0.28)
	local core=A.globe(parent,"Galactic nucleus",axis,V(2.8,2.8,2.8),"D9CCD1","Neon")
	for _,side in ipairs({-1,1}) do
		local points={{0,0,side*18,side*7},{side*29,side*3,-side*11,-side*8},{side*7,-side*11,-side*18,side*2}}
		local anchors={}
		for _,p in ipairs(points) do
			local a=A.object("Attachment",core,"Tidal arm control")
			a.Position=V(p[1],p[2],0)
			a.Axis=V(p[3],p[4],0).Unit
			table.insert(anchors,a)
		end
		for j=1,2 do
			local b=A.object("Beam",core,"Stellar haze")
			b.Attachment0,b.Attachment1=anchors[j],anchors[j+1]
			b.CurveSize0,b.CurveSize1=15,12
			b.Width0,b.Width1=if j==1 then 9 else 6,if j==1 then 6 else 2
			b.FaceCamera,b.Segments,b.LightEmission=true,12,0.38
			b.Color=A.r.ColorSequence.new(A.r.Color3.fromHex("ACACC9"),A.r.Color3.fromHex("857EAB"))
			b.Transparency=A.r.NumberSequence.new(0.55,0.88)
			b.Texture="rbxasset://textures/particles/smoke_main.dds"
			b.TextureMode,b.TextureSpeed=A.E.TextureMode.Stretch,0
		end
	end
end
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
	local ice=C(229,77,-380)*turn(0.38,-0.24,-0.6)
	A.globe(parent,"Glacial primary",ice,V(39,39,39),"B5CED2","Marble")
	A.arc(parent,"Ice fault",ice*turn(0,0.7,0),19.6,19.6,5,106,9,0.65,0.55,"7D9DA7")
	A.arc(parent,"Subpolar rift",ice*turn(0.35,1,0.18),19.6,19.6,91,174,8,0.45,0.5,"7D9DA7")
	spiral(parent)
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
return orbits
