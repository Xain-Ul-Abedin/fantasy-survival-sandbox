-- FanIsle: Save / Load Module
local Save = {}

-- Serialize a table recursively to a Lua script string
local function serialize(val)
    if type(val) == "string" then
        return string.format("%q", val)
    elseif type(val) == "number" or type(val) == "boolean" then
        return tostring(val)
    elseif type(val) == "table" then
        local parts = {}
        for k, v in pairs(val) do
            local keyStr
            if type(k) == "string" then
                keyStr = "[" .. string.format("%q", k) .. "]"
            else
                keyStr = "[" .. tostring(k) .. "]"
            end
            table.insert(parts, keyStr .. "=" .. serialize(v))
        end
        return "{" .. table.concat(parts, ",") .. "}"
    else
        return "nil"
    end
end

-- Save game state
function Save.game(player, world, goblin, ui)
    local state = {
        difficulty = ui.difficulty,
        player = {
            x = player.x,
            y = player.y,
            health = player.health,
            hunger = player.hunger,
            stamina = player.stamina,
            inventory = player.inventory
        },
        resources = {},
        drops = {},
        goblins = {},
        buildings = {}
    }
    
    -- Save resources
    for _, res in ipairs(world.resources) do
        table.insert(state.resources, {
            id = res.id,
            x = res.x,
            y = res.y,
            type = res.type,
            hits = res.hits,
            destroyed = res.destroyed,
            dropSpawned = res.dropSpawned,
            dropType = res.dropType,
            dropCount = res.dropCount,
            dropFlint = res.dropFlint
        })
    end
    
    -- Save drops
    for _, drop in ipairs(world.drops) do
        table.insert(state.drops, {
            x = drop.x,
            y = drop.y,
            type = drop.type,
            count = drop.count,
            pickedUp = drop.pickedUp
        })
    end
    
    -- Save goblins
    for _, gob in ipairs(goblin.list) do
        table.insert(state.goblins, {
            id = gob.id,
            name = gob.name,
            x = gob.x,
            y = gob.y,
            tamed = gob.tamed,
            state = gob.state,
            lastActionType = gob.lastActionType,
            lastActionTargetType = gob.lastActionTargetType,
            lastBlueprintType = gob.lastBlueprintType
        })
    end

    -- Save buildings (if building module provided)
    if building then
        for _, struct in ipairs(building.list) do
            table.insert(state.buildings, {
                id = struct.id,
                type = struct.type,
                x = struct.x,
                y = struct.y,
                w = struct.w,
                h = struct.h,
                completed = struct.completed,
                hammersLeft = struct.hammersLeft,
                storage = struct.storage,
                isCooking = struct.isCooking,
                cookTimer = struct.cookTimer
            })
        end
    end
    
    local content = "return " .. serialize(state)
    local success, err = love.filesystem.write("savegame.lua", content)
    if success then
        print("Report. Game saved successfully to savegame.lua")
        return true
    else
        print("Error. Save failed: " .. tostring(err))
        return false
    end
end

-- Load game state
function Save.load(player, world, goblin, ui, building)
    local info = love.filesystem.getInfo("savegame.lua")
    if not info then
        print("Report. No save file found.")
        return false
    end
    
    local chunk, err = love.filesystem.load("savegame.lua")
    if not chunk then
        print("Error. Load chunk compile failed: " .. tostring(err))
        return false
    end
    
    local state = chunk()
    if not state then
        print("Error. State parsing returned nil.")
        return false
    end
    
    -- Restore UI
    ui.difficulty = state.difficulty or "easy"
    if ui.difficulty == "easy" then ui.difficultyLabel = "Easy"
    elseif ui.difficulty == "normal" then ui.difficultyLabel = "Normal"
    elseif ui.difficulty == "hard" then ui.difficultyLabel = "Hard" end
    
    -- Restore Player
    player.x = state.player.x
    player.y = state.player.y
    player.health = state.player.health
    player.hunger = state.player.hunger
    player.stamina = state.player.stamina
    player.inventory = state.player.inventory or {}
    
    -- Restore Resources
    world.resources = {}
    for _, r in ipairs(state.resources or {}) do
        table.insert(world.resources, {
            id = r.id,
            x = r.x,
            y = r.y,
            type = r.type,
            hits = r.hits,
            destroyed = r.destroyed,
            dropSpawned = r.dropSpawned,
            dropType = r.dropType,
            dropCount = r.dropCount,
            dropFlint = r.dropFlint
        })
    end
    
    -- Restore Drops
    world.drops = {}
    for _, d in ipairs(state.drops or {}) do
        table.insert(world.drops, {
            x = d.x,
            y = d.y,
            type = d.type,
            count = d.count,
            pickedUp = d.pickedUp
        })
    end
    
    -- Restore Goblins
    goblin.list = {}
    for _, g in ipairs(state.goblins or {}) do
        table.insert(goblin.list, {
            id = g.id,
            name = g.name,
            x = g.x,
            y = g.y,
            size = 20,
            tamed = g.tamed,
            state = g.state or "wild",
            speed = 120,
            targetX = 0,
            targetY = 0,
            wanderTimer = 0,
            harvestTimer = 0,
            lastActionType = g.lastActionType,
            lastActionTargetType = g.lastActionTargetType,
            lastBlueprintType = g.lastBlueprintType,
            targetResource = nil
        })
    end

    -- Restore Buildings
    if building then
        building.list = {}
        for _, s in ipairs(state.buildings or {}) do
            table.insert(building.list, {
                id = s.id,
                type = s.type,
                x = s.x,
                y = s.y,
                w = s.w,
                h = s.h,
                completed = s.completed,
                hammersLeft = s.hammersLeft or 0,
                storage = s.storage or {},
                isOpen = false,
                isCooking = s.isCooking or false,
                cookTimer = s.cookTimer or 0
            })
        end
    end

    print("Report. Game state loaded successfully.")
    return true
end

return Save
