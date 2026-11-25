local fs=require("@lune/fs")
local K=require("./station/kit")
local A=K.A
local berths=require("./station/berths")
local world=K.model(nil,"World")
require("./station/hub")(world)
local bridges=A.object("Folder",world,"Bridges")
local bases=A.object("Folder",world,"PlayerBases")
for i=1,8 do
	local axis=A.turn(0,math.rad(22.5+(i-1)*45),0)
	berths.bridge(bridges,axis,i)
	berths.base(bases,axis,i)
end
require("./station/space")(world)
local floor=berths.floor(nil,"FloorTemplate",K.C())
-- StationPorts.rbxm is the editable gameplay layout for the central deck.
for name,model in pairs({OrbitalStation=world,FloorTemplate=floor}) do
	fs.writeFile("world/"..name..".rbxm",A.r.serializeModel({model}))
end
fs.writeFile("WORLD_ZONES.md",require("./station/zone-guide")())
