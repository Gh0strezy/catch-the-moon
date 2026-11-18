local fs=require("@lune/fs")
local A=require("./world/architecture")
local hub=require("./world/meridian")
local sites=require("./world/destinations")
local zones=require("./world/zones")
local guide=require("./world/zone-guide")
local root=A.object("Model",nil,"World")
local groups={}
for _,name in ipairs({"MainHub","MoonSurface","FutureLocations","ReservedAreas","DistantSky"}) do
	groups[name]=A.object("Folder",root,name)
end
hub.build(groups.MainHub)
require("./world/horizon")(groups.MoonSurface,groups.DistantSky)
local used={}
for _,zone in ipairs(zones) do
	assert(not used[zone.id],"Duplicate parcel "..zone.id)
	used[zone.id]=true
	local m=A.object("Model",groups[zone.group],zone.id.."_"..zone.key)
	local x,y,z=unpack(zone.center)
	local f=A.C(x,y,z)
	m:SetAttribute("ZoneId",zone.id)
	m:SetAttribute("ZoneName",zone.name)
	m:SetAttribute("ZoneStatus",zone.status)
	m:SetAttribute("ZoneDescription",zone.purpose)
	m:SetAttribute("ZoneCenter",f.Position)
	m:SetAttribute("ZoneSize",A.r.Vector2.new(unpack(zone.size)))
	-- Keep each rectangular land grant aligned to the world axes. Portals face the approach.
	local inward=if x>0 then math.pi/2 else -math.pi/2
	if zone.group=="MainHub" then hub[zone.key](m,f)
	elseif zone.group=="ReservedAreas" then sites.reserve(m,f,unpack(zone.size))
	else sites[zone.key](m,f*A.turn(0,inward,0),zone.size[2],zone.size[1]) end
end
fs.writeFile("world/Meridian.rbxmx",A.r.serializeModel({root},true))
fs.writeFile("WORLD_ZONES.md",guide())
