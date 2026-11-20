local TweenService=game:GetService("TweenService")
local tower=workspace:WaitForChild("World"):WaitForChild("CentralStation"):WaitForChild("Observatory")
local roof=tower:WaitForChild("RetractableRoof")
-- Both carriages share a stroke and resting interval. No per-frame script work.
local cycle=TweenInfo.new(6,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true,4)
for _,leaf in roof:GetChildren() do
	local travel=Vector3.new(leaf:GetAttribute("TravelX"),0,0)
	for _,part in leaf:GetChildren() do
		if part:IsA("BasePart") then
			TweenService:Create(part,cycle,{CFrame=part.CFrame+travel}):Play()
		end
	end
end
local light=tower:WaitForChild("StatusBeacon"):WaitForChild("Reflected light")
TweenService:Create(light,TweenInfo.new(3.5,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{Brightness=1.05}):Play()
