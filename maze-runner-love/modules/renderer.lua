--[[
    renderer.lua - 렌더링 모듈
    미로, 플레이어, 보물, UI 렌더링
]]

local Renderer = {}
Renderer.__index = Renderer

-- 색상 상수
local COLORS = {
    background  = {0.12, 0.12, 0.18},
    wall        = {0.85, 0.85, 0.90},
    path        = {0.20, 0.22, 0.30},
    start       = {0.20, 0.80, 0.30},
    exit        = {0.90, 0.25, 0.25},
    player      = {1.00, 0.95, 0.40},
    playerGlow  = {1.00, 0.95, 0.40, 0.3},
    uiBg        = {0.10, 0.10, 0.15},
    uiText      = {0.90, 0.90, 0.95},
    uiAccent    = {0.40, 0.70, 1.00},
}

function Renderer.new(cellSize, offsetX, offsetY)
    local self = setmetatable({}, Renderer)
    self.cellSize = cellSize
    self.offsetX = offsetX
    self.offsetY = offsetY
    self.wallWidth = 2
    self.time = 0
    return self
end

-- 미로 그리기
function Renderer:drawMaze(maze)
    local cs = self.cellSize
    local ox = self.offsetX
    local oy = self.offsetY

    -- 배경 (경로 영역)
    love.graphics.setColor(COLORS.path)
    love.graphics.rectangle("fill", ox, oy, maze.cols * cs, maze.rows * cs)

    -- 각 셀의 벽 그리기
    love.graphics.setColor(COLORS.wall)
    love.graphics.setLineWidth(self.wallWidth)
    love.graphics.setLineStyle("rough")

    for y = 1, maze.rows do
        for x = 1, maze.cols do
            local cell = maze:getWalls(x, y)
            local px = ox + (x - 1) * cs
            local py = oy + (y - 1) * cs

            -- North wall (bit 0)
            if cell % 2 == 1 then
                love.graphics.line(px, py, px + cs, py)
            end
            -- South wall (bit 1)
            if math.floor(cell / 2) % 2 == 1 then
                love.graphics.line(px, py + cs, px + cs, py + cs)
            end
            -- West wall (bit 2)
            if math.floor(cell / 4) % 2 == 1 then
                love.graphics.line(px, py, px, py + cs)
            end
            -- East wall (bit 3)
            if math.floor(cell / 8) % 2 == 1 then
                love.graphics.line(px + cs, py, px + cs, py + cs)
            end
        end
    end

    -- 외곽 벽 (확실하게 그리기)
    love.graphics.setColor(COLORS.wall)
    love.graphics.setLineWidth(self.wallWidth + 1)
    love.graphics.rectangle("line", ox, oy, maze.cols * cs, maze.rows * cs)
end

-- 시작/탈출 위치 표시
function Renderer:drawMarkers(maze)
    local cs = self.cellSize
    local ox = self.offsetX
    local oy = self.offsetY
    local padding = 4

    -- 시작 위치 (초록)
    love.graphics.setColor(COLORS.start)
    love.graphics.rectangle("fill",
        ox + (maze.startX - 1) * cs + padding,
        oy + (maze.startY - 1) * cs + padding,
        cs - padding * 2, cs - padding * 2, 4)

    -- 탈출 위치 (빨간색, 펄스 애니메이션)
    local pulse = 0.7 + 0.3 * math.sin(self.time * 3)
    love.graphics.setColor(COLORS.exit[1], COLORS.exit[2], COLORS.exit[3], pulse)
    love.graphics.rectangle("fill",
        ox + (maze.exitX - 1) * cs + padding,
        oy + (maze.exitY - 1) * cs + padding,
        cs - padding * 2, cs - padding * 2, 4)

    -- 탈출 위치 아이콘 (별 모양 힌트)
    love.graphics.setColor(1, 1, 1, pulse * 0.8)
    local ex = ox + (maze.exitX - 1) * cs + cs / 2
    local ey = oy + (maze.exitY - 1) * cs + cs / 2
    love.graphics.print("EXIT", ex - 14, ey - 8)
end

-- 플레이어 그리기
function Renderer:drawPlayer(player)
    local cs = self.cellSize
    local radius = cs * 0.3

    -- 글로우 효과
    love.graphics.setColor(COLORS.playerGlow)
    love.graphics.circle("fill", player.pixelX, player.pixelY, radius + 4)

    -- 플레이어 원
    love.graphics.setColor(COLORS.player)
    love.graphics.circle("fill", player.pixelX, player.pixelY, radius)

    -- 하이라이트
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.circle("fill", player.pixelX - 2, player.pixelY - 2, radius * 0.3)
end

-- 보물 그리기
function Renderer:drawTreasures(treasure, cellSize, offsetX, offsetY)
    local cs = cellSize or self.cellSize
    local ox = offsetX or self.offsetX
    local oy = offsetY or self.offsetY

    for _, item in ipairs(treasure.items) do
        if not item.collected then
            local cx = ox + (item.gridX - 1) * cs + cs / 2
            local cy = oy + (item.gridY - 1) * cs + cs / 2

            -- 부유 애니메이션
            local float = math.sin(item.animTimer) * 2

            -- 글로우
            love.graphics.setColor(item.color[1], item.color[2], item.color[3], 0.25)
            love.graphics.circle("fill", cx, cy + float, item.radius + 4)

            -- 보물 다이아몬드 모양
            love.graphics.setColor(item.color)
            local r = item.radius
            love.graphics.polygon("fill",
                cx, cy + float - r,
                cx + r, cy + float,
                cx, cy + float + r,
                cx - r, cy + float
            )

            -- 하이라이트
            love.graphics.setColor(1, 1, 1, 0.6)
            love.graphics.circle("fill", cx - 1, cy + float - 2, 2)
        end
    end
end

-- UI 그리기 (점수, 이동 횟수 등)
function Renderer:drawUI(player, treasure, maze, elapsedTime)
    local w = love.graphics.getWidth()
    local uiY = self.offsetY + maze.rows * self.cellSize + 10

    -- UI 배경
    love.graphics.setColor(COLORS.uiBg)
    love.graphics.rectangle("fill", 0, uiY, w, 50)

    -- 구분선
    love.graphics.setColor(COLORS.uiAccent)
    love.graphics.setLineWidth(1)
    love.graphics.line(0, uiY, w, uiY)

    -- 폰트 설정
    local font = love.graphics.getFont()

    -- 점수
    love.graphics.setColor(COLORS.uiAccent)
    love.graphics.print("SCORE", 20, uiY + 8)
    love.graphics.setColor(COLORS.uiText)
    love.graphics.print(tostring(player.score), 20, uiY + 26)

    -- 이동 횟수
    love.graphics.setColor(COLORS.uiAccent)
    love.graphics.print("MOVES", 140, uiY + 8)
    love.graphics.setColor(COLORS.uiText)
    love.graphics.print(tostring(player.moveCount), 140, uiY + 26)

    -- 보물
    love.graphics.setColor(COLORS.uiAccent)
    love.graphics.print("TREASURE", 260, uiY + 8)
    love.graphics.setColor(COLORS.uiText)
    local totalTreasures = #treasure.items
    local remaining = treasure:remainingCount()
    love.graphics.print(
        tostring(totalTreasures - remaining) .. " / " .. tostring(totalTreasures),
        260, uiY + 26
    )

    -- 시간
    love.graphics.setColor(COLORS.uiAccent)
    love.graphics.print("TIME", 420, uiY + 8)
    love.graphics.setColor(COLORS.uiText)
    local mins = math.floor(elapsedTime / 60)
    local secs = math.floor(elapsedTime % 60)
    love.graphics.print(string.format("%02d:%02d", mins, secs), 420, uiY + 26)

    -- 조작법 안내
    love.graphics.setColor(0.5, 0.5, 0.55)
    love.graphics.print("Arrow Keys: Move  |  ESC: Menu  |  R: Restart", 540, uiY + 18)
end

-- 시간 업데이트
function Renderer:update(dt)
    self.time = self.time + dt
end

return Renderer
