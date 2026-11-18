local Catalog = require(game.ReplicatedStorage:WaitForChild("MoonCatalog"))
local Interface = {}
Interface.__index = Interface

local ink, panel, line = Color3.fromHex("11182B"), Color3.fromHex("202B43"), Color3.fromHex("53637F")
local paper, muted, gold = Color3.fromHex("F2EFE6"), Color3.fromHex("B5C4DD"), Color3.fromHex("FFD391")
local function box(class, parent, name, size, pos, color)
	local o = Instance.new(class)
	o.Name, o.Size, o.Position = name, size, pos
	o.BorderSizePixel = 0
	o.BackgroundColor3 = color or ink
	o.BackgroundTransparency = if color then 0 else 1
	o.Parent = parent
	return o
end
local function shape(o, radius, border)
	local corner = Instance.new("UICorner")
	corner.CornerRadius, corner.Parent = UDim.new(0,radius), o
	if border then
		local s = Instance.new("UIStroke")
		s.Color, s.Transparency, s.ApplyStrokeMode, s.Parent = border, 0.2, Enum.ApplyStrokeMode.Border, o
	end
end
local function label(parent, name, value, size, pos, textSize, color, font)
	local o = box("TextLabel",parent,name,size,pos)
	o.Text, o.TextSize, o.TextColor3 = value,textSize,color or paper
	o.Font = font or Enum.Font.GothamMedium
	o.TextXAlignment = Enum.TextXAlignment.Left
	return o
end
local function button(parent,name,value,size,pos,color)
	local o = box("TextButton",parent,name,size,pos,color or panel)
	o.Text, o.TextSize, o.Font = value,16,Enum.Font.GothamBold
	o.TextColor3 = if color == gold then ink else paper
	o.AutoButtonColor = true
	shape(o,10,if color == gold then nil else line)
	return o
end
local function fit(o, maxWidth, maxHeight)
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize, limit.Parent = Vector2.new(maxWidth,maxHeight), o
end

function Interface.new(parent)
	local self = setmetatable({rows = {}}, Interface)
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.ResetOnSpawn, gui.DisplayOrder = "MoonStation",false,3
	gui.ZIndexBehavior, gui.Parent = Enum.ZIndexBehavior.Sibling,parent
	self.gui = gui
	local full = UDim2.fromScale(1,1)
	local header = box("Frame",gui,"Status",UDim2.new(1,-28,0,56),UDim2.fromOffset(14,6))
	self.title = label(header,"Title","Поймай Луну",UDim2.new(1,-125,0,29),UDim2.fromOffset(0,0),25,paper,Enum.Font.GothamBold)
	self.stats = label(header,"Resources","Подключение…",UDim2.new(1,-104,0,22),UDim2.fromOffset(1,30),14,gold)
	self.atlas = button(header,"Atlas","Атлас   0/5",UDim2.fromOffset(106,40),UDim2.new(1,-106,0,0))

	local dock = box("Frame",gui,"Capture",UDim2.new(1,-24,0,102),UDim2.new(0.5,0,1,-10),ink)
	dock.AnchorPoint = Vector2.new(0.5,1)
	dock.BackgroundTransparency = 0.05
	shape(dock,14,line)
	fit(dock,510,110)
	self.status = label(dock,"Status","Поиск орбиты…",UDim2.new(1,-110,0,22),UDim2.fromOffset(14,6),15,paper)
	self.meter = label(dock,"Count","",UDim2.fromOffset(80,22),UDim2.new(1,-94,0,6),15,muted)
	self.meter.TextXAlignment = Enum.TextXAlignment.Right
	local track = box("Frame",dock,"Track",UDim2.new(1,-28,0,5),UDim2.fromOffset(14,34),panel)
	shape(track,3)
	self.fill = box("Frame",track,"Fill",UDim2.fromScale(0,1),UDim2.fromOffset(0,0),gold)
	shape(self.fill,3)
	self.tap = button(dock,"Tap","Ловить Луну",UDim2.new(0.62,-17,0,43),UDim2.fromOffset(12,48),gold)
	self.luck = button(dock,"Luck","Удача  +",UDim2.new(0.38,-13,0,43),UDim2.new(0.62,5,0,48))

	local overlay = box("TextButton",gui,"AtlasBackdrop",full,UDim2.fromOffset(0,0),ink)
	overlay.Text, overlay.AutoButtonColor, overlay.Modal = "",false,true
	overlay.BackgroundTransparency, overlay.Visible, overlay.ZIndex = 0.18,false,10
	self.overlay = overlay
	local sheet = box("Frame",overlay,"AtlasPanel",UDim2.new(1,-24,1,-18),UDim2.fromScale(0.5,0.5),ink)
	sheet.AnchorPoint, sheet.Active = Vector2.new(0.5,0.5),true
	fit(sheet,500,500)
	shape(sheet,16,line)
	label(sheet,"Title","Атлас лун",UDim2.new(1,-82,0,34),UDim2.fromOffset(16,10),25,paper,Enum.Font.GothamBold)
	local close = button(sheet,"Close","×",UDim2.fromOffset(36,36),UDim2.new(1,-50,0,10))
	close.Activated:Connect(function() overlay.Visible = false end)
	local scroll = box("ScrollingFrame",sheet,"Entries",UDim2.new(1,-24,1,-121),UDim2.fromOffset(12,53))
	scroll.ScrollBarThickness, scroll.ScrollBarImageColor3 = 4,line
	scroll.CanvasSize = UDim2.fromOffset(0,#Catalog.Moons*58+36)
	for i, moon in ipairs(Catalog.Moons) do
		local row = box("Frame",scroll,moon.id,UDim2.new(1,-8,0,51),UDim2.fromOffset(0,(i-1)*58),panel)
		shape(row,10)
		local badge = box("Frame",row,"Moon",UDim2.fromOffset(30,30),UDim2.fromOffset(10,10),Color3.fromHex(moon.color))
		shape(badge,15)
		for j,dot in ipairs({{7,6,8},{17,15,6},{6,19,4}}) do
			local crater = box("Frame",badge,"Crater"..j,UDim2.fromOffset(dot[3],dot[3]),UDim2.fromOffset(dot[1],dot[2]),Color3.fromHex(moon.dark))
			shape(crater,4)
		end
		label(row,"Name",moon.name,UDim2.new(1,-144,0,22),UDim2.fromOffset(50,4),16,paper,Enum.Font.GothamBold)
		self.rows[i] = {
			info = label(row,"Rarity","",UDim2.new(1,-60,0,20),UDim2.fromOffset(50,26),12,muted),
			odds = label(row,"Odds","",UDim2.fromOffset(120,24),UDim2.new(1,-130,0,4),13,Color3.fromHex(moon.color))
		}
		self.rows[i].odds.TextXAlignment = Enum.TextXAlignment.Right
	end
	self.saveNote = label(scroll,"SaveMode","",UDim2.new(1,-10,0,32),UDim2.fromOffset(2,#Catalog.Moons*58),12,muted)
	self.upgrade = button(sheet,"Upgrade","Улучшить удачу",UDim2.new(1,-28,0,46),UDim2.new(0,14,1,-57),gold)
	for _, b in ipairs({self.atlas,self.luck}) do
		b.Activated:Connect(function() overlay.Visible = true end)
	end
	return self
end

function Interface:profile(data, practice)
	local owned = 0
	local chances = Catalog.chances(data.level)
	local nextChances = Catalog.chances(math.min(data.level+1,Catalog.MaxLevel))
	for i,moon in ipairs(Catalog.Moons) do
		local n = data.counts[moon.id] or 0
		if n > 0 then owned += 1 end
		self.rows[i].info.Text = string.format("%s  ·  Поймано %d",moon.rarity,n)
		self.rows[i].odds.Text = if data.level < Catalog.MaxLevel then
			string.format("%.2f → %.2f%%",chances[i]*100,nextChances[i]*100)
			else string.format("%.2f%%",chances[i]*100)
	end
	local luck = Catalog.luck(data.level)
	self.atlas.Text = string.format("Атлас   %d/%d",owned,#Catalog.Moons)
	self.stats.Text = string.format("Пыль %d   ·   Удача ×%.2f",data.dust,luck)
	self.saveNote.Text = "Шанс сейчас → после улучшения" .. (if practice then "\nStudio · прогресс на время теста" else "")
	local maxed = data.level >= Catalog.MaxLevel
	local price = Catalog.price(data.level)
	self.canUpgrade = not maxed and data.dust >= price
	self.upgrade.Text = if maxed then "Удача максимальная" else
		string.format("Удача ×%.2f → ×%.2f   ·   %d/%d пыли",luck,Catalog.luck(data.level+1),data.dust,price)
	self.upgrade.TextSize = 14
	self.upgrade.BackgroundColor3 = if self.canUpgrade then gold else panel
	self.upgrade.TextColor3 = if self.canUpgrade then ink else muted
	self.upgrade.AutoButtonColor = self.canUpgrade
	self.luck.Text = if self.canUpgrade then "Удача  ↑" else "Удача  +"
end

function Interface:progress(packet)
	self.fill.Size = UDim2.fromScale(packet.hits/packet.goal,1)
	self.meter.Text = string.format("%d / %d",packet.hits,packet.goal)
	self.status.TextColor3 = paper
	self.status.Text = if packet.paused then "Луна поймана!" elseif packet.crew > 1 then
		string.format("Ловим вместе · %d",packet.crew) elseif packet.hits > 0 then "Тянем Луну ближе" else "Нажимай на Луну или кнопку"
	self.tap.Text = if packet.paused then "Следующая орбита…" else "Ловить Луну"
	self.tap.AutoButtonColor = not packet.paused
end

function Interface:reveal(moon)
	self.status.TextColor3 = Color3.fromHex(moon.color)
	self.status.Text = string.format("%s  ·  +%d пыли",moon.name,moon.dust)
end

return Interface
