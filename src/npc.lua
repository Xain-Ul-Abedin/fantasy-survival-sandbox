-- FanIsle: NPC Module — Villager with dialogue & trade
local NPC = {}

NPC.list = {}

-- Dialogue lines per NPC
local VILLAGER_DIALOGUE = {
    "Welcome, traveller. FanIsle has grown dark since the Lich awoke on day seven.",
    "I can trade supplies. Bring me wood and I shall cook you berries from my secret stash.",
    "Beware the Cave zones to the north and south — skeletons nest there. Stay in the Forest!",
    "If you survive to Day 7, light many torches. The Lich fears warmth.",
    "The goblins here are friendlier than they look. A berry goes a long way.",
}

-- Spawn villagers into the world
function NPC.spawn()
    NPC.list = {}
    -- One villager in the center Forest zone (zone col=2, row=2 center ≈ world 1440, 1080)
    table.insert(NPC.list, {
        id          = "villager_1",
        name        = "Elder Mira",
        x           = 1450,
        y           = 1070,
        size        = 18,
        dialogueIdx = 1,
        talkOpen    = false,
        color       = { 0.90, 0.80, 0.55 },
        -- Trade: 5 wood → 2 cooked_berries
        trade       = { give = { wood = 5 }, receive = { cooked_berries = 2 } }
    })
end

-- Interact: open/advance dialogue or trade
function NPC.interact(player, key)
    local px = player.x + player.size / 2
    local py = player.y + player.size / 2

    for _, npc in ipairs(NPC.list) do
        local dist = math.sqrt((px - npc.x)^2 + (py - npc.y)^2)
        if dist <= 55 then
            if not npc.talkOpen then
                -- Open dialogue
                npc.talkOpen    = true
                npc.dialogueIdx = 1
                return "open", npc
            else
                -- Advance dialogue
                npc.dialogueIdx = npc.dialogueIdx + 1
                if npc.dialogueIdx > #VILLAGER_DIALOGUE then
                    npc.talkOpen    = false
                    npc.dialogueIdx = 1
                    return "close", npc
                end
                return "advance", npc
            end
        end
    end
    return nil, nil
end

-- Trade action: press a dedicated key (G) when dialogue is open
function NPC.trade(player)
    local px = player.x + player.size / 2
    local py = player.y + player.size / 2

    for _, npc in ipairs(NPC.list) do
        if npc.talkOpen then
            local dist = math.sqrt((px - npc.x)^2 + (py - npc.y)^2)
            if dist <= 55 then
                local t = npc.trade
                -- Check if player has enough to give
                for item, qty in pairs(t.give) do
                    if (player.inventory[item] or 0) < qty then
                        return "insufficient", item
                    end
                end
                -- Deduct give items
                for item, qty in pairs(t.give) do
                    player.inventory[item] = player.inventory[item] - qty
                end
                -- Add receive items
                for item, qty in pairs(t.receive) do
                    player.inventory[item] = (player.inventory[item] or 0) + qty
                end
                return "traded", npc
            end
        end
    end
    return nil, nil
end

-- Return current dialogue line for an open NPC
function NPC.getDialogueLine(npc)
    return VILLAGER_DIALOGUE[npc.dialogueIdx] or ""
end

-- Close any open dialogue
function NPC.closeDialogue()
    for _, npc in ipairs(NPC.list) do
        npc.talkOpen = false
    end
end

-- Check if any NPC dialogue is open
function NPC.anyOpen()
    for _, npc in ipairs(NPC.list) do
        if npc.talkOpen then return npc end
    end
    return nil
end

-- Draw all NPCs
function NPC.draw()
    for _, npc in ipairs(NPC.list) do
        -- Body (hooded figure: circle + small rectangle)
        love.graphics.setColor(npc.color)
        love.graphics.circle("fill", npc.x, npc.y, npc.size)
        -- Hood accent
        love.graphics.setColor(0.70, 0.55, 0.30)
        love.graphics.arc("fill", npc.x, npc.y, npc.size, math.pi, 2 * math.pi)
        -- Name + interact hint
        love.graphics.setColor(1, 0.95, 0.7, 0.9)
        love.graphics.print(npc.name, npc.x - 28, npc.y - npc.size - 16)
        love.graphics.setColor(0.7, 0.7, 0.7, 0.7)
        love.graphics.print("[T] Talk  [G] Trade", npc.x - 42, npc.y + npc.size + 4)

        -- Dialogue speech bubble if open
        if npc.talkOpen then
            love.graphics.setColor(0.95, 0.90, 0.75, 0.85)
            love.graphics.circle("fill", npc.x, npc.y - npc.size - 8, 6)
            love.graphics.circle("fill", npc.x + 5, npc.y - npc.size - 18, 4)
        end
    end
end

return NPC
