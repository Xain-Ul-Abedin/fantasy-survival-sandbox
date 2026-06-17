-- FanIsle: Combat Module
-- Manages player melee swings, hit detection, weapon damage, and floating damage numbers
local Combat = {}

-- Damage numbers floating on screen
Combat.damageFeed = {}

-- Cooldown state for player attack
Combat.swingCooldown = 0
Combat.SWING_COOLDOWN = 0.45   -- Seconds between player swings

-- Weapon damage lookup
local WEAPON_DAMAGE = {
    fist     = 5,
    wood_axe = 15,
    -- future weapons can be added here
}

-- Determine the player's active weapon and its damage
local function getWeaponDamage(player)
    if (player.inventory.wood_axe or 0) > 0 then
        return "wood_axe", WEAPON_DAMAGE.wood_axe
    end
    return "fist", WEAPON_DAMAGE.fist
end

-- Called every frame to update floating text timers
function Combat.update(dt)
    Combat.swingCooldown = math.max(0, Combat.swingCooldown - dt)
    for i = #Combat.damageFeed, 1, -1 do
        local d = Combat.damageFeed[i]
        d.timer = d.timer - dt
        d.y     = d.y - 28 * dt   -- Float upward
        if d.timer <= 0 then
            table.remove(Combat.damageFeed, i)
        end
    end
end

-- Execute a melee swing from the player toward their facing direction
-- Returns: weaponName, damage, hitX, hitY  (or nil if on cooldown)
function Combat.swing(player, enemies)
    if Combat.swingCooldown > 0 then return nil end
    Combat.swingCooldown = Combat.SWING_COOLDOWN

    local weaponName, damage = getWeaponDamage(player)
    local reach = 48
    local px = player.x + player.size / 2
    local py = player.y + player.size / 2
    local hitX, hitY = px, py

    if player.direction == "left"  then hitX = px - reach
    elseif player.direction == "right" then hitX = px + reach
    elseif player.direction == "up"    then hitY = py - reach
    elseif player.direction == "down"  then hitY = py + reach
    end

    -- Strike all enemies in radius around hit point
    enemies.strikeInRange(hitX, hitY, reach * 0.75, damage, Combat.damageFeed)

    return weaponName, damage, hitX, hitY
end

-- Draw all floating damage numbers
function Combat.draw()
    for _, d in ipairs(Combat.damageFeed) do
        local alpha = math.min(1, d.timer)
        love.graphics.setColor(d.color[1], d.color[2], d.color[3], alpha)
        love.graphics.print(d.text, d.x, d.y)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

return Combat
