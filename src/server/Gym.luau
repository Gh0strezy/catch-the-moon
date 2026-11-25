local TweenService = game:GetService("TweenService")
local Catalog = require(game.ReplicatedStorage.MoonCatalog)

local Gym = {}
local platform = workspace.Observatory.Stations:WaitForChild("Gym")
local origin = CFrame.new(platform.Position)
local machine = Instance.new("Model")
machine.Name = "ResistanceTrainer"
local function part(name, size, frame, color, shape, material)
	local piece = Instance.new("Part")
	piece.Name, piece.Size, piece.CFrame = name, size, origin * frame
	piece.Shape = shape or Enum.PartType.Block
	piece.Color, piece.Material = Color3.fromHex(color), material or Enum.Material.Metal
	piece.Anchored, piece.CanCollide, piece.CanTouch = true, false, false
	piece.Parent = machine
	return piece
end

part("BenchFoot", Vector3.new(3, 0.24, 2.8), CFrame.new(0, 0.48, 0.55), "293852")
part("BenchPost", Vector3.new(0.7, 0.85, 0.7), CFrame.new(0, 0.98, 0.6), "53637F")
part("SeatPad", Vector3.new(2.4, 0.25, 1.55), CFrame.new(0, 1.35, 0.7), "202B43")
part("BackPad", Vector3.new(2.15, 2, 0.22), CFrame.new(0, 2.22, 1.44), "202B43")
local accents = {}
for _, x in ipairs({-2.12, 2.12}) do
	part("Rail", Vector3.new(0.34, 3.9, 0.46), CFrame.new(x, 2.42, -0.76), "53637F")
	part("Counterweight", Vector3.new(0.8, 0.63, 0.63), CFrame.new(x, 3.29, -0.76), "374661", Enum.PartType.Cylinder)
	table.insert(accents, part("RailLight", Vector3.new(0.1, 2.3, 0.12), CFrame.new(x, 2.45, -0.5),
		Catalog.GymTiers[1].color, nil, Enum.Material.Neon))
end
local bar = part("LiftBar", Vector3.new(4.4, 0.19, 0.19), CFrame.new(0, 2.65, -0.76), "CDD5E1", Enum.PartType.Cylinder)
local rest = bar.CFrame
local raised = rest + Vector3.new(0, 0.96, -0.12)
local grips = {}
for side, x in pairs({Left = -0.95, Right = 0.95}) do
	local grip = part(side .. "Grip", Vector3.new(0.52, 0.28, 0.28), CFrame.new(x, 2.65, -0.76),
		"202B43", Enum.PartType.Cylinder)
	local weld = Instance.new("WeldConstraint")
	weld.Part0, weld.Part1, weld.Parent = bar, grip, grip
	grip.Anchored = false
	local target = Instance.new("Attachment")
	target.Parent = grip
	grips[side] = target
end

local seat = Instance.new("Seat")
seat.Name, seat.Size, seat.CFrame = "WorkoutSeat", Vector3.new(2.4, 0.25, 1.55), origin * CFrame.new(0, 1.35, 0.7)
seat.Transparency, seat.Anchored, seat.CanCollide, seat.CanTouch = 1, true, false, false
seat.Parent = machine
machine.Parent = platform

local workout
local function setColor(tier)
	local color = Color3.fromHex(Catalog.GymTiers[tier].color)
	for _, light in ipairs(accents) do light.Color = color end
end

function Gym.active(player)
	return workout ~= nil and workout.player == player
end

function Gym.stop(player)
	if not Gym.active(player) then return end
	local active = workout
	workout = nil
	if active.tween then active.tween:Cancel() end
	for _, control in ipairs(active.controls) do control:Destroy() end
	if seat.Occupant == active.humanoid then
		local weld = seat:FindFirstChild("SeatWeld")
		if weld then weld:Destroy() end
		active.humanoid.Sit = false
	end
	bar.CFrame = rest
	setColor(1)
	active.onStop()
end

function Gym.start(player, tier, onRep, onStart, onStop)
	if workout or seat.Occupant then return false end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 or humanoid.Sit then return false end
	local active = {player = player, humanoid = humanoid, controls = {}, onStop = onStop}
	workout = active
	seat:Sit(humanoid)
	task.spawn(function()
		local deadline = os.clock() + 0.6
		while workout == active and seat.Occupant ~= humanoid and os.clock() < deadline do task.wait() end
		if workout ~= active then return end
		if seat.Occupant ~= humanoid then
			Gym.stop(player)
			return
		end
		setColor(tier)
		for side, target in pairs(grips) do
			local upperArm = character:FindFirstChild(side .. "UpperArm")
			local hand = character:FindFirstChild(side .. "Hand")
			if upperArm and hand then
				local control = Instance.new("IKControl")
				control.Type, control.ChainRoot, control.EndEffector = Enum.IKControlType.Position, upperArm, hand
				control.Target, control.SmoothTime, control.Parent = target, 0.08, humanoid
				table.insert(active.controls, control)
			end
		end
		onStart()
		while workout == active and seat.Occupant == humanoid and humanoid.Health > 0 do
			for _, frame in ipairs({raised, rest}) do
				active.tween = TweenService:Create(bar, TweenInfo.new(0.58, Enum.EasingStyle.Sine), {CFrame = frame})
				active.tween:Play()
				active.tween.Completed:Wait()
				if workout ~= active then return end
				if seat.Occupant ~= humanoid or humanoid.Health <= 0 then
					Gym.stop(player)
					return
				end
			end
			if not onRep() then break end
		end
		if workout == active then Gym.stop(player) end
	end)
	return true
end

seat:GetPropertyChangedSignal("Occupant"):Connect(function()
	if workout and seat.Occupant ~= workout.humanoid and workout.tween then Gym.stop(workout.player) end
end)

return Gym
