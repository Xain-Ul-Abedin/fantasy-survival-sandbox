-- FanIsle: World & Resources Module
local World = {}

World.resources = {}
World.drops = {}

World.resourceTypes = {
    tree = { color = {0.15, 0.5, 0.2}, size = 24, label = "Tree" },
    stone = { color = {0.4, 0.4, 0.45}, size = 16, label = "Rock" },
    berry = { color = {0.8, 0.1, 0.2}, size = 12, label = "Berry Shrub" }
}

-- Generate initial resources on the map
function World.spawnResources()
    World.resources = {}
    World.drops = {}
    math.randomseed(os.time())
    for i = 1, 30 do
        local rType = "tree"
        local rand = math.random(1, 3)
        if rand == 2 then rType = "stone"
        elseif rand == 3 then rType = "berry" end

        table.insert(World.resources, {
            id = "res_" .. i,
            x = math.random(60, 900),
            y = math.random(100, 650),
            type = rType,
            hits = 3,
            destroyed = false
        })
    end
end

-- Update dropped items and handle pickup radius collision
function World.updateDrops(dt, player)
    -- Process resource destructions and spawn drops
    for _, res in ipairs(World.resources) do
        if res.destroyed and not res.dropSpawned then
            res.dropSpawned = true
            -- Main item drop
            if res.dropType then
                table.insert(World.drops, {
                    x = res.x + math.random(-15, 15),
                    y = res.y + math.random(-15, 15),
                    type = res.dropType,
                    count = res.dropCount or 1,
                    pickedUp = false
                })
            end
            -- Additional Flint drop from Rocks
            if res.dropFlint then
                table.insert(World.drops, {
                    x = res.x + math.random(-15, 15),
                    y = res.y + math.random(-15, 15),
                    type = "flint",
                    count = 1,
                    pickedUp = false
                })
            end
        end
    end

    -- Player pickup checks (within 30 pixels radius)
    local playerCenterX = player.x + player.size / 2
    local playerCenterY = player.y + player.size / 2
    local pickupRadius = 30

    for _, drop in ipairs(World.drops) do
        if not drop.pickedUp then
            local distSq = (playerCenterX - drop.x)^2 + (playerCenterY - drop.y)^2
            if distSq < pickupRadius^2 then
                drop.pickedUp = true
                -- Add to player inventory
                if player.inventory[drop.type] then
                    player.inventory[drop.type] = player.inventory[drop.type] + drop.count
                else
                    player.inventory[drop.type] = drop.count
                end
            end
        end
    end
end

-- Render resources and active drops
function World.draw()
    -- 1. Draw resources
    for _, res in ipairs(World.resources) do
        if not res.destroyed then
            local config = World.resourceTypes[res.type]
            love.graphics.setColor(config.color)
            love.graphics.circle("fill", res.x, res.y, config.size)
            
            -- Label
            love.graphics.setColor(1, 1, 1, 0.7)
            love.graphics.print(config.label .. " (" .. res.hits .. ")", res.x - 20, res.y + config.size + 2)
        end
    end

    -- 2. Draw drops on the ground
    for _, drop in ipairs(World.drops) do
        if not drop.pickedUp then
            -- Set color based on item type
            if drop.type == "wood" then
                love.graphics.setColor(0.6, 0.4, 0.2)
            elseif drop.type == "stone" then
                love.graphics.setColor(0.5, 0.5, 0.5)
            elseif drop.type == "flint" then
                love.graphics.setColor(0.3, 0.3, 0.35)
            elseif drop.type == "berries" then
                love.graphics.setColor(0.9, 0.1, 0.3)
            else
                love.graphics.setColor(0.9, 0.9, 0.9)
            end
            
            -- Small drop shape
            love.graphics.circle("fill", drop.x, drop.y, 6)
            
            -- Text label indicating item count
            love.graphics.setColor(1, 1, 1, 0.8)
            love.graphics.print(drop.type .. " x" .. drop.count, drop.x - 15, drop.y - 18)
        end
    end
end

return World
