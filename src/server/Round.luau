local Round = {}
Round.__index = Round

function Round.new(id, index, moon, width, random, now)
	local self = setmetatable({
		id=id, index=index, goal=moon.hits, width=width, hits=0, mistakes=0,
		step=0, random=random, period=1.7, ownHit=false, expires=now+90,
	}, Round)
	self:advance(now)
	return self
end

function Round:advance(now)
	self.step+=1
	self.start=now+0.38
	self.center=self.random:NextNumber(0.32,0.78)
end

function Round:packet(feedback)
	return {id=self.id,index=self.index,hits=self.hits,goal=self.goal,mistakes=self.mistakes,
		step=self.step,start=self.start,period=self.period,center=self.center,width=self.width,feedback=feedback}
end

-- Consume one input per step. Bound the client's synchronized timestamp by the connection latency.
function Round:judge(step, pressed, now, maxLag)
	if step~=self.step or type(pressed)~="number" or pressed~=pressed
		or pressed<self.start or now>self.expires or pressed<now-maxLag or pressed>now+0.06 then return nil end
	local phase=((pressed-self.start)/self.period)%1
	local hit=math.abs(phase-self.center)<=self.width/2
	if hit then
		self.ownHit=true
		self.hits+=1
	else
		self.mistakes+=1
	end
	self:advance(now)
	return hit
end
return Round
