-- Fantasy Survival Sandbox: Core Engine
local gameState = "menu" -- Options: "menu", "play", "gameover"

-- Player properties
local player = {
    x = 480,
    y = 360,
    speed = 200,
    size = 32,
    health = 100,
    maxHealth = 100,
    hunger = 100,
    maxHunger = 100,
    stamina = 100,
    maxStamina = 100,
    direction = "down"
}

-- Resource types on the map
local resources = {}
local resourceTypes = {
    tree = { color = {0.15, 0.5, 0.2}, size = 24, label = "Tree" },
    stone = { color = {0.4, 0.4, 0.45}, size = 16, label = "Rock" },
    berry = { color = {0.8, 0.1, 0.2}, size = 12, label = "Berry Shrub" }
}

-- Helper function to spawn resources
local function spawnResources()
    resources = {}
    math.randomseed(os.time())
    for i = 1, 30 do
        local rType = "tree"
        local rand = math.random(1, 3)
        if rand == 2 then rType = "stone"
        elseif rand == 3 then rType = "berry" end

        table.insert(resources, {
            x = math.random(50, 910),
            y = math.random(50, 670),
            type = rType,
            hits = 3 -- Hits needed to harvest
        })
    end
end

function love.load()
    spawnResources()
    print("Report. Game components loaded. World generated successfully.")
end

function love.update(dt)
    if gameState == "menu" then
        if love.keyboard.isDown("return") or love.keyboard.isDown("space") then
            gameState = "play"
        end
        return
    elseif gameState == "gameover" then
        if love.keyboard.isDown("r") then
            player.health = 100
            player.hunger = 100
            player.stamina = 100
            player.x, player.y = 480, 360
            spawnResources()
            gameState = "play"
        end
        return
    end

    -- 1. Deplete hunger over time
    player.hunger = player.hunger - 1.5 * dt
    if player.hunger <= 0 then
        player.hunger = 0
        player.health = player.health - 5 * dt -- Starvation drains health
    end

    if player.health <= 0 then
        player.health = 0
        gameState = "gameover"
    end

    -- 2. Movement inputs calculated by Raph
    local dx, dy = 0, 0
    local isSprinting = love.keyboard.isDown("lshift") and player.stamina > 0

    if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
        dx = -1
        player.direction = "left"
    elseif love.keyboard.isDown("right") or love.keyboard.isDown("d") then
        dx = 1
        player.direction = "right"
    end
    if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
        dy = -1
        player.direction = "up"
    elseif love.keyboard.isDown("down") or love.keyboard.isDown("s") then
        dy = 1
        player.direction = "down"
    end

    -- Vector normalization
    if dx ~= 0 and dy ~= 0 then
        local length = math.sqrt(dx * dx + dy * dy)
        dx = dx / length
        dy = dy / length
    end

    -- Apply speed multipliers based on stamina and sprint state
    local activeSpeed = player.speed
    if isSprinting and (dx ~= 0 or dy ~= 0) then
        activeSpeed = player.speed * 1.6
        player.stamina = player.stamina - 25 * dt
    else
        player.stamina = math.min(player.maxStamina, player.stamina + 10 * dt)
    end

    player.x = player.x + dx * activeSpeed * dt
    player.y = player.y + dy * activeSpeed * dt

    -- Clamp to screen edges
    player.x = math.max(0, math.min(player.x, love.graphics.getWidth() - player.size))
    player.y = math.max(0, math.min(player.y, love.graphics.getHeight() - player.size))
end

function love.draw()
    if gameState == "menu" then
        -- Title Screen
        love.graphics.clear(0.08, 0.08, 0.12)
        love.graphics.setColor(0.9, 0.8, 0.4)
        love.graphics.printf("🏰 FANISLE 🏰", 0, 200, love.graphics.getWidth(), "center")
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.printf("Inspired by The Survivalists", 0, 250, love.graphics.getWidth(), "center")
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Press ENTER or SPACE to Start Your Island Survival", 0, 450, love.graphics.getWidth(), "center")
        return
    elseif gameState == "gameover" then
        -- Game Over Screen
        love.graphics.clear(0.2, 0.05, 0.05)
        love.graphics.setColor(0.9, 0.1, 0.1)
        love.graphics.printf("YOU PERISHED", 0, 250, love.graphics.getWidth(), "center")
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.printf("Press R to Respawn on the Island", 0, 400, love.graphics.getWidth(), "center")
        return
    end

    -- Gameplay Canvas
    love.graphics.clear(0.22, 0.35, 0.22) -- Grass green background

    -- Draw resources (rocks, trees, berries)
    for _, res in ipairs(resources) do
        local config = resourceTypes[res.type]
        love.graphics.setColor(config.color)
        love.graphics.circle("fill", res.x, res.y, config.size)
        
        -- Text tag for visibility
        love.graphics.setColor(1, 1, 1, 0.6)
        love.graphics.print(config.label, res.x - 15, res.y + config.size + 2)
    end

    -- Draw Player
    love.graphics.setColor(0.8, 0.6, 0.4)
    love.graphics.rectangle("fill", player.x, player.y, player.size, player.size)

    -- Draw player orientation indicator
    love.graphics.setColor(0.2, 0.2, 0.2)
    if player.direction == "left" then
        love.graphics.rectangle("fill", player.x, player.y + 12, 6, 8)
    elseif player.direction == "right" then
        love.graphics.rectangle("fill", player.x + player.size - 6, player.y + 12, 6, 8)
    elseif player.direction == "up" then
        love.graphics.rectangle("fill", player.x + 12, player.y, 8, 6)
    elseif player.direction == "down" then
        love.graphics.rectangle("fill", player.x + 12, player.y + player.size - 6, 8, 6)
    end

    -- Draw HUD Panel (styled by Win)
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 10, 10, 250, 110)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Xain-Sama's HUD", 20, 20)
    
    -- Health Bar (Red)
    love.graphics.setColor(0.8, 0.2, 0.2)
    love.graphics.rectangle("fill", 20, 45, player.health * 2, 12)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("HP: " .. math.floor(player.health), 25, 43)

    -- Hunger Bar (Orange)
    love.graphics.setColor(0.9, 0.5, 0.1)
    love.graphics.rectangle("fill", 20, 65, player.hunger * 2, 12)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Food: " .. math.floor(player.hunger), 25, 63)

    -- Stamina Bar (Green)
    love.graphics.setColor(0.2, 0.7, 0.3)
    love.graphics.rectangle("fill", 20, 85, player.stamina * 2, 12)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Stam: " .. math.floor(player.stamina), 25, 83)
end
