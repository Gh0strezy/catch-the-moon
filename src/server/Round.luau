local Round = {}
Round.__index = Round

function Round.new(goal)
	return setmetatable({ goal = goal, id = 1, hits = 0, paused = false, contributors = {} }, Round)
end

function Round:restart()
	self.id += 1
	self.hits = 0
	self.paused = false
	table.clear(self.contributors)
end

function Round:remove(player)
	self.contributors[player] = nil
end

function Round:tap(player, roundId, now)
	if self.paused or self.id ~= roundId then return false end
	local last = self.contributors[player]
	if last and now - last < 0.09 then return false end
	self.contributors[player] = now
	self.hits += 1
	self.paused = self.hits >= self.goal
	return true
end

function Round:packet()
	local crew = 0
	for _ in pairs(self.contributors) do crew += 1 end
	return { id = self.id, hits = self.hits, goal = self.goal, paused = self.paused, crew = crew }
end

return Round
