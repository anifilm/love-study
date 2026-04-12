local Grid = {}
Grid.__index = Grid

function Grid.new()
    local self = setmetatable({}, Grid)
    self.size = 4
    self.cells = {}
    self.score = 0
    self.mergedPositions = {}
    self.tileMovements = {}
    self.newTilePos = nil
    for r = 1, self.size do
        self.cells[r] = {}
        for c = 1, self.size do
            self.cells[r][c] = 0
        end
    end
    return self
end

function Grid:reset()
    for r = 1, self.size do
        for c = 1, self.size do
            self.cells[r][c] = 0
        end
    end
    self.score = 0
    self.mergedPositions = {}
    self.tileMovements = {}
    self.newTilePos = nil
end

function Grid:emptyPositions()
    local positions = {}
    for r = 1, self.size do
        for c = 1, self.size do
            if self.cells[r][c] == 0 then
                table.insert(positions, {r = r, c = c})
            end
        end
    end
    return positions
end

function Grid:addRandomTile()
    local empty = self:emptyPositions()
    if #empty == 0 then return false end
    local pos = empty[math.random(#empty)]
    self.cells[pos.r][pos.c] = math.random() < 0.9 and 2 or 4
    self.newTilePos = pos
    return pos
end

function Grid:get(row, col)
    return self.cells[row][col]
end

function Grid:set(row, col, value)
    self.cells[row][col] = value
end

local function processLineWithTracking(line)
    local result = {0, 0, 0, 0}
    local mergedIndices = {}
    local score = 0
    local movements = {}

    local nonZero = {}
    for i = 1, #line do
        if line[i] ~= 0 then
            table.insert(nonZero, {value = line[i], origIdx = i})
        end
    end

    local destIdx = 1
    local i = 1
    while i <= #nonZero do
        if i < #nonZero and nonZero[i].value == nonZero[i + 1].value then
            local val = nonZero[i].value * 2
            result[destIdx] = val
            table.insert(mergedIndices, destIdx)
            score = score + val
            table.insert(movements, {fromIdx = nonZero[i].origIdx, toIdx = destIdx, value = nonZero[i].value})
            table.insert(movements, {fromIdx = nonZero[i + 1].origIdx, toIdx = destIdx, value = nonZero[i + 1].value})
            i = i + 2
        else
            result[destIdx] = nonZero[i].value
            table.insert(movements, {fromIdx = nonZero[i].origIdx, toIdx = destIdx, value = nonZero[i].value})
            i = i + 1
        end
        destIdx = destIdx + 1
    end

    return result, mergedIndices, score, movements
end

local function reverseLine(line)
    local result = {}
    for i = #line, 1, -1 do
        table.insert(result, line[i])
    end
    return result
end

function Grid:move(direction)
    self.mergedPositions = {}
    self.tileMovements = {}
    local moved = false
    local totalMergeScore = 0

    if direction == "left" then
        for r = 1, self.size do
            local line = {self:get(r, 1), self:get(r, 2), self:get(r, 3), self:get(r, 4)}
            local processed, mergedIndices, mergeScore, movements = processLineWithTracking(line)
            for c = 1, 4 do
                if self:get(r, c) ~= processed[c] then moved = true end
                self:set(r, c, processed[c])
            end
            totalMergeScore = totalMergeScore + mergeScore
            for _, idx in ipairs(mergedIndices) do
                table.insert(self.mergedPositions, {r = r, c = idx})
            end
            for _, mov in ipairs(movements) do
                table.insert(self.tileMovements, {
                    fromR = r, fromC = mov.fromIdx,
                    toR = r, toC = mov.toIdx,
                    value = mov.value
                })
            end
        end
    elseif direction == "right" then
        for r = 1, self.size do
            local line = {self:get(r, 1), self:get(r, 2), self:get(r, 3), self:get(r, 4)}
            local reversed = reverseLine(line)
            local processed, mergedIndices, mergeScore, movements = processLineWithTracking(reversed)
            processed = reverseLine(processed)
            for c = 1, 4 do
                if self:get(r, c) ~= processed[c] then moved = true end
                self:set(r, c, processed[c])
            end
            totalMergeScore = totalMergeScore + mergeScore
            for _, idx in ipairs(mergedIndices) do
                table.insert(self.mergedPositions, {r = r, c = 5 - idx})
            end
            for _, mov in ipairs(movements) do
                table.insert(self.tileMovements, {
                    fromR = r, fromC = 5 - mov.fromIdx,
                    toR = r, toC = 5 - mov.toIdx,
                    value = mov.value
                })
            end
        end
    elseif direction == "up" then
        for c = 1, self.size do
            local line = {self:get(1, c), self:get(2, c), self:get(3, c), self:get(4, c)}
            local processed, mergedIndices, mergeScore, movements = processLineWithTracking(line)
            for r = 1, 4 do
                if self:get(r, c) ~= processed[r] then moved = true end
                self:set(r, c, processed[r])
            end
            totalMergeScore = totalMergeScore + mergeScore
            for _, idx in ipairs(mergedIndices) do
                table.insert(self.mergedPositions, {r = idx, c = c})
            end
            for _, mov in ipairs(movements) do
                table.insert(self.tileMovements, {
                    fromR = mov.fromIdx, fromC = c,
                    toR = mov.toIdx, toC = c,
                    value = mov.value
                })
            end
        end
    elseif direction == "down" then
        for c = 1, self.size do
            local line = {self:get(1, c), self:get(2, c), self:get(3, c), self:get(4, c)}
            local reversed = reverseLine(line)
            local processed, mergedIndices, mergeScore, movements = processLineWithTracking(reversed)
            processed = reverseLine(processed)
            for r = 1, 4 do
                if self:get(r, c) ~= processed[r] then moved = true end
                self:set(r, c, processed[r])
            end
            totalMergeScore = totalMergeScore + mergeScore
            for _, idx in ipairs(mergedIndices) do
                table.insert(self.mergedPositions, {r = 5 - idx, c = c})
            end
            for _, mov in ipairs(movements) do
                table.insert(self.tileMovements, {
                    fromR = 5 - mov.fromIdx, fromC = c,
                    toR = 5 - mov.toIdx, toC = c,
                    value = mov.value
                })
            end
        end
    end

    self.score = self.score + totalMergeScore
    return moved, totalMergeScore
end

function Grid:canMove()
    for r = 1, self.size do
        for c = 1, self.size do
            if self.cells[r][c] == 0 then return true end
            if c < self.size and self.cells[r][c] == self.cells[r][c + 1] then return true end
            if r < self.size and self.cells[r][c] == self.cells[r + 1][c] then return true end
        end
    end
    return false
end

function Grid:hasWon()
    for r = 1, self.size do
        for c = 1, self.size do
            if self.cells[r][c] == 2048 then return true end
        end
    end
    return false
end

function Grid:clone()
    local copy = Grid.new()
    copy.score = self.score
    for r = 1, self.size do
        for c = 1, self.size do
            copy.cells[r][c] = self.cells[r][c]
        end
    end
    return copy
end

return Grid
