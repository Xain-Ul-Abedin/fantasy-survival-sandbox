-- FanIsle: Music Module (Procedural Synth Sequencer — no external files needed)
-- Zero runtime memory allocation, pre-allocates voice pools, and uses setPitch for scaling.
local Music = {}

local Sound = require("src.sound")
local DayCycle = require("src.daycycle")

-- Configuration
local RATE = 22050
local poolSize = 8

-- Voice pools
local dayPool = {}
local nightPool = {}

-- State variables
Music.enabled = true
Music.tempo = 90
Music.timer = 0
Music.beatTimer = 0
Music.beatCount = 0
Music.volume = 0.55        -- Master music volume (scaled by Sound.volume)
Music.targetVolume = 0.55  -- For transitions (e.g. menu, victory)

local dayVolume = 1.0     -- Fades 0 -> 1 depending on phase
local nightVolume = 0.0   -- Fades 0 -> 1 depending on phase

-- Waveform generators (executed only at load time)
local function clamp(v) return math.max(-1, math.min(1, v)) end

-- Base note for Day: sine/triangle blend (C4 = 261.63 Hz)
local function makeDayWave(freq, dur)
    local n = math.floor(RATE * dur)
    local sd = love.sound.newSoundData(n, RATE, 16, 1)
    for i = 0, n - 1 do
        local t = i / RATE
        local env = 1
        if t < 0.05 then
            env = t / 0.05
        else
            env = math.exp(-(t - 0.05) * 2.5)
        end
        local sinVal = math.sin(2 * math.pi * freq * t)
        local triVal = 2 * math.abs(2 * ((freq * t) % 1) - 1) - 1
        local sample = (sinVal * 0.70 + triVal * 0.30) * env * 0.40
        sd:setSample(i, clamp(sample))
    end
    return love.audio.newSource(sd)
end

-- Base note for Night: sawtooth/square blend (C3 = 130.81 Hz)
local function makeNightWave(freq, dur)
    local n = math.floor(RATE * dur)
    local sd = love.sound.newSoundData(n, RATE, 16, 1)
    for i = 0, n - 1 do
        local t = i / RATE
        local env = 1
        if t < 0.01 then
            env = t / 0.01
        else
            env = math.exp(-(t - 0.01) * 4.5)
        end
        local sawVal = 2 * ((freq * t) % 1) - 1
        local sqVal = math.sin(2 * math.pi * freq * t) >= 0 and 1 or -1
        local sample = (sawVal * 0.30 + sqVal * 0.70) * env * 0.30
        sd:setSample(i, clamp(sample))
    end
    return love.audio.newSource(sd)
end

-- Populate voice pools
function Music.load()
    if not Sound or not Sound.enabled then
        Music.enabled = false
        return
    end

    local ok, err = pcall(function()
        local baseDay = makeDayWave(261.63, 2.0) -- C4
        local baseNight = makeNightWave(130.81, 1.2) -- C3

        for i = 1, poolSize do
            dayPool[i] = baseDay:clone()
            nightPool[i] = baseNight:clone()
        end
    end)

    if not ok then
        print("Music.load error: " .. tostring(err) .. " — music disabled.")
        Music.enabled = false
    end
end

-- Note player
local function playNote(pool, semitone, vol)
    if not Music.enabled or not Sound or not Sound.enabled then return end
    
    -- Find idle voice
    local src = nil
    for i = 1, poolSize do
        if not pool[i]:isPlaying() then
            src = pool[i]
            break
        end
    end

    -- Voice stealing (overwrite first if all busy)
    if not src then
        src = pool[1]
        src:stop()
    end

    local pitch = 2 ^ (semitone / 12)
    src:setPitch(pitch)
    src:setVolume(vol * Music.volume * Sound.volume)
    src:play()
end

-- Musical scales (semitone offsets)
-- Day scale: C major pentatonic (C4 root)
local DAY_MELODY_SCALE = { 0, 2, 4, 7, 9, 12, 14, 16, 19, 21 }

-- Night scale: Dissonant, tense minor (C3 root)
local NIGHT_MELODY_SCALE = { 1, 6, 7, 8, 13, 18, 19 } -- Db, F#, G, Ab (tritones/seconds)

-- Day chords (base semitone arrays)
local DAY_CHORDS = {
    [1] = { -12, -5, 0, 7 },   -- C Major
    [5] = { -17, -10, -5, 2 },  -- G Major
    [9] = { -15, -8, -3, 4 },   -- A Minor
    [13] = { -19, -12, -7, 0 }  -- F Major
}

-- Sequencer beat trigger
local function triggerBeat(gameState, phase)
    Music.beatCount = Music.beatCount + 1
    if Music.beatCount > 16 then
        Music.beatCount = 1
    end

    if gameState == "menu" or phase == "dawn" or phase == "day" then
        -- ── DAY SEQUENCER ──
        -- Chord pad change on beat 1, 5, 9, 13
        local chord = DAY_CHORDS[Music.beatCount]
        if chord then
            for i = 1, #chord do
                -- Play chord notes softly
                playNote(dayPool, chord[i], 0.22 * dayVolume)
            end
        end

        -- Melodic chimes on other beats
        if Music.beatCount ~= 1 and Music.beatCount ~= 5 and Music.beatCount ~= 9 and Music.beatCount ~= 13 then
            -- Random chance to play a melody note (e.g. 50% chance)
            if math.random() < 0.50 then
                local idx = math.random(1, #DAY_MELODY_SCALE)
                local note = DAY_MELODY_SCALE[idx]
                playNote(dayPool, note, 0.35 * dayVolume)
            end
        end

    elseif phase == "night" or phase == "dusk" then
        -- ── NIGHT SEQUENCER ──
        -- Constant pulse on every beat
        -- Alternate low bass drone pitch or accents
        if Music.beatCount % 2 == 1 then
            playNote(nightPool, 0, 0.45 * nightVolume) -- Strong pulse
        else
            -- Soft off-beat tension pulse
            local offset = (math.random() < 0.30) and 1 or 0 -- Db3 or C3
            playNote(nightPool, offset, 0.25 * nightVolume)
        end

        -- Extra deep sub-bass drop on beat 1 of each 4-beat bar
        if Music.beatCount % 4 == 1 then
            playNote(nightPool, -12, 0.60 * nightVolume)
        end

        -- Unpredictable high-pitched tense dissonant chime
        if math.random() < 0.30 then
            local idx = math.random(1, #NIGHT_MELODY_SCALE)
            local note = NIGHT_MELODY_SCALE[idx]
            -- Transpose up 2 octaves to make it high/chimey
            playNote(nightPool, note + 24, 0.30 * nightVolume)
        end
    end
end

-- Update loop
function Music.update(dt, gameState)
    if not Music.enabled then return end

    -- Determine phase and targets
    local phase = DayCycle.phase
    if gameState == "menu" then
        Music.targetVolume = 0.40
        phase = "day" -- Force day music in menu
    elseif gameState == "play" then
        Music.targetVolume = 0.55
    else
        -- Fade out music entirely on game over or victory
        Music.targetVolume = 0.0
    end

    -- Smooth master volume cross-fade
    Music.volume = Music.volume + (Music.targetVolume - Music.volume) * dt * 2.0

    -- Crossfade day and night mixes
    if phase == "dawn" or phase == "day" then
        dayVolume = math.min(1.0, dayVolume + dt * 0.8)
        nightVolume = math.max(0.0, nightVolume - dt * 1.2)
        Music.tempo = 90
    else
        dayVolume = math.max(0.0, dayVolume - dt * 1.2)
        nightVolume = math.min(1.0, nightVolume + dt * 0.8)
        Music.tempo = 120
    end

    -- Sequencer ticker
    local secsPerBeat = 60 / Music.tempo
    Music.beatTimer = Music.beatTimer + dt
    if Music.beatTimer >= secsPerBeat then
        Music.beatTimer = Music.beatTimer - secsPerBeat
        triggerBeat(gameState, phase)
    end
end

return Music
