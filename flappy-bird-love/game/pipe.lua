-- game/pipe.lua — 개별 파이프

local Pipe = {}
Pipe.__index = Pipe

-- 상수
local PIPE_WIDTH = 52
local GAP_SIZE = 120       -- 상단/하단 파이프 사이 간격
local PIPE_SPEED = 150     -- px/s
local PIPE_COLOR = {0.2, 0.7, 0.2}   -- 녹색
local CAP_HEIGHT = 26      -- 파이프 뚜껑 높이
local CAP_EXTRA = 4        -- 뚜껑이 본체보다 튀어나온 너비 (양쪽)

function Pipe.new(x, gapY)
    local self = setmetatable({}, Pipe)
    self.x = x
    self.gapY = gapY       -- 갭의 중앙 y 좌표
    self.width = PIPE_WIDTH
    self.gap = GAP_SIZE
    self.speed = PIPE_SPEED
    self.passed = false     -- 점수를 이미 획득했는지
    return self
end

function Pipe:update(dt)
    self.x = self.x - self.speed * dt
end

function Pipe:draw()
    local topBottom = self.gapY - self.gap / 2       -- 상단 파이프 하단
    local bottomTop = self.gapY + self.gap / 2        -- 하단 파이프 상단
    local screenH = love.graphics.getHeight()

    love.graphics.setColor(PIPE_COLOR)

    -- 상단 파이프 본체
    love.graphics.rectangle("fill", self.x, 0, self.width, topBottom - CAP_HEIGHT)
    -- 상단 파이프 뚜껑
    love.graphics.rectangle("fill",
        self.x - CAP_EXTRA, topBottom - CAP_HEIGHT,
        self.width + CAP_EXTRA * 2, CAP_HEIGHT)

    -- 하단 파이프 본체
    love.graphics.rectangle("fill", self.x, bottomTop + CAP_HEIGHT, self.width, screenH - bottomTop - CAP_HEIGHT)
    -- 하단 파이프 뚜껑
    love.graphics.rectangle("fill",
        self.x - CAP_EXTRA, bottomTop,
        self.width + CAP_EXTRA * 2, CAP_HEIGHT)

    love.graphics.setColor(1, 1, 1)  -- 리셋
end

function Pipe:isOffScreen()
    return self.x + self.width < 0
end

function Pipe:collides(bird)
    local b = bird:getBounds()
    local topBottom = self.gapY - self.gap / 2
    local bottomTop = self.gapY + self.gap / 2

    -- AABB 충돌: 새가 파이프의 x 범위 안에 있는지
    if b.x + b.w > self.x and b.x < self.x + self.width then
        -- 상단 파이프와 충돌
        if b.y < topBottom then
            return true
        end
        -- 하단 파이프와 충돌
        if b.y + b.h > bottomTop then
            return true
        end
    end

    return false
end

function Pipe:getSpeed()
    return PIPE_SPEED
end

return Pipe
