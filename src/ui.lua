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
    love.graphics.printf("Controls: WASD/Arrows to Move | LShift to Sprint | Space to Harvest | E to Eat", 0, 560, love.graphics.getWidth(), "center")
    love.graphics.printf("Press [S] to Save | [L] to Load Persistence", 0, 590, love.graphics.getWidth(), "center")
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
    love.graphics.rectangle("fill", 10, 10, 280, 140, 6, 6)
    
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
    local invText = "Inv: "
    local idx = 1
    for item, count in pairs(player.inventory) do
        if count > 0 then
            invText = invText .. item .. "x" .. count .. " | "
            idx = idx + 1
        end
    end
    if invText == "Inv: " then invText = "Inv: (Empty)" end
    love.graphics.print(invText, 20, 115)
end

return UI
