--[[
    play.lua - 게임 플레이 상태
    미로 생성, 플레이어 이동, 보물 수집, 탈출 체크
]]

local Maze      = require("modules.maze")
local Player    = require("modules.player")
local Treasure  = require("modules.treasure")
local Renderer  = require("modules.renderer")

local Play = {}
Play.__index = Play

function Play.new()
    local self = setmetatable({}, Play)
    self.maze = nil
    self.player = nil
    self.treasure = nil
    self.renderer = nil
    self.difficulty = "MEDIUM"
    self.elapsedTime = 0
    self.cellSize = 0
    self.offsetX = 0
    self.offsetY = 0
    self.message = nil
    self.messageTimer = 0
    return self
end

function Play:load(difficulty)
    self.difficulty = difficulty or "MEDIUM"
    self.elapsedTime = 0
    self.message = nil
    self.messageTimer = 0
    self.gameoverResult = nil

    -- 미로 크기 결정
    local size = Maze.DIFFICULTY[self.difficulty]

    -- 셀 크기 계산 (미로 영역에 맞게)
    local mazeAreaW = love.graphics.getWidth() - 40   -- 좌우 여백
    local mazeAreaH = love.graphics.getHeight() - 80   -- 상단 여백 + UI 영역
    local cellW = math.floor(mazeAreaW / size.cols)
    local cellH = math.floor(mazeAreaH / size.rows)
    self.cellSize = math.min(cellW, cellH)
    -- 셀 크기 상한/하한
    self.cellSize = math.max(self.cellSize, 16)
    self.cellSize = math.min(self.cellSize, 48)

    -- 미로 중앙 정렬 오프셋
    local totalMazeW = size.cols * self.cellSize
    local totalMazeH = size.rows * self.cellSize
    self.offsetX = math.floor((love.graphics.getWidth() - totalMazeW) / 2)
    self.offsetY = 15

    -- 미로 생성
    self.maze = Maze.new(size.cols, size.rows)

    -- 플레이어 생성
    self.player = Player.new(self.maze.startX, self.maze.startY)
    self.player:initPixelPos(self.cellSize, self.offsetX, self.offsetY)

    -- 보물 배치 (미로 크기의 약 8%)
    self.treasure = Treasure.new()
    local treasureCount = math.floor(size.cols * size.rows * 0.08)
    treasureCount = math.max(treasureCount, 3)
    self.treasure:placeTreasures(self.maze, treasureCount)

    -- 렌더러 생성
    self.renderer = Renderer.new(self.cellSize, self.offsetX, self.offsetY)
end

function Play:update(dt)
    self.elapsedTime = self.elapsedTime + dt
    self.treasure:update(dt)
    self.renderer:update(dt)

    -- 메시지 타이머
    if self.messageTimer > 0 then
        self.messageTimer = self.messageTimer - dt
        if self.messageTimer <= 0 then
            self.message = nil
        end
    end

    -- 키보드 상태로 이동 방향 결정 (매 프레임)
    local dir = nil
    if love.keyboard.isDown("up", "w")    then dir = "up"    end
    if love.keyboard.isDown("down", "s")  then dir = "down"  end
    if love.keyboard.isDown("left", "a")  then dir = "left"  end
    if love.keyboard.isDown("right", "d") then dir = "right" end
    self.player.moveDir = dir

    -- 플레이어 연속 이동 업데이트
    local prevGX, prevGY = self.player.gridX, self.player.gridY
    self.player:update(dt, self.maze)

    -- 격자가 바뀌었을 때 보물/탈출 체크
    if self.player.gridX ~= prevGX or self.player.gridY ~= prevGY then
        -- 보물 획득 체크
        local points, treasureType = self.treasure:checkCollection(
            self.player.gridX, self.player.gridY)
        if points > 0 then
            self.player:collectTreasure(points)
            self.message = "+" .. points .. " (" .. treasureType .. ")"
            self.messageTimer = 1.5
        end

        -- 탈출 체크
        if self.maze:isExit(self.player.gridX, self.player.gridY) then
            self.player.moveDir = nil
            self.gameoverResult = {
                score = self.player.score,
                moves = self.player.moveCount,
                treasures = self.player.treasuresCollected,
                totalTreasures = #self.treasure.items,
                time = self.elapsedTime,
                difficulty = self.difficulty,
            }
        end
    end
end

function Play:draw()
    -- 배경
    love.graphics.clear(0.10, 0.10, 0.15)

    -- 미로
    self.renderer:drawMaze(self.maze)

    -- 시작/탈출 마커
    self.renderer:drawMarkers(self.maze)

    -- 보물
    self.renderer:drawTreasures(self.treasure)

    -- 플레이어
    self.renderer:drawPlayer(self.player)

    -- UI
    self.renderer:drawUI(self.player, self.treasure, self.maze, self.elapsedTime)

    -- 메시지 표시
    if self.message then
        local alpha = math.min(self.messageTimer, 1.0)
        love.graphics.setColor(1, 1, 1, alpha)
        local font = love.graphics.getFont()
        local tw = font:getWidth(self.message)
        love.graphics.print(self.message,
            love.graphics.getWidth() / 2 - tw / 2,
            love.graphics.getHeight() / 2 - 10)
    end
end

function Play:keypressed(key)
    if key == "escape" then
        return "menu"
    end

    if key == "r" then
        self:load(self.difficulty)
        return nil
    end

    return nil
end

return Play
