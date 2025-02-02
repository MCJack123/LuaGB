local bit32 = bit32

local rshift = bit32.rshift

function apply(opcodes, opcode_cycles, z80, memory, interrupts)
  local read_nn = z80.read_nn
  local reg = z80.registers

  local call_nnnn = function()
    local lower = tonumber(read_nn())
    local upper = tonumber(read_nn()) * 256
    -- at this point, reg.pc points at the next instruction after the call,
    -- so store the current PC to the stack
    return ([[
    reg.sp = (reg.sp + 0xFFFF) %% 0x10000
    write_byte(reg.sp, 0x%02X)
    reg.sp = (reg.sp + 0xFFFF) %% 0x10000
    write_byte(reg.sp, 0x%02X)

    return z80.jit[0x%04X]()
    ]]):format(rshift(reg.pc, 8), reg.pc % 0x100, upper + lower)
  end

  -- call nn
  opcode_cycles[0xCD] = 24
  opcodes[0xCD] = function()
    return call_nnnn(), true
  end

  -- call nz, nnnn
  opcode_cycles[0xC4] = 12
  opcodes[0xC4] = function() return ([[
    if not flags.z then
      %s
      %s
    end
  ]]):format(z80.add_cycles(12), call_nnnn()) end

  -- call nc, nnnn
  opcode_cycles[0xD4] = 12
  opcodes[0xD4] = function() return ([[
    if not flags.c then
      %s
      %s
    end
  ]]):format(z80.add_cycles(12), call_nnnn()) end

  -- call z, nnnn
  opcode_cycles[0xCC] = 12
  opcodes[0xCC] = function() return ([[
    if flags.z then
      %s
      %s
    end
  ]]):format(z80.add_cycles(12), call_nnnn()) end

  -- call c, nnnn
  opcode_cycles[0xDC] = 12
  opcodes[0xDC] = function() return ([[
    if flags.c then
      %s
      %s
    end
  ]]):format(z80.add_cycles(12), call_nnnn()) end

  local ret = function() return [[do
    local lower = read_byte(reg.sp)
    reg.sp = (reg.sp + 1) % 0x10000
    local upper = read_byte(reg.sp) * 256
    reg.sp = (reg.sp + 1) % 0x10000
    ]] .. z80.add_cycles(12) .. [[
    return z80.jit[upper + lower]()
  end ]] end

  -- ret
  opcodes[0xC9] = function() return ret(), true end

  -- ret nz
  opcode_cycles[0xC0] = 8
  opcodes[0xC0] = function() return ([[
    if not flags.z then
      %s
    end
  ]]):format(ret()) end

  -- ret nc
  opcode_cycles[0xD0] = 8
  opcodes[0xD0] = function() return ([[
    if not flags.c then
      %s
    end
  ]]):format(ret()) end

  -- ret z
  opcode_cycles[0xC8] = 8
  opcodes[0xC8] = function() return ([[
    if flags.z then
      %s
    end
  ]]):format(ret()) end

  -- ret c
  opcode_cycles[0xD8] = 8
  opcodes[0xD8] = function() return ([[
    if flags.c then
      %s
    end
  ]]):format(ret()) end

  -- reti
  opcodes[0xD9] = function() return [[do
    local lower = read_byte(reg.sp)
    reg.sp = (reg.sp + 1) % 0x10000
    local upper = read_byte(reg.sp) * 256
    reg.sp = (reg.sp + 1) % 0x10000
    ]] .. z80.add_cycles(12) .. [[
    interrupts.enable()
    z80.service_interrupt()
    return z80.jit[upper + lower]()
  end ]], true end

  -- note: used only for the RST instructions below
  local function call_address(address) return ([[
    reg.sp = (reg.sp + 0xFFFF) %% 0x10000
    write_byte(reg.sp, 0x%02X)
    reg.sp = (reg.sp + 0xFFFF) %% 0x10000
    write_byte(reg.sp, 0x%02X)

    return z80.jit[0x%04X]()
  ]]):format(rshift(reg.pc, 8), reg.pc % 0x100, address) end

  -- rst N
  opcode_cycles[0xC7] = 16
  opcodes[0xC7] = function() return call_address(0x00), true end

  opcode_cycles[0xCF] = 16
  opcodes[0xCF] = function() return call_address(0x08), true end

  opcode_cycles[0xD7] = 16
  opcodes[0xD7] = function() return call_address(0x10), true end

  opcode_cycles[0xDF] = 16
  opcodes[0xDF] = function() return call_address(0x18), true end

  opcode_cycles[0xE7] = 16
  opcodes[0xE7] = function() return call_address(0x20), true end

  opcode_cycles[0xEF] = 16
  opcodes[0xEF] = function() return call_address(0x28), true end

  opcode_cycles[0xF7] = 16
  opcodes[0xF7] = function() return call_address(0x30), true end

  opcode_cycles[0xFF] = 16
  opcodes[0xFF] = function() return call_address(0x38), true end
end

return apply
