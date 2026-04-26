--[[
    treasure.lua - 보물 시스템 모듈
    미로 내 랜덤 위치에 보물 배치, 획득 처리
]]

local Treasure = {}
Treasure.__index = Treasure

-- 보물 타입 정의
Treasure.TYPES = {
    { name = "normal",  points = 10, color = {0.2, 0.8, 0.2}, radius = 6 },  -- 초록
    { name = "rare",    points = 30, color = {0.2, 0.6, 1.0}, radius = 7 },  -- 파랑
    { name = "epic",    points = 50, color = {1.0, 0.8, 0.0}, radius = 8 },  -- 금색
}

function Treasure.new()
    local self = setmetatable({}, Treasure)
    self.items = {}
    return self
end

-- 미로에 보물 배치
function Treasure:placeTreasures(maze, count)
    self.items = {}
    local placed = 0
    local maxAttempts = count * 20  -- 무한 루프 방지
    local attempts = 0

    while placed < count and attempts < maxAttempts do
        attempts = attempts + 1
        local x = love.math.random(1, maze.cols)
        local y = love.math.random(1, maze.rows)

        -- 시작 위치와 탈출 위치에는 보물 배치하지 않음
        local isStart = (x == maze.startX and y == maze.startY)
        local isExit  = (x == maze.exitX  and y == maze.exitY)

        -- 이미 같은 위치에 보물이 있는지 확인
        local occupied = false
        for _, item in ipairs(self.items) do
            if item.gridX == x and item.gridY == y then
                occupied = true
                break
            end
        end

        if not isStart and not isExit and not occupied then
            -- 보물 타입 랜덤 선택 (확률: normal 60%, rare 30%, epic 10%)
            local roll = love.math.random(100)
            local typeIndex
            if roll <= 60 then
                typeIndex = 1
            elseif roll <= 90 then
                typeIndex = 2
            else
                typeIndex = 3
            end

            local treasureType = self.TYPES[typeIndex]
            table.insert(self.items, {
                gridX = x,
                gridY = y,
                type = treasureType.name,
                points = treasureType.points,
                color = treasureType.color,
                radius = treasureType.radius,
                collected = false,
                animTimer = love.math.random() * math.pi * 2,  -- 애니메이션 위상 랜덤
            })
            placed = placed + 1
        end
    end
end

-- 플레이어 위치에서 보물 획득 체크
function Treasure:checkCollection(playerX, playerY)
    for _, item in ipairs(self.items) do
        if not item.collected and item.gridX == playerX and item.gridY == playerY then
            item.collected = true
            return item.points, item.type
        end
    end
    return 0, nil
end

-- 남은 보물 개수 반환
function Treasure:remainingCount()
    local count = 0
    for _, item in ipairs(self.items) do
        if not item.collected then
            count = count + 1
        end
    end
    return count
end

-- 애니메이션 타이머 업데이트
function Treasure:update(dt)
    for _, item in ipairs(self.items) do
        if not item.collected then
            item.animTimer = item.animTimer + dt * 3
        end
    end
end

return Treasure
