-- FanIsle: Player Module
local Player = {}

Player.x = 480
Player.y = 360
Player.speed = 200
Player.size = 32
Player.health = 100
Player.maxHealth = 100
Player.hunger = 100
Player.maxHunger = 100
Player.stamina = 100
Player.maxStamina = 100
Player.direction = "down"
Player.inventory = {
    wood = 0,
    stone = 0,
    flint = 0,
    berries = 0
}

-- Reinitialize player values
function Player.reset()
    Player.x = 480
    Player.y = 360
    Player.health = 100
    Player.hunger = 100
    Player.stamina = 100
    Player.direction = "down"
    Player.inventory = {
        wood = 0,
        stone = 0,
        flint = 0,
        berries = 0
    }
end

-- Update stats and process inputs
function Player.update(dt, difficulty)
    -- Determine depletion rate based on difficulty
    local hungerRate = 1.5
    local starvationDamage = 5.0
    if difficulty == "easy" then
        hungerRate = 1.0
        starvationDamage = 3.0
    elseif difficulty == "normal" then
        hungerRate = 1.5
        starvationDamage = 5.0
    elseif difficulty == "hard" then
        hungerRate = 2.0
        starvationDamage = 8.0
    end

    -- 1. Deplete hunger over time
    Player.hunger = Player.hunger - hungerRate * dt
    if Player.hunger <= 0 then
        Player.hunger = 0
        Player.health = Player.health - starvationDamage * dt -- Starvation drains health
    end

    if Player.health <= 0 then
        Player.health = 0
    end

    -- 2. Movement controls
    local dx, dy = 0, 0
    local isSprinting = love.keyboard.isDown("lshift") and Player.stamina > 0

    if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
        dx = -1
        Player.direction = "left"
    elseif love.keyboard.isDown("right") or love.keyboard.isDown("d") then
        dx = 1
        Player.direction = "right"
    end
    if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
        dy = -1
        Player.direction = "up"
    elseif love.keyboard.isDown("down") or love.keyboard.isDown("s") then
        dy = 1
        Player.direction = "down"
    end

    -- Normalize speed vector
    if dx ~= 0 and dy ~= 0 then
        local length = math.sqrt(dx * dx + dy * dy)
        dx = dx / length
        dy = dy / length
    end

    -- Handle stamina mechanics
    local activeSpeed = Player.speed
    if isSprinting and (dx ~= 0 or dy ~= 0) then
        activeSpeed = Player.speed * 1.6
        Player.stamina = math.max(0, Player.stamina - 25 * dt)
    else
        Player.stamina = math.min(Player.maxStamina, Player.stamina + 12 * dt)
    end

    -- Update position
    Player.x = Player.x + dx * activeSpeed * dt
    Player.y = Player.y + dy * activeSpeed * dt

    -- Clamp to screen edges
    Player.x = math.max(0, math.min(Player.x, love.graphics.getWidth() - Player.size))
    Player.y = math.max(0, math.min(Player.y, love.graphics.getHeight() - Player.size))
end

-- Draw the player box and directional pointer
function Player.draw()
    -- Character Box
    love.graphics.setColor(0.8, 0.6, 0.4)
    love.graphics.rectangle("fill", Player.x, Player.y, Player.size, Player.size)

    -- Direction pointer
    love.graphics.setColor(0.2, 0.2, 0.2)
    if Player.direction == "left" then
        love.graphics.rectangle("fill", Player.x, Player.y + 12, 6, 8)
    elseif Player.direction == "right" then
        love.graphics.rectangle("fill", Player.x + Player.size - 6, Player.y + 12, 6, 8)
    elseif Player.direction == "up" then
        love.graphics.rectangle("fill", Player.x + 12, Player.y, 8, 6)
    elseif Player.direction == "down" then
        love.graphics.rectangle("fill", Player.x + 12, Player.y + Player.size - 6, 8, 6)
    end
end

-- Harvest Action (check if player can hit a resource)
function Player.harvest(resources, resourceTypes, goblins)
    -- Range box or circle in front of player
    local reach = 40
    local targetX = Player.x + Player.size / 2
    local targetY = Player.y + Player.size / 2

    if Player.direction == "left" then targetX = targetX - reach
    elseif Player.direction == "right" then targetX = targetX + reach
    elseif Player.direction == "up" then targetY = targetY - reach
    elseif Player.direction == "down" then targetY = targetY + reach end

    -- Check overlap with resources
    for _, res in ipairs(resources) do
        if not res.destroyed then
            local config = resourceTypes[res.type]
            local distSq = (targetX - res.x)^2 + (targetY - res.y)^2
            local hitRadius = config.size + 15
            if distSq < hitRadius^2 then
                res.hits = res.hits - 1
                
                -- Record player's harvesting action for Goblins to mimic
                for _, gob in ipairs(goblins) do
                    if gob.tamed and gob.state == "mimic" then
                        gob.lastActionType = "harvest"
                        gob.lastActionTargetType = res.type
                    end
                end

                if res.hits <= 0 then
                    res.destroyed = true
                    -- Spawn drops
                    local drops = {}
                    local randQty = math.random(1, 3)
                    if res.type == "tree" then
                        res.dropType = "wood"
                        res.dropCount = randQty
                    elseif res.type == "stone" then
                        res.dropType = "stone"
                        res.dropCount = randQty
                        if math.random() > 0.6 then
                            res.dropFlint = true
                        end
                    elseif res.type == "berry" then
                        res.dropType = "berries"
                        res.dropCount = math.random(2, 4)
                    end
                end
                break -- Hit only one resource at a time
            end
        end
    end
end

-- Handle eating berries
function Player.eat()
    if Player.inventory.berries > 0 then
        Player.inventory.berries = Player.inventory.berries - 1
        Player.hunger = math.min(Player.maxHunger, Player.hunger + 25)
        Player.health = math.min(Player.maxHealth, Player.health + 10)
        return true
    end
    return false
end

return Player
