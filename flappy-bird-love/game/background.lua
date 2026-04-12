-- game/background.lua — 배경 렌더링 (하늘, 땅)

local Background = {}
Background.__index = Background

-- 상수
local GROUND_HEIGHT = 112
local GROUND_SPEED = 150   -- 파이프 속도와 동기화
local SKY_COLOR = {0.31, 0.75, 0.92}       -- 하늘색
local GROUND_TOP_COLOR = {0.55, 0.78, 0.24} -- 땅 상단 (잔디)
local GROUND_COLOR = {0.76, 0.65, 0.42}     -- 땅 (흙)

function Background.new()
    local self = setmetatable({}, Background)
    self.screenW = 288
    self.screenH = 512
    self.groundX = 0        -- 땅 스크롤 오프셋
    return self
end

function Background:update(dt)
    -- 무한 스크롤 땅
    self.groundX = self.groundX - GROUND_SPEED * dt
    if self.groundX <= -self.screenW then
        self.groundX = self.groundX + self.screenW
    end
end

function Background:draw()
    local groundY = self.screenH - GROUND_HEIGHT

    -- 하늘
    love.graphics.setColor(SKY_COLOR)
    love.graphics.rectangle("fill", 0, 0, self.screenW, groundY)

    -- 구름 (간단한 원형 3개)
    love.graphics.setColor(1, 1, 1, 0.8)
    self:drawCloud(50, 80, 40)
    self:drawCloud(180, 120, 30)
    self:drawCloud(120, 50, 25)

    love.graphics.setColor(1, 1, 1)  -- 리셋
end

function Background:drawGround()
    local groundY = self.screenH - GROUND_HEIGHT

    -- 땅 상단 (잔디 띠)
    love.graphics.setColor(GROUND_TOP_COLOR)
    love.graphics.rectangle("fill", 0, groundY, self.screenW, 4)

    -- 땅 (무한 스크롤)
    love.graphics.setColor(GROUND_COLOR)
    love.graphics.rectangle("fill", 0, groundY + 4, self.screenW, GROUND_HEIGHT - 4)

    -- 땅 패턴 (스크롤 효과)
    love.graphics.setColor(0.68, 0.58, 0.35)
    for i = -1, 2 do
        local offset = self.groundX + i * self.screenW
        love.graphics.rectangle("fill", offset + 20, groundY + 20, 30, 8)
        love.graphics.rectangle("fill", offset + 80, groundY + 40, 25, 6)
        love.graphics.rectangle("fill", offset + 150, groundY + 15, 35, 7)
        love.graphics.rectangle("fill", offset + 220, groundY + 50, 20, 5)
    end

    love.graphics.setColor(1, 1, 1)  -- 리셋
end

function Background:drawCloud(cx, cy, r)
    love.graphics.circle("fill", cx, cy, r)
    love.graphics.circle("fill", cx - r * 0.7, cy + r * 0.2, r * 0.7)
    love.graphics.circle("fill", cx + r * 0.8, cy + r * 0.1, r * 0.6)
end

function Background:getGroundY()
    return self.screenH - GROUND_HEIGHT
end

function Background:reset()
    self.groundX = 0
end

return Background
