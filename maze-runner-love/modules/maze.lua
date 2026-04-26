--[[
    maze.lua - 미로 생성 모듈
    Recursive Backtracking (반복문 기반 DFS) 알고리즘 사용
]]

local Maze = {}
Maze.__index = Maze

-- 난이도별 미로 크기
Maze.DIFFICULTY = {
    EASY   = { cols = 10, rows = 8  },
    MEDIUM = { cols = 20, rows = 15 },
    HARD   = { cols = 30, rows = 20 },
}

-- 방향 정의 (dx, dy, 비트 플래그, 반대 방향 비트)
local DIRS = {
    { dx =  0, dy = -1, wall = 1, opposite = 2 },  -- North (up)
    { dx =  0, dy =  1, wall = 2, opposite = 1 },  -- South (down)
    { dx = -1, dy =  0, wall = 4, opposite = 8 },  -- West (left)
    { dx =  1, dy =  0, wall = 8, opposite = 4 },  -- East (right)
}

function Maze.new(cols, rows)
    local self = setmetatable({}, Maze)
    self.cols = cols
    self.rows = rows
    self.grid = {}
    self.startX = 1
    self.startY = 1
    self.exitX = cols
    self.exitY = rows
    self:generate()
    return self
end

function Maze:generate()
    -- 격자 초기화: 각 셀에 4방향 벽 모두 설정 (비트마스크)
    self.grid = {}
    for y = 1, self.rows do
        self.grid[y] = {}
        for x = 1, self.cols do
            self.grid[y][x] = 15  -- 1111 (N=1, S=2, W=4, E=8)
        end
    end

    -- Recursive Backtracking (반복문 버전)
    local visited = {}
    for y = 1, self.rows do
        visited[y] = {}
        for x = 1, self.cols do
            visited[y][x] = false
        end
    end

    local stack = {}
    local startX, startY = 1, 1
    visited[startY][startX] = true
    table.insert(stack, { x = startX, y = startY })

    while #stack > 0 do
        local current = stack[#stack]
        local cx, cy = current.x, current.y

        -- 방문하지 않은 이웃 찾기
        local neighbors = {}
        for _, dir in ipairs(DIRS) do
            local nx, ny = cx + dir.dx, cy + dir.dy
            if nx >= 1 and nx <= self.cols and ny >= 1 and ny <= self.rows and not visited[ny][nx] then
                table.insert(neighbors, { x = nx, y = ny, dir = dir })
            end
        end

        if #neighbors > 0 then
            -- 랜덤 이웃 선택
            local chosen = neighbors[love.math.random(#neighbors)]
            local nx, ny = chosen.x, chosen.y
            local dir = chosen.dir

            -- 두 셀 사이의 벽 제거
            self.grid[cy][cx] = self.grid[cy][cx] - dir.wall
            self.grid[ny][nx] = self.grid[ny][nx] - dir.opposite

            -- 이웃 방문 처리 및 스택에 push
            visited[ny][nx] = true
            table.insert(stack, { x = nx, y = ny })
        else
            -- 이웃이 없으면 backtrack
            table.remove(stack)
        end
    end
end

-- 특정 방향으로 이동 가능한지 확인 (벽이 없을 때 이동 가능)
function Maze:canMove(x, y, direction)
    if x < 1 or x > self.cols or y < 1 or y > self.rows then
        return false
    end
    local cell = self.grid[y][x]
    if direction == "up"    then return cell % 2 == 0 end  -- North 벽 비트(bit0)가 0이면 이동 가능
    if direction == "down"  then return math.floor(cell / 2) % 2 == 0 end  -- South 벽 비트(bit1)가 0이면 이동 가능
    if direction == "left"  then return math.floor(cell / 4) % 2 == 0 end  -- West 벽 비트(bit2)가 0이면 이동 가능
    if direction == "right" then return math.floor(cell / 8) % 2 == 0 end  -- East 벽 비트(bit3)가 0이면 이동 가능
    return false
end

-- 셀의 벽 비트 반환
function Maze:getWalls(x, y)
    if x < 1 or x > self.cols or y < 1 or y > self.rows then
        return 15
    end
    return self.grid[y][x]
end

-- 탈출 지점 도달 확인
function Maze:isExit(x, y)
    return x == self.exitX and y == self.exitY
end

return Maze
