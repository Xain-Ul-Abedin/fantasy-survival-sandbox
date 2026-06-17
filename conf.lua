function love.conf(t)
    t.identity = "fanisle"
    t.version = "11.5"
    t.window.title = "FanIsle"
    t.window.width = 960
    t.window.height = 720
    t.window.resizable = false
    t.window.vsync = true
    
    -- Modules
    t.modules.physics = false -- Using custom AABB collision boxes by Raph
    t.modules.joystick = true
    t.modules.keyboard = true
    t.modules.event = true
    t.modules.graphics = true
    t.modules.audio = true
    t.modules.sound = true
    t.modules.timer = true
end
