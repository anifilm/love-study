-- game/bird.lua — 새(플레이어)

local Bird = {}
Bird.__index = Bird

-- 상수
local GRAVITY = 980       -- px/s²
local JUMP_FORCE = -300   -- 위로 가는 velocity
local RADIUS = 12         -- 새 크기 (원형)
local MAX_ROTATION = math.rad(90)  -- 최대 회전 각도 (아래)
local ROTATION_SPEED = 1

function Bird.new()
    local self = setmetatable({}, Bird)
    self.x = 72           -- 화면 왼쪽에서 약간 떨어진 위치
    self.y = 256          -- 화면 중앙
    self.velocity = 0
    self.rotation = 0
    self.radius = RADIUS
    self.alive = true
    return self
end

function Bird:jump()
    if self.alive then
        self.velocity = JUMP_FORCE
    end
end

function Bird:update(dt)
    -- 중력 적용
    self.velocity = self.velocity + GRAVITY * dt
    self.y = self.y + self.velocity * dt

    -- 회전: 위로 올라가면 음수 각도, 아래로 떨어지면 양수 각도
    if self.velocity < 0 then
        -- 위로 올라갈 때: -25도 정도 기울임
        self.rotation = math.max(self.rotation - ROTATION_SPEED * dt * 50, math.rad(-25))
    else
        -- 아래로 떨어질 때: 점진적으로 90도까지 회전
        self.rotation = math.min(self.rotation + ROTATION_SPEED * dt * 5, MAX_ROTATION)
    end
end

function Bird:draw()
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.rotation)

    -- 몸통 (노란색 원)
    love.graphics.setColor(1, 0.85, 0)  -- 노란색
    love.graphics.circle("fill", 0, 0, self.radius)

    -- 눈 (흰색 원 + 검은색 동공)
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", 5, -4, 5)
    love.graphics.setColor(0, 0, 0)
    love.graphics.circle("fill", 7, -4, 2)

    -- 부리 (주황색 삼각형)
    love.graphics.setColor(1, 0.5, 0)
    love.graphics.polygon("fill", 10, 0, 18, 2, 10, 5)

    -- 날개 (작은 원)
    love.graphics.setColor(0.9, 0.75, 0)
    love.graphics.circle("fill", -4, 2, 6)

    love.graphics.pop()
    love.graphics.setColor(1, 1, 1)  -- 색상 리셋
end

function Bird:getBounds()
    -- 충돌 박스 (시각적보다 약간 작게 — 관대한 판정)
    local shrink = 3
    return {
        x = self.x - self.radius + shrink,
        y = self.y - self.radius + shrink,
        w = self.radius * 2 - shrink * 2,
        h = self.radius * 2 - shrink * 2
    }
end

function Bird:reset()
    self.x = 72
    self.y = 256
    self.velocity = 0
    self.rotation = 0
    self.alive = true
end

return Bird
