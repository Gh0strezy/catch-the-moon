local A=require("../world/architecture")
local K={A=A,C=A.C,V=A.V,R=A.turn}
K.ink="253346"
K.armor="CAD7DA"
K.steel="5D7386"
K.dark="374A60"
K.teal="77DAD5"
K.glass="739CAC"
K.violet="A7A5DA"
K.gold="DDB783"
K.deckY=1.45
K.radius=174
K.pitch=16
function K.model(parent,name) return A.object("Model",parent,name) end
function K.marker(parent,name,cf)
	local p=A.part(parent,name,A.V(0.2,0.2,0.2),cf,K.ink)
	p.Transparency,p.CastShadow=1,false
	return p
end
function K.attach(parent,name,cf)
	local a=A.object("Attachment",parent,name)
	a.CFrame=cf or A.C()
	return a
end
function K.glassPanel(parent,name,size,cf,solid)
	local p=A.part(parent,name,size,cf,K.glass,"Glass",solid)
	p.Transparency,p.CastShadow=0.48,false
	return p
end
-- Extrude a right triangle in XZ. A WedgePart's tall edge is at local +Z.
function K.triangle(parent,name,frame,corner,legA,legB,height,color,mat,solid)
	local a,b=legA-corner,legB-corner
	local y,z=a.Unit,-b.Unit
	local pose=A.r.CFrame.fromMatrix((legA+legB)/2,y:Cross(z),y,z)
	return A.part(parent,name,A.V(height,a.Magnitude,b.Magnitude),frame*pose,color,mat,solid,"WedgePart")
end
function K.hull(parent,f,scale,y,thickness,color)
	local width,back,shoulder,tip=28*scale,-23*scale,11*scale,33*scale
	local localFrame=f*A.C(0,y,0)
	A.part(parent,"Keel box",A.V(width*2,thickness,shoulder-back),localFrame*A.C(0,0,(back+shoulder)/2),color)
	for _,s in ipairs({-1,1}) do
		K.triangle(parent,"Prow chine",localFrame,A.V(0,0,shoulder),A.V(s*width,0,shoulder),A.V(0,0,tip),thickness,color,"Metal")
	end
end
return K
