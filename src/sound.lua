-- FanIsle: Sound Module (Procedural Synth — no external files needed)
-- Generates waveform buffers at load time using love.sound.newSoundData
local Sound = {}

Sound.enabled = true
Sound.volume  = 0.6

local sources = {}

-- ── Waveform generators ────────────────────────────────────────────────────

local RATE = 22050  -- Sample rate (22kHz is fine for game SFX)

local function clamp(v) return math.max(-1, math.min(1, v)) end

-- Sine tone: freq Hz, duration secs, volume, optional fade-out
local function makeSine(freq, dur, vol, fadeOut)
    vol = vol or 0.8
    local n = math.floor(RATE * dur)
    local sd = love.sound.newSoundData(n, RATE, 16, 1)
    for i = 0, n - 1 do
        local t     = i / RATE
        local env   = fadeOut and (1 - t / dur) or 1
        local sample = clamp(math.sin(2 * math.pi * freq * t) * vol * env)
        sd:setSample(i, sample)
    end
    return love.audio.newSource(sd)
end

-- Noise burst: white noise, short duration
local function makeNoise(dur, vol)
    vol = vol or 0.6
    local n  = math.floor(RATE * dur)
    local sd = love.sound.newSoundData(n, RATE, 16, 1)
    for i = 0, n - 1 do
        local t   = i / RATE
        local env = 1 - (t / dur)            -- linear fade
        sd:setSample(i, clamp((math.random() * 2 - 1) * vol * env))
    end
    return love.audio.newSource(sd)
end

-- Descending sweep: freq slides from hi → lo over duration
local function makeSweep(freqHi, freqLo, dur, vol)
    vol = vol or 0.7
    local n  = math.floor(RATE * dur)
    local sd = love.sound.newSoundData(n, RATE, 16, 1)
    local phase = 0
    for i = 0, n - 1 do
        local t    = i / RATE
        local frac = t / dur
        local freq = freqHi + (freqLo - freqHi) * frac
        local env  = 1 - frac
        phase = phase + (2 * math.pi * freq / RATE)
        sd:setSample(i, clamp(math.sin(phase) * vol * env))
    end
    return love.audio.newSource(sd)
end

-- Ascending chime: freq slides lo → hi, shorter
local function makeChime(freqLo, freqHi, dur, vol)
    vol = vol or 0.65
    local n  = math.floor(RATE * dur)
    local sd = love.sound.newSoundData(n, RATE, 16, 1)
    local phase = 0
    for i = 0, n - 1 do
        local t    = i / RATE
        local frac = t / dur
        local freq = freqLo + (freqHi - freqLo) * frac
        local env  = frac < 0.3 and (frac / 0.3) or (1 - (frac - 0.3) / 0.7)
        phase = phase + (2 * math.pi * freq / RATE)
        sd:setSample(i, clamp(math.sin(phase) * vol * env))
    end
    return love.audio.newSource(sd)
end

-- Low thud: short bass hit + noise blend
local function makeThud(dur, vol)
    vol = vol or 0.7
    local n  = math.floor(RATE * dur)
    local sd = love.sound.newSoundData(n, RATE, 16, 1)
    for i = 0, n - 1 do
        local t    = i / RATE
        local env  = math.exp(-t * 18)
        local bass = math.sin(2 * math.pi * 80 * t) * 0.7
        local nois = (math.random() * 2 - 1) * 0.3
        sd:setSample(i, clamp((bass + nois) * vol * env))
    end
    return love.audio.newSource(sd)
end

-- Deep bell-like resonance (night ambience)
local function makeBell(freq, dur, vol)
    vol = vol or 0.5
    local n  = math.floor(RATE * dur)
    local sd = love.sound.newSoundData(n, RATE, 16, 1)
    for i = 0, n - 1 do
        local t   = i / RATE
        local env = math.exp(-t * 1.2)
        local s   = math.sin(2 * math.pi * freq * t)
                  + 0.4 * math.sin(2 * math.pi * freq * 2 * t)
                  + 0.15 * math.sin(2 * math.pi * freq * 3 * t)
        sd:setSample(i, clamp(s * vol * env))
    end
    return love.audio.newSource(sd)
end

-- ── Build sound table ──────────────────────────────────────────────────────

function Sound.load()
    if not Sound.enabled then return end
    local ok, err = pcall(function()
        sources.harvest    = makeSweep(300, 120, 0.18, 0.55)   -- Whoosh down
        sources.craft      = makeChime(400, 900, 0.22, 0.65)    -- Rising chime
        sources.build      = makeThud(0.20, 0.70)               -- Hammer thud
        sources.hit_enemy  = makeNoise(0.10, 0.60)              -- Short crack
        sources.hit_player = makeSweep(600, 200, 0.25, 0.80)    -- Damage sting
        sources.eat        = makeChime(500, 700, 0.18, 0.55)    -- Soft nom
        sources.night_bell = makeBell(110, 2.00, 0.55)          -- Night onset
        sources.boss_roar  = makeThud(0.50, 0.90)               -- Deep rumble
        sources.projectile = makeSine(880, 0.10, 0.45, true)    -- Orb whoosh
    end)
    if not ok then
        print("Sound.load error: " .. tostring(err) .. " — audio disabled.")
        Sound.enabled = false
    end
end

-- Play a named sound effect (clone so overlapping plays work)
function Sound.play(id)
    if not Sound.enabled then return end
    local src = sources[id]
    if not src then return end
    local clone = src:clone()
    clone:setVolume(Sound.volume)
    clone:play()
end

return Sound
