local Grid = require("grid")

local Game = {}
Game.__index = Game

function Game.new()
    local self = setmetatable({}, Game)
    self.grid = Grid.new()
    self.score = 0
    self.bestScore = self:loadBestScore()
    self.gameOver = false
    self.won = false
    self.keepPlaying = false
    self.grid:addRandomTile()
    self.grid:addRandomTile()
    return self
end

function Game:restart()
    self.grid:reset()
    self.score = 0
    self.gameOver = false
    self.won = false
    self.keepPlaying = false
    self.grid:addRandomTile()
    self.grid:addRandomTile()
end

function Game:move(direction)
    if self.gameOver then return false end
    if self.won and not self.keepPlaying then return false end

    local moved, mergeScore = self.grid:move(direction)
    if moved then
        self.score = self.score + mergeScore
        if self.score > self.bestScore then
            self.bestScore = self.score
            self:saveBestScore()
        end
        self.grid:addRandomTile()

        if not self.keepPlaying and self.grid:hasWon() then
            self.won = true
        elseif not self.grid:canMove() then
            self.gameOver = true
        end
    end
    return moved
end

function Game:continueAfterWin()
    self.keepPlaying = true
end

function Game:loadBestScore()
    local info = love.filesystem.getInfo("bestscore.txt")
    if info then
        local contents = love.filesystem.read("bestscore.txt")
        if contents then
            return tonumber(contents) or 0
        end
    end
    return 0
end

function Game:saveBestScore()
    love.filesystem.write("bestscore.txt", tostring(self.bestScore))
end

return Game
