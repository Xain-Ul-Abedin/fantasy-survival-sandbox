-- FanIsle v1.0  —  Main Game Coordination (Phase 7 — Victory, Polish & Packaging)
local Player   = require("src.player")
local World    = require("src.world")
local Goblin   = require("src.goblin")
local UI       = require("src.ui")
local Save     = require("src.save")
local Crafting = require("src.crafting")
local Building = require("src.building")
local Enemy    = require("src.enemy")
local Combat   = require("src.combat")
local DayCycle = require("src.daycycle")
local Camera   = require("src.camera")
local Biome    = require("src.biome")
local Sound    = require("src.sound")
local NPC      = require("src.npc")

-- Expose globals for cross-module access
_Building = Building
_World    = World
_Camera   = Camera

local VERSION             = "v1.0"
local gameState           = "menu"
local messageNotification = ""
local messageTimer        = 0
local bossWaveTriggered   = false
local showDebugInfo       = false


local function showMessage(msg, duration)
    messageNotification = msg
    messageTimer        = duration or 2.5
end

local function fullReset()
    Player.reset()
    World.spawnResources()
    Goblin.spawnGoblins()
    NPC.spawn()
    Building.list      = {}
    Enemy.list         = {}
    Enemy.projectiles  = {}
    Enemy.lichDefeated = false
    Crafting.isOpen    = false
    DayCycle.elapsed   = 0
    DayCycle.day       = 1
    DayCycle.nightWaveSpawned = false
    Combat.damageFeed  = {}
    bossWaveTriggered  = false
    Camera.x = math.max(0, math.min(Player.x - love.graphics.getWidth()  / 2, Camera.WORLD_W - love.graphics.getWidth()))
    Camera.y = math.max(0, math.min(Player.y - love.graphics.getHeight() / 2, Camera.WORLD_H - love.graphics.getHeight()))
end

function love.load()
    love.window.setTitle("FanIsle " .. VERSION)
    Sound.load()
    World.spawnResources()
    Goblin.spawnGoblins()
    NPC.spawn()
    Building.list     = {}
    Enemy.list        = {}
    Enemy.projectiles = {}

    -- World-space starter enemies (biome-correct)
    Enemy.spawn("skeleton", 1100, 350)
    Enemy.spawn("skeleton", 1900, 1500)
    Enemy.spawn("bat",       500,  900)
    Enemy.spawn("orc",      2400,  750)

    Camera.x = math.max(0, math.min(Player.x - love.graphics.getWidth()  / 2, Camera.WORLD_W - love.graphics.getWidth()))
    Camera.y = math.max(0, math.min(Player.y - love.graphics.getHeight() / 2, Camera.WORLD_H - love.graphics.getHeight()))

    print("Report. FanIsle " .. VERSION .. " loaded. All 7 phases active.")
end

function love.keypressed(key)
    -- F3 toggles diagnostic debug overlay
    if key == "f3" then
        showDebugInfo = not showDebugInfo
        return
    end

    -- ESC closes NPC dialogue globally
    if key == "escape" then NPC.closeDialogue(); return end


    -- NPC Trade (G) — available in play state
    if key == "g" and gameState == "play" then
        if NPC.anyOpen() then
            local result, _ = NPC.trade(Player)
            if result == "traded" then
                showMessage("Traded! Received 2 Cooked Berries.", 2.5)
                Sound.play("craft")
            elseif result == "insufficient" then
                showMessage("You need 5 wood to trade!", 2.0)
            end
        end
        return
    end

    -- ── MENU ──
    if gameState == "menu" then
        if     key == "1" then UI.difficulty = "easy";   UI.difficultyLabel = "Easy";   gameState = "play"
        elseif key == "2" then UI.difficulty = "normal"; UI.difficultyLabel = "Normal"; gameState = "play"
        elseif key == "3" then UI.difficulty = "hard";   UI.difficultyLabel = "Hard";   gameState = "play"
        end
        return
    end

    -- ── GAME OVER ──
    if gameState == "gameover" then
        if key == "r" then fullReset(); gameState = "play" end
        return
    end

    -- ── VICTORY ──
    if gameState == "victory" then
        if key == "r" then fullReset(); gameState = "play" end
        return
    end

    -- ── PLAY ──
    if gameState == "play" then

        -- Crafting intercepts all keys when open
        if Crafting.isOpen then
            if     key == "up"    then Crafting.navigate("up")
            elseif key == "down"  then Crafting.navigate("down")
            elseif key == "space" then
                local recipe, result = Crafting.craft(Player)
                if result == "success" then
                    showMessage("Crafted: " .. recipe.name .. "!", 2.5)
                    Sound.play("craft")
                elseif result and result:find("insufficient") then
                    showMessage("Not enough " .. result:gsub("insufficient_",""):gsub("_"," ") .. "!", 2.0)
                end
            elseif key == "c" then Crafting.toggle()
            end
            return
        end

        if key == "c" then
            Crafting.toggle()

        elseif key == "t" then
            local npcResult, npc = NPC.interact(Player, key)
            if npcResult then
                if npcResult == "open"  then showMessage("Speaking with " .. npc.name .. "...", 2.0)
                elseif npcResult == "close" then showMessage("Farewell!", 1.5)
                end
            else
                local result = Goblin.interact(Player)
                if result == "tamed"          then showMessage("Goblin recruited!", 3.0)
                elseif result == "need_berry" then showMessage("Need 1 berry to tame!", 2.5)
                elseif result == "cycled"     then showMessage("Goblin command updated!", 2.0)
                else showMessage("No goblins nearby!", 1.8)
                end
            end

        elseif key == "space" then
            local hammered = Building.hammer(Player, Goblin.list)
            if hammered then
                showMessage(hammered.completed
                    and "Structure built: " .. hammered.type .. "!"
                    or  "Hammering... " .. hammered.hammersLeft .. " hits left.", 2.0)
                if hammered.completed then Sound.play("build") end
            else
                local wName, dmg = Combat.swing(Player, Enemy)
                Player.harvest(World.resources, World.resourceTypes, Goblin.list)
                if wName then
                    showMessage(wName:gsub("_"," ") .. " attack! (" .. dmg .. " dmg)", 1.5)
                    Sound.play("hit_enemy")
                else
                    Sound.play("harvest")
                end
            end

        elseif key == "e" then
            local ate, kind = Player.eat()
            if ate and kind == "cooked" then showMessage("Ate Cooked Berries! (+50 Food +25 HP)", 2.5)
            elseif ate                  then showMessage("Ate a raw berry. (+25 Food +10 HP)", 2.0)
            else                             showMessage("Nothing edible!", 2.0)
            end
            if ate then Sound.play("eat") end

        elseif key == "f" then
            local result = Building.interact(Player)
            if     result == "campfire_start"     then showMessage("Cooking berries! 2 seconds...", 2.5)
            elseif result == "campfire_busy"      then showMessage("Campfire already cooking!", 1.8)
            elseif result == "campfire_no_berries"then showMessage("Need 2 berries to cook!", 2.0)
            elseif result == "chest_opened"       then showMessage("Chest opened.", 1.5)
            elseif result == "chest_closed"       then showMessage("Chest closed.", 1.5)
            elseif result == "bed_sleep" then
                if DayCycle.phase == "night" or DayCycle.phase == "dusk" then
                    DayCycle.elapsed = 0
                    DayCycle.day     = DayCycle.day + 1
                    DayCycle.nightWaveSpawned = false
                    bossWaveTriggered = false
                    showMessage("You rest... Dawn breaks on Day " .. DayCycle.day .. ".", 3.5)
                    Sound.play("night_bell")
                else
                    showMessage("You can only sleep at night.", 2.0)
                end
            else
                showMessage("Nothing nearby to interact with.", 1.8)
            end

        elseif key == "b" then
            local bpTypes = { "torch", "bed", "stone_wall", "wall", "campfire", "chest" }
            local placed  = false
            for _, bpType in ipairs(bpTypes) do
                if (Player.inventory[bpType .. "_blueprint"] or 0) > 0 then
                    local ok = Building.placeBlueprint(Player, bpType)
                    showMessage(ok
                        and "Placed " .. bpType:gsub("_"," ") .. " blueprint!"
                        or  "Could not place " .. bpType .. ".", 2.0)
                    placed = true
                    break
                end
            end
            if not placed then showMessage("No blueprints! Craft one first (C).", 2.0) end

        elseif key == "s" then
            local ok = Save.game(Player, World, Goblin, UI, Building, Enemy, DayCycle)
            showMessage(ok and "Game saved!" or "Save failed!", 2.0)

        elseif key == "l" then
            local ok = Save.load(Player, World, Goblin, UI, Building, Enemy, DayCycle)
            showMessage(ok and "Game loaded!" or "No save file found!", 2.0)
        end
    end
end

function love.update(dt)
    if gameState ~= "play" then return end

    local W, H = love.graphics.getDimensions()

    Player.update(dt, UI.difficulty)
    Camera.update(dt, Player)
    World.updateDrops(dt, Player)
    Goblin.update(dt, Player, World.resources, World.resourceTypes)
    Building.update(dt, Player)
    Enemy.update(dt, Player, World, Combat.damageFeed)
    Combat.update(dt)

    local event, waveSize = DayCycle.update(dt, Enemy, W, H)
    if event == "night_wave" then
        if DayCycle.day >= 7 and not bossWaveTriggered then
            bossWaveTriggered = true
            Enemy.spawnBossWave()
            showMessage("THE NIGHT LICH HAS RISEN! Day " .. DayCycle.day .. " — survive!", 5.0)
            Sound.play("boss_roar")
        else
            showMessage("Night falls! " .. (waveSize or 0) .. " enemies approach!", 4.0)
            Sound.play("night_bell")
        end
    end

    if DayCycle.phase == "dawn" then bossWaveTriggered = false end

    -- ── VICTORY CHECK ──
    if Enemy.lichDefeated then
        gameState = "victory"
        Sound.play("night_bell")
        Enemy.lichDefeated = false  -- consumed
    end

    if messageTimer > 0 then messageTimer = messageTimer - dt end
    if Player.health <= 0 then gameState = "gameover" end
end

function love.draw()
    local W, H = love.graphics.getDimensions()

    if gameState == "menu"    then UI.drawMenu();    return end
    if gameState == "gameover"then UI.drawGameOver(); return end
    if gameState == "victory" then UI.drawVictory(Player, DayCycle); return end

    -- ── WORLD LAYER (camera-space) ──
    Camera.attach()
        Biome.draw()
        World.draw()
        Building.draw()
        NPC.draw()
        Goblin.draw()
        Enemy.draw()
        Enemy.drawProjectiles()
        Player.draw()
        UI.drawPlayerFlash(Player)
    Camera.detach()

    -- ── OVERLAYS (screen-space) ──
    if DayCycle.phase == "night" or DayCycle.phase == "dusk" then
        Camera.attach()
        local nightAlpha = DayCycle.phase == "night" and 0.68 or 0.22
        Building.drawTorchGlow(nightAlpha)
        Camera.detach()
    end
    DayCycle.drawOverlay(W, H)
    Combat.draw()

    -- HUD
    UI.drawHUD(Player)
    UI.drawDayClock(DayCycle)
    UI.drawMinimap(Player, Enemy, Building, Biome, Camera)
    UI.drawLichWarning(Enemy.isLichAlive(), DayCycle)

    -- NPC dialogue (hides crafting when open)
    local activeNPC = NPC.anyOpen()
    if activeNPC then
        UI.drawDialogue(activeNPC, NPC.getDialogueLine(activeNPC))
    else
        UI.drawCraftingMenu(Crafting, Player)
    end

    -- Notification banner
    if messageTimer > 0 then
        love.graphics.setColor(0, 0, 0, 0.65)
        love.graphics.rectangle("fill", W / 2 - 260, 18, 520, 30, 5, 5)
        love.graphics.setColor(0.9, 0.8, 0.4)
        love.graphics.printf(messageNotification, 0, 26, W, "center")
    end

    -- Biome zone indicator + version tag
    local currentBiome = Biome.getAt(Player.x, Player.y)
    love.graphics.setColor(0, 0, 0, 0.45)
    love.graphics.rectangle("fill", W / 2 - 60, H - 30, 120, 20, 4, 4)
    love.graphics.setColor(0.85, 0.85, 0.85)
    love.graphics.printf(string.upper(currentBiome) .. " ZONE", 0, H - 27, W, "center")
    love.graphics.setColor(0.35, 0.35, 0.40, 0.7)
    love.graphics.print("FanIsle " .. VERSION, 4, H - 18)

    -- Debug Diagnostic Overlay
    if showDebugInfo and gameState == "play" then
        UI.drawDebugInfo(Player, Goblin.list, World.resources, Building.list, Enemy.list, Enemy.projectiles, currentBiome)
    end
end

