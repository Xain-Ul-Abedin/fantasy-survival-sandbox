-- FanIsle: NPC Module — Villager roster with dialogue & trades
local NPC = {}

NPC.list = {}

-- Dialogue lists per NPC
local MIRA_DIALOGUES = {
    "Welcome, traveller. FanIsle has grown dark since the Lich awoke on day seven.",
    "I can trade supplies. Bring me wood and I shall cook you berries from my secret stash.",
    "Beware the Cave zones to the north and south — skeletons nest there. Stay in the Forest!",
    "If you survive to Day 7, light many torches. The Lich fears warmth.",
    "The goblins here are friendlier than they look. A berry goes a long way.",
}

local HEKTOR_DIALOGUES = {
    "I am Hektor, the forge-master of FanIsle.",
    "The Lich's shadow has made my forge cold, but I still have some of my special stone alloys.",
    "Bring me 8 stone, and I will trade you 2 flint to refine your tools!",
    "Skeletons hate axes, but the Golem is made of solid stone. Use your pickaxe on resources, but watch out for its slam!",
}

local ELENIA_DIALOGUES = {
    "Greetings, traveler. I can sense the life energy of the island fading.",
    "The Cave is dangerous, but rare herbs grow here. I've brewed them into life-saving remedies.",
    "Bring me 4 raw berries, and I'll trade you 1 Cooked Berry to heal your wounds.",
    "If you get bitten by a Vampire, it will steal your lifeforce. Stay healthy and warm!",
}

-- Spawn villagers into the world
function NPC.spawn()
    NPC.list = {}

    -- 1. Elder Mira (Center Forest: zone col=2, row=2)
    table.insert(NPC.list, {
        id            = "villager_1",
        name          = "Elder Mira",
        x             = 1450,
        y             = 1070,
        size          = 18,
        dialogueIdx   = 1,
        talkOpen      = false,
        color         = { 0.90, 0.80, 0.55 },
        characterType = "npc_mira",
        tradeHint     = "Trade (5 Wood -> 2 Cooked Berries)",
        trade         = { give = { wood = 5 }, receive = { cooked_berries = 2 } },
        dialogues     = MIRA_DIALOGUES
    })

    -- 2. Blacksmith Hektor (Desert Zone: zone col=3, row=2)
    table.insert(NPC.list, {
        id            = "villager_2",
        name          = "Blacksmith Hektor",
        x             = 2400,
        y             = 1070,
        size          = 18,
        dialogueIdx   = 1,
        talkOpen      = false,
        color         = { 0.45, 0.45, 0.50 },
        characterType = "npc_blacksmith",
        tradeHint     = "Trade (8 Stone -> 2 Flint)",
        trade         = { give = { stone = 8 }, receive = { flint = 2 } },
        dialogues     = HEKTOR_DIALOGUES
    })

    -- 3. Healer Elenia (Cave Zone: zone col=2, row=3)
    table.insert(NPC.list, {
        id            = "villager_3",
        name          = "Healer Elenia",
        x             = 1440,
        y             = 1790,
        size          = 18,
        dialogueIdx   = 1,
        talkOpen      = false,
        color         = { 0.50, 0.85, 0.70 },
        characterType = "npc_healer",
        tradeHint     = "Trade (4 Berries -> 1 Cooked Berry)",
        trade         = { give = { berries = 4 }, receive = { cooked_berries = 1 } },
        dialogues     = ELENIA_DIALOGUES
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
                -- Close dialogue on other NPCs first
                NPC.closeDialogue()
                -- Open dialogue
                npc.talkOpen    = true
                npc.dialogueIdx = 1
                return "open", npc
            else
                -- Advance dialogue
                npc.dialogueIdx = npc.dialogueIdx + 1
                if npc.dialogueIdx > #npc.dialogues then
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
    return npc.dialogues[npc.dialogueIdx] or ""
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
        local drawn = false
        if _Assets and _Assets.sheet then
            local animTimer = love.timer.getTime()
            local quad = _Assets.getQuad(npc.characterType, nil, true, animTimer)
            if quad then
                love.graphics.setColor(1, 1, 1, 1)
                local _, _, qw, qh = quad:getViewport()
                love.graphics.draw(_Assets.sheet, quad, npc.x - npc.size, npc.y - npc.size, 0, (npc.size * 2) / qw, (npc.size * 2) / qh)
                drawn = true
            end
        end

        if not drawn then
            -- Fallback Body (hooded figure: circle + small rectangle)
            love.graphics.setColor(npc.color)
            love.graphics.circle("fill", npc.x, npc.y, npc.size)
            -- Hood accent
            love.graphics.setColor(0.70, 0.55, 0.30)
            love.graphics.arc("fill", npc.x, npc.y, npc.size, math.pi, 2 * math.pi)
        end

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
