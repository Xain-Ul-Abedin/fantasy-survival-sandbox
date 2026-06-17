-- FanIsle: Main Game Coordination
local Player = require("src.player")
local World = require("src.world")
local Goblin = require("src.goblin")
local UI = require("src.ui")
local Save = require("src.save")

local gameState = "menu" -- Options: "menu", "play", "gameover"
local messageNotification = ""
local messageTimer = 0

function love.load()
    World.spawnResources()
    Goblin.spawnGoblins()
    print("Report. Game components loaded. Island world generated successfully.")
end

function love.keypressed(key)
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
    elseif gameState == "gameover" then
        if key == "r" then
            Player.reset()
            World.spawnResources()
            Goblin.spawnGoblins()
            gameState = "play"
        end
    elseif gameState == "play" then
        if key == "space" then
            Player.harvest(World.resources, World.resourceTypes, Goblin.list)
        elseif key == "e" then
            local ate = Player.eat()
            if ate then
                messageNotification = "Ate a delicious berry!"
                messageTimer = 2.0
            else
                messageNotification = "No berries in inventory!"
                messageTimer = 2.0
            end
        elseif key == "t" then
            local result = Goblin.interact(Player)
            if result == "tamed" then
                messageNotification = "Tamed a Goblin helper!"
                messageTimer = 3.0
            elseif result == "need_berry" then
                messageNotification = "Need 1 berry to tame!"
                messageTimer = 3.0
            elseif result == "cycled" then
                messageNotification = "Cycled Goblin command!"
                messageTimer = 2.0
            else
                messageNotification = "No Goblins nearby!"
                messageTimer = 2.0
            end
        elseif key == "s" then
            local success = Save.game(Player, World, Goblin, UI)
            if success then
                messageNotification = "Game saved successfully!"
                messageTimer = 2.0
            else
                messageNotification = "Failed to save game!"
                messageTimer = 2.0
            end
        elseif key == "l" then
            local success = Save.load(Player, World, Goblin, UI)
            if success then
                messageNotification = "Game loaded successfully!"
                messageTimer = 2.0
            else
                messageNotification = "No save file found!"
                messageTimer = 2.0
            end
        end
    end
end

function love.update(dt)
    if gameState == "play" then
        -- 1. Update Player mechanics
        Player.update(dt, UI.difficulty)
        
        -- 2. Update resource drops and pickups
        World.updateDrops(dt, Player)
        
        -- 3. Update Goblins AI state machine
        Goblin.update(dt, Player, World.resources, World.resourceTypes)
        
        -- 4. Check death state
        if Player.health <= 0 then
            gameState = "gameover"
        end
        
        -- Update message notifications
        if messageTimer > 0 then
            messageTimer = messageTimer - dt
        end
    end
end

function love.draw()
    if gameState == "menu" then
        UI.drawMenu()
    elseif gameState == "gameover" then
        UI.drawGameOver()
    elseif gameState == "play" then
        -- Clear with field green grass
        love.graphics.clear(0.22, 0.35, 0.22)
        
        -- Draw modules
        World.draw()
        Goblin.draw()
        Player.draw()
        UI.drawHUD(Player)
        
        -- Draw floating message notification
        if messageTimer > 0 then
            love.graphics.setColor(0, 0, 0, 0.6)
            love.graphics.rectangle("fill", love.graphics.getWidth() / 2 - 150, 20, 300, 35, 5, 5)
            love.graphics.setColor(0.9, 0.8, 0.4)
            love.graphics.printf(messageNotification, 0, 30, love.graphics.getWidth(), "center")
        end
    end
end
