local Animations = {}
Animations.__index = Animations

local NEW_TILE_DURATION = 0.15
local MERGE_TILE_DURATION = 0.2
local SLIDE_DURATION = 0.1

function Animations.new()
    local self = setmetatable({}, Animations)
    self.active = {}
    self.slideActive = false
    self.slideElapsed = 0
    self.slideMovements = {}
    self.pendingNewTile = nil
    self.pendingMerges = {}
    return self
end

function Animations:startNewTileAnimation(r, c)
    self.active[newTileKey(r, c)] = {
        type = "new",
        elapsed = 0,
        duration = NEW_TILE_DURATION,
        row = r,
        col = c,
    }
end

function Animations:startMergeAnimation(r, c)
    self.active[mergeTileKey(r, c)] = {
        type = "merge",
        elapsed = 0,
        duration = MERGE_TILE_DURATION,
        row = r,
        col = c,
    }
end

function Animations:update(dt)
    if self.slideActive then
        self.slideElapsed = self.slideElapsed + dt
        if self.slideElapsed >= SLIDE_DURATION then
            self.slideActive = false
            if self.pendingNewTile then
                self:startNewTileAnimation(self.pendingNewTile.r, self.pendingNewTile.c)
            end
            for _, pos in ipairs(self.pendingMerges) do
                self:startMergeAnimation(pos.r, pos.c)
            end
            self.pendingNewTile = nil
            self.pendingMerges = {}
        end
        return
    end

    local toRemove = {}
    for key, anim in pairs(self.active) do
        anim.elapsed = anim.elapsed + dt
        if anim.elapsed >= anim.duration then
            table.insert(toRemove, key)
        end
    end
    for _, key in ipairs(toRemove) do
        self.active[key] = nil
    end
end

function Animations:getTileScale(r, c)
    local newAnim = self.active[newTileKey(r, c)]
    if newAnim then
        local t = newAnim.elapsed / newAnim.duration
        t = math.min(t, 1.0)
        return easeOutBack(t)
    end

    local mergeAnim = self.active[mergeTileKey(r, c)]
    if mergeAnim then
        local t = mergeAnim.elapsed / mergeAnim.duration
        t = math.min(t, 1.0)
        return 1.0 + 0.2 * math.sin(t * math.pi)
    end

    return 1.0
end

function Animations:isAnimating()
    if self.slideActive then return true end
    return next(self.active) ~= nil
end

function Animations:isSliding()
    return self.slideActive
end

function Animations:getSlideProgress()
    if not self.slideActive then return 1.0 end
    local t = math.min(self.slideElapsed / SLIDE_DURATION, 1.0)
    return easeOutQuad(t)
end

function Animations:getSlideMovements()
    return self.slideMovements
end

function Animations:startFromGrid(grid)
    if grid.tileMovements and #grid.tileMovements > 0 then
        self.slideActive = true
        self.slideElapsed = 0
        self.slideMovements = grid.tileMovements
        self.pendingNewTile = grid.newTilePos
        self.pendingMerges = grid.mergedPositions or {}
    else
        if grid.newTilePos then
            self:startNewTileAnimation(grid.newTilePos.r, grid.newTilePos.c)
        end
        for _, pos in ipairs(grid.mergedPositions or {}) do
            self:startMergeAnimation(pos.r, pos.c)
        end
    end
end

function Animations:clear()
    self.active = {}
    self.slideActive = false
    self.slideMovements = {}
    self.pendingNewTile = nil
    self.pendingMerges = {}
end

function newTileKey(r, c)
    return "new_" .. r .. "_" .. c
end

function mergeTileKey(r, c)
    return "merge_" .. r .. "_" .. c
end

function easeOutBack(t)
    local c1 = 1.70158
    local c3 = c1 + 1
    return 1 + c3 * math.pow(t - 1, 3) + c1 * math.pow(t - 1, 2)
end

function easeOutQuad(t)
    return t * (2 - t)
end

return Animations
