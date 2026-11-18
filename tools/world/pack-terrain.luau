-- Retain the local voxel grid and its palette. Studio exports extra metadata for cloud terrain.
local fs=require("@lune/fs")
local r=require("@lune/roblox")
local args=require("@lune/process").args
local input=r.deserializeModel(fs.readFile(args[1]))[1]
assert(input.ClassName=="Terrain","Expected a Terrain export")
assert(#input.SmoothGrid>0,"Expected locally stored voxels")
fs.writeFile(args[2],r.serializeModel({input}))
