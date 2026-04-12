local Input = {}
Input.__index = Input

local SWIPE_THRESHOLD = 30

function Input.new()
    local self = setmetatable({}, Input)
    self.touchStartX = nil
    self.touchStartY = nil
    return self
end

function Input.getDirection(key)
    if key == "up" or key == "w" then
        return "up"
    elseif key == "down" or key == "s" then
        return "down"
    elseif key == "left" or key == "a" then
        return "left"
    elseif key == "right" or key == "d" then
        return "right"
    end
    return nil
end

function Input:touchStarted(x, y)
    self.touchStartX = x
    self.touchStartY = y
end

function Input:touchEnded(x, y)
    if self.touchStartX == nil then return nil end
    local dx = x - self.touchStartX
    local dy = y - self.touchStartY
    self.touchStartX = nil
    self.touchStartY = nil

    local absDx = math.abs(dx)
    local absDy = math.abs(dy)

    if math.max(absDx, absDy) < SWIPE_THRESHOLD then return nil end

    if absDx > absDy then
        return dx > 0 and "right" or "left"
    else
        return dy > 0 and "down" or "up"
    end
end

return Input
