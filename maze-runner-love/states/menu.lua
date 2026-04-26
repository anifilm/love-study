--[[
    menu.lua - 시작 메뉴 상태
    게임 제목, 난이도 선택, 시작 안내
]]

local Menu = {}
Menu.__index = Menu

local Maze = require("modules.maze")

function Menu.new()
    local self = setmetatable({}, Menu)
    self.selectedDifficulty = 2  -- 1=Easy, 2=Medium, 3=Hard
    self.difficulties = {"Easy", "Medium", "Hard"}
    self.difficultyKeys = {"EASY", "MEDIUM", "HARD"}
    self.time = 0
    self.titleFont = nil
    self.normalFont = nil
    return self
end

function Menu:load()
    local fontPath = "assets/fonts/AppleGothic.ttf"
    self.titleFont = love.graphics.newFont(fontPath, 48)
    self.normalFont = love.graphics.newFont(fontPath, 20)
    self.smallFont = love.graphics.newFont(fontPath, 16)
    self.time = 0
end

function Menu:update(dt)
    self.time = self.time + dt
end

function Menu:draw()
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()

    -- 배경
    love.graphics.clear(0.10, 0.10, 0.15)

    -- 타이틀
    love.graphics.setFont(self.titleFont)
    local titleText = "MAZE RUNNER"
    local titleW = self.titleFont:getWidth(titleText)
    local titleY = h * 0.2
    -- 타이틀 그림자
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.print(titleText, (w - titleW) / 2 + 2, titleY + 2)
    -- 타이틀 본문
    love.graphics.setColor(1.0, 0.85, 0.3)
    love.graphics.print(titleText, (w - titleW) / 2, titleY)

    -- 서브타이틀
    love.graphics.setFont(self.smallFont)
    love.graphics.setColor(0.6, 0.6, 0.7)
    local subText = "미로를 탈출하고 보물을 모으세요!"
    local subW = self.smallFont:getWidth(subText)
    love.graphics.print(subText, (w - subW) / 2, titleY + 65)

    -- 난이도 선택
    love.graphics.setFont(self.normalFont)
    local diffY = h * 0.45
    love.graphics.setColor(0.5, 0.7, 1.0)
    local diffLabel = "난이도 선택"
    local diffLabelW = self.normalFont:getWidth(diffLabel)
    love.graphics.print(diffLabel, (w - diffLabelW) / 2, diffY - 35)

    for i, name in ipairs(self.difficulties) do
        local size = Maze.DIFFICULTY[self.difficultyKeys[i]]
        local text = name .. "  (" .. size.cols .. "×" .. size.rows .. ")"
        local textW = self.normalFont:getWidth(text)
        local itemY = diffY + (i - 1) * 35

        if i == self.selectedDifficulty then
            -- 선택된 항목
            love.graphics.setColor(1.0, 0.85, 0.3)
            love.graphics.print("▶ " .. text, (w - textW) / 2 - 20, itemY)
        else
            love.graphics.setColor(0.5, 0.5, 0.6)
            love.graphics.print("  " .. text, (w - textW) / 2 - 20, itemY)
        end
    end

    -- 시작 안내 (깜빡임)
    love.graphics.setFont(self.normalFont)
    local blink = math.sin(self.time * 3) * 0.3 + 0.7
    love.graphics.setColor(0.4, 0.8, 1.0, blink)
    local startText = "Press ENTER to Start"
    local startW = self.normalFont:getWidth(startText)
    love.graphics.print(startText, (w - startW) / 2, h * 0.75)

    -- 조작법
    love.graphics.setFont(self.smallFont)
    love.graphics.setColor(0.4, 0.4, 0.5)
    local controls = "↑↓: 난이도 선택  |  ENTER: 시작  |  ESC: 종료"
    local controlsW = self.smallFont:getWidth(controls)
    love.graphics.print(controls, (w - controlsW) / 2, h * 0.88)
end

function Menu:keypressed(key)
    if key == "up" then
        self.selectedDifficulty = self.selectedDifficulty - 1
        if self.selectedDifficulty < 1 then
            self.selectedDifficulty = #self.difficulties
        end
    elseif key == "down" then
        self.selectedDifficulty = self.selectedDifficulty + 1
        if self.selectedDifficulty > #self.difficulties then
            self.selectedDifficulty = 1
        end
    elseif key == "return" or key == "kpenter" then
        return "play", self.difficultyKeys[self.selectedDifficulty]
    elseif key == "escape" then
        love.event.quit()
    end
    return nil
end

return Menu
