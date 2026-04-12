-- Tetris Love - LÖVE2D 기반 테트리스 게임
-- 완성 버전: Phase 0~5 모두 구현 (이동, 회전, 자동낙하, 라인클리어, 점수, 게임오버)

local BLOCK_SIZE = 30
local GRID_WIDTH = 10
local GRID_HEIGHT = 20

-- Playfield (2D grid)
local grid = {}

-- Tetromino shapes (4 rotations)
local tetrominoes = {
    I = {
        { {0,0,0,0}, {1,1,1,1}, {0,0,0,0}, {0,0,0,0} },
        { {0,1,0,0}, {0,1,0,0}, {0,1,0,0}, {0,1,0,0} },
        { {0,0,0,0}, {1,1,1,1}, {0,0,0,0}, {0,0,0,0} },
        { {0,1,0,0}, {0,1,0,0}, {0,1,0,0}, {0,1,0,0} }
    },
    O = {
        { {0,0,0,0}, {0,2,2,0}, {0,2,2,0}, {0,0,0,0} },
        { {0,0,0,0}, {0,2,2,0}, {0,2,2,0}, {0,0,0,0} },
        { {0,0,0,0}, {0,2,2,0}, {0,2,2,0}, {0,0,0,0} },
        { {0,0,0,0}, {0,2,2,0}, {0,2,2,0}, {0,0,0,0} }
    },
    T = {
        { {0,0,0,0}, {0,3,0,0}, {3,3,3,0}, {0,0,0,0} },
        { {0,3,0,0}, {0,3,3,0}, {0,3,0,0}, {0,0,0,0} },
        { {0,0,0,0}, {3,3,3,0}, {0,3,0,0}, {0,0,0,0} },
        { {0,3,0,0}, {3,3,0,0}, {0,3,0,0}, {0,0,0,0} }
    },
    S = {
        { {0,0,0,0}, {0,4,4,0}, {4,4,0,0}, {0,0,0,0} },
        { {0,4,0,0}, {0,4,4,0}, {0,0,4,0}, {0,0,0,0} },
        { {0,0,0,0}, {0,4,4,0}, {4,4,0,0}, {0,0,0,0} },
        { {0,4,0,0}, {0,4,4,0}, {0,0,4,0}, {0,0,0,0} }
    },
    Z = {
        { {0,0,0,0}, {5,5,0,0}, {0,5,5,0}, {0,0,0,0} },
        { {0,0,5,0}, {0,5,5,0}, {0,5,0,0}, {0,0,0,0} },
        { {0,0,0,0}, {5,5,0,0}, {0,5,5,0}, {0,0,0,0} },
        { {0,0,5,0}, {0,5,5,0}, {0,5,0,0}, {0,0,0,0} }
    },
    J = {
        { {0,0,0,0}, {6,0,0,0}, {6,6,6,0}, {0,0,0,0} },
        { {0,6,6,0}, {0,6,0,0}, {0,6,0,0}, {0,0,0,0} },
        { {0,0,0,0}, {6,6,6,0}, {0,0,6,0}, {0,0,0,0} },
        { {0,6,0,0}, {0,6,0,0}, {6,6,0,0}, {0,0,0,0} }
    },
    L = {
        { {0,0,0,0}, {0,0,7,0}, {7,7,7,0}, {0,0,0,0} },
        { {0,7,0,0}, {0,7,0,0}, {0,7,7,0}, {0,0,0,0} },
        { {0,0,0,0}, {7,7,7,0}, {7,0,0,0}, {0,0,0,0} },
        { {7,7,0,0}, {0,7,0,0}, {0,7,0,0}, {0,0,0,0} }
    }
}

local colors = {
    {0.0, 0.8, 1.0}, -- I (cyan)
    {1.0, 1.0, 0.0}, -- O (yellow)
    {0.8, 0.0, 0.8}, -- T (purple)
    {0.0, 1.0, 0.0}, -- S (green)
    {1.0, 0.0, 0.0}, -- Z (red)
    {0.0, 0.0, 1.0}, -- J (blue)
    {1.0, 0.6, 0.0}  -- L (orange)
}

-- Wall kick data (SRS-style)
-- Format: key = "from_to", value = {{dx, dy}, ...}
local wallKickData = {
    -- J, L, S, T, Z pieces
    ["JLSTZ"] = {
        ["0_1"] = {{0,0}, {-1,0}, {-1,-1}, {0,2}, {-1,2}},   -- 0->1
        ["1_2"] = {{0,0}, {1,0}, {1,1}, {0,-2}, {1,-2}},      -- 1->2
        ["2_3"] = {{0,0}, {1,0}, {1,-1}, {0,2}, {1,2}},       -- 2->3
        ["3_0"] = {{0,0}, {-1,0}, {-1,1}, {0,-2}, {-1,-2}},  -- 3->0
        ["1_0"] = {{0,0}, {1,0}, {1,-1}, {0,2}, {1,2}},       -- 1->0 (CCW)
        ["2_1"] = {{0,0}, {-1,0}, {-1,1}, {0,-2}, {-1,-2}},  -- 2->1 (CCW)
        ["3_2"] = {{0,0}, {-1,0}, {-1,-1}, {0,2}, {-1,2}},   -- 3->2 (CCW)
        ["0_3"] = {{0,0}, {1,0}, {1,1}, {0,-2}, {1,-2}},     -- 0->3 (CCW)
    },
    -- I piece (different offsets - SRS standard)
    ["I"] = {
           ["0_1"] = {{0,0}, {-2,0}, {1,0}, {-2,1}, {1,-2}},    -- 0->1 (CW)
           ["1_2"] = {{0,0}, {-1,0}, {2,0}, {-1,-2}, {2,1}},    -- 1->2 (CW)
           ["2_3"] = {{0,0}, {2,0}, {-1,0}, {2,-1}, {-1,2}},    -- 2->3 (CW)
           ["3_0"] = {{0,0}, {1,0}, {-2,0}, {1,2}, {-2,-1}},    -- 3->0 (CW)
           ["1_0"] = {{0,0}, {2,0}, {-1,0}, {2,-1}, {-1,2}},    -- 1->0 (CCW)
           ["2_1"] = {{0,0}, {1,0}, {-2,0}, {1,2}, {-2,-1}},    -- 2->1 (CCW)
           ["3_2"] = {{0,0}, {-2,0}, {1,0}, {-2,1}, {1,-2}},    -- 3->2 (CCW)
           ["0_3"] = {{0,0}, {-1,0}, {2,0}, {-1,-2}, {2,1}},    -- 0->3 (CCW)
    },
}

-- Current falling piece
local currentPiece = nil
local nextPieceType = nil

-- Game state variables
local gameState = "playing"
local score = 0
local level = 1
local linesCleared = 0
local dropTimer = 0
local dropInterval = 0.8
local instructionTimer = 10  -- Instructions visible for 10 seconds

-- Collision detection (defined first, used by newPiece and lockPiece)
local function checkCollision(piece, x, y, shape)
    shape = shape or piece.shape
    for py = 1, 4 do
        for px = 1, 4 do
            if shape[py][px] ~= 0 then
                local newX = x + px
                local newY = y + py
                -- Check boundaries
                if newX < 1 or newX > GRID_WIDTH or newY > GRID_HEIGHT then
                    return true
                end
                -- Check locked blocks (only if within grid)
                if newY >= 1 and grid[newY] and grid[newY][newX] ~= 0 then
                    return true
                end
            end
        end
    end
    return false
end

-- Lock piece to grid
local function lockPiece()
    local piece = currentPiece
    if not piece then return end

    for py = 1, 4 do
        for px = 1, 4 do
            if piece.shape[py][px] ~= 0 then
                local gridX = piece.x + px
                local gridY = piece.y + py
                if gridY >= 1 and gridY <= GRID_HEIGHT and gridX >= 1 and gridX <= GRID_WIDTH then
                    grid[gridY][gridX] = piece.colorIndex
                end
            end
        end
    end

    -- Check for line clear
    local linesToClear = {}
    for y = GRID_HEIGHT, 1, -1 do
        local full = true
        for x = 1, GRID_WIDTH do
            if grid[y][x] == 0 then
                full = false
                break
            end
        end
        if full then
            table.insert(linesToClear, y)
        end
    end

    -- Clear lines and shift down
    for _, lineY in ipairs(linesToClear) do
        table.remove(grid, lineY)
        table.insert(grid, 1, {})
        for x = 1, GRID_WIDTH do
            grid[1][x] = 0
        end
        linesCleared = linesCleared + 1
    end

    -- Score calculation
    local lineScores = {100, 300, 500, 800}
    if #linesToClear > 0 then
        score = score + (lineScores[#linesToClear] or 100) * level
    end

    -- Level up every 10 lines
    level = math.floor(linesCleared / 10) + 1
    dropInterval = math.max(0.1, 0.8 - (level - 1) * 0.05)

    -- Spawn next piece
    currentPiece = {
        type = nextPieceType,
        shape = tetrominoes[nextPieceType][1],
        rotation = 1,
        x = 4,
        y = 0,
        colorIndex = ({I=1,O=2,T=3,S=4,Z=5,J=6,L=7})[nextPieceType]
    }

    -- Generate next piece
    local types = {"I","O","T","S","Z","J","L"}
    nextPieceType = types[math.random(1, #types)]

    -- Check game over
    if checkCollision(currentPiece, currentPiece.x, currentPiece.y) then
        gameState = "gameover"
    end
end

-- Piece generator
local function newPiece()
    local types = {"I","O","T","S","Z","J","L"}
    local type = types[math.random(1, #types)]
    local piece = {
        type = type,
        shape = tetrominoes[type][1],
        rotation = 1,
        x = 4,
        y = 0,
        colorIndex = ({I=1,O=2,T=3,S=4,Z=5,J=6,L=7})[type]
    }
    -- Spawn check
    if checkCollision(piece, piece.x, piece.y) then
        gameState = "gameover"
        print("Game Over!")
    end
    return piece
end


function love.load()
    love.graphics.setBackgroundColor(0.1, 0.1, 0.15)
    math.randomseed(os.time())
    --print("Tetris Love가 시작되었습니다! (완성 버전)")

    -- Grid 초기화 (빈 공간 = 0)
    for y = 1, GRID_HEIGHT do
        grid[y] = {}
        for x = 1, GRID_WIDTH do
            grid[y][x] = 0
        end
    end

    -- 초기 조각 생성
    currentPiece = newPiece()
    nextPieceType = currentPiece.type
end

function love.update(dt)
    if gameState ~= "playing" or not currentPiece then return end

    -- Hide instructions after 10 seconds
    if instructionTimer > 0 then
        instructionTimer = instructionTimer - dt
    end

    dropTimer = dropTimer + dt

    -- Auto drop
    if dropTimer >= dropInterval then
        if not checkCollision(currentPiece, currentPiece.x, currentPiece.y + 1) then
            currentPiece.y = currentPiece.y + 1
        else
            lockPiece()
        end
        dropTimer = 0
    end
end

function love.draw()
    -- Title
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(32))
    love.graphics.printf("TETRIS", 0, 30, 640, "center")
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.printf("Complete Tetris - LÖVE2D", 0, 65, 640, "center")

    -- Playfield border
    love.graphics.setColor(0.4, 0.4, 0.45)
    love.graphics.rectangle("line", 49, 99, GRID_WIDTH * BLOCK_SIZE + 2, GRID_HEIGHT * BLOCK_SIZE + 2)

    -- Draw locked blocks in grid
    for y = 1, GRID_HEIGHT do
        for x = 1, GRID_WIDTH do
            if grid[y][x] ~= 0 then
                local color = colors[grid[y][x]]
                love.graphics.setColor(color[1], color[2], color[3])
                love.graphics.rectangle("fill",
                    50 + (x-1)*BLOCK_SIZE, 100 + (y-1)*BLOCK_SIZE,
                    BLOCK_SIZE-1, BLOCK_SIZE-1)
            end
        end
    end

    -- Draw current falling piece
    if currentPiece then
        local color = colors[currentPiece.colorIndex]
        love.graphics.setColor(color[1], color[2], color[3])
        for py = 1, 4 do
            for px = 1, 4 do
                if currentPiece.shape[py][px] ~= 0 then
                    love.graphics.rectangle("fill",
                        50 + (currentPiece.x + px - 1) * BLOCK_SIZE,
                        100 + (currentPiece.y + py - 1) * BLOCK_SIZE,
                        BLOCK_SIZE - 1, BLOCK_SIZE - 1)
                end
            end
        end

        -- Draw ghost piece (only on level 1)
        if level == 1 then
            local ghostY = currentPiece.y
            while not checkCollision(currentPiece, currentPiece.x, ghostY + 1) do
                ghostY = ghostY + 1
            end
            if ghostY > currentPiece.y then
                love.graphics.setColor(color[1], color[2], color[3], 0.3)
                for py = 1, 4 do
                    for px = 1, 4 do
                        if currentPiece.shape[py][px] ~= 0 then
                            love.graphics.rectangle("fill",
                                50 + (currentPiece.x + px - 1) * BLOCK_SIZE,
                                100 + (ghostY + py - 1) * BLOCK_SIZE,
                                BLOCK_SIZE - 1, BLOCK_SIZE - 1)
                        end
                    end
                end
            end
        end
    end

    -- Game Over overlay
    if gameState == "gameover" then
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, 640, 480)
        love.graphics.setColor(1, 0.3, 0.3)
        love.graphics.setFont(love.graphics.newFont(48))
        love.graphics.printf("GAME OVER", 0, 180, 640, "center")
        love.graphics.setFont(love.graphics.newFont(24))
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Final Score: " .. score .. "\nPress ESC to quit", 0, 260, 640, "center")
    end

    -- Side panel
    love.graphics.setColor(0.2, 0.2, 0.25)
    love.graphics.rectangle("fill", 420, 100, 180, 300)

    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.setFont(love.graphics.newFont(18))
    love.graphics.print("NEXT", 470, 120)
    love.graphics.printf("SCORE\n" .. score, 470, 220, 120, "left")
    love.graphics.printf("LEVEL\n" .. level, 470, 280, 120, "left")
    love.graphics.printf("LINES\n" .. linesCleared, 470, 340, 120, "left")

    -- Draw Next piece preview (simple)
    if nextPieceType then
        local previewShape = tetrominoes[nextPieceType][1]
        local idx = ({I=1,O=2,T=3,S=4,Z=5,J=6,L=7})[nextPieceType]
        local color = colors[idx]
        love.graphics.setColor(color[1], color[2], color[3])
        for y = 1, 4 do
            for x = 1, 4 do
                if previewShape[y][x] ~= 0 then
                    love.graphics.rectangle("fill", 460 + (x-1)*18, 155 + (y-1)*18, 16, 16)
                end
            end
        end
    end

    -- Game Over overlay (drawn last to appear on top)
    if gameState == "gameover" then
        love.graphics.setColor(0, 0, 0, 0.85)
        love.graphics.rectangle("fill", 0, 0, 640, 720)
        love.graphics.setColor(1, 0.3, 0.3)
        love.graphics.setFont(love.graphics.newFont(48))
        love.graphics.printf("GAME OVER", 0, 250, 640, "center")
        love.graphics.setFont(love.graphics.newFont(24))
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Final Score: " .. score .. "\n\nENTER/SPACE: Restart\nESC: Quit", 0, 340, 640, "center")
    end

    -- Instruction (visible for first 10 seconds)
    if instructionTimer > 0 then
        love.graphics.setFont(love.graphics.newFont(14))
        love.graphics.setColor(0.6, 0.6, 0.7)
        love.graphics.printf("LEFT/RIGHT: Move  DOWN: Soft Drop\nSPACE: Hard Drop  Z/UP: CCW  X: CW\nESC: Quit", 50, 410, 540, "center")
    end
end

function love.keypressed(key)
    -- ESC works even when game is over
    if key == "escape" then
        love.event.quit()
    end

    if gameState == "gameover" then
        -- Press ENTER or SPACE to restart
        if key == "return" or key == "space" then
            -- Reset game state
            gameState = "playing"
            score = 0
            level = 1
            linesCleared = 0
            dropTimer = 0
            dropInterval = 0.8
            instructionTimer = 10

            -- Clear grid
            for y = 1, GRID_HEIGHT do
                grid[y] = {}
                for x = 1, GRID_WIDTH do
                    grid[y][x] = 0
                end
            end

            -- New pieces
            currentPiece = newPiece()
            nextPieceType = currentPiece.type
        end
        return
    end

    if gameState ~= "playing" then return end

    if key == "left" and currentPiece then
        if not checkCollision(currentPiece, currentPiece.x - 1, currentPiece.y) then
            currentPiece.x = currentPiece.x - 1
        end
    elseif key == "right" and currentPiece then
        if not checkCollision(currentPiece, currentPiece.x + 1, currentPiece.y) then
            currentPiece.x = currentPiece.x + 1
        end
    elseif key == "down" and currentPiece then
        if not checkCollision(currentPiece, currentPiece.x, currentPiece.y + 1) then
            currentPiece.y = currentPiece.y + 1
            score = score + 1  -- soft drop point
        end
    elseif (key == "space" or key == "return") and currentPiece then
        -- Hard drop
        while not checkCollision(currentPiece, currentPiece.x, currentPiece.y + 1) do
            currentPiece.y = currentPiece.y + 1
            score = score + 2
        end
        lockPiece()
    elseif (key == "z" or key == "up") and currentPiece then
        -- Rotate counter-clockwise with wall kick
        local oldRot = currentPiece.rotation
        local newRot = oldRot - 1
        if newRot < 1 then newRot = 4 end
        local newShape = tetrominoes[currentPiece.type][newRot]
        local kicked = false
        local kickTable = (currentPiece.type == "I") and wallKickData["I"] or wallKickData["JLSTZ"]
        local kickKey = (oldRot - 1) .. "_" .. (newRot - 1)
        local kickOffsets = kickTable[kickKey]
        if kickOffsets then
            for _, offset in ipairs(kickOffsets) do
                if not checkCollision(currentPiece, currentPiece.x + offset[1], currentPiece.y + offset[2], newShape) then
                    currentPiece.x = currentPiece.x + offset[1]
                    currentPiece.y = currentPiece.y + offset[2]
                    kicked = true
                    break
                end
            end
        end
        if not kicked and not checkCollision(currentPiece, currentPiece.x, currentPiece.y, newShape) then
            kicked = true
        end
        if kicked then
            currentPiece.rotation = newRot
            currentPiece.shape = newShape
        end
    elseif key == "x" and currentPiece then
        -- Rotate clockwise with wall kick
        local oldRot = currentPiece.rotation
        local newRot = (oldRot % 4) + 1
        local newShape = tetrominoes[currentPiece.type][newRot]
        local kicked = false
        local kickTable = (currentPiece.type == "I") and wallKickData["I"] or wallKickData["JLSTZ"]
        local kickKey = (oldRot - 1) .. "_" .. (newRot - 1)
        local kickOffsets = kickTable[kickKey]
        if kickOffsets then
            for _, offset in ipairs(kickOffsets) do
                if not checkCollision(currentPiece, currentPiece.x + offset[1], currentPiece.y + offset[2], newShape) then
                    currentPiece.x = currentPiece.x + offset[1]
                    currentPiece.y = currentPiece.y + offset[2]
                    kicked = true
                    break
                end
            end
        end
        if not kicked and not checkCollision(currentPiece, currentPiece.x, currentPiece.y, newShape) then
            kicked = true
        end
        if kicked then
            currentPiece.rotation = newRot
            currentPiece.shape = newShape
        end
    end
end
