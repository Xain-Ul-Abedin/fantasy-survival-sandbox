-- FanIsle: Main Game Coordination
local Player   = require("src.player")
local World    = require("src.world")
local Goblin   = require("src.goblin")
local UI       = require("src.ui")
local Save     = require("src.save")
local Crafting = require("src.crafting")
local Building = require("src.building")

-- Expose Building globally for player wall collision
_Building = Building

local gameState           = "menu"
local messageNotification = ""
local messageTimer        = 0

local function showMessage(msg, duration)
    messageNotification = msg
    messageTimer        = duration or 2.5
end

function love.load()
    World.spawnResources()
    Goblin.spawnGoblins()
    Building.list = {}
    print("Report. FanIsle loaded. Island world generated successfully.")
end

function love.keypressed(key)
    -- ──────────────────────────────────────────────
    --  MENU STATE
    -- ──────────────────────────────────────────────
    if gameState == "menu" then
        if key == "1" then
            UI.difficulty = "easy"
            UI.difficultyLabel = "Easy"
            gameState = "play"
        elseif key == "2" then
            UI.difficulty = "normal"
            UI.difficultyLabel = "Normal"
            gameState = "play"
        elseif key == "3" then
            UI.difficulty = "hard"
            UI.difficultyLabel = "Hard"
            gameState = "play"
        end
        return
    end

    -- ──────────────────────────────────────────────
    --  GAME OVER STATE
    -- ──────────────────────────────────────────────
    if gameState == "gameover" then
        if key == "r" then
            Player.reset()
            World.spawnResources()
            Goblin.spawnGoblins()
            Building.list = {}
            Crafting.isOpen = false
            gameState = "play"
        end
        return
    end

    -- ──────────────────────────────────────────────
    --  PLAY STATE
    -- ──────────────────────────────────────────────
    if gameState == "play" then
        -- ── Crafting Menu navigation (takes priority when open) ──
        if Crafting.isOpen then
            if key == "up" then
                Crafting.navigate("up")
            elseif key == "down" then
                Crafting.navigate("down")
            elseif key == "space" then
                local recipe, result = Crafting.craft(Player)
                if result == "success" then
                    showMessage("Crafted: " .. recipe.name .. "!", 2.5)
                elseif result:find("insufficient") then
                    local mat = result:gsub("insufficient_", "")
                    showMessage("Not enough " .. mat .. "!", 2.0)
                end
            elseif key == "c" then
                Crafting.toggle()
            end
            return -- All other keys consumed while crafting is open
        end

        -- ── Toggle crafting menu ──
        if key == "c" then
            Crafting.toggle()

        -- ── Harvest or Hammer (Space) ──
        elseif key == "space" then
            -- Try to hammer a nearby blueprint first
            local hammered = Building.hammer(Player, Goblin.list)
            if hammered then
                if hammered.completed then
                    showMessage("Structure built: " .. hammered.type .. "!", 2.5)
                else
                    showMessage("Hammering... " .. hammered.hammersLeft .. " hits left.", 1.5)
                end
            else
                -- Fall through to resource harvesting
                Player.harvest(World.resources, World.resourceTypes, Goblin.list)
            end

        -- ── Eat (E) ──
        elseif key == "e" then
            local ate, kind = Player.eat()
            if ate and kind == "cooked" then
                showMessage("Ate Cooked Berries! (+50 Food +25 HP)", 2.5)
            elseif ate and kind == "raw" then
                showMessage("Ate a raw berry. (+25 Food +10 HP)", 2.0)
            else
                showMessage("Nothing edible in inventory!", 2.0)
            end

        -- ── Goblin Interact (T) ──
        elseif key == "t" then
            local result = Goblin.interact(Player)
            if result == "tamed" then
                showMessage("Goblin recruited as a helper!", 3.0)
            elseif result == "need_berry" then
                showMessage("Need 1 berry to tame the goblin!", 2.5)
            elseif result == "cycled" then
                showMessage("Goblin command updated!", 2.0)
            else
                showMessage("No goblins nearby!", 1.8)
            end

        -- ── Place Blueprint (B) ──
        elseif key == "b" then
            -- Determine which blueprint the player has
            local bpTypes = { "wall", "campfire", "chest" }
            local placed = false
            for _, bpType in ipairs(bpTypes) do
                local key_inv = bpType .. "_blueprint"
                if (Player.inventory[key_inv] or 0) > 0 then
                    local ok, result = Building.placeBlueprint(Player, bpType)
                    if ok then
                        showMessage("Placed " .. bpType .. " blueprint. Hammer to build!", 2.5)
                    else
                        showMessage("Could not place " .. bpType .. ".", 2.0)
                    end
                    placed = true
                    break
                end
            end
            if not placed then
                showMessage("No blueprints in inventory! Craft one first.", 2.0)
            end

        -- ── Interact with structures (F) ──
        elseif key == "f" then
            local result = Building.interact(Player)
            if result == "campfire_start" then
                showMessage("Cooking berries! Ready in 2 seconds...", 2.5)
            elseif result == "campfire_busy" then
                showMessage("Campfire is already cooking!", 1.8)
            elseif result == "campfire_no_berries" then
                showMessage("Need at least 2 berries to cook!", 2.0)
            elseif result == "chest_opened" then
                showMessage("Chest opened.", 1.5)
            elseif result == "chest_closed" then
                showMessage("Chest closed.", 1.5)
            else
                showMessage("Nothing nearby to interact with.", 1.8)
            end

        -- ── Save (S) ──
        elseif key == "s" then
            local ok = Save.game(Player, World, Goblin, UI, Building)
            showMessage(ok and "Game saved!" or "Save failed!", 2.0)

        -- ── Load (L) ──
        elseif key == "l" then
            local ok = Save.load(Player, World, Goblin, UI, Building)
            showMessage(ok and "Game loaded!" or "No save file found!", 2.0)
        end
    end
end

function love.update(dt)
    if gameState ~= "play" then return end

    -- Update player stats and movement
    Player.update(dt, UI.difficulty)

    -- Update world drops and item pickups
    World.updateDrops(dt, Player)

    -- Update goblin AI
    Goblin.update(dt, Player, World.resources, World.resourceTypes)

    -- Update building campfire timers
    Building.update(dt, Player)

    -- Drain message timer
    if messageTimer > 0 then
        messageTimer = messageTimer - dt
    end

    -- Death check
    if Player.health <= 0 then
        gameState = "gameover"
    end
end

function love.draw()
    if gameState == "menu" then
        UI.drawMenu()
        return
    end

    if gameState == "gameover" then
        UI.drawGameOver()
        return
    end

    -- Gameplay canvas
    love.graphics.clear(0.22, 0.35, 0.22)

    -- World layer
    World.draw()
    Building.draw()
    Goblin.draw()
    Player.draw()

    -- HUD overlay
    UI.drawHUD(Player)

    -- Crafting menu overlay (drawn on top of everything)
    UI.drawCraftingMenu(Crafting, Player)

    -- Floating notification banner
    if messageTimer > 0 then
        local W = love.graphics.getWidth()
        love.graphics.setColor(0, 0, 0, 0.65)
        love.graphics.rectangle("fill", W / 2 - 200, 18, 400, 30, 5, 5)
        love.graphics.setColor(0.9, 0.8, 0.4)
        love.graphics.printf(messageNotification, 0, 26, W, "center")
    end
end
