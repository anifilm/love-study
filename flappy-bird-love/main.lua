-- Flappy Bird (LÖVE)
-- main.lua — 엔트리포인트

local GameState = require("game.game_state")

function love.load()
    GameState:init()
end

function love.update(dt)
    GameState:update(dt)
end

function love.draw()
    GameState:draw()
end

function love.keypressed(key)
    GameState:keypressed(key)
end

function love.mousepressed(x, y, button)
    GameState:mousepressed(x, y, button)
end
