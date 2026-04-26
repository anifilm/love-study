--[[
    gameover.lua - 게임 클리어 상태
    결과 표시, 재시작/메뉴 복귀
]]

local GameOver = {}
GameOver.__index = GameOver

function GameOver.new()
    local self = setmetatable({}, GameOver)
    self.result = nil
    self.time = 0
    self.titleFont = nil
    self.normalFont = nil
    self.smallFont = nil
    return self
end

function GameOver:load()
    local fontPath = "assets/fonts/AppleGothic.ttf"
    self.titleFont = love.graphics.newFont(fontPath, 42)
    self.normalFont = love.graphics.newFont(fontPath, 22)
    self.smallFont = love.graphics.newFont(fontPath, 16)
    self.time = 0
end

function GameOver:setResult(result)
    self.result = result
end

function GameOver:update(dt)
    self.time = self.time + dt
end

function GameOver:draw()
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()

    -- 배경
    love.graphics.clear(0.10, 0.10, 0.15)

    if not self.result then return end

    -- 클리어 타이틀
    love.graphics.setFont(self.titleFont)
    local titleText = "* ESCAPE! *"
    local titleW = self.titleFont:getWidth(titleText)
    love.graphics.setColor(1.0, 0.85, 0.3)
    love.graphics.print(titleText, (w - titleW) / 2, h * 0.12)

    -- 결과 박스
    local boxW = 360
    local boxH = 220
    local boxX = (w - boxW) / 2
    local boxY = h * 0.25

    love.graphics.setColor(0.15, 0.15, 0.22)
    love.graphics.rectangle("fill", boxX, boxY, boxW, boxH, 8)
    love.graphics.setColor(0.4, 0.7, 1.0)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", boxX, boxY, boxW, boxH, 8)

    -- 결과 항목
    love.graphics.setFont(self.normalFont)
    local items = {
        { label = "난이도",   value = self.result.difficulty },
        { label = "점수",     value = tostring(self.result.score) },
        { label = "이동 횟수", value = tostring(self.result.moves) },
        { label = "보물",     value = self.result.treasures .. " / " .. self.result.totalTreasures },
        { label = "시간",     value = string.format("%02d:%02d",
            math.floor(self.result.time / 60), math.floor(self.result.time % 60)) },
    }

    for i, item in ipairs(items) do
        local iy = boxY + 20 + (i - 1) * 38
        love.graphics.setColor(0.5, 0.7, 1.0)
        love.graphics.print(item.label, boxX + 25, iy)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(item.value, boxX + 200, iy)
    end

    -- 재시작 안내 (깜빡임)
    love.graphics.setFont(self.normalFont)
    local blink = math.sin(self.time * 3) * 0.3 + 0.7
    love.graphics.setColor(0.4, 0.8, 1.0, blink)
    local restartText = "Press ENTER to Restart"
    local restartW = self.normalFont:getWidth(restartText)
    love.graphics.print(restartText, (w - restartW) / 2, h * 0.72)

    -- 메뉴 복귀 안내
    love.graphics.setFont(self.smallFont)
    love.graphics.setColor(0.4, 0.4, 0.5)
    local menuText = "Press ESC for Menu"
    local menuW = self.smallFont:getWidth(menuText)
    love.graphics.print(menuText, (w - menuW) / 2, h * 0.80)
end

function GameOver:keypressed(key)
    if key == "return" or key == "kpenter" then
        return "play", self.result and self.result.difficulty or "MEDIUM"
    elseif key == "escape" then
        return "menu"
    end
    return nil
end

return GameOver
