-- FanIsle: Camera Module
-- Smooth-follow camera clamped to the full world boundaries.
local Camera = {}

-- World dimensions (3x3 screen grid at 960x720 each)
Camera.WORLD_W = 2880
Camera.WORLD_H = 2160

Camera.x = 0   -- Top-left corner of camera view in world space
Camera.y = 0

local LERP_SPEED = 6.0  -- Camera smoothing factor (higher = snappier)

-- Call every frame before drawing the world
function Camera.update(dt, player)
    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()

    -- Target: center the camera on the player
    local targetX = (player.x + player.size / 2) - sw / 2
    local targetY = (player.y + player.size / 2) - sh / 2

    -- Smooth lerp toward target
    Camera.x = Camera.x + (targetX - Camera.x) * LERP_SPEED * dt
    Camera.y = Camera.y + (targetY - Camera.y) * LERP_SPEED * dt

    -- Clamp so camera never shows outside world bounds
    Camera.x = math.max(0, math.min(Camera.x, Camera.WORLD_W - sw))
    Camera.y = math.max(0, math.min(Camera.y, Camera.WORLD_H - sh))
end

-- Apply camera transform (call before drawing world objects)
function Camera.attach()
    love.graphics.push()
    love.graphics.translate(-math.floor(Camera.x), -math.floor(Camera.y))
end

-- Remove camera transform (call after drawing world objects, before HUD)
function Camera.detach()
    love.graphics.pop()
end

-- Convert screen coordinates to world coordinates
function Camera.toWorld(sx, sy)
    return sx + Camera.x, sy + Camera.y
end

-- Convert world coordinates to screen coordinates
function Camera.toScreen(wx, wy)
    return wx - Camera.x, wy - Camera.y
end

-- Check if a world-space rect is visible on screen (culling helper)
function Camera.isVisible(wx, wy, w, h)
    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()
    return wx + w > Camera.x and wx < Camera.x + sw and
           wy + h > Camera.y and wy < Camera.y + sh
end

return Camera
