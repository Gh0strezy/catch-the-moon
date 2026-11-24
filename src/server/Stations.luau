local Catalog = require(game.ReplicatedStorage.MoonCatalog)
local Stations = {}
local hub = workspace:WaitForChild("Observatory")
local static = hub:WaitForChild("Stations")
local catchRing = hub:WaitForChild("TelescopeDeck"):WaitForChild("Azimuth scale")
local gallery = Instance.new("Folder")
gallery.Name, gallery.Parent = "Gallery", hub
local plots, owners, floors = {}, {}, {}

local function block(parent,name,size,frame,color,material)
	local p=Instance.new("Part")
	p.Name,p.Size,p.CFrame=name,size,frame
	p.Color,p.Material=Color3.fromHex(color),material or Enum.Material.Metal
	p.Anchored,p.CanTouch,p.Parent=true,false,parent
	return p
end

local function sign(part,title,color,height)
	local board=Instance.new("BillboardGui")
	board.Name,board.Size,board.StudsOffset="Sign",UDim2.fromOffset(166,35),Vector3.new(0,height,0)
	board.AlwaysOnTop,board.MaxDistance,board.Parent=true,65,part
	local label=Instance.new("TextLabel")
	label.Size,label.BackgroundColor3,label.BackgroundTransparency=UDim2.fromScale(1,1),Color3.fromHex("152038"),0.12
	label.Font,label.TextSize,label.TextColor3=Enum.Font.GothamBold,15,Color3.fromHex(color)
	label.Text,label.Parent=title,board
	local corner=Instance.new("UICorner")
	corner.CornerRadius,corner.Parent=UDim.new(0,8),label
	return label
end

local function prompt(part,key,object,action,hold)
	local mount=Instance.new("Attachment")
	mount.Position=Vector3.new(0,0,0)
	mount.Parent=part
	local p=Instance.new("ProximityPrompt")
	p.Name,p.ObjectText,p.ActionText="StationPrompt",object,action
	p.HoldDuration,p.MaxActivationDistance,p.RequiresLineOfSight=hold or 0,10,false
	p:SetAttribute("MoonStation",key)
	p.Parent=mount
	return p
end

local labels={
	Catch={"Телескоп","Искать планету","F1CB88",7},
	Luck={"Удача","Улучшения","93E7CC",5.4},
	Speed={"Скорость","Улучшения","FFC299",5.6},
	Gym={"Тренажёр силы","Поднять штангу","C1BDFF",5.8},
}
for key,info in pairs(labels) do
	local p=static:WaitForChild(key)
	sign(p,info[1],info[3],info[4])
	prompt(p,key,info[1],info[2],if key=="Gym" then 0.55 else 0)
end

local entry=block(gallery,"GalleryEntrance",Vector3.new(12,0.6,8),CFrame.new(0,1.15,33),"44526A")
sign(entry,"Галерея планет","EBD7AD",6)

function Stations.assign(player)
	local index=1
	while owners[index] do index+=1 end
	owners[index]=player
	local row=math.floor((index-1)/2)
	local z=43+18*row
	if not floors[row] then
		floors[row]=block(gallery,"GalleryDeck"..row,Vector3.new(46,1,18.1),CFrame.new(0,1,z),"384760",Enum.Material.Slate)
		for _,edge in ipairs({-22.8,22.8}) do
			block(gallery,"EdgeLight",Vector3.new(0.22,0.2,18),CFrame.new(edge,1.55,z),"BBA170",Enum.Material.Neon)
		end
	end
	local x=if index%2==1 then -11.5 else 11.5
	local model=Instance.new("Model")
	model.Name,model.Parent="Plot_"..player.UserId,gallery
	model:SetAttribute("OwnerId",player.UserId)
	local plaque=block(model,"Nameplate",Vector3.new(14,1,0.5),CFrame.new(x,2,z+4),"5B5160")
	sign(plaque,player.DisplayName,"FFE4B1",3)
	local plot={index=index,model=model,pads={}}
	plots[player]=plot
	for slot=1,Catalog.Slots do
		local pad=block(model,"Slot"..slot,Vector3.new(0.8,4.2,4.2),CFrame.new(x+(slot-2)*5.5,2,z)*CFrame.Angles(0,0,math.pi/2),"908069")
		pad.Shape=Enum.PartType.Cylinder
		local p=prompt(pad,"Display","Витрина "..slot,"Выбрать планету")
		p:SetAttribute("OwnerId",player.UserId)
		p:SetAttribute("Slot",slot)
		plot.pads[slot]=pad
	end
end

function Stations.render(player,data)
	local plot=plots[player]
	if not plot then return end
	for slot,pad in ipairs(plot.pads) do
		local id=data.slots[slot]
		if pad:GetAttribute("ItemId")==id then continue end
		pad:SetAttribute("ItemId",id)
		local previous=pad:FindFirstChild("Exhibit")
		if previous then previous:Destroy() end
		local moon=Catalog.ById[id]
		if moon then
			local ball=block(pad,"Exhibit",Vector3.one*2.7,CFrame.new(pad.Position+Vector3.yAxis*2.8),moon.color,Enum.Material.SmoothPlastic)
			ball.Shape,ball.CanCollide=Enum.PartType.Ball,false
			for j=1,4 do
				local a=j*1.8
				local crater=block(ball,"Crater",Vector3.one*(0.36+j*0.06),CFrame.new(ball.Position+Vector3.new(math.cos(a),0.2*math.sin(a*2),math.sin(a))*1.15),moon.dark)
				crater.Shape,crater.CanCollide=Enum.PartType.Ball,false
			end
			sign(ball,moon.name.."  ·  $"..moon.rent.."/5 с",moon.color,2.4).Parent.MaxDistance=18
		end
	end
end

local function livingRoot(player)
	local char=player.Character
	local root=char and char:FindFirstChild("HumanoidRootPart")
	local humanoid=char and char:FindFirstChildOfClass("Humanoid")
	return if root and humanoid and humanoid.Health>0 then root else nil
end

local function overRing(position)
	local offset = position - catchRing.Position
	local radius = catchRing.Size.Y / 2
	return offset.Y >= -1 and offset.Y <= 10 and offset.X^2 + offset.Z^2 <= radius^2
end

function Stations.inCatchCircle(player)
	local root = livingRoot(player)
	return root ~= nil and overRing(root.Position)
end

function Stations.near(player,key,slot)
	local root=livingRoot(player)
	if not root then return false end
	if key=="Catch" and overRing(root.Position) then return true end
	local part
	if key=="Display" then
		part=plots[player] and plots[player].pads[slot]
	elseif labels[key] then
		part=static:FindFirstChild(key)
	end
	return part~=nil and (root.Position-part.Position).Magnitude<=12
end

function Stations.remove(player)
	local plot=plots[player]
	if plot then
		plot.model:Destroy()
		owners[plot.index],plots[player]=nil,nil
	end
end
return Stations
