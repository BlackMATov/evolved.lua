if os.getenv('LOCAL_LUA_DEBUGGER_VSCODE') == '1' then
    require('lldebugger').start()
end

---@type love.conf
function love.conf(t)
    t.window.title = 'Evolved Example'
    t.window.width = 640
    t.window.height = 480
end
