-- FanIsle: Biome Module
-- Defines a 3x3 zone grid over the world (each zone = 960x720).
local Biome = {}

-- Zone dimensions match the original single-screen size
Biome.ZONE_W = 960
Biome.ZONE_H = 720

--[[
  3x3 layout (col, row) — 1-indexed:
  Forest  | Cave   | Forest
  Desert  | Forest | Desert
  Forest  | Cave   | Forest
--]]
local GRID = {
    { "forest", "cave",   "forest" },  -- row 1 (top)
    { "desert", "forest", "desert" },  -- row 2 (middle)
    { "forest", "cave",   "forest" },  -- row 3 (bottom)
}

-- Biome visual ground colours
local GROUND_COLOR = {
    forest = { 0.22, 0.38, 0.20 },
    cave   = { 0.28, 0.27, 0.25 },
    desert = { 0.68, 0.58, 0.35 },
}

-- Transition accent colour drawn on zone borders
local BORDER_COLOR = {
    forest = { 0.18, 0.30, 0.16 },
    cave   = { 0.20, 0.20, 0.18 },
    desert = { 0.55, 0.46, 0.26 },
}

-- Return biome type string for a given world position
function Biome.getAt(wx, wy)
    local col = math.floor(wx / Biome.ZONE_W) + 1
    local row = math.floor(wy / Biome.ZONE_H) + 1
    col = math.max(1, math.min(col, 3))
    row = math.max(1, math.min(row, 3))
    return GRID[row][col]
end

-- Return the world-space rect of a specific zone
function Biome.getZoneRect(col, row)
    return (col - 1) * Biome.ZONE_W,
           (row - 1) * Biome.ZONE_H,
           Biome.ZONE_W,
           Biome.ZONE_H
end

local canvas = nil

-- Pre-render the entire 2880x2160 world background onto a Canvas for high performance
function Biome.load()
    local ok, cv = pcall(love.graphics.newCanvas, 2880, 2160)
    if not ok then
        print("Warning: Could not create Biome canvas. Fallback to dynamic primitives will be used.")
        return
    end

    canvas = cv
    love.graphics.setCanvas(canvas)
    love.graphics.clear()

    local Assets = require("src.assets")
    local tileW, tileH = 32, 32

    -- For consistent generative decorations
    math.randomseed(42)

    for row = 1, 3 do
        for col = 1, 3 do
            local biomeType = GRID[row][col]
            local zx, zy, zw, zh = Biome.getZoneRect(col, row)

            -- 1. Ground Fill (tiled texture or solid color)
            if Assets.tileset and Assets.quads.tiles and Assets.quads.tiles[biomeType] then
                love.graphics.setColor(1, 1, 1, 1)
                local quad = Assets.quads.tiles[biomeType]
                for y = zy, zy + zh - tileH, tileH do
                    for x = zx, zx + zw - tileW, tileW do
                        love.graphics.draw(Assets.tileset, quad, x, y)
                    end
                end
            else
                local gc = GROUND_COLOR[biomeType]
                love.graphics.setColor(gc[1], gc[2], gc[3])
                love.graphics.rectangle("fill", zx, zy, zw, zh)
            end

            -- 2. Subtle zone borders
            local bc = BORDER_COLOR[biomeType]
            love.graphics.setColor(bc[1], bc[2], bc[3], 0.5)
            love.graphics.rectangle("line", zx + 2, zy + 2, zw - 4, zh - 4)

            -- 3. Large faint label
            love.graphics.setColor(0, 0, 0, 0.08)
            love.graphics.printf(string.upper(biomeType), zx, zy + zh / 2 - 20, zw, "center")
        end
    end

    -- 4. Biome decorations
    for row = 1, 3 do
        for col = 1, 3 do
            local biomeType = GRID[row][col]
            local zx, zy, zw, zh = Biome.getZoneRect(col, row)

            if biomeType == "cave" then
                -- Cave stalactite/stalagmite spikes
                love.graphics.setColor(0.20, 0.18, 0.16, 0.6)
                for i = 0, 7 do
                    local sx = zx + 60 + i * (zw - 120) / 7
                    local h  = math.random(20, 55)
                    love.graphics.polygon("fill", sx - 8, zy, sx + 8, zy, sx, zy + h)
                    love.graphics.polygon("fill", sx - 8, zy + zh, sx + 8, zy + zh, sx, zy + zh - h)
                end
            elseif biomeType == "desert" then
                -- Desert dune ripple lines
                love.graphics.setColor(0.55, 0.44, 0.24, 0.35)
                for i = 1, 5 do
                    local dy = zy + i * (zh / 6)
                    love.graphics.line(zx + 30, dy, zx + zw - 30, dy + 20)
                end
            elseif biomeType == "forest" then
                -- Forest scattered leaf cluster circles
                love.graphics.setColor(0.15, 0.32, 0.13, 0.3)
                for i = 1, 6 do
                    local lx = zx + math.random(40, zw - 40)
                    local ly = zy + math.random(40, zh - 40)
                    love.graphics.circle("fill", lx, ly, math.random(10, 22))
                end
            end
        end
    end

    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1, 1)
end

-- Draw pre-rendered biome ground canvas (or fallback to primitives)
function Biome.draw()
    if canvas then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(canvas, 0, 0)
    else
        for row = 1, 3 do
            for col = 1, 3 do
                local biomeType = GRID[row][col]
                local gc = GROUND_COLOR[biomeType]
                local bc = BORDER_COLOR[biomeType]
                local zx, zy, zw, zh = Biome.getZoneRect(col, row)

                love.graphics.setColor(gc[1], gc[2], gc[3])
                love.graphics.rectangle("fill", zx, zy, zw, zh)

                love.graphics.setColor(bc[1], bc[2], bc[3], 0.5)
                love.graphics.rectangle("line", zx + 2, zy + 2, zw - 4, zh - 4)

                love.graphics.setColor(0, 0, 0, 0.08)
                love.graphics.printf(string.upper(biomeType), zx, zy + zh / 2 - 20, zw, "center")
            end
        end
    end
    love.graphics.setColor(1, 1, 1, 1)
end

-- Return the grid layout table (for minimap)
function Biome.getGrid()
    return GRID
end

-- Biome minimap colours (small, for radar)
Biome.MINIMAP_COLOR = {
    forest = { 0.25, 0.55, 0.22 },
    cave   = { 0.40, 0.38, 0.35 },
    desert = { 0.78, 0.68, 0.42 },
}

return Biome
