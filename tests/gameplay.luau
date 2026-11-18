local C=require("../src/shared/MoonCatalog")
local Round=require("../src/server/Round")
local old=C.newProfile({dust=80,level=4,counts={chalk=1,tidal=2}})
assert(old.cash==80 and old.level==4 and old.counts.tidal==2 and old.strength==0)
assert(C.place(old,1,"chalk") and C.inBag(old,"chalk")==0 and C.income(old)==1)
assert(not C.place(old,2,"chalk") and not C.place(old,4,"tidal") and not C.place(old,1,"missing"))
assert(C.place(old,1,"tidal") and C.inBag(old,"chalk")==1)
assert(C.place(old,2,"tidal") and C.income(old)==6 and C.inBag(old,"tidal")==0)
local copy=C.newProfile(old)
assert(C.place(copy,1,"") and C.income(copy)==3 and C.income(old)==6)
assert(C.newProfile({slots={"corona","corona","corona"},counts={corona=1}}).slots[2]=="")
local d=C.newProfile()
assert(not C.buy(d,"level"))
C.award(d,1)
assert(d.cash==8 and d.counts.chalk==1)
d.cash=44
assert(C.buy(d,"level") and C.buy(d,"speed") and d.cash==0)
assert(C.walkSpeed(d.speed)==18 and C.luck(d.level)==1.25)
for _=1,3 do assert(C.train(d)) end
assert(d.strength==1 and d.reps==0 and C.window(1)>C.window(0))
for _,stat in ipairs({"speed","level"}) do
	d.cash=1e9
	while C.buy(d,stat) do end
	assert(d[stat]==(if stat=="speed" then C.SpeedCap else C.MaxLevel))
end
local previous
for level=0,C.MaxLevel do
	local odds=C.chances(level)
	local sum,tail,prevTail=0,0,0
	for i,chance in ipairs(odds) do
		assert(C.roll(level,sum+chance/2)==i)
		sum+=chance
		if i>1 then assert(C.Moons[i].hits>C.Moons[i-1].hits) end
	end
	assert(math.abs(sum-1)<1e-10)
	for i=#odds,2,-1 do
		tail+=odds[i]
		if previous then prevTail+=previous[i]; assert(tail>prevTail) end
	end
	previous=odds
end
local random={NextNumber=function() return 0.5 end}
local round=Round.new(1,1,C.Moons[1],C.window(0),random,100)
assert(round:judge(1,100,100,0.2)==nil)
local miss=round.start+0.1
assert(round:judge(1,miss,miss,0.2)==false and round.mistakes==1)
assert(round:judge(1,miss,miss,0.2)==nil)
local ideal=round.start+round.period*0.5
assert(round:judge(2,ideal,ideal+1,0.2)==nil)
assert(round:judge(2,ideal,ideal+0.05,0.2)==true and round.hits==1 and round.ownHit)
print("PASS: migration, inventory ownership, rentals, economy, strength, rarity and timing")
