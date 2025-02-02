--os.loadAPI(shell.dir() .. "/require.lua")
--require = dofile(shell.dir() .. "/require.lua")
--require.addPath(shell.dir())
--require.addPath(fs.getDir(shell.dir()))
--if term.getGraphicsMode == nil then error("This requires CraftOS-PC v1.2 or later.") end
package.path = package.path .. ";?.lua;../?.lua;?/init.lua;../?/init.lua"

if pcall(require, "jit.opt") then
    require("jit.opt").start(
        "maxmcode=8192",
        "maxtrace=2000"
        --
    )
end
local bit32 = bit32
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

LuaGB.palette = {[0] = {r = 0, g = 0, b = 0}, {r = 128, g = 128, b = 128}, {r = 192, g = 192, b = 192}, {r = 255, g = 255, b = 255}}
LuaGB.palettesize = 4
term.setPaletteColor(1, LuaGB.palette[0].r / 255, LuaGB.palette[0].g / 255, LuaGB.palette[0].b / 255)
term.setPaletteColor(2, LuaGB.palette[1].r / 255, LuaGB.palette[1].g / 255, LuaGB.palette[1].b / 255)
term.setPaletteColor(4, LuaGB.palette[2].r / 255, LuaGB.palette[2].g / 255, LuaGB.palette[2].b / 255)
term.setPaletteColor(8, LuaGB.palette[3].r / 255, LuaGB.palette[3].g / 255, LuaGB.palette[3].b / 255)

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
    for k,v in pairs(self.palette) do term.setPaletteColor(k, v.r / 256, v.g / 256, v.b / 256) end
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
local function writeBinaryToFile(filename, data, size)
    size = size or string.len(data)
    local file = fs.open(shell.resolve(filename), "wb")
    if file == nil then return false end
    for i = 1, size do file.write(string.byte(data, i, i)) end
    file.close()
    return true
end
local function readBinaryFromFile(path)
    if not fs.exists(shell.resolve(path)) then return false, "File doesn't exist" end
    local file = fs.open(shell.resolve(path), "rb")
    local size = fs.getSize(shell.resolve(path))
    local data = {}
    for i = 0, size - 1 do data[i] = file.read() end
    file.close()
    return data, size
end

function LuaGB:save_ram()
    print("Saving SRAM... (" .. #self.gameboy.cartridge.external_ram .. ")")
    local filename = "saves/" .. self.game_filename .. ".sav"
    --local save_data = textutils.serialize(self.gameboy.cartridge.external_ram)
    local save_data = ""
    for i = 0, #self.gameboy.cartridge.external_ram do 
        local v = self.gameboy.cartridge.external_ram[i]
        if type(v) ~= "number" or v > 255 or v < -128 then error("Bad value " .. v) end
        save_data = save_data .. string.char(v) 
    end
    if writeBinaryToFile(filename, save_data) then
        print("Successfully wrote SRAM to: ", filename)
    else
        print("Failed to save SRAM: ", filename)
    end
end

function LuaGB:load_ram()
    local filename = "saves/" .. self.game_filename .. ".sav"
    local file_data, size = readBinaryFromFile(filename)
    if type(size) == "string" then
        print(size)
        print("Couldn't load SRAM: ", filename)
    else
        if size > 0 then
            --local save_data, elements = binser.deserialize(file_data)
            if #file_data > 0 then
                for i = 0, #file_data do
                    self.gameboy.cartridge.external_ram[i] = file_data[i]
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

LuaGB.sound_buffer_left, LuaGB.sound_buffer_right = {}, {}
local leftSpeaker, rightSpeaker
if peripheral.getType("left") == "speaker" and peripheral.getType("right") == "speaker" then
    leftSpeaker, rightSpeaker = peripheral.wrap("left"), peripheral.wrap("right")
    if leftSpeaker.setPosition then leftSpeaker.setPosition(1, 0, 0) end
    if rightSpeaker.setPosition then rightSpeaker.setPosition(-1, 0, 0) end
    LuaGB.speaker = leftSpeaker
else LuaGB.speaker = peripheral.find("speaker") end

function LuaGB.play_gameboy_audio(buffer)
    if not LuaGB.speaker or not LuaGB.speaker.playAudio then return end -- ComputerCraft < 1.100 has no audio
    local l = #LuaGB.sound_buffer_left
    for i = 1, 750 do
        LuaGB.sound_buffer_left[l+i] = buffer[math.floor((i-1)/1.46484375)*2] * 127
        LuaGB.sound_buffer_right[l+i] = buffer[math.floor((i-1)/1.46484375)*2+1] * 127
    end
    if #LuaGB.sound_buffer_left > 2400 then
        if leftSpeaker then
            leftSpeaker.playAudio(LuaGB.sound_buffer_left, 1)
            rightSpeaker.playAudio(LuaGB.sound_buffer_right, 1)
        else
            local buf = {}
            for i = 1, #LuaGB.sound_buffer_left do buf[i] = (LuaGB.sound_buffer_left[i] + LuaGB.sound_buffer_right[i]) / 2 end
            LuaGB.speaker.stop()
            LuaGB.speaker.playAudio(buf, 1)
        end
        LuaGB.sound_buffer_left, LuaGB.sound_buffer_right = {}, {}
    end
    --LuaGB.sound_buffer[#LuaGB.sound_buffer+1] = buffer
    --if #LuaGB.sound_buffer >= 4 then
        -- local file, err = io.open(audio_flip and "LuaGBAudioTmp2.wav" or "LuaGBAudioTmp1.wav", "wb")
        -- if file == nil then print("Could not write audio: " .. (err or "nil")) return end
        -- file:write("RIFF\36\32\0\0WAVEfmt \16\0\0\0\1\0\2\0\0\128\0\0\0\0\2\0\4\0\16\0data\0\32\0\0")
        -- for j = 1, 4 do
        --     for i = 0, 1023 do
        --         --local n = LuaGB.sound_buffer[j][i] * 32767
        --         local n = buffer[i] * 32767
        --         file:write(string.char(bit32.band(n, 0xFF)) .. string.char(bit32.band(bit32.rshift(n, 8), 0xFF)))
        --     end
        -- end
        --local n = LuaGB.sound_buffer[4][1023] * 32767
        --file:write((string.char(bit32.band(n, 0xFF)) .. string.char(bit32.band(bit32.rshift(n, 8), 0xFF))):rep(4096))
        -- file:close()
        --LuaGB.speaker.playNote("hat")
        --LuaGB.speaker.playLocalMusic(audio_flip and "LuaGBAudioTmp2.wav" or "LuaGBAudioTmp1.wav")
        --LuaGB.sound_buffer = {}
        --audio_flip = not audio_flip
        --term.setPixel(200, 100, audio_flip and 11 or 10)
    --end
    --print("Audio success")
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

function LuaGB:load_game(game_path)
    self:reset()

    local file_data, size = readBinaryFromFile(game_path)
    if file_data then
        self.game_path = game_path
        self.game_filename = fs.getName(game_path)

        self.gameboy.cartridge.load(file_data, size)
        if self.gameboy.cartridge.header.color then
            print("ComputerCraft doesn't support Game Boy Color ROMs, giving up.")
            return
        end
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
    term.clear()
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
    term.clear()
    term.setCursorPos(0, 0)
    
    --love.graphics.push()
    --love.graphics.scale(2, 2)
    for i = 1, #shortcuts do
        print(shortcuts[i])
    end
    --love.graphics.pop()
    os.pullEvent("char")
end

local draw_calls = 0
local update_calls = 0

local fpsCharacters = {
    ["0"] = {
        "\255\255\255\254",
        "\255\254\255\254",
        "\255\254\255\254",
        "\255\254\255\254",
        "\255\255\255\254"
    },
    ["1"] = {
        "\254\255\254\254\254",
        "\254\255\254\254\254",
        "\254\255\254\254\254",
        "\254\255\254\254\254",
        "\254\255\254\254\254",
    },
    ["2"] = {
        "\255\255\255\254",
        "\254\254\255\254",
        "\255\255\255\254",
        "\255\254\254\254",
        "\255\255\255\254",
    },
    ["3"] = {
        "\255\255\255\254",
        "\254\254\255\254",
        "\255\255\255\254",
        "\254\254\255\254",
        "\255\255\255\254",
    },
    ["4"] = {
        "\255\254\255\254",
        "\255\254\255\254",
        "\255\255\255\254",
        "\254\254\255\254",
        "\254\254\255\254",
    },
    ["5"] = {
        "\255\255\255\254",
        "\255\254\254\254",
        "\255\255\255\254",
        "\254\254\255\254",
        "\255\255\255\254",
    },
    ["6"] = {
        "\255\255\255\254",
        "\255\254\254\254",
        "\255\255\255\254",
        "\255\254\255\254",
        "\255\255\255\254",
    },
    ["7"] = {
        "\255\255\255\254",
        "\254\254\255\254",
        "\254\254\255\254",
        "\254\254\255\254",
        "\254\254\255\254",
    },
    ["8"] = {
        "\255\255\255\254",
        "\255\254\255\254",
        "\255\255\255\254",
        "\255\254\255\254",
        "\255\255\255\254",
    },
    ["9"] = {
        "\255\255\255\254",
        "\255\254\255\254",
        "\255\255\255\254",
        "\254\254\255\254",
        "\255\255\255\254",
    },
    [" "] = {
        "\254\254\254\254",
        "\254\254\254\254",
        "\254\254\254\254",
        "\254\254\254\254",
        "\254\254\254\254",
    },
    ["F"] = {
        "\255\255\255\254",
        "\255\254\254\254",
        "\255\255\255\254",
        "\255\254\254\254",
        "\255\254\254\254",
    },
    ["P"] = {
        "\255\255\255\254",
        "\255\254\255\254",
        "\255\255\255\254",
        "\255\254\254\254",
        "\255\254\254\254",
    },
    ["S"] = {
        "\254\255\255\254",
        "\255\254\254\254",
        "\254\255\254\254",
        "\254\254\255\254",
        "\255\255\254\254",
    },
}

local lastFrameUpdate, frameCount = math.floor(os.epoch("utc") / 1000), 0

function LuaGB:get_color_for_rgb(v_pixel)
    local r, g, b = v_pixel[1], v_pixel[2], v_pixel[3]
    for k,v in pairs(self.palette) do 
        if v.r == r and v.g == g and v.b == b then
            return k
        end 
    end
    if self.palettesize >= 16 then error("Too many colors") end
    local c = self.palettesize
    self.palette[c] = {r = r, g = g, b = b}
    self.palettesize = self.palettesize + 1
    term.setPaletteColor(2^c, r / 255, g / 255, b / 255)
    return c
end

function LuaGB:draw_game_screen(dx, dy, scale)
    local pixels = self.gameboy.graphics.game_screen
    local c = 0
    local screen = {}
    term.setBackgroundColor(colors.black)
    local win = window.create(term.current(), 1, 1, 80, 48, false)
    for y = 0, 143, 3 do
        local row = {"", "", ""}
        for x = 0, 159, 2 do
            local colors = {}
            local used_colors = {}
            for i = 0, 2 do
                colors[i*2+1] = self:get_color_for_rgb(pixels[y+i][x])
                local found = false
                for n,v in ipairs(used_colors) do if v == colors[i*2+1] then found = true break end end
                if not found then used_colors[#used_colors+1] = colors[i*2+1] end
            end
            for i = 0, 2 do
                colors[i*2+2] = self:get_color_for_rgb(pixels[y+i][x+1])
                local found = false
                for n,v in ipairs(used_colors) do if v == colors[i*2+2] then found = true break end end
                if not found then used_colors[#used_colors+1] = colors[i*2+2] end
            end
            if #used_colors == 1 then
                row[1] = row[1] .. " "
                row[2] = row[2] .. "f"
                row[3] = row[3] .. ("0123456789abcdef"):sub(used_colors[1]+1, used_colors[1]+1)
            elseif #used_colors == 2 then
                local char, fg, bg = 128, used_colors[2], used_colors[1]
                for i = 1, 5 do if colors[i] == fg then char = char + 2^(i-1) end end
                if colors[6] == fg then char, fg, bg = bit32.band(bit32.bnot(char), 0x1F) + 128, bg, fg end
                row[1] = row[1] .. string.char(char)
                row[2] = row[2] .. ("0123456789abcdef"):sub(fg+1, fg+1)
                row[3] = row[3] .. ("0123456789abcdef"):sub(bg+1, bg+1)
            elseif #used_colors == 3 then
                local color_distances = {}
                local color_map = {}
                local char, fg, bg = 128
                table.sort(used_colors, function(a, b) return (self.palette[a].r + self.palette[a].g + self.palette[a].b) < (self.palette[b].r + self.palette[b].g + self.palette[b].b) end)
                color_distances[1] = math.sqrt((self.palette[used_colors[1]].r - self.palette[used_colors[2]].r)^2 + (self.palette[used_colors[1]].g - self.palette[used_colors[2]].g)^2 + (self.palette[used_colors[1]].b - self.palette[used_colors[2]].b)^2)
                color_distances[2] = math.sqrt((self.palette[used_colors[2]].r - self.palette[used_colors[3]].r)^2 + (self.palette[used_colors[2]].g - self.palette[used_colors[3]].g)^2 + (self.palette[used_colors[2]].b - self.palette[used_colors[3]].b)^2)
                color_distances[3] = math.sqrt((self.palette[used_colors[3]].r - self.palette[used_colors[1]].r)^2 + (self.palette[used_colors[3]].g - self.palette[used_colors[1]].g)^2 + (self.palette[used_colors[3]].b - self.palette[used_colors[1]].b)^2)
                if color_distances[1] - color_distances[2] > 10 then
                    color_map[used_colors[1]] = used_colors[1]
                    color_map[used_colors[2]] = used_colors[3]
                    color_map[used_colors[3]] = used_colors[3] 
                    fg, bg = used_colors[3], used_colors[1]
                elseif color_distances[2] - color_distances[1] > 10 then
                    color_map[used_colors[1]] = used_colors[1]
                    color_map[used_colors[2]] = used_colors[1]
                    color_map[used_colors[3]] = used_colors[3] 
                    fg, bg = used_colors[3], used_colors[1]
                else
                    if (self.palette[used_colors[1]].r + self.palette[used_colors[1]].g + self.palette[used_colors[1]].b) < 32 then
                        color_map[used_colors[1]] = used_colors[2]
                        color_map[used_colors[2]] = used_colors[2]
                        color_map[used_colors[3]] = used_colors[3] 
                        fg, bg = used_colors[2], used_colors[3]
                    elseif (self.palette[used_colors[3]].r + self.palette[used_colors[3]].g + self.palette[used_colors[3]].b) >= 224 then
                        color_map[used_colors[1]] = used_colors[2]
                        color_map[used_colors[2]] = used_colors[3]
                        color_map[used_colors[3]] = used_colors[3]
                        fg, bg = used_colors[2], used_colors[3]
                    else -- Fallback if the algorithm fails
                        color_map[used_colors[1]] = used_colors[2]
                        color_map[used_colors[2]] = used_colors[3]
                        color_map[used_colors[3]] = used_colors[3]
                        fg, bg = used_colors[2], used_colors[3]
                    end
                end
                for i = 1, 5 do if color_map[colors[i]] == fg then char = char + 2^(i-1) end end
                if color_map[colors[6]] == fg then char, fg, bg = bit32.band(bit32.bnot(char), 0x1F) + 128, bg, fg end
                row[1] = row[1] .. string.char(char)
                row[2] = row[2] .. ("0123456789abcdef"):sub(fg+1, fg+1)
                row[3] = row[3] .. ("0123456789abcdef"):sub(bg+1, bg+1)
            elseif #used_colors == 4 then
                local color_map = {}
                local char, fg, bg = 128
                color_map[used_colors[1]] = used_colors[2]
                color_map[used_colors[2]] = used_colors[2]
                color_map[used_colors[3]] = used_colors[3] 
                color_map[used_colors[4]] = used_colors[3] 
                fg, bg = used_colors[2], used_colors[3]
                for i = 1, 5 do if color_map[colors[i]] == fg then char = char + 2^(i-1) end end
                if color_map[colors[6]] == fg then char, fg, bg = bit32.band(bit32.bnot(char), 0x1F) + 128, bg, fg end
                row[1] = row[1] .. string.char(char)
                row[2] = row[2] .. ("0123456789abcdef"):sub(fg+1, fg+1)
                row[3] = row[3] .. ("0123456789abcdef"):sub(bg+1, bg+1)
            else
                for i = 0, self.palettesize - 1 do print(self.palette[i]) end
                error("Too many colors! " .. #used_colors)
            end
        end
        win.setCursorPos(1, y / 3 + 1)
        win.blit(row[1], row[2], row[3])
        --print(row[3])
        --sleep(1)
    end
    --self:setPalette()
    win.setVisible(true)
    term.setCursorPos(1, 49)
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.lightGray)
    --[[draw_calls = draw_calls + 1
    if math.floor(os.epoch("utc") / 1000) > lastFrameUpdate then
        lastFrameUpdate = math.floor(os.epoch("utc") / 1000)
        local str = tostring(frameCount) .. " FPS"
        term.setPaletteColor(254, 0, 0, 0)
        term.setPaletteColor(255, 1, 1, 1)
        for i = 1, #str do term.drawPixels(160 + i*4, 0, fpsCharacters[str:sub(i, i)]) end
        frameCount = 0
    end
    frameCount = frameCount + 1]]
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
    --self.gameboy.audio.disabled = true
    self.gameboy.audio.on_buffer_full(self.play_gameboy_audio)
    self.audio_dump_running = false
    self.gameboy.graphics.palette_dmg_colors = palette
    if sound then
        for i = 1, 4 do sound.setVolume(i, 0) end
        sound.setWaveType(1, "square")
        sound.setWaveType(2, "square")
        sound.setWaveType(3, "triangle")
        sound.setWaveType(4, "noise")
        sound.setFrequency(4, 1)
    end

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
        --filebrowser.keyreleased(key)
    end

    if input_mappings[key] then
        LuaGB.gameboy.input.keys[input_mappings[key]] = 0
        LuaGB.gameboy.input.update()
    end

    if key == "escape" and LuaGB.game_loaded then
        --LuaGB.menu_active = not LuaGB.menu_active
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
        --filebrowser.mousepressed(x / scale, y / scale, button)
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
    --print(draw_calls)
    --print(update_calls)
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

local last_render = 0
function update_loop()
    while true do
        os.pullEvent("update")
        if os.epoch("utc") - last_render >= 16 then
            last_render = os.epoch("utc")
            update()
            draw()
        end
        os.queueEvent("update")
    end
end

os.queueEvent("update")
parallel.waitForAny(update_loop, event_loop)

for i = 0, 15 do term.setPaletteColor(2^i, term.nativePaletteColor(2^i)) end
term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1, 1)
if sound then for i = 1, 4 do sound.setVolume(i, 0) end end
