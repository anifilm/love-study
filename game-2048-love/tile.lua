local Tile = {}

Tile.COLORS = {
    [0]     = {0.804, 0.757, 0.706},
    [2]     = {0.933, 0.894, 0.855},
    [4]     = {0.929, 0.878, 0.784},
    [8]     = {0.949, 0.694, 0.475},
    [16]    = {0.961, 0.584, 0.388},
    [32]    = {0.965, 0.486, 0.373},
    [64]    = {0.965, 0.369, 0.231},
    [128]   = {0.929, 0.812, 0.447},
    [256]   = {0.929, 0.800, 0.380},
    [512]   = {0.929, 0.784, 0.314},
    [1024]  = {0.929, 0.773, 0.247},
    [2048]  = {0.929, 0.761, 0.180},
    [4096]  = {0.235, 0.227, 0.196},
    [8192]  = {0.235, 0.227, 0.196},
}

Tile.TEXT_COLORS = {
    [2]     = {0.467, 0.431, 0.396},
    [4]     = {0.467, 0.431, 0.396},
    [8]     = {0.976, 0.965, 0.949},
    [16]    = {0.976, 0.965, 0.949},
    [32]    = {0.976, 0.965, 0.949},
    [64]    = {0.976, 0.965, 0.949},
    [128]   = {0.976, 0.965, 0.949},
    [256]   = {0.976, 0.965, 0.949},
    [512]   = {0.976, 0.965, 0.949},
    [1024]  = {0.976, 0.965, 0.949},
    [2048]  = {0.976, 0.965, 0.949},
    [4096]  = {0.976, 0.965, 0.949},
    [8192]  = {0.976, 0.965, 0.949},
}

Tile.fontCache = {}

function Tile.getColor(value)
    return Tile.COLORS[value] or Tile.COLORS[0]
end

function Tile.getTextColor(value)
    return Tile.TEXT_COLORS[value] or {0.976, 0.965, 0.949}
end

function Tile.getFontSize(value)
    if value < 100 then
        return 45
    elseif value < 1000 then
        return 38
    elseif value < 10000 then
        return 30
    else
        return 24
    end
end

function Tile.getFont(value, scale)
    local fontSize = Tile.getFontSize(value)
    local scaledFontSize = math.floor(fontSize * math.min(scale, 1.0))
    scaledFontSize = math.max(10, scaledFontSize)

    if not Tile.fontCache[scaledFontSize] then
        Tile.fontCache[scaledFontSize] = love.graphics.newFont(scaledFontSize)
    end
    return Tile.fontCache[scaledFontSize]
end

function Tile.draw(x, y, size, value, scale)
    scale = scale or 1.0
    local color = Tile.getColor(value)
    love.graphics.setColor(color[1], color[2], color[3])

    local padding = 3
    local tileSize = size - padding * 2
    local cx = x + size / 2
    local cy = y + size / 2
    local s = tileSize * scale

    local rx = cx - s / 2
    local ry = cy - s / 2
    local radius = 6 * scale
    radius = math.max(0, radius)

    love.graphics.rectangle("fill", rx, ry, s, s, radius)

    if value > 0 then
        local textColor = Tile.getTextColor(value)
        love.graphics.setColor(textColor[1], textColor[2], textColor[3])

        local font = Tile.getFont(value, scale)
        love.graphics.setFont(font)
        local text = tostring(value)
        local tw = font:getWidth(text)
        local th = font:getHeight()
        love.graphics.print(text, cx - tw / 2, cy - th / 2)
    end
end

return Tile
