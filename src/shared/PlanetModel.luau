local PlanetModel = {}

-- All dimensions below are relative to a unit sphere. Both scenes scale the finished model.
function PlanetModel.new(appearance, radius)
	local model = Instance.new("Model")
	local axis = CFrame.Angles(math.rad(16), 0, math.rad(appearance.tilt or 0))
	local function part(name, shape, size, frame, color)
		local p = Instance.new("Part")
		p.Name, p.Shape, p.Size, p.CFrame = name, shape, size, axis * frame
		p.Color, p.Material = Color3.fromHex(color), Enum.Material.SmoothPlastic
		p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = true, false, false, false, false
		p.Parent = model
		return p
	end
	local ball = part("Surface", Enum.PartType.Ball, Vector3.one * 2, CFrame.identity, appearance.color)
	-- Pivot about the unrotated centre so PivotTo preserves the axial tilt.
	ball.PivotOffset = axis:Inverse()
	model.PrimaryPart = ball

	-- A shallow ellipsoid tangent to the globe, with local X pointing east.
	local function patch(name, latitude, longitude, width, height, color, lift)
		local lat, lon = math.rad(latitude), math.rad(longitude)
		local east = Vector3.new(math.cos(lon), 0, -math.sin(lon))
		local normal = Vector3.new(math.cos(lat)*math.sin(lon), math.sin(lat), math.cos(lat)*math.cos(lon))
		local frame = CFrame.fromMatrix(normal * (0.966 + (lift or 0)), east, normal:Cross(east), normal)
		part(name, Enum.PartType.Ball, Vector3.new(width, height, 0.11), frame, color)
	end
	for _, band in ipairs(appearance.bands or {}) do
		local lat = math.rad(band[1])
		local diameter = 2 * math.cos(lat) + 0.016
		local frame = CFrame.new(0, math.sin(lat), 0) * CFrame.Angles(0, 0, math.pi/2)
		part("Band", Enum.PartType.Cylinder, Vector3.new(band[2], diameter, diameter), frame, band[3])
	end
	for _, detail in ipairs(appearance.parts or {}) do
		local frame = CFrame.new(table.unpack(detail.position))
		if detail.rotation then
			local x, y, z = table.unpack(detail.rotation)
			frame *= CFrame.Angles(math.rad(x), math.rad(y), math.rad(z))
		end
		part(detail.name, Enum.PartType[detail.shape], Vector3.new(table.unpack(detail.size)), frame, detail.color)
	end
	for _, detail in ipairs(appearance.patches or {}) do
		patch("Marking", table.unpack(detail))
	end
	local craters = appearance.craters
	if craters then
		local rng = Random.new(craters.seed)
		for i = 1, craters.count do
			local latitude = math.deg(math.asin(1 - (i - 0.5) * 2 / craters.count))
			local longitude = i * 137.5
			local size = rng:NextNumber(0.12, 0.31)
			patch("CraterRim", latitude, longitude, size, size, craters.rim)
			patch("CraterFloor", latitude, longitude, size*0.72, size*0.72, craters.floor, 0.009)
		end
	end
	for _, ring in ipairs(appearance.rings or {}) do
		local segments = 36
		local length = 2 * ring.outer * math.tan(math.pi / segments)
		for i = 1, segments do
			local frame = CFrame.Angles(0, i * 2 * math.pi / segments, 0)
				* CFrame.new(0, 0, (ring.inner + ring.outer)/2)
			part("Ring", Enum.PartType.Block, Vector3.new(length, 0.025, ring.outer-ring.inner), frame, ring.color)
		end
	end
	model:ScaleTo(radius)
	return model
end

return PlanetModel
