-- FanIsle: Assets & Sprite Slicing Module
local Assets = {}

Assets.sheet = nil
Assets.tileset = nil
Assets.objects = nil
Assets.items = nil
Assets.quads = {}

function Assets.load()
    -- Load character spritesheet (PNG preferred, JPG chroma-key as fallback)
    local img = nil
    local ok, charImg = pcall(love.graphics.newImage, "assets/sprites/characters.png")
    if ok then
        img = charImg
    else
        -- Fallback to JPG and apply chroma keying
        local okJpg, imgData = pcall(love.image.newImageData, "assets/sprites/characters.jpg")
        if okJpg then
            imgData:mapPixel(function(x, y, r, g, b, a)
                if r > 0.8 and g < 0.2 and b > 0.8 then
                    return 0, 0, 0, 0
                else
                    return r, g, b, a
                end
            end)
            img = love.graphics.newImage(imgData)
        else
            print("Warning: Could not load characters spritesheet, drawing will fallback to basic primitives.")
        end
    end

    if img then
        img:setFilter("nearest", "nearest")
        Assets.sheet = img
        local imgW, imgH = img:getDimensions()
        
        -- Assume an 8x8 grid of sprites
        local cellW = imgW / 8
        local cellH = imgH / 8

        -- Slice player (row 1, 8 frames)
        -- Directions map sequentially to 8 columns:
        -- down: cols 1-2, up: cols 3-4, left: cols 5-6, right: cols 7-8
        Assets.quads.player = {}
        local directions = { "down", "up", "left", "right" }
        for i, dir in ipairs(directions) do
            Assets.quads.player[dir] = {
                love.graphics.newQuad((i - 1) * 2 * cellW, 0, cellW, cellH, imgW, imgH),
                love.graphics.newQuad(((i - 1) * 2 + 1) * cellW, 0, cellW, cellH, imgW, imgH)
            }
        end

        -- Slice goblin (row 2, 8 frames)
        Assets.quads.goblin = {}
        for i, dir in ipairs(directions) do
            Assets.quads.goblin[dir] = {
                love.graphics.newQuad((i - 1) * 2 * cellW, cellH, cellW, cellH, imgW, imgH),
                love.graphics.newQuad(((i - 1) * 2 + 1) * cellW, cellH, cellW, cellH, imgW, imgH)
            }
        end

        -- Slice enemies (row 3)
        -- cols 1-2: skeleton, cols 3-4: bat, cols 5-6: orc, cols 7-8: lich
        Assets.quads.skeleton = {
            love.graphics.newQuad(0, cellH * 2, cellW, cellH, imgW, imgH),
            love.graphics.newQuad(cellW, cellH * 2, cellW, cellH, imgW, imgH)
        }
        Assets.quads.bat = {
            love.graphics.newQuad(cellW * 2, cellH * 2, cellW, cellH, imgW, imgH),
            love.graphics.newQuad(cellW * 3, cellH * 2, cellW, cellH, imgW, imgH)
        }
        Assets.quads.orc = {
            love.graphics.newQuad(cellW * 4, cellH * 2, cellW, cellH, imgW, imgH),
            love.graphics.newQuad(cellW * 5, cellH * 2, cellW, cellH, imgW, imgH)
        }
        Assets.quads.lich = {
            love.graphics.newQuad(cellW * 6, cellH * 2, cellW, cellH, imgW, imgH),
            love.graphics.newQuad(cellW * 7, cellH * 2, cellW, cellH, imgW, imgH)
        }

        -- Slice new enemies & NPCs (row 4)
        Assets.quads.vampire = {
            love.graphics.newQuad(0, cellH * 3, cellW, cellH, imgW, imgH),
            love.graphics.newQuad(cellW, cellH * 3, cellW, cellH, imgW, imgH)
        }
        Assets.quads.golem = {
            love.graphics.newQuad(cellW * 2, cellH * 3, cellW, cellH, imgW, imgH),
            love.graphics.newQuad(cellW * 3, cellH * 3, cellW, cellH, imgW, imgH)
        }
        Assets.quads.npc_mira = {
            love.graphics.newQuad(cellW * 4, cellH * 3, cellW, cellH, imgW, imgH),
            love.graphics.newQuad(cellW * 5, cellH * 3, cellW, cellH, imgW, imgH)
        }
        Assets.quads.npc_healer = {
            love.graphics.newQuad(cellW * 6, cellH * 3, cellW, cellH, imgW, imgH),
            love.graphics.newQuad(cellW * 7, cellH * 3, cellW, cellH, imgW, imgH)
        }

        -- Slice Blacksmith NPC (row 5)
        Assets.quads.npc_blacksmith = {
            love.graphics.newQuad(0, cellH * 4, cellW, cellH, imgW, imgH),
            love.graphics.newQuad(cellW, cellH * 4, cellW, cellH, imgW, imgH)
        }
    end

    -- Load tileset
    local okT, tilesetImg = pcall(love.graphics.newImage, "assets/sprites/tileset.png")
    if okT then
        tilesetImg:setFilter("nearest", "nearest")
        Assets.tileset = tilesetImg
        Assets.quads.tiles = {
            forest = love.graphics.newQuad(0, 0, 32, 32, 128, 128),
            cave   = love.graphics.newQuad(32, 0, 32, 32, 128, 128),
            desert = love.graphics.newQuad(64, 0, 32, 32, 128, 128)
        }
    end

    -- Load objects
    local okO, objectsImg = pcall(love.graphics.newImage, "assets/sprites/objects.png")
    if okO then
        objectsImg:setFilter("nearest", "nearest")
        Assets.objects = objectsImg
        Assets.quads.objects = {
            tree          = love.graphics.newQuad(0, 0, 32, 32, 128, 128),
            stone         = love.graphics.newQuad(32, 0, 32, 32, 128, 128), -- Rock
            berry         = love.graphics.newQuad(64, 0, 32, 32, 128, 128), -- Shrub
            flint_cluster = love.graphics.newQuad(96, 0, 32, 32, 128, 128), -- Flint Vein

            campfire      = love.graphics.newQuad(0, 32, 32, 32, 128, 128),
            chest         = love.graphics.newQuad(32, 32, 32, 32, 128, 128),
            bed           = love.graphics.newQuad(64, 32, 32, 32, 128, 128),
            torch         = love.graphics.newQuad(96, 32, 32, 32, 128, 128),

            wall          = love.graphics.newQuad(0, 64, 32, 32, 128, 128), -- Wooden wall
            stone_wall    = love.graphics.newQuad(32, 64, 32, 32, 128, 128)
        }
    end

    -- Load items
    local okI, itemsImg = pcall(love.graphics.newImage, "assets/sprites/items.png")
    if okI then
        itemsImg:setFilter("nearest", "nearest")
        Assets.items = itemsImg
        Assets.quads.items = {
            wood           = love.graphics.newQuad(0, 0, 32, 32, 128, 128),
            stone          = love.graphics.newQuad(32, 0, 32, 32, 128, 128),
            flint          = love.graphics.newQuad(64, 0, 32, 32, 128, 128),
            berries        = love.graphics.newQuad(96, 0, 32, 32, 128, 128),
            cooked_berries = love.graphics.newQuad(0, 32, 32, 32, 128, 128)
        }
    end
end

-- Helper to get a Quad for drawing
-- characterType: "player", "goblin", "skeleton", "bat", "orc", "lich"
-- direction: "down", "up", "left", "right"
-- isMoving: boolean
-- animTimer: number
function Assets.getQuad(characterType, direction, isMoving, animTimer)
    if not Assets.sheet or not Assets.quads[characterType] then return nil end

    if characterType == "player" or characterType == "goblin" then
        local dirQuads = Assets.quads[characterType][direction or "down"]
        if not dirQuads then return nil end
        if isMoving then
            -- Alternate walk frames based on time
            local frameIdx = math.floor(animTimer * 5) % 2 + 1
            return dirQuads[frameIdx]
        else
            return dirQuads[1] -- Idle frame
        end
    else
        -- Enemies: simple 2-frame loop
        local list = Assets.quads[characterType]
        local frameIdx = math.floor(animTimer * 4) % 2 + 1
        return list[frameIdx]
    end
end

return Assets
