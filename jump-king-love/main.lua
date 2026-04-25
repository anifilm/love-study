-- Jump King 스타일의 수직 상승 플랫포머 MVP
-- Framework: LÖVE2D (https://love2d.org/)

---------------------------------------------------------
-- 1. 상수 및 설정값 (물리 감각 조정용)
---------------------------------------------------------
local GRAVITY = 1500          -- 중력 가속도
local PLAYER_SPEED = 200      -- 지상 이동 속도
local AIR_CONTROL = 0.2       -- 공중 제어력 (0~1, 1이면 지상과 동일)
local MAX_JUMP_POWER = 800    -- 최대 점프 힘
local MIN_JUMP_POWER = 200    -- 최소 점프 힘
local CHARGE_SPEED = 600      -- 초당 차지 속도
local JUMP_ANGLE = math.rad(75) -- 점프 각도 (수직에 가까울수록 높게 뜀)

local SCREEN_WIDTH = 800
local SCREEN_HEIGHT = 600

---------------------------------------------------------
-- 2. 게임 상태 및 객체 정의
---------------------------------------------------------
local player = {
    x = 400,
    y = 500,
    width = 30,
    height = 40,
    vx = 0,
    vy = 0,
    isGrounded = false,
    isCharging = false,
    chargeAmount = 0,
    direction = 0, -- -1: 왼쪽, 0: 정지, 1: 오른쪽
    maxReachedY = 500
}

local platforms = {}
local camera = {
    y = 0
}

---------------------------------------------------------
-- 3. 초기화 (love.load)
---------------------------------------------------------
function love.load()
    love.window.setTitle("Vertical Climber MVP")
    love.window.setMode(SCREEN_WIDTH, SCREEN_HEIGHT)

    -- 플랫폼 생성 (수직 구조)
    -- 바닥
    table.insert(platforms, {x = 0, y = 550, width = 800, height = 50})

    -- 계단식 플랫폼 배치 (도달 가능성 고려)
    local lastY = 550
    local lastX = 0
    local lastW = 800

    for i = 1, 100 do
        local w = love.math.random(120, 200)

        -- 이전 플랫폼에서 점프해서 닿을 수 있는 수평 범위 계산
        -- 최대 점프 시 수평 이동 거리가 약 200~250px임을 고려
        local jumpRange = 220
        local minX = math.max(50, lastX - jumpRange)
        local maxX = math.min(SCREEN_WIDTH - w - 50, lastX + lastW + jumpRange - w)

        local x = love.math.random(minX, maxX)
        local y = lastY - love.math.random(130, 170) -- 수직 간격도 도달 가능하게 제한

        table.insert(platforms, {x = x, y = y, width = w, height = 20})

        -- 가끔씩 옆에 보조 발판 추가 (낙하 방지 및 경로 다양화)
        if love.math.random() > 0.7 then
            local sideW = 80
            local sideX = (x < SCREEN_WIDTH / 2) and (x + w + 50) or (x - sideW - 50)
            if sideX > 0 and sideX + sideW < SCREEN_WIDTH then
                table.insert(platforms, {x = sideX, y = y - 30, width = sideW, height = 20})
            end
        end

        lastX = x
        lastW = w
        lastY = y
    end
end

---------------------------------------------------------
-- 4. 업데이트 로직 (love.update)
---------------------------------------------------------
function love.update(dt)
    -- 4.1 입력 처리 (좌우 이동)
    player.direction = 0
    if love.keyboard.isDown("left") then
        player.direction = -1
    elseif love.keyboard.isDown("right") then
        player.direction = 1
    end

    -- 4.2 점프 차지 처리
    if player.isGrounded and love.keyboard.isDown("space") then
        player.isCharging = true
        player.chargeAmount = math.min(player.chargeAmount + CHARGE_SPEED * dt, MAX_JUMP_POWER)
    else
        -- 스페이스바를 뗐을 때 점프 실행 (love.keyreleased에서 처리해도 되지만 여기서 상태 변화 감지)
        if player.isCharging then
            jump()
        end
    end

    -- 4.3 물리 엔진 (중력 및 이동)
    if not player.isCharging then
        -- 공중 제어 또는 지상 이동
        local targetVx = player.direction * PLAYER_SPEED
        if player.isGrounded then
            player.vx = targetVx
        else
            -- 공중에서는 관성을 유지하며 아주 약간만 제어 가능
            player.vx = player.vx + (targetVx - player.vx) * AIR_CONTROL * dt * 10
        end
    else
        -- 차지 중에는 이동 불가
        player.vx = 0
    end

    -- 중력 적용
    if not player.isGrounded then
        player.vy = player.vy + GRAVITY * dt
    end

    -- 위치 업데이트
    player.x = player.x + player.vx * dt
    player.y = player.y + player.vy * dt

    -- 4.4 충돌 처리 (단순 AABB)
    checkCollisions()

    -- 4.5 화면 경계 처리 (좌우 벽)
    if player.x < 0 then
        player.x = 0
        player.vx = -player.vx * 0.5 -- 벽에 부딪히면 튕김
    elseif player.x + player.width > SCREEN_WIDTH then
        player.x = SCREEN_WIDTH - player.width
        player.vx = -player.vx * 0.5
    end

    -- 4.6 카메라 업데이트 (플레이어를 부드럽게 추적)
    local targetCamY = player.y - SCREEN_HEIGHT * 0.6
    camera.y = camera.y + (targetCamY - camera.y) * 5 * dt

    -- 최고 높이 기록
    if player.y < player.maxReachedY then
        player.maxReachedY = player.y
    end
end

---------------------------------------------------------
-- 5. 점프 함수
---------------------------------------------------------
function jump()
    local power = math.max(player.chargeAmount, MIN_JUMP_POWER)

    -- 점프 방향 계산
    player.vy = -math.sin(JUMP_ANGLE) * power
    player.vx = player.direction * math.cos(JUMP_ANGLE) * power

    player.isGrounded = false
    player.isCharging = false
    player.chargeAmount = 0
end

---------------------------------------------------------
-- 6. 충돌 체크 함수
---------------------------------------------------------
function checkCollisions()
    local wasGrounded = player.isGrounded
    player.isGrounded = false

    for _, plat in ipairs(platforms) do
        -- 플레이어가 플랫폼 위에 있고, 아래로 떨어지는 중일 때만 착지 (One-way platform 방식)
        if player.x + player.width > plat.x and
           player.x < plat.x + plat.width and
           player.y + player.height >= plat.y and
           player.y + player.height <= plat.y + plat.height + 10 and -- 약간의 오차 허용
           player.vy >= 0 then

            player.y = plat.y - player.height
            player.vy = 0

            -- 공중에서 떨어지다 착지했을 때만 속도를 0으로 (Jump King 스타일 착지)
            if not wasGrounded then
                player.vx = 0
            end

            player.isGrounded = true
            return
        end
    end
end

---------------------------------------------------------
-- 7. 그리기 (love.draw)
---------------------------------------------------------
function love.draw()
    -- 카메라 적용
    love.graphics.push()
    love.graphics.translate(0, -camera.y)

    -- 배경 (간단한 가이드 라인)
    love.graphics.setColor(0.2, 0.2, 0.2)
    for i = 0, 10 do
        local lineY = 550 - i * 1000
        love.graphics.line(0, lineY, SCREEN_WIDTH, lineY)
    end

    -- 플랫폼 그리기
    love.graphics.setColor(0.7, 0.7, 0.7)
    for _, plat in ipairs(platforms) do
        love.graphics.rectangle("fill", plat.x, plat.y, plat.width, plat.height)
    end

    -- 플레이어 그리기
    if player.isCharging then
        love.graphics.setColor(1, 0.5, 0) -- 차지 중에는 주황색
    elseif not player.isGrounded then
        love.graphics.setColor(0.5, 0.5, 1) -- 공중에서는 파란색
    else
        love.graphics.setColor(0, 1, 0) -- 지상에서는 초록색
    end
    love.graphics.rectangle("fill", player.x, player.y, player.width, player.height)

    love.graphics.pop()

    -- UI (카메라 영향 받지 않음)
    drawUI()
end

function drawUI()
    -- 차지 게이지
    if player.isCharging then
        local gaugeWidth = 200
        local fillWidth = (player.chargeAmount / MAX_JUMP_POWER) * gaugeWidth
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.rectangle("fill", 20, 20, gaugeWidth, 20)
        love.graphics.setColor(1, 0, 0)
        love.graphics.rectangle("fill", 20, 20, fillWidth, 20)
    end

    -- 높이 정보
    love.graphics.setColor(1, 1, 1)
    local currentHeight = math.floor((550 - player.y) / 10)
    local maxHeight = math.floor((550 - player.maxReachedY) / 10)
    love.graphics.print("Current Height: " .. currentHeight, 20, 50)
    love.graphics.print("Max Height: " .. maxHeight, 20, 70)
    love.graphics.print("Controls: Left/Right to move, Hold Space to Jump", 20, SCREEN_HEIGHT - 30)
end

---------------------------------------------------------
-- 8. 키 입력 이벤트
---------------------------------------------------------
function love.keyreleased(key)
    if key == "space" and player.isCharging then
        jump()
    end
end
