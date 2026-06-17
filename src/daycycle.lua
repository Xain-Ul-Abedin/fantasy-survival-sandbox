-- FanIsle: Day/Night Cycle Module
-- Full day = CYCLE_DURATION seconds. Phases: dawn, day, dusk, night.
local DayCycle = {}

DayCycle.CYCLE_DURATION = 180   -- 3 minutes per full day

DayCycle.elapsed     = 0        -- Seconds elapsed within current day
DayCycle.day         = 1        -- Day counter
DayCycle.phase       = "dawn"   -- Current phase label
DayCycle.nightWaveSpawned = false

-- Phase thresholds as fraction of CYCLE_DURATION
local PHASE_THRESHOLDS = {
    dawn  = 0.0,
    day   = 0.12,  -- 12% through = fully day
    dusk  = 0.72,  -- 72% = dusk starts
    night = 0.85   -- 85% = night
}

-- Phase ambient overlay color { r, g, b, a }
local PHASE_OVERLAY = {
    dawn  = { 0.95, 0.60, 0.30, 0.18 },   -- warm orange blush
    day   = { 0.0,  0.0,  0.0,  0.0  },   -- no overlay
    dusk  = { 0.55, 0.20, 0.05, 0.22 },   -- red-orange haze
    night = { 0.02, 0.02, 0.10, 0.68 }    -- deep dark blue vignette
}

-- Determine current phase string from elapsed fraction
local function calcPhase(frac)
    if frac >= PHASE_THRESHOLDS.night then return "night"
    elseif frac >= PHASE_THRESHOLDS.dusk then return "dusk"
    elseif frac >= PHASE_THRESHOLDS.day  then return "day"
    else return "dawn"
    end
end

-- Update the cycle. Returns "night_wave" event when night starts for the first time each cycle.
function DayCycle.update(dt, enemy, W, H)
    DayCycle.elapsed = DayCycle.elapsed + dt

    if DayCycle.elapsed >= DayCycle.CYCLE_DURATION then
        DayCycle.elapsed = DayCycle.elapsed - DayCycle.CYCLE_DURATION
        DayCycle.day     = DayCycle.day + 1
        DayCycle.nightWaveSpawned = false
    end

    local frac        = DayCycle.elapsed / DayCycle.CYCLE_DURATION
    local prevPhase   = DayCycle.phase
    DayCycle.phase    = calcPhase(frac)
    DayCycle.fraction = frac

    -- Trigger a night enemy wave once per night
    if DayCycle.phase == "night" and not DayCycle.nightWaveSpawned and enemy then
        DayCycle.nightWaveSpawned = true
        local waveSize = math.random(3, 5)
        enemy.spawnWave(waveSize, W, H)
        return "night_wave", waveSize
    end

    return nil
end

-- Draw the ambient overlay (call AFTER the world is drawn, BEFORE UI)
function DayCycle.drawOverlay(W, H)
    local ov = PHASE_OVERLAY[DayCycle.phase]
    if not ov or ov[4] == 0 then return end

    if DayCycle.phase == "night" then
        -- Radial vignette: darkest at edges, lighter in center
        local cx, cy = W / 2, H / 2
        local steps  = 12
        for i = steps, 1, -1 do
            local frac  = i / steps
            local r     = math.max(W, H) * frac
            local alpha = ov[4] * (frac * 0.85)
            love.graphics.setColor(ov[1], ov[2], ov[3], alpha)
            love.graphics.circle("fill", cx, cy, r)
        end
    else
        -- Flat tint overlay
        love.graphics.setColor(ov[1], ov[2], ov[3], ov[4])
        love.graphics.rectangle("fill", 0, 0, W, H)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

-- Returns a human-readable clock string (e.g. "06:00" for dawn start)
function DayCycle.getClockString()
    -- Map fraction 0-1 to 24 hours, dawn starts at 05:00
    local startHour = 5
    local frac = DayCycle.elapsed / DayCycle.CYCLE_DURATION
    local totalMinutes = math.floor((frac * 24 * 60) + startHour * 60) % (24 * 60)
    local h = math.floor(totalMinutes / 60)
    local m = totalMinutes % 60
    return string.format("%02d:%02d", h, m)
end

return DayCycle
