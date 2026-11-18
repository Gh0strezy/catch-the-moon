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
	local self=setmetatable({rows={}},Interface)
	local gui=Instance.new("ScreenGui")
	gui.Name,gui.ResetOnSpawn,gui.DisplayOrder="MoonStation",false,3
	gui.ZIndexBehavior,gui.Parent=Enum.ZIndexBehavior.Sibling,parent
	local header=box("Frame",gui,"Status",UDim2.new(1,-24,0,56),UDim2.fromOffset(12,5))
	local balance=box("Frame",header,"Wallet",UDim2.fromOffset(174,49),UDim2.fromOffset(0,0),ink)
	shape(balance,10,line)
	self.cash=label(balance,"Cash","$0",UDim2.fromOffset(150,24),UDim2.fromOffset(11,2),20,gold,Enum.Font.GothamBold)
	self.rate=label(balance,"Income","Витрины  +$0 / 5 с",UDim2.fromOffset(158,19),UDim2.fromOffset(11,26),12,muted)
	self.bag=button(header,"Bag","Рюкзак",UDim2.fromOffset(98,40),UDim2.new(1,-98,0,0))

	self.toast=label(gui,"Notice","",UDim2.new(1,-28,0,44),UDim2.new(0.5,0,0,62),15,paper)
	self.toast.AnchorPoint=Vector2.new(0.5,0)
	self.toast.TextXAlignment=Enum.TextXAlignment.Center
	self.toast.BackgroundColor3,self.toast.BackgroundTransparency,self.toast.TextWrapped=ink,0.1,true
	fit(self.toast,450,44)
	shape(self.toast,10)
	self.toast.Visible=false

	local dock=box("Frame",gui,"Capture",UDim2.new(1,-20,0,122),UDim2.new(0.5,0,1,-10),ink)
	dock.AnchorPoint,dock.Visible=Vector2.new(0.5,1),false
	shape(dock,14,line)
	fit(dock,506,124)
	self.dock=dock
	self.target=label(dock,"Target","",UDim2.new(1,-92,0,23),UDim2.fromOffset(13,6),16,paper,Enum.Font.GothamBold)
	self.progress=label(dock,"Progress","",UDim2.fromOffset(70,22),UDim2.new(1,-83,0,7),15,gold)
	self.progress.TextXAlignment=Enum.TextXAlignment.Right
	self.hint=label(dock,"Hint","",UDim2.new(1,-20,0,18),UDim2.fromOffset(13,28),12,muted)
	local bar=box("Frame",dock,"Track",UDim2.new(1,-28,0,13),UDim2.fromOffset(14,51),panel)
	shape(bar,5)
	self.zone=box("Frame",bar,"PerfectWindow",UDim2.fromScale(0.16,1),UDim2.fromOffset(0,0),Color3.fromHex("84DBBB"))
	shape(self.zone,4)
	self.marker=box("Frame",bar,"Pointer",UDim2.fromOffset(4,23),UDim2.fromScale(0,0.5),paper)
	self.marker.AnchorPoint=Vector2.new(0.5,0.5)
	self.hit=button(dock,"Strike","Поймать",UDim2.new(0.72,-16,0,40),UDim2.fromOffset(13,74),gold)
	self.cancel=button(dock,"Cancel","Выйти",UDim2.new(0.28,-14,0,40),UDim2.new(0.72,1,0,74))

	local shade=box("TextButton",gui,"Backdrop",UDim2.fromScale(1,1),UDim2.fromOffset(0,0),ink)
	shade.Text,shade.AutoButtonColor,shade.BackgroundTransparency="",false,0.28
	shade.Visible,shade.ZIndex=false,10
	self.overlay=shade
	local sheet=box("Frame",shade,"Sheet",UDim2.new(1,-22,1,-16),UDim2.fromScale(0.5,0.5),ink)
	sheet.AnchorPoint,sheet.Active=Vector2.new(0.5,0.5),true
	fit(sheet,472,450)
	shape(sheet,15,line)
	self.heading=label(sheet,"Title","",UDim2.new(1,-70,0,30),UDim2.fromOffset(16,10),23,paper,Enum.Font.GothamBold)
	self.close=button(sheet,"Close","×",UDim2.fromOffset(36,36),UDim2.new(1,-47,0,8))
	self.summary=label(sheet,"Summary","",UDim2.new(1,-32,0,29),UDim2.fromOffset(16,43),13,muted)
	self.summary.TextWrapped=true
	local list=box("ScrollingFrame",sheet,"Items",UDim2.new(1,-24,1,-138),UDim2.fromOffset(12,74))
	list.ScrollBarThickness,list.ScrollBarImageColor3=4,line
	self.list=list
	for i,moon in ipairs(Catalog.Moons) do
		local b=button(list,moon.id,"",UDim2.new(1,-7,0,49),UDim2.fromOffset(0,(i-1)*55))
		local swatch=box("Frame",b,"Sample",UDim2.fromOffset(25,25),UDim2.fromOffset(10,12),Color3.fromHex(moon.color))
		shape(swatch,13)
		local crater=box("Frame",swatch,"Crater",UDim2.fromOffset(8,8),UDim2.fromOffset(5,6),Color3.fromHex(moon.dark))
		shape(crater,4)
		label(b,"Name",moon.name,UDim2.new(1,-111,0,22),UDim2.fromOffset(44,3),15,paper,Enum.Font.GothamBold)
		local note=label(b,"Detail","",UDim2.new(1,-50,0,18),UDim2.fromOffset(44,26),12,muted)
		local qty=label(b,"Quantity","",UDim2.fromOffset(62,20),UDim2.new(1,-70,0,4),14,Color3.fromHex(moon.color))
		qty.TextXAlignment=Enum.TextXAlignment.Right
		self.rows[i]={button=b,note=note,qty=qty}
	end
	self.info=label(list,"UpgradeDetails","",UDim2.new(1,-14,0,95),UDim2.fromOffset(8,4),18,paper)
	self.info.TextWrapped=true
	self.confirm=button(sheet,"Confirm","",UDim2.new(1,-24,0,43),UDim2.new(0,12,1,-53),gold)
	return self
end

function Interface:notice(text)
	self.toast.Text=text
	self.toast.Visible=true
	self.noticeId=(self.noticeId or 0)+1
	local id=self.noticeId
	task.delay(4,function() if self.noticeId==id then self.toast.Visible=false end end)
end

function Interface:menu(mode,slot)
	self.mode,self.slot=mode,slot
	self.overlay.Visible=mode~=nil
	self.list.CanvasPosition=Vector2.zero
	self:refresh()
end

function Interface:refresh()
	local d=self.data
	if not d then return end
	self.cash.Text="$"..d.cash
	self.rate.Text=string.format("Витрины   +$%d / 5 с",Catalog.income(d))
	if not self.mode then return end
	local exhibition=self.mode=="Display"
	local shop=self.mode=="Luck" or self.mode=="Speed"
	local stat=if self.mode=="Luck" then "level" else "speed"
	local chances=Catalog.chances(d.level)
	local equipped=exhibition and Catalog.ById[d.slots[self.slot]]
	self.heading.Text=if exhibition then "Витрина "..self.slot elseif self.mode=="Luck" then "Мастерская удачи"
		elseif shop then "Скорость бега" else "Рюкзак"
	self.summary.Text=if exhibition then (if equipped then "Выставлена "..equipped.name..". Выбери замену." else "Выбери планету для витрины")
		else string.format("Удача ×%.2f   ·   Скорость %d   ·   Сила %d",Catalog.luck(d.level),Catalog.walkSpeed(d.speed),d.strength)
	self.info.Visible=shop
	self.list.CanvasSize=UDim2.fromOffset(0,if shop then 106 else #self.rows*55)
	for i,row in ipairs(self.rows) do
		local moon=Catalog.Moons[i]
		local bag=Catalog.inBag(d,moon.id)
		row.button.Visible=not shop
		row.button.AutoButtonColor=exhibition and bag>0
		row.qty.Text="×"..bag
		row.note.Text=string.format("%.2f%%   ·   %d попад.   ·   $%d / 5 с",chances[i]*100,moon.hits,moon.rent)
	end
	self.confirm.Visible=shop or exhibition
	local enabled=false
	if shop then
		local level=d[stat]
		local capped=level>=(if stat=="level" then Catalog.MaxLevel else Catalog.SpeedCap)
		local nextLevel=if capped then level else level+1
		local price=Catalog.price(stat,level)
		self.info.Text=if stat=="level" then string.format("Удача ×%.2f → ×%.2f\nШанс легендарной %.2f%% → %.2f%%",Catalog.luck(level),Catalog.luck(nextLevel),chances[5]*100,Catalog.chances(nextLevel)[5]*100)
			else string.format("Скорость %d → %d\nстудов в секунду",Catalog.walkSpeed(level),Catalog.walkSpeed(nextLevel))
		enabled=not capped and d.cash>=price
		self.confirm.Text=if capped then "Максимальный уровень" elseif enabled then "Улучшить за $"..price else "Цена $"..price.."  ·  Нужно ещё $"..(price-d.cash)
	elseif exhibition then
		enabled=equipped~=nil
		self.confirm.Text=if enabled then "Вернуть планету в рюкзак" else "Витрина свободна"
	end
	self.confirm.AutoButtonColor=enabled
	self.confirm.BackgroundColor3=if enabled then gold else panel
	self.confirm.TextColor3=if enabled then ink else muted
	self.canConfirm=enabled
end

function Interface:hunt(packet)
	self.dock.Visible=packet~=nil
	if not packet then return end
	local planet=Catalog.Moons[packet.index]
	self.target.Text=planet.name.."   ·   "..planet.rarity
	self.progress.Text=string.format("%d / %d",packet.hits,packet.goal)
	self.hint.Text=(packet.feedback or "Нажми в зелёной зоне").."   ·   Промахи "..packet.mistakes.."/3"
	self.zone.Size=UDim2.fromScale(packet.width,1)
	self.zone.Position=UDim2.fromScale(packet.center-packet.width/2,0)
end
return Interface
