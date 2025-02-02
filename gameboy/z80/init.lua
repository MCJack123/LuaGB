local bit32 = bit32

local lshift = bit32.lshift
local rshift = bit32.rshift
local band = bit32.band
local bxor = bit32.bxor
local bor = bit32.bor
local bnot = bit32.bnot

local apply_arithmetic = require("gameboy/z80/arithmetic")
local apply_bitwise = require("gameboy/z80/bitwise")
local apply_call = require("gameboy/z80/call")
local apply_cp = require("gameboy/z80/cp")
local apply_inc_dec = require("gameboy/z80/inc_dec")
local apply_jp = require("gameboy/z80/jp")
local apply_ld = require("gameboy/z80/ld")
local apply_rl_rr_cb = require("gameboy/z80/rl_rr_cb")
local apply_stack = require("gameboy/z80/stack")

os.loadAPI("/LuaGB/gameboy/opcode_names.lua")
local opcode_names_g = opcode_names.generate()
--print(textutils.serialize(opcode_names))

local Registers = require("gameboy/z80/registers")

local Z80 = {}

function Z80.new(modules)
  local z80 = {}

  local interrupts = modules.interrupts
  local io = modules.io
  local memory = modules.memory
  local timers = modules.timers

  -- local references, for shorter code
  local read_byte = memory.read_byte
  local write_byte = memory.write_byte
  local compile

  z80.registers = Registers.new()
  local reg = z80.registers
  local flags = reg.flags

  -- Intentionally bad naming convention: I am NOT typing "registers"
  -- a bazillion times. The exported symbol uses the full name as a
  -- reasonable compromise.
  z80.halted = 0

  z80.add_cycles = function(cycles)
    return ("timers.system_clock = timers.system_clock + %d / clock_div\n"):format(cycles)
  end

  z80.double_speed = false

  z80.reset = function(gameboy)
    -- Initialize registers to what the GB's
    -- iternal state would be after executing
    -- BIOS code

    flags.z = true
    flags.n = false
    flags.h = true
    flags.c = true

    if gameboy.type == gameboy.types.color then
      reg.a = 0x11
    else
      reg.a = 0x01
    end

    reg.b = 0x00
    reg.c = 0x13
    reg.d = 0x00
    reg.e = 0xD8
    reg.h = 0x01
    reg.l = 0x4D
    reg.pc = 0x100 --entrypoint for GB games
    reg.sp = 0xFFFE

    z80.halted = 0
    for k in pairs(z80.jit) do z80.jit[k] = nil end
    z80.jit_map = {}
    for i = 0, 255 do z80.jit_map[i] = setmetatable({active = {}}, {__index = compile}) end
    z80.jit_banks = {}
    z80.coro = nil

    z80.double_speed = false
    z80.clock_div = 1
    timers:set_normal_speed()
  end

  z80.save_state = function()
    local state = {}
    state.double_speed = z80.double_speed
    state.registers = z80.registers
    state.halted = z80.halted
    return state
  end

  z80.load_state = function(state)
    -- Note: doing this explicitly for safety, so as
    -- not to replace the table with external, possibly old / wrong structure
    flags.z = state.registers.flags.z
    flags.n = state.registers.flags.n
    flags.h = state.registers.flags.h
    flags.c = state.registers.flags.c

    z80.registers.a = state.registers.a
    z80.registers.b = state.registers.b
    z80.registers.c = state.registers.c
    z80.registers.d = state.registers.d
    z80.registers.e = state.registers.e
    z80.registers.h = state.registers.h
    z80.registers.l = state.registers.l
    z80.registers.pc = state.registers.pc
    z80.registers.sp = state.registers.sp

    z80.double_speed = state.double_speed
    if z80.double_speed then
      timers:set_double_speed()
    else
      timers:set_normal_speed()
    end
    z80.halted = state.halted
  end

  io.write_mask[0x4D] = 0x01

  local opcodes = {}
  local opcode_cycles = {}
  local opcode_names = {}

  -- Initialize the opcode_cycles table with 4 as a base cycle, so we only
  -- need to care about variations going forward
  for i = 0x00, 0xFF do
    opcode_cycles[i] = 4
  end

  function z80.read_at_hl()
    return "(memory.block_map[reg.h * 0x100][reg.h * 0x100 + reg.l])"
  end

  function z80.set_at_hl(value)
    memory.block_map[reg.h * 0x100][reg.h * 0x100 + reg.l] = value
  end

  function z80.read_nn()
    local nn = read_byte(reg.pc)
    reg.pc = reg.pc + 1
    return nn
  end

  local read_at_hl = z80.read_at_hl
  local set_at_hl = z80.set_at_hl
  local read_nn = z80.read_nn

  apply_arithmetic(opcodes, opcode_cycles, z80, memory)
  apply_bitwise(opcodes, opcode_cycles, z80, memory)
  apply_call(opcodes, opcode_cycles, z80, memory, interrupts)
  apply_cp(opcodes, opcode_cycles, z80, memory)
  apply_inc_dec(opcodes, opcode_cycles, z80, memory)
  apply_jp(opcodes, opcode_cycles, z80, memory)
  apply_ld(opcodes, opcode_cycles, z80, memory)
  apply_rl_rr_cb(opcodes, opcode_cycles, z80, memory)
  apply_stack(opcodes, opcode_cycles, z80, memory)

  -- ====== GMB CPU-Controlcommands ======
  -- ccf
  opcodes[0x3F] = function() return [[
    flags.c = not flags.c
    flags.n = false
    flags.h = false
  ]] end

  -- scf
  opcodes[0x37] = function() return [[
    flags.c = true
    flags.n = false
    flags.h = false
  ]] end

  -- nop
  opcodes[0x00] = function() return "" end

  -- halt
  opcodes[0x76] = function() return [[
    if false and interrupts.enabled == 1 then
      print("Halting!")
      z80.halted = 1
      coroutine.yield()
    --else
      --print("Interrupts not enabled! Not actually halting...")
    end
  ]] end

  -- stop
  opcodes[0x10] = function() return [[do
    -- The stop opcode should always, for unknown reasons, be followed
    -- by an 0x00 data byte. If it isn't, this may be a sign that the
    -- emulator has run off the deep end, and this isn't a real STOP
    -- instruction.
    -- TODO: Research real hardware's behavior in these cases
    local stop_value = read_nn()
    if stop_value == 0x00 then
      print("STOP instruction not followed by NOP!")
      --halted = 1
    else
      print("Unimplemented WEIRDNESS after 0x10")
    end

    if band(io.ram[0x4D], 0x01) ~= 0 then
      --speed switch!
      print("Switching speeds!")
      if z80.double_speed then
        z80.double_speed = false
        z80.clock_div = 1
        io.ram[0x4D] = band(io.ram[0x4D], 0x7E) + 0x00
        timers:set_normal_speed()
        print("Switched to Normal Speed")
      else
        z80.double_speed = true
        z80.clock_div = 2
        io.ram[0x4D] = band(io.ram[0x4D], 0x7E) + 0x80
        timers:set_double_speed()
        print("Switched to Double Speed")
      end
    end
  end ]] end

  -- di
  opcodes[0xF3] = function() return [[
    interrupts.disable()
    print("Disabled interrupts with DI")
  ]] end
  -- ei
  opcodes[0xFB] = function() return [[
    interrupts.enable()
    print("Enabled interrupts with EI")
    z80.service_interrupt()
  ]] end

  local intr_count = 0
  z80.service_interrupt = function()
    local fired = band(io.ram[0xFF], io.ram[0x0F])
    if fired ~= 0 then
      --print("Unhalting!")
      z80.halted = 0
      if interrupts.enabled ~= 0 then
        -- First, disable interrupts to prevent nesting routines (unless the program explicitly re-enables them later)
        interrupts.disable()

        -- Now, figure out which interrupt this is, and call the corresponding
        -- interrupt vector
        local vector = 0x40
        local count = 0
        while band(fired, 0x1) == 0 and count < 5 do
          vector = vector + 0x08
          fired = rshift(fired, 1)
          count = count + 1
        end
        -- we need to clear the corresponding bit first, to avoid infinite loops
        io.ram[0x0F] = bxor(lshift(0x1, count), io.ram[0x0F])

        --[[
        reg.sp = band(0xFFFF, reg.sp - 1)
        write_byte(reg.sp, rshift(band(reg.pc, 0xFF00), 8))
        reg.sp = band(0xFFFF, reg.sp - 1)
        write_byte(reg.sp, band(reg.pc, 0xFF))
        ]]

        reg.intr_pc = vector
        intr_count = intr_count + 1

        timers.system_clock = timers.system_clock + 12 / z80.clock_div
        return true
      end
    end
    return false
  end

  -- register this as a callback with the interrupts module
  interrupts.service_handler = z80.service_interrupt

  -- For any opcodes that at this point are undefined,
  -- go ahead and "define" them with the following panic
  -- function
  local function undefined_opcode(i) return function() return ([[
    print("Unhandled opcode!: %02x")
  ]]):format(i) end end

  for i = 0, 0xFF do
    if not opcodes[i] then
      opcodes[i] = undefined_opcode(i)
    end
  end

  --local disfile = fs.open("/LuaGB/craftos-pc/disassembly.txt", "w")
  --print(textutils.serialise(opcode_names_g))

  z80.read_byte = memory.read_byte
  z80.write_byte = function(addr, val)
    local a = z80.jit_map[rshift(addr, 8)].active[addr]
    if a then
      for i = 1, #a do z80.jit[a[i]] = nil end
      z80.jit_map[rshift(addr, 8)].active[addr] = nil
    end
    return memory.write_byte(addr, val)
  end
  local compile_count, compile_time = 0, 0
  compile = function(self, pc)
    compile_count = compile_count + 1
    --local start = os.epoch "nano"
    --print(("Compiling at $%04X"):format(pc))
    local source = [[
      local bit32, z80, modules, memory = bit32, z80, modules, memory
      local band, bor, bnot, bxor, lshift, rshift = bit32.band, bit32.bor, bit32.bnot, bit32.bxor, bit32.lshift, bit32.rshift
      local read_byte, write_byte, reg, set_at_hl = z80.read_byte, z80.write_byte, z80.registers, z80.set_at_hl
      local flags = reg.flags
      return function()
      local check_exit, clock_div = z80.check_exit, z80.clock_div
      check_exit()
    ]]
    local pcs = {}
    reg.pc = pc
    repeat
      pcs[#pcs+1] = reg.pc
      local op = read_byte(reg.pc)
      local intr = ([[
        ::_%04X::
        if reg.intr_pc then
          local pc = reg.intr_pc
          reg.intr_pc = nil
          reg.sp = (reg.sp + 0xFFFF) %% 0x10000
          write_byte(reg.sp, %d)
          reg.sp = (reg.sp + 0xFFFF) %% 0x10000
          write_byte(reg.sp, %d)
          return z80.jit[pc]()
        end
        timers.system_clock = timers.system_clock + %d / clock_div
      ]]):format(reg.pc, rshift(band(reg.pc, 0xFF00), 8), band(reg.pc, 0xFF), opcode_cycles[op])
      --if pc == 0x20AF then intr = intr .. ("print('$%04X %02X')\n"):format(reg.pc, op) end
      --write(("$%04X %02X "):format(reg.pc, op))
      reg.pc = reg.pc + 1
      local inst, jump = opcodes[op]()
      --assert(not inst:find("reg.hl%(%)") and not inst:find("reg.bc%(%)"), inst)
      --print(inst)
      source = source .. intr .. inst
    until jump
    for _, v in ipairs(pcs) do source = source:gsub(("return z80.jit%%[0x%04X%%]%%(%%)"):format(v), ("check_exit() goto _%04X"):format(v)) end
    --if pc == 0x20AF then local file = assert(fs.open("LuaGB/20AF.lua", "w")) file.write(source .. " end\n") file.close() end
    --print(source, ("at $%04X"):format(pc))
    local fn = assert(load(source .. " end", ("=z80jit:$%04X"):format(pc), "t", setmetatable({z80 = z80, modules = modules, interrupts = modules.interrupts, io = modules.io, memory = modules.memory, timers = modules.timers}, {__index = _G})))()
    self[pc] = fn
    for addr = pc, reg.pc - 1 do
      local r = self.active[addr] or {}
      r[#r+1] = pc
      self.active[addr] = r
    end
    --compile_time = compile_time + (os.epoch "nano" - start)
    return fn
  end
  z80.jit = setmetatable({active = {}}, {__index = function(_, pc) return z80.jit_map[rshift(pc, 8)][pc] end})

  rawset(memory, "cachebust", function(addr_hi, newbank, oldbank)
    --print("Cachebusting at " .. addr_hi, z80.registers.pc)
    if oldbank and newbank then
      z80.jit_banks[oldbank] = z80.jit_banks[oldbank] or {}
      z80.jit_banks[oldbank][addr_hi / 256] = z80.jit_map[addr_hi / 256]
      local o = z80.jit_banks[newbank]
      z80.jit_map[addr_hi / 256] = o and o[addr_hi / 256] or setmetatable({active = {}}, {__index = compile})
    else
      z80.jit_map[addr_hi / 256] = setmetatable({active = {}}, {__index = compile})
    end
  end)

  local total_time = 0
  --local global_start = os.epoch "nano"
  if false then
    local jit = z80.jit
    local times = {[0] = 0}
    local start, pc = 0, ""
    local timer = os.epoch "utc"
    z80.jit = setmetatable({active = jit.active}, {__index = function(_, idx)
      if idx == "active" then return jit.active end
      times[pc] = os.epoch("nano") - start + (times[pc] or 0)
      if os.epoch "utc" - timer >= 5000 then
        times[""] = nil
        local file = assert(fs.open("LuaGB/profile.txt", "w"))
        file.writeLine("total time: " .. total_time)
        file.writeLine("wall time: " .. (os.epoch "nano" - global_start))
        file.writeLine("compilations: " .. compile_count .. " (" .. compile_time .. ")")
        file.writeLine("interrupts: " .. intr_count)
        local lines = {}
        for k, v in pairs(times) do
          lines[#lines+1] = {k, v}
        end
        table.sort(lines, function(a, b) return a[2] > b[2] end)
        for _, l in ipairs(lines) do
          file.writeLine(("$%04X %d"):format(l[1], l[2]))
        end
        file.close()
        timer = os.epoch "utc"
      end
      local fn = jit[idx]
      local a = os.epoch "nano"
      return function()
        pc, start = idx, os.epoch "nano"
        times[0] = times[0] + (start - a)
        return fn()
      end
    end, __newindex = function(_, idx, val) jit[idx] = val end})
  end

  z80.run_until_yield = function()
    if z80.halted ~= 0 then
      timers.system_clock = timers.system_clock + 4 / z80.clock_div
      return
    end
    if not z80.coro then z80.coro = coroutine.create(z80.jit[reg.pc]) end
    --local start = os.epoch "nano"
    local ok, err = coroutine.resume(z80.coro)
    --total_time = total_time + (os.epoch "nano" - start)
    if not ok then error(debug.traceback(z80.coro, err), 0) end
  end

  return z80
end

return Z80
