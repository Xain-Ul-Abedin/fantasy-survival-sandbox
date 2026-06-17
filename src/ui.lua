-- FanIsle: UI & Menu Module
local UI = {}

-- Selected difficulty configuration
UI.difficulty = "easy"
UI.difficultyLabel = "Easy"

-- Render the start menu
function UI.drawMenu()
    love.graphics.clear(0.08, 0.08, 0.12)
    
    -- Draw title
    love.graphics.setColor(0.9, 0.8, 0.4)
    love.graphics.printf("🏰 FANISLE 🏰", 0, 180, love.graphics.getWidth(), "center")
    
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.printf("Inspired by The Survivalists", 0, 230, love.graphics.getWidth(), "center")
    
    -- Instruction to select difficulty
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.printf("Select Difficulty to Start:", 0, 340, love.graphics.getWidth(), "center")
    
    love.graphics.setColor(0.2, 0.7, 0.3)
    love.graphics.printf("[1] Easy Mode (Hunger Drain: 1.0/s)", 0, 380, love.graphics.getWidth(), "center")
    
    love.graphics.setColor(0.9, 0.5, 0.1)
    love.graphics.printf("[2] Normal Mode (Hunger Drain: 1.5/s)", 0, 410, love.graphics.getWidth(), "center")
    
    love.graphics.setColor(0.9, 0.2, 0.2)
    love.graphics.printf("[3] Hard Mode (Hunger Drain: 2.0/s)", 0, 440, love.graphics.getWidth(), "center")
    
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.printf("Controls: WASD/Arrows to Move | LShift to Sprint | Space to Harvest/Hammer | E to Eat", 0, 555, love.graphics.getWidth(), "center")
    love.graphics.printf("T = Tame/Cycle Goblin | C = Crafting Menu | B = Place Blueprint | F = Interact", 0, 580, love.graphics.getWidth(), "center")
    love.graphics.printf("S = Save | L = Load", 0, 605, love.graphics.getWidth(), "center")
end

-- Render the Game Over screen
function UI.drawGameOver()
    love.graphics.clear(0.2, 0.05, 0.05)
    love.graphics.setColor(0.9, 0.1, 0.1)
    love.graphics.printf("YOU PERISHED ON THE ISLAND", 0, 250, love.graphics.getWidth(), "center")
    
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.printf("Press [R] to Respawn", 0, 400, love.graphics.getWidth(), "center")
end

-- Render the HUD during gameplay
function UI.drawHUD(player)
    -- HUD panel background
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 10, 10, 280, 155, 6, 6)
    
    -- Header
    love.graphics.setColor(0.9, 0.8, 0.4)
    love.graphics.print("Xain-Sama's HUD - " .. UI.difficultyLabel, 20, 20)
    
    -- Health Bar (Red)
    love.graphics.setColor(0.1, 0.1, 0.1, 0.8)
    love.graphics.rectangle("fill", 20, 45, 200, 14, 3, 3)
    love.graphics.setColor(0.8, 0.2, 0.2)
    local hpPercent = math.max(0, player.health / player.maxHealth)
    love.graphics.rectangle("fill", 20, 45, hpPercent * 200, 14, 3, 3)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("HP: " .. math.floor(player.health) .. "/" .. player.maxHealth, 25, 43)

    -- Hunger Bar (Orange)
    love.graphics.setColor(0.1, 0.1, 0.1, 0.8)
    love.graphics.rectangle("fill", 20, 68, 200, 14, 3, 3)
    love.graphics.setColor(0.9, 0.5, 0.1)
    local hungerPercent = math.max(0, player.hunger / player.maxHunger)
    love.graphics.rectangle("fill", 20, 68, hungerPercent * 200, 14, 3, 3)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Food: " .. math.floor(player.hunger) .. "/" .. player.maxHunger, 25, 66)

    -- Stamina Bar (Green)
    love.graphics.setColor(0.1, 0.1, 0.1, 0.8)
    love.graphics.rectangle("fill", 20, 91, 200, 14, 3, 3)
    love.graphics.setColor(0.2, 0.7, 0.3)
    local stamPercent = math.max(0, player.stamina / player.maxStamina)
    love.graphics.rectangle("fill", 20, 91, stamPercent * 200, 14, 3, 3)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Stam: " .. math.floor(player.stamina) .. "/" .. player.maxStamina, 25, 89)

    -- Inventory readout
    love.graphics.setColor(0.8, 0.8, 0.8)
    local invLines = {}
    local priorityOrder = { "wood", "stone", "flint", "berries", "cooked_berries", "wood_axe",
                             "campfire_blueprint", "chest_blueprint", "wall_blueprint" }
    local shown = {}
    for _, item in ipairs(priorityOrder) do
        local count = player.inventory[item] or 0
        if count > 0 then
            table.insert(invLines, item:gsub("_", " ") .. " x" .. count)
            shown[item] = true
        end
    end
    for item, count in pairs(player.inventory) do
        if count > 0 and not shown[item] then
            table.insert(invLines, item:gsub("_", " ") .. " x" .. count)
        end
    end
    if #invLines == 0 then table.insert(invLines, "(Empty)") end
    love.graphics.print("Inv: " .. table.concat(invLines, " | "), 20, 115)

    -- Tool indicator
    if (player.inventory.wood_axe or 0) > 0 then
        love.graphics.setColor(0.8, 0.6, 0.2)
        love.graphics.print("[Axe equipped - faster tree harvest]", 20, 135)
    end
end

-- Render the Crafting Menu overlay
function UI.drawCraftingMenu(crafting, player)
    if not crafting.isOpen then return end

    local W, H = love.graphics.getWidth(), love.graphics.getHeight()
    local panelW, panelH = 420, 40 + #crafting.recipes * 60 + 20
    local panelX = (W - panelW) / 2
    local panelY = (H - panelH) / 2

    -- Background panel
    love.graphics.setColor(0.08, 0.08, 0.14, 0.95)
    love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, 8, 8)
    love.graphics.setColor(0.5, 0.4, 0.7, 0.9)
    love.graphics.rectangle("line", panelX, panelY, panelW, panelH, 8, 8)

    -- Title
    love.graphics.setColor(0.9, 0.8, 0.4)
    love.graphics.printf("[ Crafting Menu ]", panelX, panelY + 10, panelW, "center")
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.printf("Up/Down to navigate | Space to craft | C to close", panelX, panelY + 26, panelW, "center")

    for i, recipe in ipairs(crafting.recipes) do
        local rowY = panelY + 44 + (i - 1) * 60
        local isSelected = (i == crafting.selectedIndex)

        -- Row background highlight
        if isSelected then
            love.graphics.setColor(0.25, 0.20, 0.40, 0.9)
            love.graphics.rectangle("fill", panelX + 8, rowY, panelW - 16, 55, 5, 5)
            love.graphics.setColor(0.6, 0.4, 0.9)
            love.graphics.rectangle("line", panelX + 8, rowY, panelW - 16, 55, 5, 5)
        end

        -- Recipe name
        love.graphics.setColor(isSelected and 1 or 0.8, isSelected and 0.9 or 0.8, isSelected and 0.4 or 0.8)
        love.graphics.print(recipe.name, panelX + 18, rowY + 6)

        -- Description
        love.graphics.setColor(0.6, 0.6, 0.7)
        love.graphics.print(recipe.desc, panelX + 18, rowY + 22)

        -- Cost list
        local costParts = {}
        for mat, qty in pairs(recipe.cost) do
            local have = player.inventory[mat] or 0
            local color = have >= qty and "(+)" or "(-)"
            table.insert(costParts, mat:gsub("_"," ") .. " x" .. qty .. " " .. color)
        end
        love.graphics.setColor(0.7, 0.8, 0.7)
        love.graphics.print("Cost: " .. table.concat(costParts, "  "), panelX + 18, rowY + 38)
    end
end

-- Draw the day/night clock widget (top-right corner)
function UI.drawDayClock(dayCycle)
    local W       = love.graphics.getWidth()
    local phase   = dayCycle.phase
    local clock   = dayCycle.getClockString()
    local day     = dayCycle.day
    local frac    = dayCycle.fraction or 0

    -- Phase colors
    local phaseColors = {
        dawn  = { 0.95, 0.65, 0.30 },
        day   = { 0.98, 0.92, 0.50 },
        dusk  = { 0.80, 0.35, 0.15 },
        night = { 0.35, 0.40, 0.80 }
    }
    local col = phaseColors[phase] or { 1, 1, 1 }

    -- Background panel (top-right)
    local panelW, panelH = 160, 50
    local px = W - panelW - 10
    local py = 10

    love.graphics.setColor(0, 0, 0, 0.55)
    love.graphics.rectangle("fill", px, py, panelW, panelH, 6, 6)

    -- Phase label
    love.graphics.setColor(col[1], col[2], col[3])
    love.graphics.printf(string.upper(phase) .. "  Day " .. day, px, py + 6, panelW, "center")

    -- Clock
    love.graphics.setColor(1, 1, 1, 0.85)
    love.graphics.printf(clock, px, py + 24, panelW, "center")

    -- Thin cycle progress bar below
    love.graphics.setColor(0.15, 0.15, 0.15, 0.8)
    love.graphics.rectangle("fill", px + 6, py + panelH - 8, panelW - 12, 5, 2, 2)
    love.graphics.setColor(col[1], col[2], col[3], 0.9)
    love.graphics.rectangle("fill", px + 6, py + panelH - 8, (panelW - 12) * frac, 5, 2, 2)
end

-- Draw a red hit-flash overlay on the player when taking damage (iframes active)
function UI.drawPlayerFlash(player)
    if player.iframeTimer and player.iframeTimer > 0 then
        local alpha = (player.iframeTimer / player.IFRAME_DURATION) * 0.45
        love.graphics.setColor(0.95, 0.1, 0.1, alpha)
        love.graphics.rectangle("fill", player.x - 2, player.y - 2, player.size + 4, player.size + 4, 4, 4)
        love.graphics.setColor(1, 1, 1, 1)
    end
end

return UI

