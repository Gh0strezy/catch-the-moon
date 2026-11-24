local Round = {}
Round.__index = Round
Round.MissLimit = 3

function Round.new(id, index, moon, width, random, now)
	local self = setmetatable({
		id=id, index=index, goal=moon.hits, width=width, hits=0, mistakes=0,
		step=0, random=random, period=1.7, ownHit=false, expires=now+90,
	}, Round)
	self:advance(now)
	self.start = now+0.85 -- Let the opening throw land before the first pass.
	return self
end

function Round:advance(now)
	self.step+=1
	self.start=now+0.38
	self.center=self.random:NextNumber(0.32,0.78)
end

function Round:packet(feedback)
	return {id=self.id,index=self.index,hits=self.hits,goal=self.goal,mistakes=self.mistakes,
		missLimit=Round.MissLimit,step=self.step,start=self.start,period=self.period,center=self.center,width=self.width,feedback=feedback}
end

function Round:miss(now)
	self.mistakes+=1
	self.hits=math.max(0,self.hits-1)
	self:advance(now)
end

function Round:missIfOverdue(now,maxLag)
	-- At the end of the track, wait only if an on-target press can still be in flight.
	local lastHit=self.start+self.period*(self.center+self.width/2)
	local deadline=math.max(self.start+self.period,lastHit+maxLag)
	if now<deadline or now>self.expires then return false end
	self:miss(now)
	return true
end

-- Consume one input per step. Bound the client's synchronized timestamp by the connection latency.
function Round:judge(step, pressed, now, maxLag)
	if step~=self.step or type(pressed)~="number" or pressed~=pressed
		or pressed<self.start or pressed>=self.start+self.period or now>self.expires
		or pressed<now-maxLag or pressed>now+0.06 then return nil end
	local phase=(pressed-self.start)/self.period
	local hit=math.abs(phase-self.center)<=self.width/2
	if hit then
		self.ownHit=true
		self.hits+=1
		self:advance(now)
	else
		self:miss(now)
	end
	return hit
end
return Round
