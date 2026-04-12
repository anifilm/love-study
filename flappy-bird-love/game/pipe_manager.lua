-- game/pipe_manager.lua — 파이프 생성 및 관리

local Pipe = require("game.pipe")

local PipeManager = {}
PipeManager.__index = PipeManager

-- 상수
local SPAWN_INTERVAL = 1.5   -- 초
local MIN_GAP_Y = 100        -- 갭 중앙 최소 y
local MAX_GAP_Y = 350        -- 갭 중앙 최대 y

function PipeManager.new()
    local self = setmetatable({}, PipeManager)
    self.pipes = {}
    self.timer = 0
    self.screenW = 288
    self.screenH = 512
    return self
end

function PipeManager:update(dt, bird)
    -- 타이머 증가 → 새 파이프 생성
    self.timer = self.timer + dt
    if self.timer >= SPAWN_INTERVAL then
        self.timer = self.timer - SPAWN_INTERVAL
        self:spawn()
    end

    -- 각 파이프 업데이트
    for i = #self.pipes, 1, -1 do
        local pipe = self.pipes[i]
        pipe:update(dt)

        -- 점수 판정: 파이프를 통과하면 +1
        if not pipe.passed and pipe.x + pipe.width < bird.x then
            pipe.passed = true
            return 1  -- 점수 증가 신호
        end

        -- 화면 밖 파이프 제거
        if pipe:isOffScreen() then
            table.remove(self.pipes, i)
        end
    end

    return 0  -- 점수 변동 없음
end

function PipeManager:spawn()
    local gapY = love.math.random(MIN_GAP_Y, MAX_GAP_Y)
    local pipe = Pipe.new(self.screenW, gapY)
    table.insert(self.pipes, pipe)
end

function PipeManager:draw()
    for _, pipe in ipairs(self.pipes) do
        pipe:draw()
    end
end

function PipeManager:checkCollision(bird)
    for _, pipe in ipairs(self.pipes) do
        if pipe:collides(bird) then
            return true
        end
    end
    return false
end

function PipeManager:reset()
    self.pipes = {}
    self.timer = 0
end

return PipeManager
