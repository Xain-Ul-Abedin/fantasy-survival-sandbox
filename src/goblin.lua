-- FanIsle: Goblin Helpers Module
local Goblin = {}

Goblin.list = {}

-- Generate initial goblins
function Goblin.spawnGoblins()
    Goblin.list = {}
    -- Spawn 3 goblins on the island
    for i = 1, 3 do
        table.insert(Goblin.list, {
            id = "goblin_" .. i,
            name = "Goblin " .. string.char(64 + i), -- Goblin A, B, C
            x = math.random(100, 800),
            y = math.random(150, 600),
            size = 20,
            tamed = false,
            state = "wild", -- "wild", "follow", "mimic", "standby"
            speed = 120,
            targetX = 0,
            targetY = 0,
            wanderTimer = 0,
            harvestTimer = 0,
            lastActionType = nil,
            lastActionTargetType = nil,
            lastBlueprintType = nil,
            targetResource = nil,
            direction = "down",
            isMoving = false,
            animTimer = 0
        })
    end
end

-- Update Goblin movements and state machine logic
function Goblin.update(dt, player, resources, resourceTypes)
    local playerCenterX = player.x + player.size / 2
    local playerCenterY = player.y + player.size / 2

    for _, gob in ipairs(Goblin.list) do
        local prevX, prevY = gob.x, gob.y
        if not gob.tamed then
            -- 1. Wild state: wanders around randomly
            gob.wanderTimer = gob.wanderTimer - dt
            if gob.wanderTimer <= 0 then
                gob.targetX = gob.x + math.random(-80, 80)
                gob.targetY = gob.y + math.random(-80, 80)
                gob.wanderTimer = math.random(3, 6)
            end
            
            -- Move slowly toward wander target
            local dx = gob.targetX - gob.x
            local dy = gob.targetY - gob.y
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist > 5 then
                gob.x = gob.x + (dx / dist) * (gob.speed * 0.5) * dt
                gob.y = gob.y + (dy / dist) * (gob.speed * 0.5) * dt
            end

        elseif gob.state == "follow" then
            -- 2. Follow state: follows player but stays at a short distance
            local dx = playerCenterX - gob.x
            local dy = playerCenterY - gob.y
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist > 50 then
                gob.x = gob.x + (dx / dist) * gob.speed * dt
                gob.y = gob.y + (dy / dist) * gob.speed * dt
            end

        elseif gob.state == "standby" then
            -- 3. Standby state: stays stationary
            -- Do nothing

        elseif gob.state == "mimic" then
            -- 4. Mimic state: mimicking harvesting or building
            if gob.lastActionType == "build" and gob.lastBlueprintType and _Building then
                -- Find nearest incomplete blueprint of that type
                local nearestBP = nil
                local minDist = 999999
                for _, struct in ipairs(_Building.list) do
                    if not struct.completed and struct.type == gob.lastBlueprintType then
                        local dSq = (struct.x + struct.w/2 - gob.x)^2 + (struct.y + struct.h/2 - gob.y)^2
                        if dSq < minDist then
                            minDist = dSq
                            nearestBP = struct
                        end
                    end
                end

                if nearestBP then
                    local cx = nearestBP.x + nearestBP.w / 2
                    local cy = nearestBP.y + nearestBP.h / 2
                    local dx = cx - gob.x
                    local dy = cy - gob.y
                    local dist = math.sqrt(dx*dx + dy*dy)
                    if dist > 40 then
                        gob.x = gob.x + (dx / dist) * gob.speed * dt
                        gob.y = gob.y + (dy / dist) * gob.speed * dt
                    else
                        gob.harvestTimer = gob.harvestTimer + dt
                        if gob.harvestTimer >= 1.5 then
                            gob.harvestTimer = 0
                            nearestBP.hammersLeft = nearestBP.hammersLeft - 1
                            if nearestBP.hammersLeft <= 0 then
                                nearestBP.completed = true
                                nearestBP.hammersLeft = 0
                            end
                        end
                    end
                else
                    -- No blueprints left, follow player
                    local dx = playerCenterX - gob.x
                    local dy = playerCenterY - gob.y
                    local dist = math.sqrt(dx*dx + dy*dy)
                    if dist > 60 then
                        gob.x = gob.x + (dx / dist) * gob.speed * dt
                        gob.y = gob.y + (dy / dist) * gob.speed * dt
                    end
                end
            elseif gob.lastActionType == "harvest" and gob.lastActionTargetType then
                -- Find nearest active resource of that type
                local nearestRes = nil
                local minDist = 999999
                
                for _, res in ipairs(resources) do
                    if not res.destroyed and res.type == gob.lastActionTargetType then
                        local rx = res.x
                        local ry = res.y
                        local dSq = (rx - gob.x)^2 + (ry - gob.y)^2
                        if dSq < minDist then
                            minDist = dSq
                            nearestRes = res
                        end
                    end
                end
                
                if nearestRes then
                    gob.targetResource = nearestRes
                    local dx = nearestRes.x - gob.x
                    local dy = nearestRes.y - gob.y
                    local dist = math.sqrt(dx*dx + dy*dy)
                    
                    if dist > 35 then
                        -- Walk to resource
                        gob.x = gob.x + (dx / dist) * gob.speed * dt
                        gob.y = gob.y + (dy / dist) * gob.speed * dt
                    else
                        -- At resource: swing/harvest periodically
                        gob.harvestTimer = gob.harvestTimer + dt
                        if gob.harvestTimer >= 1.5 then
                            gob.harvestTimer = 0
                            nearestRes.hits = nearestRes.hits - 1
                            if nearestRes.hits <= 0 then
                                nearestRes.destroyed = true
                                -- Spawn drops
                                local randQty = math.random(1, 3)
                                if nearestRes.type == "tree" then
                                    nearestRes.dropType = "wood"
                                    nearestRes.dropCount = randQty
                                elseif nearestRes.type == "stone" then
                                    nearestRes.dropType = "stone"
                                    nearestRes.dropCount = randQty
                                    if math.random() > 0.6 then nearestRes.dropFlint = true end
                                elseif nearestRes.type == "berry" then
                                    nearestRes.dropType = "berries"
                                    nearestRes.dropCount = math.random(2, 4)
                                end
                                gob.targetResource = nil
                            end
                        end
                    end
                else
                    -- No matching resources left; default to following player
                    local dx = playerCenterX - gob.x
                    local dy = playerCenterY - gob.y
                    local dist = math.sqrt(dx*dx + dy*dy)
                    if dist > 60 then
                        gob.x = gob.x + (dx / dist) * gob.speed * dt
                        gob.y = gob.y + (dy / dist) * gob.speed * dt
                    end
                end
            else
                -- No mimic action learned yet; follow player
                local dx = playerCenterX - gob.x
                local dy = playerCenterY - gob.y
                local dist = math.sqrt(dx*dx + dy*dy)
                if dist > 60 then
                    gob.x = gob.x + (dx / dist) * gob.speed * dt
                    gob.y = gob.y + (dy / dist) * gob.speed * dt
                end
            end
        end

        -- Clamp goblins inside full world boundary
        local WORLD_W = _Camera and _Camera.WORLD_W or 2880
        local WORLD_H = _Camera and _Camera.WORLD_H or 2160
        gob.x = math.max(10, math.min(gob.x, WORLD_W - 10))
        gob.y = math.max(10, math.min(gob.y, WORLD_H - 10))

        -- Compute delta movement to update walk cycle and direction
        local movedX = gob.x - prevX
        local movedY = gob.y - prevY
        local distMoved = math.sqrt(movedX * movedX + movedY * movedY)

        if distMoved > 0.05 then
            gob.isMoving = true
            gob.animTimer = gob.animTimer + dt
            if math.abs(movedX) > math.abs(movedY) then
                if movedX > 0 then gob.direction = "right" else gob.direction = "left" end
            else
                if movedY > 0 then gob.direction = "down" else gob.direction = "up" end
            end
        else
            gob.isMoving = false
            gob.animTimer = 0
        end
    end
end

-- Tame and cycle state interaction
function Goblin.interact(player)
    local playerCenterX = player.x + player.size / 2
    local playerCenterY = player.y + player.size / 2
    local interactRange = 60

    for _, gob in ipairs(Goblin.list) do
        local dist = math.sqrt((playerCenterX - gob.x)^2 + (playerCenterY - gob.y)^2)
        if dist <= interactRange then
            if not gob.tamed then
                -- Try to tame (requires 1 berry)
                if player.inventory.berries > 0 then
                    player.inventory.berries = player.inventory.berries - 1
                    gob.tamed = true
                    gob.state = "follow"
                    print("Report. Tamed goblin: " .. gob.name)
                    return "tamed"
                else
                    return "need_berry"
                end
            else
                -- Cycle states: follow -> mimic -> standby
                if gob.state == "follow" then
                    gob.state = "mimic"
                elseif gob.state == "mimic" then
                    gob.state = "standby"
                else
                    gob.state = "follow"
                end
                print("Report. Goblin state updated: " .. gob.name .. " is now " .. gob.state)
                return "cycled"
            end
        end
    end
    return nil
end

-- Render all Goblins
function Goblin.draw()
    for _, gob in ipairs(Goblin.list) do
        local drawn = false
        if _Assets and _Assets.sheet then
            local quad = _Assets.getQuad("goblin", gob.direction, gob.isMoving, gob.animTimer)
            if quad then
                love.graphics.setColor(1, 1, 1, 1)
                local _, _, qw, qh = quad:getViewport()
                love.graphics.draw(_Assets.sheet, quad, gob.x - gob.size, gob.y - gob.size, 0, (gob.size * 2) / qw, (gob.size * 2) / qh)
                drawn = true
            end
        end

        if gob.tamed then
            -- Tamed outline (only if drawn with shapes, or draw ring around sprite)
            love.graphics.setColor(0.9, 0.5, 0.1)
            love.graphics.circle("line", gob.x, gob.y, gob.size + 4)

            if not drawn then
                -- Main body: green fallback
                love.graphics.setColor(0.4, 0.7, 0.3)
                love.graphics.circle("fill", gob.x, gob.y, gob.size)
            end
            
            -- State label
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(gob.name .. " (" .. string.upper(gob.state) .. ")", gob.x - 30, gob.y + gob.size + 4)
            if gob.state == "mimic" and gob.lastActionTargetType then
                love.graphics.setColor(0.9, 0.8, 0.4, 0.8)
                love.graphics.print("Mimics: " .. gob.lastActionTargetType, gob.x - 30, gob.y - gob.size - 14)
            end
        else
            if not drawn then
                -- Wild color fallback
                love.graphics.setColor(0.2, 0.5, 0.2)
                love.graphics.circle("fill", gob.x, gob.y, gob.size)
                love.graphics.setColor(0.5, 0.8, 0.5)
                love.graphics.circle("fill", gob.x, gob.y, gob.size - 3)
            end
            
            -- Wild Label
            love.graphics.setColor(0.7, 0.9, 0.7)
            love.graphics.print("Wild Goblin (Needs Berry)", gob.x - 55, gob.y + gob.size + 4)
        end
    end
end

return Goblin
