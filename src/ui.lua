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
    -- 1. Gather/layout inventory items to determine dynamic height
    local priorityOrder = { "wood", "stone", "flint", "berries", "cooked_berries", "wood_axe",
                             "campfire_blueprint", "chest_blueprint", "wall_blueprint" }
    local shown = {}
    local invItems = {}
    for _, item in ipairs(priorityOrder) do
        local count = player.inventory[item] or 0
        if count > 0 then
            table.insert(invItems, { name = item, count = count })
            shown[item] = true
        end
    end
    for item, count in pairs(player.inventory) do
        if count > 0 and not shown[item] then
            table.insert(invItems, { name = item, count = count })
        end
    end

    local invX, invY = 20, 115
    local maxW = 260
    local iconSize = 12
    local hasSprites = _Assets and _Assets.items and _Assets.quads and _Assets.quads.items

    local layout = {}
    local maxY = invY + 12
    if #invItems > 0 then
        local curX = invX + 30
        local curY = invY
        for _, entry in ipairs(invItems) do
            local quad = hasSprites and _Assets.quads.items[entry.name]
            local label = "x" .. entry.count
            local labelW = love.graphics.getFont():getWidth(label)
            local itemW = (quad and (iconSize + 2) or love.graphics.getFont():getWidth(entry.name:gsub("_", " ") .. " ")) + labelW + 8

            -- Wrap to next row if exceeding panel width
            if curX + itemW > invX + maxW then
                curX = invX + 30
                curY = curY + iconSize + 4
            end

            table.insert(layout, {
                entry = entry,
                quad = quad,
                label = label,
                x = curX,
                y = curY,
                w = itemW
            })
            curX = curX + itemW
            if curY + iconSize > maxY then
                maxY = curY + iconSize
            end
        end
    end

    -- Determine bottom y and total HUD height
    local hasAxe = (player.inventory.wood_axe or 0) > 0
    local toolY = maxY + 6
    local finalY = hasAxe and (toolY + 16) or (maxY + 10)
    local hudHeight = finalY - 10  -- because panel starts at y=10

    -- 2. Draw HUD panel background with dynamic height
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 10, 10, 280, hudHeight, 6, 6)
    
    -- 3. Draw Header & Status Bars (HP, Food, Stamina)
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

    -- 4. Draw Inventory Content
    if #invItems == 0 then
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.print("Inv: (Empty)", invX, invY)
    else
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.print("Inv:", invX, invY)
        for _, itemInfo in ipairs(layout) do
            if itemInfo.quad then
                -- Draw scaled 12x12 sprite icon from the 32x32 quad
                love.graphics.setColor(1, 1, 1)
                local scaleX = iconSize / 32
                local scaleY = iconSize / 32
                love.graphics.draw(_Assets.items, itemInfo.quad, itemInfo.x, itemInfo.y, 0, scaleX, scaleY)
                love.graphics.setColor(0.8, 0.8, 0.8)
                love.graphics.print(itemInfo.label, itemInfo.x + iconSize + 2, itemInfo.y)
            else
                -- Text fallback when no sprite is available
                love.graphics.setColor(0.8, 0.8, 0.8)
                love.graphics.print(itemInfo.entry.name:gsub("_", " ") .. " " .. itemInfo.label, itemInfo.x, itemInfo.y)
            end
        end
    end

    -- 5. Draw Tool indicator (if axe is equipped)
    if hasAxe then
        love.graphics.setColor(0.8, 0.6, 0.2)
        love.graphics.print("[Axe equipped - faster tree harvest]", 20, toolY)
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

-- Draw minimap radar (bottom-right corner)
function UI.drawMinimap(player, enemies, building, biome, camera)
    if not biome then return end

    local W, H       = love.graphics.getWidth(), love.graphics.getHeight()
    local mapW, mapH = 135, 100
    local px         = W - mapW - 10
    local py         = H - mapH - 10
    local WORLD_W    = camera and camera.WORLD_W or 2880
    local WORLD_H    = camera and camera.WORLD_H or 2160

    -- Panel background
    love.graphics.setColor(0, 0, 0, 0.65)
    love.graphics.rectangle("fill", px, py, mapW, mapH, 4, 4)
    love.graphics.setColor(0.4, 0.4, 0.5, 0.8)
    love.graphics.rectangle("line", px, py, mapW, mapH, 4, 4)

    -- Biome grid tiles (3x3)
    local tW = mapW / 3
    local tH = mapH / 3
    local grid = biome.getGrid()
    local mc   = biome.MINIMAP_COLOR

    for row = 1, 3 do
        for col = 1, 3 do
            local bt  = grid[row][col]
            local col3 = mc[bt] or {0.5, 0.5, 0.5}
            love.graphics.setColor(col3[1], col3[2], col3[3], 0.75)
            love.graphics.rectangle("fill",
                px + (col - 1) * tW,
                py + (row - 1) * tH,
                tW, tH)
        end
    end

    -- Zone grid lines
    love.graphics.setColor(0, 0, 0, 0.30)
    love.graphics.line(px + tW,     py, px + tW,     py + mapH)
    love.graphics.line(px + tW * 2, py, px + tW * 2, py + mapH)
    love.graphics.line(px, py + tH,     px + mapW, py + tH)
    love.graphics.line(px, py + tH * 2, px + mapW, py + tH * 2)

    -- Helper: world → minimap screen position
    local function toMap(wx, wy)
        return px + (wx / WORLD_W) * mapW,
               py + (wy / WORLD_H) * mapH
    end

    -- Structure dots (yellow)
    if building then
        love.graphics.setColor(0.95, 0.85, 0.25, 0.85)
        for _, s in ipairs(building.list) do
            local mx, my = toMap(s.x + s.w / 2, s.y + s.h / 2)
            love.graphics.circle("fill", mx, my, 2)
        end
    end

    -- Enemy dots (red)
    if enemies then
        love.graphics.setColor(0.90, 0.20, 0.20, 0.90)
        for _, e in ipairs(enemies.list or {}) do
            if e.state ~= "dead" then
                local mx, my = toMap(e.x, e.y)
                love.graphics.circle("fill", mx, my, 2)
            end
        end
    end

    -- Player dot (bright white with pulse ring)
    local mpx, mpy = toMap(player.x + player.size / 2, player.y + player.size / 2)
    love.graphics.setColor(0.3, 0.5, 1.0, 0.5)
    love.graphics.circle("line", mpx, mpy, 4)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.circle("fill", mpx, mpy, 2.5)

    -- Camera view rect
    if camera then
        local sw = love.graphics.getWidth()
        local sh = love.graphics.getHeight()
        local vrx = px + (camera.x / WORLD_W) * mapW
        local vry = py + (camera.y / WORLD_H) * mapH
        local vrw = (sw / WORLD_W) * mapW
        local vrh = (sh / WORLD_H) * mapH
        love.graphics.setColor(1, 1, 1, 0.25)
        love.graphics.rectangle("line", vrx, vry, vrw, vrh)
    end

    -- Label
    love.graphics.setColor(0.8, 0.8, 0.8, 0.7)
    love.graphics.print("MAP", px + 4, py + 2)
end

-- Draw NPC dialogue box at bottom of screen
function UI.drawDialogue(npc, line)
    if not npc or not line then return end
    local W, H  = love.graphics.getWidth(), love.graphics.getHeight()
    local bx    = 40
    local by    = H - 115
    local bw    = W - 80
    local bh    = 100

    -- Background panel
    love.graphics.setColor(0.08, 0.06, 0.12, 0.88)
    love.graphics.rectangle("fill", bx, by, bw, bh, 8, 8)
    love.graphics.setColor(0.70, 0.55, 0.80, 0.75)
    love.graphics.rectangle("line", bx, by, bw, bh, 8, 8)

    -- NPC name header
    love.graphics.setColor(0.95, 0.80, 0.55)
    love.graphics.print(npc.name .. ":", bx + 12, by + 10)

    -- Dialogue text (wrapped)
    love.graphics.setColor(0.92, 0.92, 0.88)
    love.graphics.printf(line, bx + 12, by + 30, bw - 24, "left")

    -- Hint
    love.graphics.setColor(0.55, 0.55, 0.60)
    love.graphics.print("[T] Next  [G] " .. (npc.tradeHint or "Trade") .. "  [ESC] Close", bx + 12, by + bh - 18)
end

-- Draw Lich warning banner when boss is alive
function UI.drawLichWarning(isLichAlive, dayCycle)
    if not isLichAlive then return end
    local W = love.graphics.getWidth()
    local pulse = math.abs(math.sin(love.timer.getTime() * 3))
    love.graphics.setColor(0.55, 0.05, 0.55, 0.35 + pulse * 0.30)
    love.graphics.rectangle("fill", 0, 48, W, 28)
    love.graphics.setColor(1, 0.50, 1, 0.85 + pulse * 0.15)
    love.graphics.printf("⚠  THE NIGHT LICH WALKS  ⚠", 0, 54, W, "center")
end

-- Draw the full-screen Victory screen
function UI.drawVictory(player, dayCycle)
    local W, H = love.graphics.getWidth(), love.graphics.getHeight()

    -- Deep dark background with slow golden shimmer
    local t = love.timer.getTime()
    love.graphics.setColor(0.04, 0.03, 0.08)
    love.graphics.rectangle("fill", 0, 0, W, H)

    -- Radiating golden rings
    for i = 1, 8 do
        local r     = (i / 8)
        local alpha = math.abs(math.sin(t * 0.8 + i)) * 0.18
        love.graphics.setColor(0.95, 0.80, 0.25, alpha)
        love.graphics.circle("line", W / 2, H / 2, r * W * 0.7)
    end

    -- Title glow backdrop
    local gPulse = 0.7 + math.abs(math.sin(t * 1.2)) * 0.3
    love.graphics.setColor(0.90, 0.70, 0.10, 0.18 * gPulse)
    love.graphics.rectangle("fill", W / 2 - 310, H / 2 - 115, 620, 80, 12, 12)

    -- Main title
    love.graphics.setColor(1.00, 0.88, 0.30, gPulse)
    love.graphics.printf("~ ISLAND SAVED ~", 0, H / 2 - 105, W, "center")

    -- Subtitle
    love.graphics.setColor(0.85, 0.95, 0.75, 0.9)
    love.graphics.printf("The Night Lich has been vanquished.", 0, H / 2 - 68, W, "center")
    love.graphics.printf("FanIsle breathes free once more.", 0, H / 2 - 48, W, "center")

    -- Divider
    love.graphics.setColor(0.75, 0.65, 0.25, 0.5)
    love.graphics.line(W / 2 - 200, H / 2 - 22, W / 2 + 200, H / 2 - 22)

    -- Stats panel
    local day  = dayCycle and dayCycle.day or 1
    local hp   = player and math.floor(player.health) or 0
    local maxhp = player and player.maxHealth or 100
    love.graphics.setColor(0.80, 0.80, 0.70, 0.85)
    love.graphics.printf("Survived to Day " .. day, 0, H / 2,      W, "center")
    love.graphics.printf("Health remaining: " .. hp .. " / " .. maxhp, 0, H / 2 + 24, W, "center")

    -- Divider
    love.graphics.setColor(0.75, 0.65, 0.25, 0.5)
    love.graphics.line(W / 2 - 200, H / 2 + 58, W / 2 + 200, H / 2 + 58)

    -- Restart prompt with blink
    local blink = math.floor(t * 2) % 2 == 0
    if blink then
        love.graphics.setColor(0.70, 0.90, 0.60, 0.9)
        love.graphics.printf("[ R ]  Play Again", 0, H / 2 + 74, W, "center")
    end

    -- Footer credit
    love.graphics.setColor(0.40, 0.40, 0.45, 0.6)
    love.graphics.printf("FanIsle  —  built with Love2D  —  by Xain", 0, H - 28, W, "center")
end

-- Render Diagnostic Debug Overlay
function UI.drawDebugInfo(player, goblins, resources, buildings, enemies, projectiles, biomeName)
    local W, H = love.graphics.getDimensions()
    local boxW, boxH = 260, 205
    local x = W - boxW - 10
    local y = 10

    love.graphics.setColor(0, 0, 0, 0.75)
    love.graphics.rectangle("fill", x, y, boxW, boxH, 6, 6)

    love.graphics.setColor(0.2, 0.8, 1.0)
    love.graphics.print("DIAGNOSTIC PANEL", x + 15, y + 15)

    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.line(x + 15, y + 32, x + boxW - 15, y + 32)

    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.print("FPS: " .. love.timer.getFPS(), x + 15, y + 42)
    love.graphics.print("RAM: " .. string.format("%.2f MB", collectgarbage("count") / 1024), x + 15, y + 57)

    local totalEnt = 1 + #goblins + #resources + #buildings + #enemies + #projectiles
    love.graphics.print("Entities: " .. totalEnt, x + 15, y + 77)
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("• Goblins: " .. #goblins, x + 25, y + 92)
    love.graphics.print("• Enemies: " .. #enemies, x + 25, y + 107)
    love.graphics.print("• Orbs: " .. #projectiles, x + 25, y + 122)
    love.graphics.print("• Map: " .. (#resources + #buildings), x + 25, y + 137)

    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.print("Pos: " .. math.floor(player.x) .. ", " .. math.floor(player.y), x + 15, y + 157)
    love.graphics.print("Biome: " .. string.upper(biomeName), x + 15, y + 175)
end

return UI

