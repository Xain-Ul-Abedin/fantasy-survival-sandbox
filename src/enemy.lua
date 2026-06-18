-- FanIsle: Enemy Module
-- Archetypes: Skeleton (melee), Bat (fast flyer), Orc Scout (brute), Lich (boss)
local Enemy = {}

Enemy.list        = {}
Enemy.idCounter   = 0
Enemy.projectiles = {}  -- Lich homing orbs
Enemy.lichDefeated = false  -- Victory flag

local ARCHETYPES = {
    skeleton = {
        hp       = 30,
        speed    = 80,
        damage   = 8,
        size     = 14,
        aggroRange = 220,
        attackRange = 22,
        attackCooldown = 1.2,
        color    = { 0.85, 0.85, 0.85 },
        label    = "Skeleton",
        loot     = { { item = "bone",  min = 1, max = 2 } }
    },
    bat = {
        hp       = 15,
        speed    = 150,
        damage   = 5,
        size     = 10,
        aggroRange = 300,
        attackRange = 16,
        attackCooldown = 0.8,
        color    = { 0.3, 0.1, 0.35 },
        label    = "Bat",
        loot     = { { item = "fang",  min = 1, max = 1 } }
    },
    orc = {
        hp       = 70,
        speed    = 50,
        damage   = 18,
        size     = 20,
        aggroRange = 180,
        attackRange = 28,
        attackCooldown = 1.8,
        color    = { 0.2, 0.5, 0.15 },
        label    = "Orc Scout",
        loot     = { { item = "orc_tusk", min = 1, max = 1 }, { item = "stone", min = 1, max = 3 } }
    },
    lich = {
        hp       = 300,
        speed    = 30,
        damage   = 25,
        size     = 30,
        aggroRange = 500,
        attackRange = 35,
        attackCooldown = 2.5,
        color    = { 0.4, 0.1, 0.55 },
        label    = "Night Lich",
        loot     = { { item = "bone", min = 5, max = 8 }, { item = "fang", min = 3, max = 5 } }
    }
}

-- Spawn a single enemy of a given type at (x, y)
function Enemy.spawn(enemyType, x, y)
    local arch = ARCHETYPES[enemyType]
    if not arch then return end
    Enemy.idCounter = Enemy.idCounter + 1
    table.insert(Enemy.list, {
        id            = "enemy_" .. Enemy.idCounter,
        type          = enemyType,
        x             = x,
        y             = y,
        hp            = arch.hp,
        maxHp         = arch.hp,
        speed         = arch.speed,
        damage        = arch.damage,
        size          = arch.size,
        aggroRange    = arch.aggroRange,
        attackRange   = arch.attackRange,
        attackCooldown = arch.attackCooldown,
        attackTimer   = 0,
        color         = arch.color,
        label         = arch.label,
        loot          = arch.loot,
        state         = "idle",   -- "idle", "aggro", "attack", "dead"
        wanderTimer   = math.random(2, 5),
        targetX       = x,
        targetY       = y,
        deathTimer    = 0,
        -- Bat hover offset for visual variety
        hoverAngle    = math.random() * math.pi * 2,
        hoverRadius   = arch.type == "bat" and 40 or 0
    })
end

-- Spawn a wave of enemies distributed across the world in biome-appropriate zones
function Enemy.spawnWave(count, W, H)
    -- Biome → preferred enemy types
    local BIOME_ENEMIES = {
        forest = { "skeleton", "bat" },
        cave   = { "skeleton", "skeleton", "bat" },
        desert = { "orc", "orc", "skeleton" },
    }
    local BIOME_GRID = {
        { "forest", "cave",   "forest" },
        { "desert", "forest", "desert" },
        { "forest", "cave",   "forest" },
    }
    local ZONE_W, ZONE_H = 960, 720

    for i = 1, count do
        -- Pick a random zone
        local row = math.random(1, 3)
        local col = math.random(1, 3)
        local biomeType = BIOME_GRID[row][col]
        local pool = BIOME_ENEMIES[biomeType] or { "skeleton" }
        local t = pool[math.random(1, #pool)]
        -- Spawn position inside that zone
        local zx = (col - 1) * ZONE_W
        local zy = (row - 1) * ZONE_H
        local sx = zx + math.random(40, ZONE_W - 40)
        local sy = zy + math.random(40, ZONE_H - 40)
        Enemy.spawn(t, sx, sy)
    end
end

-- Check if any Lich is currently alive
function Enemy.isLichAlive()
    for _, e in ipairs(Enemy.list) do
        if e.type == "lich" and e.state ~= "dead" then return true end
    end
    return false
end

-- Spawn a Day-7 Lich boss wave (called from DayCycle)
function Enemy.spawnBossWave()
    -- Spawn the Lich in the Forest center zone
    Enemy.spawn("lich", 1440 + math.random(-80, 80), 1080 + math.random(-80, 80))
    -- Set up lich-specific fields
    local lich = Enemy.list[#Enemy.list]
    lich.summonTimer = 0
    lich.SUMMON_COOLDOWN = 10
    lich.shootTimer = 0
    lich.SHOOT_COOLDOWN = 3
    -- Escort skeletons
    for i = 1, 3 do
        Enemy.spawn("skeleton",
            lich.x + math.random(-120, 120),
            lich.y + math.random(-120, 120))
    end
end

-- Update all enemies
function Enemy.update(dt, player, world, damageFeed)
    local px = player.x + player.size / 2
    local py = player.y + player.size / 2

    local toRemove = {}
    for i, e in ipairs(Enemy.list) do
        if e.state == "dead" then
            e.deathTimer = e.deathTimer + dt
            -- Victory: flag when Lich fully expires
            if e.type == "lich" and not Enemy.lichDefeated then
                Enemy.lichDefeated = true
            end
            if e.deathTimer >= 0.6 then
                table.insert(toRemove, i)
            end
        else
            local dx = px - e.x
            local dy = py - e.y
            local dist = math.sqrt(dx*dx + dy*dy)

            -- State transitions
            if dist <= e.aggroRange then
                e.state = "aggro"
            else
                e.state = "idle"
            end

            if e.state == "idle" then
                -- Wander randomly
                e.wanderTimer = e.wanderTimer - dt
                if e.wanderTimer <= 0 then
                    e.targetX = e.x + math.random(-100, 100)
                    e.targetY = e.y + math.random(-100, 100)
                    e.wanderTimer = math.random(2, 5)
                end
                local wx = e.targetX - e.x
                local wy = e.targetY - e.y
                local wd = math.sqrt(wx*wx + wy*wy)
                if wd > 5 then
                    e.x = e.x + (wx / wd) * (e.speed * 0.4) * dt
                    e.y = e.y + (wy / wd) * (e.speed * 0.4) * dt
                end

            elseif e.state == "aggro" then
                -- Bat: orbit + dive
                if e.type == "bat" then
                    e.hoverAngle = e.hoverAngle + dt * 2.5
                    local orbitX = px + math.cos(e.hoverAngle) * 60
                    local orbitY = py + math.sin(e.hoverAngle) * 60
                    local ox = orbitX - e.x
                    local oy = orbitY - e.y
                    local od = math.sqrt(ox*ox + oy*oy)
                    if od > 5 then
                        e.x = e.x + (ox / od) * e.speed * dt
                        e.y = e.y + (oy / od) * e.speed * dt
                    end
                else
                    -- Walk toward player
                    if dist > e.attackRange then
                        e.x = e.x + (dx / dist) * e.speed * dt
                        e.y = e.y + (dy / dist) * e.speed * dt
                    end
                end

                -- Melee attack cooldown
                e.attackTimer = e.attackTimer - dt
                if dist <= e.attackRange and e.attackTimer <= 0 then
                    e.attackTimer = e.attackCooldown
                    if player.takeDamage then
                        local dealt = player.takeDamage(e.damage)
                        if dealt and damageFeed then
                            table.insert(damageFeed, {
                                x = player.x + player.size / 2,
                                y = player.y,
                                text = "-" .. e.damage .. " HP",
                                timer = 1.2,
                                color = { 0.95, 0.2, 0.2 }
                            })
                        end
                    end
                end

                -- Lich: summon skeletons + shoot homing orbs
                if e.type == "lich" then
                    e.summonTimer = (e.summonTimer or 0) + dt
                    if e.summonTimer >= (e.SUMMON_COOLDOWN or 10) then
                        e.summonTimer = 0
                        for i = 1, 2 do
                            Enemy.spawn("skeleton",
                                e.x + math.random(-80, 80),
                                e.y + math.random(-80, 80))
                        end
                    end
                    e.shootTimer = (e.shootTimer or 0) + dt
                    if e.shootTimer >= (e.SHOOT_COOLDOWN or 3) then
                        e.shootTimer = 0
                        table.insert(Enemy.projectiles, {
                            x = e.x, y = e.y,
                            vx = 0,  vy = 0,
                            speed  = 90,
                            damage = 20,
                            radius = 7,
                            life   = 5.0,
                        })
                    end
                end
            end

            -- Clamp to world bounds
            e.x = math.max(0, math.min(e.x, 2880))
            e.y = math.max(0, math.min(e.y, 2160))
        end
    end

    -- Remove dead enemies
    for i = #toRemove, 1, -1 do
        table.remove(Enemy.list, toRemove[i])
    end

    -- Update homing projectiles
    local px2 = player.x + player.size / 2
    local py2 = player.y + player.size / 2
    local projDead = {}
    for i, proj in ipairs(Enemy.projectiles) do
        local hdx = px2 - proj.x
        local hdy = py2 - proj.y
        local hd  = math.sqrt(hdx * hdx + hdy * hdy)
        if hd > 1 then
            proj.vx = (hdx / hd) * proj.speed
            proj.vy = (hdy / hd) * proj.speed
        end
        proj.x    = proj.x + proj.vx * dt
        proj.y    = proj.y + proj.vy * dt
        proj.life = proj.life - dt
        local pdist = math.sqrt((px2 - proj.x)^2 + (py2 - proj.y)^2)
        if pdist <= proj.radius + player.size / 2 then
            if player.takeDamage then player.takeDamage(proj.damage) end
            table.insert(projDead, i)
        elseif proj.life <= 0 then
            table.insert(projDead, i)
        end
    end
    for i = #projDead, 1, -1 do
        table.remove(Enemy.projectiles, projDead[i])
    end
end

-- Strike enemies in front of player, returns damage feed entries
function Enemy.strikeInRange(hitX, hitY, radius, damage, damageFeed)
    for _, e in ipairs(Enemy.list) do
        if e.state ~= "dead" then
            local distSq = (hitX - e.x)^2 + (hitY - e.y)^2
            if distSq <= radius^2 then
                e.hp = e.hp - damage
                if damageFeed then
                    table.insert(damageFeed, {
                        x     = e.x,
                        y     = e.y - e.size - 4,
                        text  = "-" .. damage,
                        timer = 1.0,
                        color = { 1, 0.8, 0.2 }
                    })
                end
                if e.hp <= 0 then
                    e.hp    = 0
                    e.state = "dead"
                    -- Spawn loot into world drops
                    if _World and e.loot then
                        for _, lootDef in ipairs(e.loot) do
                            local qty = math.random(lootDef.min, lootDef.max)
                            table.insert(_World.drops, {
                                x = e.x + math.random(-12, 12),
                                y = e.y + math.random(-12, 12),
                                type = lootDef.item,
                                count = qty,
                                pickedUp = false
                            })
                        end
                    end
                end
            end
        end
    end
end

-- Draw all enemies
function Enemy.draw()
    for _, e in ipairs(Enemy.list) do
        local alpha = e.state == "dead" and math.max(0, 1 - e.deathTimer / 0.6) or 1

        -- Body
        love.graphics.setColor(e.color[1], e.color[2], e.color[3], alpha)
        if e.type == "bat" then
            -- Bat: diamond shape
            love.graphics.polygon("fill",
                e.x,          e.y - e.size,
                e.x + e.size, e.y,
                e.x,          e.y + e.size,
                e.x - e.size, e.y)
        elseif e.type == "orc" then
            love.graphics.rectangle("fill", e.x - e.size, e.y - e.size, e.size * 2, e.size * 2, 3, 3)
        else
            love.graphics.circle("fill", e.x, e.y, e.size)
        end

        if e.state ~= "dead" then
            -- HP bar above enemy
            local barW = e.size * 2 + 4
            local hpRatio = math.max(0, e.hp / e.maxHp)
            love.graphics.setColor(0.1, 0.1, 0.1, 0.8)
            love.graphics.rectangle("fill", e.x - barW / 2, e.y - e.size - 10, barW, 5)
            love.graphics.setColor(0.8, 0.15, 0.15, 0.9)
            love.graphics.rectangle("fill", e.x - barW / 2, e.y - e.size - 10, barW * hpRatio, 5)
            -- Label
            love.graphics.setColor(1, 1, 1, 0.75)
            love.graphics.print(e.label, e.x - 22, e.y + e.size + 2)
        end
    end
end

-- Serialize enemy list for save
function Enemy.serialize()
    local out = {}
    for _, e in ipairs(Enemy.list) do
        if e.state ~= "dead" then
            table.insert(out, {
                id = e.id, type = e.type,
                x = e.x, y = e.y,
                hp = e.hp
            })
        end
    end
    return out
end

-- Restore enemy list from save data
function Enemy.deserialize(data)
    Enemy.list = {}
    Enemy.idCounter = 0
    for _, d in ipairs(data or {}) do
        Enemy.spawn(d.type, d.x, d.y)
        local e = Enemy.list[#Enemy.list]
        e.hp = d.hp
        if d.id then
            e.id = d.id
            local num = tonumber(d.id:match("enemy_(%d+)")) or Enemy.idCounter
            if num > Enemy.idCounter then Enemy.idCounter = num end
        end
    end
end

-- Draw homing orb projectiles (camera-space)
function Enemy.drawProjectiles()
    for _, proj in ipairs(Enemy.projectiles) do
        local pulse = math.abs(math.sin(love.timer.getTime() * 8)) * 3
        -- Outer glow
        love.graphics.setColor(0.55, 0.10, 0.80, 0.45)
        love.graphics.circle("fill", proj.x, proj.y, proj.radius + 5 + pulse)
        -- Core orb
        love.graphics.setColor(0.80, 0.30, 1.00, 0.90)
        love.graphics.circle("fill", proj.x, proj.y, proj.radius)
        -- Bright centre
        love.graphics.setColor(1, 0.80, 1, 1)
        love.graphics.circle("fill", proj.x, proj.y, proj.radius * 0.4)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

return Enemy
