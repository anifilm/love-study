--[[
    player.lua - 플레이어 관리 모듈
    픽셀 기반 연속 이동, 격자 경계에서 벽 체크
]]

local Player = {}
Player.__index = Player

function Player.new(startX, startY)
    local self = setmetatable({}, Player)
    self.gridX = startX
    self.gridY = startY
    self.score = 0
    self.moveCount = 0
    self.treasuresCollected = 0

    -- 픽셀 좌표 (연속 이동의 핵심)
    self.pixelX = 0
    self.pixelY = 0
    self.speed = 150  -- 픽셀/초

    -- 현재 이동 방향 (nil이면 정지)
    self.moveDir = nil

    -- 셀 크기/오프셋 (initPixelPos에서 설정)
    self.cellSize = 0
    self.offsetX = 0
    self.offsetY = 0

    return self
end

-- 픽셀 좌표 초기화
function Player:initPixelPos(cellSize, offsetX, offsetY)
    self.cellSize = cellSize
    self.offsetX = offsetX
    self.offsetY = offsetY
    self.pixelX = offsetX + (self.gridX - 1) * cellSize + cellSize / 2
    self.pixelY = offsetY + (self.gridY - 1) * cellSize + cellSize / 2
    self.speed = cellSize * 5  -- 셀 크기에 비례한 속도
end

-- 픽셀 좌표 → 격자 좌표 변환
function Player:pixelToGrid()
    local gx = math.floor((self.pixelX - self.offsetX) / self.cellSize) + 1
    local gy = math.floor((self.pixelY - self.offsetY) / self.cellSize) + 1
    return gx, gy
end

-- 격자 중심 픽셀 좌표
function Player:gridCenterPixel(gx, gy)
    local cx = self.offsetX + (gx - 1) * self.cellSize + self.cellSize / 2
    local cy = self.offsetY + (gy - 1) * self.cellSize + self.cellSize / 2
    return cx, cy
end

-- 매 프레임 업데이트 (연속 이동)
function Player:update(dt, maze)
    if not self.moveDir then return end

    local cs = self.cellSize
    local half = cs / 2
    local margin = 2  -- 벽과의 최소 거리

    -- 이동 벡터
    local dx, dy = 0, 0
    if self.moveDir == "up"    then dy = -1 end
    if self.moveDir == "down"  then dy = 1  end
    if self.moveDir == "left"  then dx = -1 end
    if self.moveDir == "right" then dx = 1  end

    -- 이동할 픽셀 거리
    local moveDist = self.speed * dt
    local newX = self.pixelX + dx * moveDist
    local newY = self.pixelY + dy * moveDist

    -- 현재 격자 위치
    local gx, gy = self:pixelToGrid()

    -- 격자 경계 좌표
    local cellLeft   = self.offsetX + (gx - 1) * cs
    local cellRight  = cellLeft + cs
    local cellTop    = self.offsetY + (gy - 1) * cs
    local cellBottom = cellTop + cs

    -- 이동 방향에 따른 벽 체크
    if dx > 0 then  -- 오른쪽
        local nextRight = newX + half - margin
        if nextRight > cellRight then
            if not maze:canMove(gx, gy, "right") then
                newX = cellRight - half + margin
            else
                self.gridX = gx + 1
                self.moveCount = self.moveCount + 1
            end
        end
    elseif dx < 0 then  -- 왼쪽
        local nextLeft = newX - half + margin
        if nextLeft < cellLeft then
            if not maze:canMove(gx, gy, "left") then
                newX = cellLeft + half - margin
            else
                self.gridX = gx - 1
                self.moveCount = self.moveCount + 1
            end
        end
    elseif dy > 0 then  -- 아래
        local nextBottom = newY + half - margin
        if nextBottom > cellBottom then
            if not maze:canMove(gx, gy, "down") then
                newY = cellBottom - half + margin
            else
                self.gridY = gy + 1
                self.moveCount = self.moveCount + 1
            end
        end
    elseif dy < 0 then  -- 위
        local nextTop = newY - half + margin
        if nextTop < cellTop then
            if not maze:canMove(gx, gy, "up") then
                newY = cellTop + half - margin
            else
                self.gridY = gy - 1
                self.moveCount = self.moveCount + 1
            end
        end
    end

    -- 미로 경계 밖으로 나가지 않도록 클램프
    local minX = self.offsetX + half
    local maxX = self.offsetX + maze.cols * cs - half
    local minY = self.offsetY + half
    local maxY = self.offsetY + maze.rows * cs - half
    newX = math.max(minX, math.min(maxX, newX))
    newY = math.max(minY, math.min(maxY, newY))

    self.pixelX = newX
    self.pixelY = newY

    -- 격자 좌표 동기화
    self.gridX, self.gridY = self:pixelToGrid()
end

-- 보물 획득
function Player:collectTreasure(points)
    self.score = self.score + points
    self.treasuresCollected = self.treasuresCollected + 1
end

return Player
