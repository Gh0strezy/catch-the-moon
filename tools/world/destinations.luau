local A=require("./architecture")
local C,V,turn=A.C,A.V,A.turn
local D={}
local function crystal(parent,frame,height,width)
	-- A six-sided blade with an asymmetric cleavage plane and a pale edge.
	for i=0,2 do
		local face=frame*turn(0,math.pi*i/3,0)
		A.part(parent,"Prism face",V(width, height,width*0.56),face*C(0,height/2,0),
			({"688A99","91B3B8","ADC7C7"})[i+1],"Marble",true)
		A.part(parent,"Cleaved crown",V(width,height*0.26,width*0.56),face*C(0,height*1.13,0),
			"AFC5C5","Marble",false,"WedgePart")
	end
end
function D.GlacierPrism(parent,f,w,h)
	local dock=f*C(0,0,-h*0.34)
	A.deck(parent,"Mineral landing",dock,17,0.8,"81838D","Slate",true)
	A.socket(parent,dock*C(0,0.38,0))
	for _,g in ipairs({{-8,1,13,2.5,-12},{-11,5,7,2.2,12},{9,1,9,2.4,14},
		{w*0.36,h*0.31,24,5,-17},{w*0.39,h*0.23,13,3,12},{w*0.28,h*0.36,9,2.5,25}}) do
		crystal(parent,f*C(g[1],-0.6,g[2])*turn(0,0,math.rad(g[5])),g[3],g[4])
	end
	A.arc(parent,"Split induction hoop",dock*C(0,0.45,0),7,9,24,151,11,0.65,0.65,A.steel)
	local facet=A.globe(parent,"Resonance lens",dock*C(0,8.9,0),V(0.7,0.7,0.7),"BFDBDA","Neon")
	local dust=A.object("ParticleEmitter",facet,"Suspended ice")
	dust.Texture="rbxasset://textures/particles/sparkles_main.dds"
	dust.Color=A.r.ColorSequence.new(A.r.Color3.fromHex("B8DCDC"))
	dust.Size=A.r.NumberSequence.new(0.18)
	dust.Transparency=A.r.NumberSequence.new({
		A.r.NumberSequenceKeypoint.new(0,1),A.r.NumberSequenceKeypoint.new(0.45,0.38),A.r.NumberSequenceKeypoint.new(1,1)})
	dust.Rate,dust.Speed,dust.Lifetime=1.4,A.r.NumberRange.new(0.4,1.1),A.r.NumberRange.new(2,4)
	dust.SpreadAngle,dust.LightEmission=A.r.Vector2.new(65,65),0.45
end
function D.SpiralSound(parent,f,w,h)
	local dock=f*C(0,0,-h*0.34)
	A.deck(parent,"Pale basalt dais",dock,16,0.8,A.stone,"Slate",true)
	A.socket(parent,dock*C(0,0.4,0))
	local frame=dock*C(-7,6,2)*turn(0,-0.35,-0.42)
	A.arc(parent,"Helical receiver",frame,8,8,-62,222,19,0.85,0.95,A.brass)
	A.arc(parent,"Concentric receiver",frame*C(0,0,0.6),6.6,6.6,-35,196,16,0.35,0.42,A.porcelain)
	A.strut(parent,"Receiver pedestal",dock.Position+V(-3,0,0),frame.Position,2.2,2.5,A.steel,"Metal",true)
	for i=1,3 do
		local p=f*C(-w*0.40,0,(i-2)*h*0.29)
		A.part(parent,"Signal mast",V(0.45,6+i,0.45),p*C(0,3+i/2,0),A.steel)
		A.globe(parent,"Ceramic insulator",p*C(0,6+i,0),V(1,1,1),A.porcelain,"CeramicTiles")
	end
end
function D.BeltHarbor(parent,f,w,h)
	local dock=f*C(0,0,-h*0.32)
	A.part(parent,"Freight landing",V(18,0.8,19),dock,A.steel,"DiamondPlate",true)
	A.socket(parent,dock*C(0,0.4,0))
	for _,x in ipairs({-8,8}) do
		A.part(parent,"Channel rail",V(0.48,0.32,29),dock*C(x,0.55,4),A.brass)
		A.strut(parent,"Portal leg",dock:PointToWorldSpace(V(x,0,3)),dock:PointToWorldSpace(V(x*0.8,13,3)),1.1,1.2,A.steel,"Metal",true)
	end
	A.part(parent,"Box girder",V(16,1.35,2.2),dock*C(0,13,3),A.porcelain)
	A.part(parent,"Parked hoist",V(3,1.15,2.6),dock*C(-4,11.8,3),A.brass)
	for i=1,3 do
		local p=f*C(w*0.39,0,h*(0.22+i*0.06))
		A.part(parent,"Freight sleeper",V(11,0.75,2),p,A.stone,"Concrete",true)
	end
end
function D.Umbra(parent,f,w,h)
	local dock=f*C(0,0,-h*0.32)
	A.deck(parent,"Shadow dial",dock,18,0.9,"555364","Slate",true)
	A.socket(parent,dock*C(0,0.45,0))
	for _,side in ipairs({-1,1}) do
		local leaf=dock*C(side*6,7,2)*turn(0,0,side*0.10)
		A.part(parent,"Obsidian shutter",V(2.1,15,3.2),leaf,"414153","Basalt",true)
		A.part(parent,"Polished inner edge",V(0.19,12,2.4),leaf*C(-side*1.08,0,0),"AF9AAA","Metal")
	end
	A.arc(parent,"Eclipse crown",dock*C(0,10,2),7.2,8,32,148,11,1,1,A.steel)
	A.globe(parent,"Occulting disc",f*C(-w*0.38,8,h*0.27),V(14,14,14),"484554","Slate")
	A.arc(parent,"Limb reflector",f*C(-w*0.38,8,h*0.27)*turn(0,0,-0.4),7.8,7.8,12,160,12,0.42,0.36,A.brass)
end
function D.reserve(parent,f,w,h)
	-- Two dressed survey stones mark the threshold. The entire inner bench stays open.
	for _,side in ipairs({-1,1}) do
		local p=f*C(side*w*0.40,0,-h*0.40)
		A.part(parent,"Boundary ashlar",V(4.2,1.8,2.2),p*C(0,0.55,0),A.stone,"Limestone",true)
		A.part(parent,"Survey pin",V(0.5,0.22,1),p*C(0,1.52,0),A.brass)
	end
end
return D
