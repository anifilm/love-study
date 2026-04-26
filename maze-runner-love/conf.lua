function love.conf(t)
    t.window.title = "Maze Runner"
    t.window.width = 800
    t.window.height = 640
    t.window.resizable = false
    t.window.vsync = 1

    -- 불필요한 모듈 비활성화
    t.modules.joystick = false
    t.modules.physics = false
end
