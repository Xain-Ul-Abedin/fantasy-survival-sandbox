-- FanIsle: Building & Structures Module
local Building = {}

Building.list = {}     -- Active placed structures
Building.preview = nil -- Ghost preview for placement

local structureColors = {
    wall     = { color = {0.55, 0.40, 0.25}, borderColor = {0.35, 0.22, 0.10} },
    campfire = { color = {0.85, 0.40, 0.15}, borderColor = {0.95, 0.70, 0.10} },
    chest    = { color = {0.60, 0.38, 0.18}, borderColor = {0.40, 0.25, 0.10} },
    torch    = { color = {0.75, 0.45, 0.10}, borderColor = {0.95, 0.70, 0.10} }
}

local SIZE = {
    wall     = { w = 32, h = 32 },
    campfire = { w = 28, h = 28 },
    chest    = { w = 30, h = 30 },
    torch    = { w = 10, h = 28 }
}

-- Place a blueprint structure into the world in front of the player
function Building.placeBlueprint(player, structureType)
    local key = structureType .. "_blueprint"
    if (player.inventory[key] or 0) < 1 then
        return false, "no_blueprint"
    end

    -- Calculate placement position in front of player
    local px = player.x + player.size / 2
    local py = player.y + player.size / 2
    local offset = 50
    local sx, sy = px, py

    if player.direction == "left"  then sx = px - offset
    elseif player.direction == "right" then sx = px + offset
    elseif player.direction == "up"    then sy = py - offset
    elseif player.direction == "down"  then sy = py + offset
    end

    local sz = SIZE[structureType] or { w = 32, h = 32 }

    -- Deduct blueprint from inventory
    player.inventory[key] = player.inventory[key] - 1

    local struct = {
        id = "struct_" .. (#Building.list + 1),
        type = structureType,
        x = sx - sz.w / 2,
        y = sy - sz.h / 2,
        w = sz.w,
        h = sz.h,
        completed = false,
        hammersLeft = 3, -- Hits needed to finish construction
        -- Campfire state
        cookTimer = 0,
        isCooking = false,
        -- Chest state
        storage = {},
        isOpen = false
    }

    table.insert(Building.list, struct)
    return true, struct
end

-- Attempt to hammer (build) a nearby incomplete blueprint
function Building.hammer(player, goblins)
    local px = player.x + player.size / 2
    local py = player.y + player.size / 2
    local reach = 55

    for _, struct in ipairs(Building.list) do
        if not struct.completed then
            local cx = struct.x + struct.w / 2
            local cy = struct.y + struct.h / 2
            local dist = math.sqrt((px - cx)^2 + (py - cy)^2)
            if dist <= reach then
                struct.hammersLeft = struct.hammersLeft - 1
                -- Record mimic action for goblins
                if goblins then
                    for _, gob in ipairs(goblins) do
                        if gob.tamed and gob.state == "mimic" then
                            gob.lastActionType = "build"
                            gob.lastBlueprintType = struct.type
                        end
                    end
                end
                if struct.hammersLeft <= 0 then
                    struct.completed = true
                    struct.hammersLeft = 0
                end
                return struct
            end
        end
    end
    return nil
end

-- Interact with a campfire or chest
function Building.interact(player)
    local px = player.x + player.size / 2
    local py = player.y + player.size / 2
    local reach = 55

    for _, struct in ipairs(Building.list) do
        if struct.completed then
            local cx = struct.x + struct.w / 2
            local cy = struct.y + struct.h / 2
            local dist = math.sqrt((px - cx)^2 + (py - cy)^2)

            if dist <= reach then
                if struct.type == "campfire" then
                    -- Start cooking berries
                    if not struct.isCooking and (player.inventory.berries or 0) >= 2 then
                        player.inventory.berries = player.inventory.berries - 2
                        struct.isCooking = true
                        struct.cookTimer = 2.0
                        return "campfire_start"
                    elseif struct.isCooking then
                        return "campfire_busy"
                    else
                        return "campfire_no_berries"
                    end
                elseif struct.type == "chest" then
                    struct.isOpen = not struct.isOpen
                    return struct.isOpen and "chest_opened" or "chest_closed"
                end
            end
        end
    end
    return nil
end

-- Update campfire cooking timers
function Building.update(dt, player)
    for _, struct in ipairs(Building.list) do
        if struct.type == "campfire" and struct.isCooking then
            struct.cookTimer = struct.cookTimer - dt
            if struct.cookTimer <= 0 then
                struct.isCooking = false
                struct.cookTimer = 0
                -- Yield cooked berries to player inventory
                player.inventory.cooked_berries = (player.inventory.cooked_berries or 0) + 2
            end
        end
    end
end

-- Check AABB overlap vs completed walls (returns true if blocked)
function Building.isBlocked(nx, ny, width, height)
    for _, struct in ipairs(Building.list) do
        if struct.completed and struct.type == "wall" then
            if nx < struct.x + struct.w and
               nx + width > struct.x and
               ny < struct.y + struct.h and
               ny + height > struct.y then
                return true
            end
        end
    end
    return false
end

-- Render all structures and incomplete blueprints
function Building.draw()
    for _, struct in ipairs(Building.list) do
        local colors = structureColors[struct.type] or { color = {0.5, 0.5, 0.5}, borderColor = {0.3, 0.3, 0.3} }

        if not struct.completed then
            -- Blueprint ghost: translucent outline only
            love.graphics.setColor(colors.color[1], colors.color[2], colors.color[3], 0.35)
            love.graphics.rectangle("fill", struct.x, struct.y, struct.w, struct.h, 3, 3)
            love.graphics.setColor(colors.borderColor[1], colors.borderColor[2], colors.borderColor[3], 0.8)
            love.graphics.rectangle("line", struct.x, struct.y, struct.w, struct.h, 3, 3)
            love.graphics.setColor(1, 1, 0.4, 0.9)
            love.graphics.print("[Blueprint " .. struct.hammersLeft .. " hits left]", struct.x - 10, struct.y - 16)
        else
            -- Completed structure
            love.graphics.setColor(colors.color)
            love.graphics.rectangle("fill", struct.x, struct.y, struct.w, struct.h, 3, 3)
            love.graphics.setColor(colors.borderColor)
            love.graphics.rectangle("line", struct.x, struct.y, struct.w, struct.h, 3, 3)

            -- Campfire flame accent
            if struct.type == "campfire" then
                love.graphics.setColor(0.95, 0.70, 0.10, 0.9)
                love.graphics.circle("fill", struct.x + struct.w / 2, struct.y + struct.h / 2, 8)
                if struct.isCooking then
                    love.graphics.setColor(1, 0.6, 0.1)
                    love.graphics.print("Cooking... " .. math.ceil(struct.cookTimer) .. "s", struct.x - 20, struct.y - 16)
                else
                    love.graphics.setColor(0.8, 0.8, 0.8, 0.7)
                    love.graphics.print("Campfire [F to cook]", struct.x - 25, struct.y - 16)
                end
            end

            -- Chest lid accent
            if struct.type == "chest" then
                love.graphics.setColor(0.50, 0.30, 0.10)
                love.graphics.rectangle("fill", struct.x + 2, struct.y + 2, struct.w - 4, 6)
                love.graphics.setColor(0.9, 0.8, 0.4, 0.7)
                love.graphics.print("Chest [F]", struct.x - 5, struct.y - 16)
                if struct.isOpen then
                    love.graphics.setColor(0, 0, 0, 0.7)
                    love.graphics.rectangle("fill", struct.x - 20, struct.y - 55, 100, 45, 4, 4)
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.print("Storage:", struct.x - 15, struct.y - 52)
                    local row = 0
                    for item, qty in pairs(struct.storage) do
                        if qty > 0 then
                            love.graphics.print(item .. " x" .. qty, struct.x - 15, struct.y - 38 + row * 13)
                            row = row + 1
                        end
                    end
                end
            end

            -- Wall accent line
            if struct.type == "wall" then
                love.graphics.setColor(0.35, 0.22, 0.10, 0.6)
                love.graphics.rectangle("fill", struct.x + 3, struct.y + 3, struct.w - 6, 3)
                love.graphics.rectangle("fill", struct.x + 3, struct.y + struct.h - 6, struct.w - 6, 3)
            end

            -- Torch: pole + animated flame
            if struct.type == "torch" then
                local cx = struct.x + struct.w / 2
                local flicker = math.abs(math.sin(love.timer.getTime() * 6)) * 4
                -- Pole
                love.graphics.setColor(0.55, 0.35, 0.10)
                love.graphics.rectangle("fill", cx - 2, struct.y + 6, 4, struct.h - 6)
                -- Flame outer
                love.graphics.setColor(0.95, 0.60, 0.10, 0.9)
                love.graphics.circle("fill", cx, struct.y + 4 + flicker * 0.3, 6 + flicker * 0.5)
                -- Flame inner
                love.graphics.setColor(1, 0.92, 0.55, 0.85)
                love.graphics.circle("fill", cx, struct.y + 5 + flicker * 0.2, 3)
                love.graphics.setColor(0.9, 0.75, 0.3, 0.65)
                love.graphics.print("Torch", struct.x - 8, struct.y - 14)
            end
        end
    end
end

-- Draw warm glow circles for all completed torches (call during night overlay)
-- This punches a soft warm light into the darkness vignette
function Building.drawTorchGlow(nightAlpha)
    if not nightAlpha or nightAlpha <= 0 then return end
    for _, struct in ipairs(Building.list) do
        if struct.completed and struct.type == "torch" then
            local cx = struct.x + struct.w / 2
            local cy = struct.y + struct.h / 2
            local flicker = math.abs(math.sin(love.timer.getTime() * 5)) * 8
            local glowR   = 120 + flicker
            -- Layered warm glow (subtractive from night)
            local steps = 8
            for i = steps, 1, -1 do
                local frac  = i / steps
                local alpha = nightAlpha * frac * 0.55
                love.graphics.setColor(0.95, 0.65, 0.15, alpha)
                love.graphics.circle("fill", cx, cy, glowR * frac)
            end
        end
    end
    love.graphics.setColor(1, 1, 1, 1)
end

return Building
