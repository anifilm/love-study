--[[
    main.lua - Maze Runner 엔트리포인트
    게임 상태 관리 및 콜백 위임
]]

local Menu     = require("states.menu")
local Play     = require("states.play")
local GameOver = require("states.gameover")

-- 게임 상태
local currentState = nil
local currentStateName = ""
local menu = nil
local play = nil
local gameover = nil

-- 상태 전환
local function switchState(stateName, data)
    currentStateName = stateName

    if stateName == "menu" then
        currentState = menu
        menu:load()

    elseif stateName == "play" then
        local difficulty = data or "MEDIUM"
        play:load(difficulty)
        currentState = play

    elseif stateName == "gameover" then
        gameover:setResult(data)
        gameover:load()
        currentState = gameover
    end
end

function love.load()
    -- 랜덤 시드 초기화
    love.math.setRandomSeed(os.time())

    -- 상태 객체 생성
    menu     = Menu.new()
    play     = Play.new()
    gameover = GameOver.new()

    -- 기본 폰트 설정 (한글 지원)
    local fontPath = "assets/fonts/AppleGothic.ttf"
    local defaultFont = love.graphics.newFont(fontPath, 18)
    love.graphics.setFont(defaultFont)

    -- 시작 상태: 메뉴
    switchState("menu")
end

function love.update(dt)
    if currentState and currentState.update then
        currentState:update(dt)
    end

    -- play 상태에서 탈출 시 gameover로 전환
    if currentStateName == "play" and play.gameoverResult then
        switchState("gameover", play.gameoverResult)
        play.gameoverResult = nil
    end
end

function love.draw()
    if currentState and currentState.draw then
        currentState:draw()
    end
end

function love.keypressed(key)
    if not currentState or not currentState.keypressed then return end

    local nextState, data = currentState:keypressed(key)

    if nextState then
        switchState(nextState, data)
    end
end
