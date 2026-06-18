-- FanIsle: World & Resources Module (Phase 5 — Biome-aware spawning)
local World = {}

World.resources = {}
World.drops     = {}

World.resourceTypes = {
    tree  = { color = {0.15, 0.50, 0.20}, size = 24, label = "Tree"        },
    stone = { color = {0.40, 0.40, 0.45}, size = 16, label = "Rock"        },
    berry = { color = {0.80, 0.10, 0.20}, size = 12, label = "Berry Shrub" },
    flint_cluster = { color = {0.30, 0.28, 0.35}, size = 14, label = "Flint Vein" }
}

-- Biome resource rules: maps biome → allowed resource types + weights
local BIOME_RESOURCES = {
    forest = { { "tree", 5 }, { "berry", 3 }, { "stone", 1 } },
    cave   = { { "stone", 5 }, { "flint_cluster", 3 } },
    desert = { { "flint_cluster", 4 }, { "stone", 3 } },
}

local function pickBiomeResource(biomeType)
    local pool = BIOME_RESOURCES[biomeType]
    if not pool then return "stone" end
    local total = 0
    for _, entry in ipairs(pool) do total = total + entry[2] end
    local roll = math.random(1, total)
    local acc = 0
    for _, entry in ipairs(pool) do
        acc = acc + entry[2]
        if roll <= acc then return entry[1] end
    end
    return pool[1][1]
end

-- Spawn resources distributed across the full 2880x2160 world using biome rules
function World.spawnResources()
    World.resources = {}
    World.drops     = {}
    math.randomseed(os.time())

    -- Each of the 9 zones gets ~12 resources = ~108 total
    local zoneW = 960
    local zoneH = 720
    local BIOME_GRID = {
        { "forest", "cave",   "forest" },
        { "desert", "forest", "desert" },
        { "forest", "cave",   "forest" },
    }

    local id = 0
    for row = 1, 3 do
        for col = 1, 3 do
            local biomeType = BIOME_GRID[row][col]
            local zoneX = (col - 1) * zoneW
            local zoneY = (row - 1) * zoneH
            for i = 1, 12 do
                id = id + 1
                local rType = pickBiomeResource(biomeType)
                table.insert(World.resources, {
                    id          = "res_" .. id,
                    x           = zoneX + math.random(50, zoneW - 50),
                    y           = zoneY + math.random(50, zoneH - 50),
                    type        = rType,
                    hits        = (rType == "stone" or rType == "flint_cluster") and 4 or 3,
                    destroyed   = false,
                    biome       = biomeType
                })
            end
        end
    end
end

-- Update dropped items and handle pickup radius collision
function World.updateDrops(dt, player)
    -- Process resource destructions and spawn drops
    for _, res in ipairs(World.resources) do
        if res.destroyed and not res.dropSpawned then
            res.dropSpawned = true
            if res.dropType then
                table.insert(World.drops, {
                    x = res.x + math.random(-15, 15),
                    y = res.y + math.random(-15, 15),
                    type    = res.dropType,
                    count   = res.dropCount or 1,
                    pickedUp = false
                })
            end
            -- Extra flint from rocks
            if res.dropFlint then
                table.insert(World.drops, {
                    x = res.x + math.random(-15, 15),
                    y = res.y + math.random(-15, 15),
                    type    = "flint",
                    count   = 1,
                    pickedUp = false
                })
            end
        end
    end

    -- Player pickup (within 30px)
    local pcx = player.x + player.size / 2
    local pcy = player.y + player.size / 2
    for _, drop in ipairs(World.drops) do
        if not drop.pickedUp then
            local dSq = (pcx - drop.x)^2 + (pcy - drop.y)^2
            if dSq < 30^2 then
                drop.pickedUp = true
                player.inventory[drop.type] = (player.inventory[drop.type] or 0) + drop.count
            end
        end
    end
end

-- Harvest logic: flint_cluster drops flint
local function resolveHarvestDrops(res)
    local randQty = math.random(1, 3)
    if res.type == "tree" then
        res.dropType  = "wood"
        res.dropCount = randQty
    elseif res.type == "stone" then
        res.dropType  = "stone"
        res.dropCount = randQty
        if math.random() > 0.5 then res.dropFlint = true end
    elseif res.type == "berry" then
        res.dropType  = "berries"
        res.dropCount = math.random(2, 4)
    elseif res.type == "flint_cluster" then
        res.dropType  = "flint"
        res.dropCount = math.random(2, 4)
    end
end

-- Called after a resource's hits reach 0
function World.onResourceDestroyed(res)
    resolveHarvestDrops(res)
end

-- Render resources and active drops (camera-space — called inside Camera.attach)
function World.draw()
    -- 1. Resources
    for _, res in ipairs(World.resources) do
        if not res.destroyed then
            local config = World.resourceTypes[res.type]
            if config then
                love.graphics.setColor(config.color)
                love.graphics.circle("fill", res.x, res.y, config.size)

                -- Flint cluster gets a jagged accent
                if res.type == "flint_cluster" then
                    love.graphics.setColor(0.55, 0.50, 0.65, 0.8)
                    love.graphics.polygon("fill",
                        res.x - 8, res.y + 4,
                        res.x,     res.y - config.size + 2,
                        res.x + 8, res.y + 4)
                end

                love.graphics.setColor(1, 1, 1, 0.65)
                love.graphics.print(config.label .. " (" .. res.hits .. ")",
                    res.x - 22, res.y + config.size + 2)
            end
        end
    end

    -- 2. Drops on the ground
    local dropColors = {
        wood          = {0.60, 0.40, 0.20},
        stone         = {0.50, 0.50, 0.50},
        flint         = {0.30, 0.28, 0.38},
        berries       = {0.90, 0.10, 0.30},
        bone          = {0.88, 0.88, 0.80},
        fang          = {0.90, 0.85, 0.50},
        orc_tusk      = {0.70, 0.60, 0.35},
        cooked_berries = {0.95, 0.55, 0.20},
    }
    for _, drop in ipairs(World.drops) do
        if not drop.pickedUp then
            local col = dropColors[drop.type] or {0.9, 0.9, 0.9}
            love.graphics.setColor(col)
            love.graphics.circle("fill", drop.x, drop.y, 6)
            love.graphics.setColor(1, 1, 1, 0.8)
            love.graphics.print(drop.type:gsub("_"," ") .. " x" .. drop.count,
                drop.x - 16, drop.y - 18)
        end
    end
end

return World
