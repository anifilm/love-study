-- Minesweeper for LÖVE 11.5
-- ========================

-- 난이도 설정
local DIFFICULTIES = {
    { name = "Easy",   cols = 9,  rows = 9,  mines = 10 },
    { name = "Medium", cols = 16, rows = 16, mines = 40 },
    { name = "Hard",   cols = 30, rows = 16, mines = 99 },
}

-- 셀 크기
local CELL_SIZE = 32
local HEADER_HEIGHT = 50

-- 게임 상태
local STATE_MENU    = "menu"
local STATE_PLAYING = "playing"
local STATE_WON     = "won"
local STATE_LOST    = "lost"

-- 셀 상태 플래그
local HIDDEN  = 0
local REVEALED = 1
local FLAGGED  = 2

-- 숫자 색상
local NUMBER_COLORS = {
    [1] = {0, 0, 1, 1},       -- 파랑
    [2] = {0, 0.5, 0, 1},     -- 초록
    [3] = {1, 0, 0, 1},       -- 빨강
    [4] = {0.5, 0, 0.5, 1},   -- 보라
    [5] = {0.5, 0, 0, 1},     -- burgundy
    [6] = {0, 0.5, 0.5, 1},   -- 청록
    [7] = {0, 0, 0, 1},       -- 검정
    [8] = {0.5, 0.5, 0.5, 1}, -- 회색
}

-- 전역 게임 변수
local game = {
    state = STATE_MENU,
    difficulty = 1,
    board = {},        -- { mine: bool, adjacent: number, cellState: number }
    cols = 0,
    rows = 0,
    mines = 0,
    flagsPlaced = 0,
    firstClick = true,
    timer = 0,
    boardOffsetX = 0,
    boardOffsetY = 0,
}

-- ========================
-- 유틸리티 함수
-- ========================

local function getCellIndex(col, row)
    return (row - 1) * game.cols + col
end

local function isValidCell(col, row)
    return col >= 1 and col <= game.cols and row >= 1 and row <= game.rows
end

local function getNeighbors(col, row)
    local neighbors = {}
    for dc = -1, 1 do
        for dr = -1, 1 do
            if not (dc == 0 and dr == 0) then
                local nc, nr = col + dc, row + dr
                if isValidCell(nc, nr) then
                    table.insert(neighbors, {col = nc, row = nr})
                end
            end
        end
    end
    return neighbors
end

-- ========================
-- 보드 초기화
-- ========================

local function initBoard(difficultyIndex)
    local diff = DIFFICULTIES[difficultyIndex]
    game.difficulty = difficultyIndex
    game.cols = diff.cols
    game.rows = diff.rows
    game.mines = diff.mines
    game.flagsPlaced = 0
    game.firstClick = true
    game.timer = 0
    game.state = STATE_PLAYING

    -- 보드 중앙 정렬 오프셋 계산
    local boardWidth = game.cols * CELL_SIZE
    local boardHeight = game.rows * CELL_SIZE
    game.boardOffsetX = math.floor((800 - boardWidth) / 2)
    game.boardOffsetY = HEADER_HEIGHT + math.floor((600 - HEADER_HEIGHT - boardHeight) / 2)

    -- 빈 보드 생성
    game.board = {}
    for row = 1, game.rows do
        for col = 1, game.cols do
            local idx = getCellIndex(col, row)
            game.board[idx] = {
                mine = false,
                adjacent = 0,
                cellState = HIDDEN,
            }
        end
    end
end

-- ========================
-- 지뢰 배치 (첫 클릭 위치 제외)
-- ========================

local function placeMines(safeCol, safeRow)
    -- 안전 영역: 첫 클릭 셀 + 인접 셀
    local safeCells = {}
    safeCells[getCellIndex(safeCol, safeRow)] = true
    for _, n in ipairs(getNeighbors(safeCol, safeRow)) do
        safeCells[getCellIndex(n.col, n.row)] = true
    end

    -- 후보 셀 수집
    local candidates = {}
    for row = 1, game.rows do
        for col = 1, game.cols do
            local idx = getCellIndex(col, row)
            if not safeCells[idx] then
                table.insert(candidates, idx)
            end
        end
    end

    -- 지뢰 수가 후보보다 많으면 조정
    local mineCount = math.min(game.mines, #candidates)

    -- Fisher-Yates 셔플
    for i = #candidates, 2, -1 do
        local j = love.math.random(1, i)
        candidates[i], candidates[j] = candidates[j], candidates[i]
    end

    -- 지뢰 배치
    for i = 1, mineCount do
        game.board[candidates[i]].mine = true
    end

    -- 인접 지뢰 수 계산
    for row = 1, game.rows do
        for col = 1, game.cols do
            local idx = getCellIndex(col, row)
            if not game.board[idx].mine then
                local count = 0
                for _, n in ipairs(getNeighbors(col, row)) do
                    if game.board[getCellIndex(n.col, n.row)].mine then
                        count = count + 1
                    end
                end
                game.board[idx].adjacent = count
            end
        end
    end
end

-- ========================
-- 셀 열기 (flood fill)
-- ========================

local function revealCell(col, row)
    if not isValidCell(col, row) then return end
    local idx = getCellIndex(col, row)
    local cell = game.board[idx]

    if cell.cellState == REVEALED or cell.cellState == FLAGGED then return end

    cell.cellState = REVEALED

    if cell.mine then
        game.state = STATE_LOST
        -- 모든 지뢰 공개
        for r = 1, game.rows do
            for c = 1, game.cols do
                local ci = getCellIndex(c, r)
                if game.board[ci].mine then
                    game.board[ci].cellState = REVEALED
                end
            end
        end
        return
    end

    -- 빈 칸이면 flood fill
    if cell.adjacent == 0 then
        for _, n in ipairs(getNeighbors(col, row)) do
            revealCell(n.col, n.row)
        end
    end
end

-- ========================
-- 승리 조건 체크
-- ========================

local function checkWin()
    for row = 1, game.rows do
        for col = 1, game.cols do
            local idx = getCellIndex(col, row)
            local cell = game.board[idx]
            if not cell.mine and cell.cellState ~= REVEALED then
                return false
            end
        end
    end
    return true
end

-- ========================
-- 좌표 변환
-- ========================

local function pixelToCell(x, y)
    local col = math.floor((x - game.boardOffsetX) / CELL_SIZE) + 1
    local row = math.floor((y - game.boardOffsetY) / CELL_SIZE) + 1
    if isValidCell(col, row) then
        return col, row
    end
    return nil, nil
end

-- ========================
-- LÖVE 콜백
-- ========================

function love.load()
    love.math.setRandomSeed(os.time())
end

function love.update(dt)
    if game.state == STATE_PLAYING and not game.firstClick then
        game.timer = game.timer + dt
    end
end

function love.draw()
    if game.state == STATE_MENU then
        drawMenu()
    else
        drawHeader()
        drawBoard()
        if game.state == STATE_WON or game.state == STATE_LOST then
            drawGameOver()
        end
    end
end

function love.mousepressed(x, y, button)
    if game.state == STATE_MENU then
        handleMenuClick(x, y)
        return
    end

    if game.state == STATE_WON or game.state == STATE_LOST then
        -- 게임 오버/승리 후 클릭 → 메뉴로
        if button == 1 then
            game.state = STATE_MENU
        end
        return
    end

    -- 리셋 버튼 영역 체크
    local resetX = 400
    local resetY = HEADER_HEIGHT / 2
    if button == 1 and x >= resetX - 20 and x <= resetX + 20 and y >= resetY - 15 and y <= resetY + 15 then
        initBoard(game.difficulty)
        return
    end

    local col, row = pixelToCell(x, y)
    if not col then return end

    local idx = getCellIndex(col, row)
    local cell = game.board[idx]

    if button == 1 then
        -- 좌클릭: 셀 열기
        if cell.cellState == HIDDEN then
            if game.firstClick then
                placeMines(col, row)
                game.firstClick = false
            end
            revealCell(col, row)
            if game.state == STATE_PLAYING and checkWin() then
                game.state = STATE_WON
            end
        end
    elseif button == 2 then
        -- 우클릭: 깃발 토글
        if cell.cellState == HIDDEN then
            cell.cellState = FLAGGED
            game.flagsPlaced = game.flagsPlaced + 1
        elseif cell.cellState == FLAGGED then
            cell.cellState = HIDDEN
            game.flagsPlaced = game.flagsPlaced - 1
        end
    end
end

function love.keypressed(key)
    if key == "escape" then
        if game.state ~= STATE_MENU then
            game.state = STATE_MENU
        else
            love.event.quit()
        end
    end
    if key == "r" and (game.state == STATE_WON or game.state == STATE_LOST) then
        initBoard(game.difficulty)
    end
end

-- ========================
-- 메뉴 렌더링
-- ========================

function drawMenu()
    -- 타이틀
    love.graphics.setColor(1, 1, 1)
    local titleFont = love.graphics.newFont(36)
    love.graphics.setFont(titleFont)
    love.graphics.printf("Minesweeper", 0, 100, 800, "center")

    -- 난이도 버튼
    local btnFont = love.graphics.newFont(20)
    love.graphics.setFont(btnFont)

    for i, diff in ipairs(DIFFICULTIES) do
        local btnY = 220 + (i - 1) * 70
        local btnW, btnH = 250, 50
        local btnX = (800 - btnW) / 2

        -- 버튼 배경
        love.graphics.setColor(0.3, 0.3, 0.4)
        love.graphics.rectangle("fill", btnX, btnY, btnW, btnH, 8, 8)

        -- 버튼 테두리
        love.graphics.setColor(0.6, 0.6, 0.7)
        love.graphics.rectangle("line", btnX, btnY, btnW, btnH, 8, 8)

        -- 버튼 텍스트
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(
            string.format("%s  (%dx%d, %d mines)", diff.name, diff.cols, diff.rows, diff.mines),
            btnX, btnY + 14, btnW, "center"
        )
    end

    -- 안내
    love.graphics.setColor(0.6, 0.6, 0.6)
    local smallFont = love.graphics.newFont(14)
    love.graphics.setFont(smallFont)
    love.graphics.printf("Left click: Reveal  |  Right click: Flag  |  ESC: Menu", 0, 500, 800, "center")
end

function handleMenuClick(x, y)
    for i, _ in ipairs(DIFFICULTIES) do
        local btnY = 220 + (i - 1) * 70
        local btnW, btnH = 250, 50
        local btnX = (800 - btnW) / 2

        if x >= btnX and x <= btnX + btnW and y >= btnY and y <= btnY + btnH then
            initBoard(i)
            return
        end
    end
end

-- ========================
-- 헤더 렌더링
-- ========================

function drawHeader()
    local headerFont = love.graphics.newFont(20)
    love.graphics.setFont(headerFont)

    -- 배경
    love.graphics.setColor(0.2, 0.2, 0.25)
    love.graphics.rectangle("fill", 0, 0, 800, HEADER_HEIGHT)

    -- 남은 지뢰 수
    love.graphics.setColor(1, 0.3, 0.3)
    love.graphics.printf(
        string.format("Mines: %d", game.mines - game.flagsPlaced),
        20, 12, 200, "left"
    )

    -- 리셋 버튼 (이모지 대신 텍스트)
    local resetX = 400
    local resetY = HEADER_HEIGHT / 2
    love.graphics.setColor(0.9, 0.8, 0.2)
    love.graphics.circle("fill", resetX, resetY, 18)
    love.graphics.setColor(0, 0, 0)
    local smallFont = love.graphics.newFont(14)
    love.graphics.setFont(smallFont)
    if game.state == STATE_WON then
        love.graphics.printf("^^", resetX - 15, resetY - 8, 30, "center")
    elseif game.state == STATE_LOST then
        love.graphics.printf("XX", resetX - 15, resetY - 8, 30, "center")
    else
        love.graphics.printf(":)", resetX - 15, resetY - 8, 30, "center")
    end

    -- 타이머
    love.graphics.setFont(headerFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(
        string.format("Time: %d", math.floor(game.timer)),
        580, 12, 200, "left"
    )
end

-- ========================
-- 보드 렌더링
-- ========================

function drawBoard()
    local cellFont = love.graphics.newFont(18)

    for row = 1, game.rows do
        for col = 1, game.cols do
            local idx = getCellIndex(col, row)
            local cell = game.board[idx]
            local x = game.boardOffsetX + (col - 1) * CELL_SIZE
            local y = game.boardOffsetY + (row - 1) * CELL_SIZE

            if cell.cellState == HIDDEN then
                -- 미열람 셀
                love.graphics.setColor(0.55, 0.55, 0.6)
                love.graphics.rectangle("fill", x, y, CELL_SIZE, CELL_SIZE)
                love.graphics.setColor(0.4, 0.4, 0.45)
                love.graphics.rectangle("line", x, y, CELL_SIZE, CELL_SIZE)
                -- 3D 효과 (하이라이트)
                love.graphics.setColor(0.7, 0.7, 0.75)
                love.graphics.line(x + 1, y + 1, x + CELL_SIZE - 2, y + 1)
                love.graphics.line(x + 1, y + 1, x + 1, y + CELL_SIZE - 2)

            elseif cell.cellState == FLAGGED then
                -- 깃발
                love.graphics.setColor(0.55, 0.55, 0.6)
                love.graphics.rectangle("fill", x, y, CELL_SIZE, CELL_SIZE)
                love.graphics.setColor(0.4, 0.4, 0.45)
                love.graphics.rectangle("line", x, y, CELL_SIZE, CELL_SIZE)
                -- 깃발 삼각형
                love.graphics.setColor(1, 0.2, 0.2)
                local cx, cy = x + CELL_SIZE / 2, y + CELL_SIZE / 2
                love.graphics.polygon("fill",
                    cx - 4, cy - 8,
                    cx + 8, cy,
                    cx - 4, cy + 4
                )
                love.graphics.setColor(0.6, 0.4, 0.2)
                love.graphics.rectangle("fill", cx - 4, cy - 8, 2, 16)

            else
                -- 열람 셀
                if cell.mine then
                    love.graphics.setColor(1, 0.2, 0.2)
                    love.graphics.rectangle("fill", x, y, CELL_SIZE, CELL_SIZE)
                    -- 지뢰 원
                    love.graphics.setColor(0, 0, 0)
                    love.graphics.circle("fill", x + CELL_SIZE / 2, y + CELL_SIZE / 2, 8)
                else
                    love.graphics.setColor(0.75, 0.75, 0.8)
                    love.graphics.rectangle("fill", x, y, CELL_SIZE, CELL_SIZE)
                    love.graphics.setColor(0.6, 0.6, 0.65)
                    love.graphics.rectangle("line", x, y, CELL_SIZE, CELL_SIZE)

                    -- 숫자 표시
                    if cell.adjacent > 0 then
                        love.graphics.setFont(cellFont)
                        love.graphics.setColor(unpack(NUMBER_COLORS[cell.adjacent]))
                        love.graphics.printf(
                            tostring(cell.adjacent),
                            x, y + 6, CELL_SIZE, "center"
                        )
                    end
                end
            end
        end
    end
end

-- ========================
-- 게임 오버/승리 오버레이
-- ========================

function drawGameOver()
    -- 반투명 배경
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, 800, 600)

    -- 메시지
    local bigFont = love.graphics.newFont(40)
    love.graphics.setFont(bigFont)

    if game.state == STATE_WON then
        love.graphics.setColor(0.2, 1, 0.2)
        love.graphics.printf("YOU WIN!", 0, 230, 800, "center")
    else
        love.graphics.setColor(1, 0.2, 0.2)
        love.graphics.printf("GAME OVER", 0, 230, 800, "center")
    end

    -- 안내
    local smallFont = love.graphics.newFont(18)
    love.graphics.setFont(smallFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Click to return to menu  |  R to restart", 0, 300, 800, "center")
end
