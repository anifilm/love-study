-- game/game_state.lua — 게임 상태 머신

local Bird = require("game.bird")
local PipeManager = require("game.pipe_manager")
local Background = require("game.background")
local Score = require("ui.score")

local GameState = {}
GameState.__index = GameState

-- 상태 상수
local STATE_MENU = "menu"
local STATE_PLAYING = "playing"
local STATE_GAMEOVER = "gameover"

-- 싱글턴
local instance = nil

function GameState:init()
    self.state = STATE_MENU
    self.bird = Bird.new()
    self.pipeManager = PipeManager.new()
    self.background = Background.new()
    self.score = Score.new()
    self.groundY = self.background:getGroundY()
end

function GameState:update(dt)
    if self.state == STATE_MENU then
        -- 메뉴: 새가 부유하는 애니메이션
        self.bird.y = 256 + math.sin(love.timer.getTime() * 3) * 10

    elseif self.state == STATE_PLAYING then
        self.background:update(dt)
        self.bird:update(dt)

        -- 파이프 업데이트 + 점수 판정
        local scoreGain = self.pipeManager:update(dt, self.bird)
        if scoreGain > 0 then
            self.score:add(scoreGain)
        end

        -- 충돌 판정: 파이프
        if self.pipeManager:checkCollision(self.bird) then
            self:gameOver()
        end

        -- 충돌 판정: 땅 / 천장
        local b = self.bird:getBounds()
        if b.y + b.h >= self.groundY or b.y <= 0 then
            self:gameOver()
        end

    elseif self.state == STATE_GAMEOVER then
        -- 게임 오버: 새가 땅으로 떨어짐
        if self.bird.y + self.bird.radius < self.groundY then
            self.bird.velocity = self.bird.velocity + 980 * dt
            self.bird.y = self.bird.y + self.bird.velocity * dt
            self.bird.rotation = math.rad(90)
            if self.bird.y + self.bird.radius > self.groundY then
                self.bird.y = self.groundY - self.bird.radius
            end
        end
    end
end

function GameState:draw()
    self.background:draw()
    self.pipeManager:draw()
    self.background:drawGround()
    self.bird:draw()

    if self.state == STATE_MENU then
        self:drawMenu()
    elseif self.state == STATE_PLAYING then
        self.score:drawCurrent()
    elseif self.state == STATE_GAMEOVER then
        self.score:drawCurrent()
        self:drawGameOver()
    end
end

function GameState:keypressed(key)
    if key == "escape" then
        love.event.quit()
    end

    if key == "space" then
        self:handleAction()
    end
end

function GameState:mousepressed(x, y, button)
    if button == 1 then
        self:handleAction()
    end
end

function GameState:handleAction()
    if self.state == STATE_MENU then
        self.state = STATE_PLAYING
        self.bird:jump()
    elseif self.state == STATE_PLAYING then
        self.bird:jump()
    elseif self.state == STATE_GAMEOVER then
        self:restart()
    end
end

function GameState:gameOver()
    self.state = STATE_GAMEOVER
    self.bird.alive = false
    self.score:saveBest()
end

function GameState:restart()
    self.state = STATE_PLAYING
    self.bird:reset()
    self.pipeManager:reset()
    self.background:reset()
    self.score:reset()
    self.bird:jump()
end

function GameState:drawMenu()
    local w = love.graphics.getWidth()

    -- 제목
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Flappy Bird", 0, 120, w, "center")

    -- 안내 문구 (깜빡임)
    local alpha = 0.5 + 0.5 * math.sin(love.timer.getTime() * 4)
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.printf("Press SPACE to Start", 0, 320, w, "center")

    love.graphics.setColor(1, 1, 1)
end

function GameState:drawGameOver()
    local w = love.graphics.getWidth()

    -- 반투명 배경
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 150, w, 200)

    -- Game Over 텍스트
    love.graphics.setColor(1, 0.3, 0.3)
    love.graphics.printf("Game Over", 0, 170, w, "center")

    -- 점수
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Score: " .. self.score.current, 0, 220, w, "center")
    love.graphics.printf("Best: " .. self.score.best, 0, 250, w, "center")

    -- 재시작 안내
    local alpha = 0.5 + 0.5 * math.sin(love.timer.getTime() * 4)
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.printf("Press SPACE to Restart", 0, 300, w, "center")

    love.graphics.setColor(1, 1, 1)
end

return GameState
