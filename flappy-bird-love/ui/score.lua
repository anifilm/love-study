-- ui/score.lua — 점수 시스템

local Score = {}
Score.__index = Score

local SAVE_FILE = "flappy_best.txt"

function Score.new()
    local self = setmetatable({}, Score)
    self.current = 0
    self.best = 0
    self:loadBest()
    return self
end

function Score:add(amount)
    self.current = self.current + amount
end

function Score:reset()
    self.current = 0
end

function Score:saveBest()
    if self.current > self.best then
        self.best = self.current
        -- 파일에 저장
        love.filesystem.write(SAVE_FILE, tostring(self.best))
    end
end

function Score:loadBest()
    if love.filesystem.getInfo(SAVE_FILE) then
        local data = love.filesystem.read(SAVE_FILE)
        self.best = tonumber(data) or 0
    end
end

function Score:drawCurrent()
    local w = love.graphics.getWidth()

    -- 큰 폰트로 현재 점수 표시
    love.graphics.setColor(1, 1, 1)
    -- 그림자
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.printf(tostring(self.current), 2, 42, w, "center")
    -- 본문
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(tostring(self.current), 0, 40, w, "center")
end

return Score
