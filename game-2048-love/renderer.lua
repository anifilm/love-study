local Tile = require("tile")

local Renderer = {}
Renderer.__index = Renderer

local GRID_SIZE = 4
local CELL_SIZE = 100
local CELL_PADDING = 12
local GRID_PADDING = 15
local GRID_WIDTH = GRID_SIZE * CELL_SIZE + (GRID_SIZE + 1) * CELL_PADDING
local GRID_X = 15
local GRID_Y = 150

local BG_COLOR = {0.980, 0.976, 0.937}
local GRID_BG_COLOR = {0.733, 0.678, 0.627}
local EMPTY_CELL_COLOR = {0.804, 0.757, 0.706}
local TITLE_COLOR = {0.467, 0.431, 0.396}
local SCORE_BG = {0.733, 0.678, 0.627}
local SCORE_LABEL_COLOR = {0.933, 0.894, 0.855}
local SCORE_VALUE_COLOR = {1, 1, 1}
local OVERLAY_COLOR = {0.933, 0.894, 0.855, 0.588}
local OVERLAY_TEXT_COLOR = {0.467, 0.431, 0.396}

function Renderer.new()
    local self = setmetatable({}, Renderer)
    self.titleFont = love.graphics.newFont(60)
    self.scoreLabelFont = love.graphics.newFont(14)
    self.scoreValueFont = love.graphics.newFont(22)
    self.hintFont = love.graphics.newFont(16)
    self.overlayTitleFont = love.graphics.newFont(50)
    self.overlaySubFont = love.graphics.newFont(20)
    self.overlayKeepFont = love.graphics.newFont(16)
    self.scoreFont = love.graphics.newFont(18)
    return self
end

function Renderer:drawBackground()
    love.graphics.setColor(BG_COLOR[1], BG_COLOR[2], BG_COLOR[3])
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
end

function Renderer:drawTitle()
    love.graphics.setColor(TITLE_COLOR[1], TITLE_COLOR[2], TITLE_COLOR[3])
    love.graphics.setFont(self.titleFont)
    love.graphics.print("2048", GRID_X, 15)
end

function Renderer:drawScoreBox(x, y, label, value)
    local boxW = 100
    local boxH = 55
    love.graphics.setColor(SCORE_BG[1], SCORE_BG[2], SCORE_BG[3])
    love.graphics.rectangle("fill", x, y, boxW, boxH, 6)

    love.graphics.setColor(SCORE_LABEL_COLOR[1], SCORE_LABEL_COLOR[2], SCORE_LABEL_COLOR[3])
    love.graphics.setFont(self.scoreLabelFont)
    local lw = self.scoreLabelFont:getWidth(label)
    love.graphics.print(label, x + boxW / 2 - lw / 2, y + 8)

    love.graphics.setColor(SCORE_VALUE_COLOR[1], SCORE_VALUE_COLOR[2], SCORE_VALUE_COLOR[3])
    love.graphics.setFont(self.scoreValueFont)
    local vw = self.scoreValueFont:getWidth(tostring(value))
    love.graphics.print(tostring(value), x + boxW / 2 - vw / 2, y + 27)
end

function Renderer:drawScores(score, bestScore)
    local rightEdge = GRID_X + GRID_WIDTH
    local scoreX = rightEdge - 215
    local bestX = rightEdge - 105
    self:drawScoreBox(scoreX, 15, "SCORE", score)
    self:drawScoreBox(bestX, 15, "BEST", bestScore)
end

function Renderer:drawHint()
    love.graphics.setColor(TITLE_COLOR[1], TITLE_COLOR[2], TITLE_COLOR[3])
    love.graphics.setFont(self.hintFont)
    love.graphics.print("Join the numbers and get to the 2048 tile!", GRID_X, 85)
    love.graphics.print("Arrow keys or WASD to move. R to restart.", GRID_X, 110)
end

function Renderer:drawGridBackground()
    love.graphics.setColor(GRID_BG_COLOR[1], GRID_BG_COLOR[2], GRID_BG_COLOR[3])
    love.graphics.rectangle("fill", GRID_X, GRID_Y, GRID_WIDTH, GRID_WIDTH, 8)

    for r = 0, GRID_SIZE - 1 do
        for c = 0, GRID_SIZE - 1 do
            local x = GRID_X + CELL_PADDING + c * (CELL_SIZE + CELL_PADDING)
            local y = GRID_Y + CELL_PADDING + r * (CELL_SIZE + CELL_PADDING)
            love.graphics.setColor(EMPTY_CELL_COLOR[1], EMPTY_CELL_COLOR[2], EMPTY_CELL_COLOR[3])
            love.graphics.rectangle("fill", x, y, CELL_SIZE, CELL_SIZE, 6)
        end
    end
end

function Renderer:drawTiles(grid, animations)
    if animations and animations:isSliding() then
        local progress = animations:getSlideProgress()
        local movements = animations:getSlideMovements()
        for _, mov in ipairs(movements) do
            local x_from = GRID_X + CELL_PADDING + (mov.fromC - 1) * (CELL_SIZE + CELL_PADDING)
            local y_from = GRID_Y + CELL_PADDING + (mov.fromR - 1) * (CELL_SIZE + CELL_PADDING)
            local x_to = GRID_X + CELL_PADDING + (mov.toC - 1) * (CELL_SIZE + CELL_PADDING)
            local y_to = GRID_Y + CELL_PADDING + (mov.toR - 1) * (CELL_SIZE + CELL_PADDING)
            local x = x_from + (x_to - x_from) * progress
            local y = y_from + (y_to - y_from) * progress
            Tile.draw(x, y, CELL_SIZE, mov.value)
        end
    else
        for r = 1, GRID_SIZE do
            for c = 1, GRID_SIZE do
                local value = grid:get(r, c)
                if value > 0 then
                    local x = GRID_X + CELL_PADDING + (c - 1) * (CELL_SIZE + CELL_PADDING)
                    local y = GRID_Y + CELL_PADDING + (r - 1) * (CELL_SIZE + CELL_PADDING)

                    local scale = 1.0
                    if animations then
                        scale = animations:getTileScale(r, c) or 1.0
                    end

                    Tile.draw(x, y, CELL_SIZE, value, scale)
                end
            end
        end
    end
end

function Renderer:drawGameOver()
    love.graphics.setColor(OVERLAY_COLOR[1], OVERLAY_COLOR[2], OVERLAY_COLOR[3], OVERLAY_COLOR[4])
    love.graphics.rectangle("fill", GRID_X, GRID_Y, GRID_WIDTH, GRID_WIDTH, 8)

    love.graphics.setColor(OVERLAY_TEXT_COLOR[1], OVERLAY_TEXT_COLOR[2], OVERLAY_TEXT_COLOR[3])
    love.graphics.setFont(self.overlayTitleFont)
    local text = "Game Over!"
    local tw = self.overlayTitleFont:getWidth(text)
    local cx = GRID_X + GRID_WIDTH / 2
    local cy = GRID_Y + GRID_WIDTH / 2
    love.graphics.print(text, cx - tw / 2, cy - 40)

    love.graphics.setFont(self.overlaySubFont)
    local sub = "Press R to restart"
    local sw = self.overlaySubFont:getWidth(sub)
    love.graphics.print(sub, cx - sw / 2, cy + 25)
end

function Renderer:drawWon()
    love.graphics.setColor(OVERLAY_COLOR[1], OVERLAY_COLOR[2], OVERLAY_COLOR[3], OVERLAY_COLOR[4])
    love.graphics.rectangle("fill", GRID_X, GRID_Y, GRID_WIDTH, GRID_WIDTH, 8)

    love.graphics.setColor(OVERLAY_TEXT_COLOR[1], OVERLAY_TEXT_COLOR[2], OVERLAY_TEXT_COLOR[3])
    love.graphics.setFont(self.overlayTitleFont)
    local text = "You Win!"
    local tw = self.overlayTitleFont:getWidth(text)
    local cx = GRID_X + GRID_WIDTH / 2
    local cy = GRID_Y + GRID_WIDTH / 2
    love.graphics.print(text, cx - tw / 2, cy - 45)

    love.graphics.setFont(self.overlayKeepFont)
    local keep = "Press C to keep playing, R to restart"
    local kw = self.overlayKeepFont:getWidth(keep)
    love.graphics.print(keep, cx - kw / 2, cy + 20)
end

function Renderer:draw(game, animations)
    self:drawBackground()
    self:drawTitle()
    self:drawScores(game.score, game.bestScore)
    self:drawHint()
    self:drawGridBackground()
    self:drawTiles(game.grid, animations)

    if game.gameOver then
        self:drawGameOver()
    elseif game.won and not game.keepPlaying then
        self:drawWon()
    end
end

return Renderer
