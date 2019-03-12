--os.loadAPI(shell.dir() .. "/require.lua")
require = dofile(shell.dir() .. "/require.lua")
require.addPath(shell.dir())
require.addPath(fs.getDir(shell.dir()))

if require("jit.opt") then
    require("jit.opt").start(
        "maxmcode=8192",
        "maxtrace=2000"
        --
    )
end
local bit32 = require("bit")
--local filebrowser = require("filebrowser")
local Gameboy = require("gameboy")
local binser = require("vendor/binser")

--require("vendor/profiler")

local LuaGB = {}
LuaGB.audio_dump_running = false
LuaGB.game_filename = ""
LuaGB.game_path = ""
LuaGB.game_loaded = false
LuaGB.version = "0.1.1"
LuaGB.window_title = ""
LuaGB.save_delay = 0

LuaGB.game_screen_image = nil
LuaGB.game_screen_imagedata = nil

LuaGB.debug = {}
LuaGB.debug.active_panels = {}
LuaGB.debug.enabled = false

LuaGB.emulator_running = false
LuaGB.menu_active = true

LuaGB.screen_scale = 3

LuaGB.palette = {}

-- Do the check to see if JIT is enabled. If so use the optimized FFI structs.
local ffi_status, ffi
if type(jit) == "table" and jit.status() then
    ffi_status, ffi = pcall(require, "ffi")
    if ffi_status then
        ffi.cdef("typedef struct { unsigned char r, g, b, a; } luaGB_pixel;")
    end
end

function LuaGB:setPalette()
    --print(textutils.serialize(self.palette))
    for k,v in pairs(self.palette) do term.setPaletteColor(2^k, v.r / 256, v.g / 256, v.b / 256) end
end

function LuaGB:resize_window()
    local scale = self.screen_scale
    if self.debug.enabled then
        scale = 2
    end
    local width = 160 * scale --width of gameboy screen
    local height = 144 * scale --height of gameboy screen
    if self.debug.enabled then
        if #self.debug.active_panels > 0 then
            for _, panel in ipairs(self.debug.active_panels) do
                width = width + panel.width + 10
            end
        end
        height = 800
    end
end

function LuaGB:toggle_panel(name)
    return
    --[[if panels[name].active then
        panels[name].active = false
        for index, value in ipairs(self.debug.active_panels) do
            if value == panels[name] then
                table.remove(self.debug.active_panels, index)
            end
        end
    else
        panels[name].active = true
        table.insert(self.debug.active_panels, panels[name])
    end
    self:resize_window()]]
end

-- GLOBAL ON PURPOSE
profile_enabled = false

local function writeToFile(filename, data, size)
    size = size or string.len(data)
    local file = fs.open(shell.resolve(filename), "w")
    if file == nil then return false end
    file.write(string.sub(data, 1, size))
    file.close()
    return true
end
local function appendToFile(filename, data, size)
    size = size or string.len(data)
    local file = fs.open(shell.resolve(filename), "a")
    if file == nil then return false end
    file.write(string.sub(data, 1, size))
    file.close()
    return true
end
local function readFromFile(filename)
    if not fs.exists(shell.resolve(filename)) then return false, "File doesn't exist" end
    local file = fs.open(shell.resolve(filename), "r")
    local retval = file.readAll()
    file.close()
    return retval, string.len(retval)
end

function LuaGB:save_ram()
    local filename = "saves/" .. self.game_filename .. ".sav"
    local save_data = binser.serialize(self.gameboy.cartridge.external_ram)
    if writeToFile(filename, save_data) then
        print("Successfully wrote SRAM to: ", filename)
    else
        print("Failed to save SRAM: ", filename)
    end
end

function LuaGB:load_ram()
    local filename = "saves/" .. self.game_filename .. ".sav"
    local file_data, size = readFromFile(filename)
    if type(size) == "string" then
        print(size)
        print("Couldn't load SRAM: ", filename)
    else
        if size > 0 then
            local save_data, elements = binser.deserialize(file_data)
            if elements > 0 then
                for i = 0, #save_data[1] do
                    self.gameboy.cartridge.external_ram[i] = save_data[1][i]
                end
                print("Loaded SRAM: ", filename)
            else
                print("Error parsing SRAM data for ", filename)
            end
        end
    end
end

function LuaGB:save_state(number)
    local state_data = self.gameboy:save_state()
    local filename = "states/" .. self.game_filename .. ".s" .. number
    local state_string = binser.serialize(state_data)
    if writeToFile(filename, state_string) then
        print("Successfully wrote state: ", filename)
    else
        print("Failed to save state: ", filename)
    end
end

function LuaGB:load_state(number)
    LuaGB:reset()
    LuaGB:load_game(LuaGB.game_path)

    local filename = "states/" .. self.game_filename .. ".s" .. number
    local file_data, size = readFromFile(filename)
    if type(size) == "string" then
        print(size)
        print("Couldn't load state: ", filename)
    else
        if size > 0 then
            local state_data, elements = binser.deserialize(file_data)
            if elements > 0 then
                self.gameboy:load_state(state_data[1])
                print("Loaded state: ", filename)
            else
                print("Error parsing state data for ", filename)
            end
        end
    end
end

LuaGB.sound_buffer = nil

function LuaGB.play_gameboy_audio(buffer)
    return --[[ ComputerCraft has no audio
    sound_buffer = love.sound.newSoundData(512, 32768, 16, 2)
    for i = 0, 1024 - 1 do
        sound_buffer:setSample(i, buffer[i])
    end
    --local source = love.audio.newSource(LuaGB.sound_buffer)
    --love.audio.play(source)
    LuaGB.queueable_source:queue(sound_buffer)
    if not LuaGB.queueable_source:isPlaying() then
        LuaGB.queueable_source:play()
    end]]
end

function LuaGB.dump_audio(buffer)
    -- play the sound still
    LuaGB.play_gameboy_audio(buffer)
    -- convert this to a bytestring for output
    local output = ""
    local chars = {}
    for i = 0, 1024 - 1 do
        local sample = buffer[i]
        sample = math.floor(sample * (32768 - 1)) -- re-root in 16-bit range
        chars[i * 2] = string.char(bit32.band(sample, 0xFF))
        chars[i * 2 + 1] = string.char(bit32.rshift(bit32.band(sample, 0xFF00), 8))
    end
    output = table.concat(chars)

    appendToFile("audiodump.raw", output, 1024 * 2)
end

local function readBinaryFromFile(path)
    local file = fs.open(shell.resolve(path), "rb")
    local size = fs.getSize(shell.resolve(path))
    local data = {}
    for i = 0, size - 1 do data[i] = file.read() end
    file.close()
    return data, size
end

function LuaGB:load_game(game_path)
    self:reset()

    local file_data, size = readBinaryFromFile(game_path)
    if file_data then
        self.game_path = game_path
        self.game_filename = fs.getName(game_path)

        self.gameboy.cartridge.load(file_data, size)
        self:load_ram()
        self.gameboy:reset()

        print("Successfully loaded ", self.game_filename)
    else
        print("Couldn't open ", game_path, " giving up.")
        return
    end

    self.window_title = "LuaGB v" .. self.version .. " - " .. self.gameboy.cartridge.header.title

    self.menu_active = false
    self.emulator_running = true
    self.game_loaded = true
    print(self.gameboy.memory.read_byte(0xFF))
end

function main(args)
    LuaGB.window_title = "LuaGB v" .. LuaGB.version
    print(LuaGB.window_title)
    --LuaGB.queueable_source = love.audio.newQueueableSource(32768, 16, 2)
    --love.graphics.setDefaultFilter("nearest", "nearest")

    --local small_font = love.graphics.newImageFont("images/5x3font_bm.png", "!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~ ", 1)
    --love.graphics.setFont(small_font)

    --LuaGB.game_screen_imagedata = love.image.newImageData(256, 256)
    --if ffi_status then
    --    LuaGB.raw_game_screen_imagedata = ffi.cast("luaGB_pixel*", LuaGB.game_screen_imagedata:getPointer())
    --end
    --LuaGB.game_screen_image = love.graphics.newImage(LuaGB.game_screen_imagedata)
    --LuaGB.debug.separator_image = love.graphics.newImage("images/debug_separator.png")

    --love.window.setIcon(love.image.newImageData("images/icon_16.png"))

    -- Make sure our games / saves / states directories actually exist
    fs.makeDir("games")
    fs.makeDir("states")
    fs.makeDir("saves")

    LuaGB:reset()

    if #args >= 2 then
        local game_path = args[2]
        LuaGB:load_game(game_path)
    else error("Please specify a ROM to load.") end

    --LuaGB:toggle_panel("audio")

    --[[filebrowser.is_directory = fs.isDir
    filebrowser.get_directory_items = fs.list
    filebrowser.load_file = function(filename) LuaGB:load_game(filename) end
    filebrowser.init(LuaGB.gameboy)--]]
    term.setGraphicsMode(true)
    LuaGB:resize_window()
end

function LuaGB:print_instructions()
    --love.graphics.setColor(0, 0, 0)
    local shortcuts = {
        "[P] = Play/Pause",
        "[R] = Reset",
        "[D] = Toggle Debug Mode",
        "[Q] = Quit",
        "",
        "[Space] = Single Step",
        "[K]     = 100 Steps",
        "[L]     = 1000 Steps",
        "[H] = Run until HBlank",
        "[V] = Run until VBlank",
        "",
        "[F1-F9] = Save State",
        "[1-9]   = Load State",
        "",
        "[Num 1] = IO",
        "[Num 2] = VRAM",
        "[Num 3] = OAM",
        "[Num 4] = Disassembler",
        "[Num 5] = Audio"
    }
    term.setGraphicsMode(false)
    term.clear()
    term.setCursorPos(0, 0)
    
    --love.graphics.push()
    --love.graphics.scale(2, 2)
    for i = 1, #shortcuts do
        print(shortcuts[i])
    end
    --love.graphics.pop()
    os.pullEvent("char")
    term.setGraphicsMode(true)
end

local draw_calls = 0
local update_calls = 0

function LuaGB:draw_game_screen(dx, dy, scale)
    local pixels = self.gameboy.graphics.game_screen
    self.palette = {}
    local c = 0
    for y = 0, 143 do
        for x = 0, 159 do
            --[[if raw_image_data then
                local pixel = raw_image_data[y*stride+x]
                local v_pixel = pixels[y][x]
                pixel.r = v_pixel[1]
                pixel.g = v_pixel[2]
                pixel.b = v_pixel[3]
                pixel.a = 255
            else
                image_data:setPixel(x, y, pixels[y][x][1], pixels[y][x][2], pixels[y][x][3], 255)
            end]]
            local pixel = {}
            local v_pixel = pixels[y][x]
            pixel.r = v_pixel[1]
            pixel.g = v_pixel[2]
            pixel.b = v_pixel[3]
            --if pixel.r ~= 255 or pixel.g ~= 255 or pixel.b ~= 255 then print(textutils.serialize(pixel)) end
            local found = false
            for k,v in pairs(self.palette) do 
                if v.r == pixel.r and v.g == pixel.g and v.b == pixel.b then
                    found = true
                    term.setPixel(x, y, 2^k)
                end 
            end
            if not found then
                self.palette[c] = pixel
                term.setPixel(x, y, 2^c)
                c = c + 1
                if c >= 16 then
                    term.setGraphicsMode(false)
                    error("Too many colors on-screen")
                end
            end
        end
    end
    draw_calls = draw_calls + 1
    self:setPalette()
end

function LuaGB:run_n_cycles(n)
    for i = 1, n do
        self.gameboy:step()
    end
end

function LuaGB:reset()
    self.gameboy = Gameboy.new{}
    self.gameboy:initialize()
    self.gameboy:reset()
    self.gameboy.audio.on_buffer_full(self.play_gameboy_audio)
    self.audio_dump_running = false
    self.gameboy.graphics.palette_dmg_colors = palette

    -- Initialize Debug Panels
    --for _, panel in pairs(panels) do
    --    panel.init(self.gameboy)
    --end
end

local action_keys = {}
action_keys.space = function() LuaGB.gameboy:step() end

action_keys.k = function() LuaGB:run_n_cycles(100) end
action_keys.l = function() LuaGB:run_n_cycles(1000) end
action_keys.r = function()
    LuaGB:reset()
    if LuaGB.game_loaded then
        local emulator_running = LuaGB.emulator_running
        LuaGB:load_game(LuaGB.game_path)
        LuaGB.emulator_running = emulator_running
    end
end
action_keys.p = function() LuaGB.emulator_running = not LuaGB.emulator_running end
action_keys.h = function() LuaGB.gameboy:run_until_hblank() end
action_keys.v = function() LuaGB.gameboy:run_until_vblank() end

action_keys.o = function() LuaGB.gameboy:step_over() end
action_keys.i = function() LuaGB.gameboy:run_until_ret() end

action_keys.d = function()
    LuaGB.debug.enabled = not LuaGB.debug.enabled
    LuaGB.gameboy.audio.debug.enabled = LuaGB.debug.enabled
    LuaGB:resize_window()
end

for i = 1, 8 do
    action_keys[tostring(i)] = function()
        LuaGB:load_state(i)
    end

    action_keys["f" .. tostring(i)] = function()
        LuaGB:save_state(i)
    end
end

action_keys["f9"] = function() LuaGB.gameboy.audio.tone1.debug_disabled = not LuaGB.gameboy.audio.tone1.debug_disabled end
action_keys["f10"] = function() LuaGB.gameboy.audio.tone2.debug_disabled = not LuaGB.gameboy.audio.tone2.debug_disabled end
action_keys["f11"] = function() LuaGB.gameboy.audio.wave3.debug_disabled = not LuaGB.gameboy.audio.wave3.debug_disabled end
action_keys["f12"] = function() LuaGB.gameboy.audio.noise4.debug_disabled = not LuaGB.gameboy.audio.noise4.debug_disabled end

action_keys.numPad1 = function() LuaGB:toggle_panel("io") end
action_keys.numPad2 = function() LuaGB:toggle_panel("vram") end
action_keys.numPad3 = function() LuaGB:toggle_panel("oam") end
action_keys.numPad4 = function() LuaGB:toggle_panel("disassembler") end
action_keys.numPad5 = function() LuaGB:toggle_panel("audio") end

action_keys["numPadAdd"] = function()
    if LuaGB.screen_scale < 5 then
        LuaGB.screen_scale = LuaGB.screen_scale + 1
        LuaGB:resize_window()
    end
end

action_keys["numPadSubtract"] = function()
    if LuaGB.screen_scale > 1 then
        LuaGB.screen_scale = LuaGB.screen_scale - 1
        LuaGB:resize_window()
    end
end

action_keys.a = function()
    if LuaGB.audio_dump_running then
        LuaGB.gameboy.audio.on_buffer_full(LuaGB.play_gameboy_audio)
        print("Stopped dumping audio.")
        LuaGB.audio_dump_running = false
    else
        --love.filesystem.remove("audiodump.raw")
        LuaGB.gameboy.audio.on_buffer_full(LuaGB.dump_audio)
        print("Started dumping audio to audiodump.raw ...")
        LuaGB.audio_dump_running = true
    end
end

action_keys.leftShift = function()
    if profile_enabled then
        --profilerStop()
        profile_enabled = false
    else
        --profilerStart()
        profile_enabled = true
    end
end

local input_mappings = {}
input_mappings.up = "Up"
input_mappings.down = "Down"
input_mappings.left = "Left"
input_mappings.right = "Right"
input_mappings.x = "A"
input_mappings.z = "B"
input_mappings["enter"] = "Start"
input_mappings.rightShift = "Select"

function keypressed(key)
    if input_mappings[key] then
        LuaGB.gameboy.input.keys[input_mappings[key]] = 1
        LuaGB.gameboy.input.update()
    end
end

function keyreleased(key)
    if not profile_enabled or key == "lshift" then
        if action_keys[key] then
            action_keys[key]()
        end
    end

    if LuaGB.menu_active then
        filebrowser.keyreleased(key)
    end

    if input_mappings[key] then
        LuaGB.gameboy.input.keys[input_mappings[key]] = 0
        LuaGB.gameboy.input.update()
    end

    if key == "escape" and LuaGB.game_loaded then
        LuaGB.menu_active = not LuaGB.menu_active
    end
end

function mousepressed(x, y, button)
    local scale = LuaGB.screen_scale
    if LuaGB.debug.enabled then
        local panel_x = 160 * 2 + 10 --width of the gameboy canvas in debug mode
        for _, panel in pairs(LuaGB.debug.active_panels) do
            if panel.mousepressed then
                panel.mousepressed(x - panel_x, y, button)
            end
            panel_x = panel_x + panel.width + 10
        end
        scale = 2
    end
    if LuaGB.menu_active then
        filebrowser.mousepressed(x / scale, y / scale, button)
    end
end

function update()
    if LuaGB.menu_active then
        --filebrowser.update()
    else
        if LuaGB.emulator_running then
            --LuaGB.gameboy:run_until_vblank()
            LuaGB.gameboy:run_until_vblank()
        else os.queueEvent('terminate') end
    end
    if LuaGB.gameboy.cartridge.external_ram.dirty then
        LuaGB.save_delay = LuaGB.save_delay + 1
    end
    if LuaGB.save_delay > 60 * 10 then
        LuaGB.save_delay = 0
        LuaGB.gameboy.cartridge.external_ram.dirty = false
        LuaGB:save_ram()
    end
    update_calls = update_calls + 1
    -- Apply any changed local settings to the gameboy
    --LuaGB.gameboy.graphics.palette.set_dmg_colors(filebrowser.palette[0], filebrowser.palette[1], filebrowser.palette[2], filebrowser.palette[3])
end

function draw()
    if LuaGB.debug.enabled then
        --panels.registers.draw(0, 288)
        LuaGB:print_instructions()
        if LuaGB.menu_active then
            --filebrowser.draw(0, 0, 2)
        else
            LuaGB:draw_game_screen(0, 0, 2)
        end
        local panel_x = 160 * 2 + 10 --width of the gameboy canvas in debug mode
        --[[for _, panel in pairs(LuaGB.debug.active_panels) do
            love.graphics.push()
            love.graphics.scale(2, 2)
            love.graphics.draw(LuaGB.debug.separator_image, (panel_x - 10) / 2, 0)
            love.graphics.pop()
            panel.draw(panel_x, 0)
            panel_x = panel_x + panel.width + 10
        end]]
    else
        if LuaGB.menu_active then
            --filebrowser.draw(0, 0, LuaGB.screen_scale)
        else
            LuaGB:draw_game_screen(0, 0, LuaGB.screen_scale)
        end
    end

    if profile_enabled then
        --love.graphics.setColor(0, 0, 0, 128)
        --love.graphics.rectangle("fill", 0, 0, 1024, 1024)
        --love.graphics.setColor(255, 255, 255)
    end

    --love.window.setTitle("(FPS: " .. love.timer.getFPS() .. ") - " .. LuaGB.window_title)
end

function quit()
    --profilerReport("profiler.txt")
    if LuaGB.game_loaded then
        --LuaGB:save_ram()
    end
    print(draw_calls)
    print(update_calls)
end

main({"main.lua", ...})

function event_loop()
    while true do
        local ev, p1, p2, p3 = os.pullEventRaw()
        if ev == "key" then
            if p1 == keys.q then
                quit()
                break
            end
            keypressed(keys.getName(p1))
        elseif ev == "key_up" then
            keyreleased(keys.getName(p1))
        elseif ev == "terminate" then
            quit()
            break
        elseif ev == "mouse_click" then
            mousepressed(p2, p3, p1)
        end
    end
end

function update_loop()
    while true do
        os.pullEvent("update")
        update()
        draw()
        os.queueEvent("update")
    end
end

os.queueEvent("update")
parallel.waitForAny(update_loop, event_loop)

term.setGraphicsMode(false)
print("")