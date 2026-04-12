local Game = require("game")
local Renderer = require("renderer")
local Input = require("input")
local Animations = require("animations")

local game
local renderer
local input
local animations

function love.load()
    love.graphics.setBackgroundColor(0.980, 0.976, 0.937)
    renderer = Renderer.new()
    input = Input.new()
    animations = Animations.new()
    game = Game.new()
end

function love.update(dt)
    animations:update(dt)
end

function love.draw()
    renderer:draw(game, animations)
end

function love.keypressed(key)
    if key == "r" then
        game:restart()
        animations:clear()
        return
    end

    if key == "c" then
        if game.won and not game.keepPlaying then
            game:continueAfterWin()
        end
        return
    end

    local direction = Input.getDirection(key)
    if direction then
        if animations:isSliding() then return end
        local moved = game:move(direction)
        if moved then
            animations:startFromGrid(game.grid)
        end
    end
end

function love.touchstarted(id, x, y, dx, dy)
    input:touchStarted(x, y)
    return true
end

function love.touchended(id, x, y, dx, dy)
    local direction = input:touchEnded(x, y)
    if direction then
        if animations:isSliding() then return true end
        local moved = game:move(direction)
        if moved then
            animations:startFromGrid(game.grid)
        end
    end
    return true
end
