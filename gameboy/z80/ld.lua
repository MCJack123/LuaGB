local bit32 = bit32

local lshift = bit32.lshift
local band = bit32.band

function apply(opcodes, opcode_cycles, z80, memory)
  local read_at_hl = z80.read_at_hl
  local read_nn = z80.read_nn
  local reg = z80.registers

  -- ld r, r
  opcodes[0x40] = function() return "reg.b = reg.b\n" end
  opcodes[0x41] = function() return "reg.b = reg.c\n" end
  opcodes[0x42] = function() return "reg.b = reg.d\n" end
  opcodes[0x43] = function() return "reg.b = reg.e\n" end
  opcodes[0x44] = function() return "reg.b = reg.h\n" end
  opcodes[0x45] = function() return "reg.b = reg.l\n" end
  opcode_cycles[0x46] = 8
  opcodes[0x46] = function() return "reg.b = " .. read_at_hl() .. "\n" end
  opcodes[0x47] = function() return "reg.b = reg.a\n" end

  opcodes[0x48] = function() return "reg.c = reg.b\n" end
  opcodes[0x49] = function() return "reg.c = reg.c\n" end
  opcodes[0x4A] = function() return "reg.c = reg.d\n" end
  opcodes[0x4B] = function() return "reg.c = reg.e\n" end
  opcodes[0x4C] = function() return "reg.c = reg.h\n" end
  opcodes[0x4D] = function() return "reg.c = reg.l\n" end
  opcode_cycles[0x4E] = 8
  opcodes[0x4E] = function() return "reg.c = " .. read_at_hl() .. "\n" end
  opcodes[0x4F] = function() return "reg.c = reg.a\n" end

  opcodes[0x50] = function() return "reg.d = reg.b\n" end
  opcodes[0x51] = function() return "reg.d = reg.c\n" end
  opcodes[0x52] = function() return "reg.d = reg.d\n" end
  opcodes[0x53] = function() return "reg.d = reg.e\n" end
  opcodes[0x54] = function() return "reg.d = reg.h\n" end
  opcodes[0x55] = function() return "reg.d = reg.l\n" end
  opcode_cycles[0x56] = 8
  opcodes[0x56] = function() return "reg.d = " .. read_at_hl() .. "\n" end
  opcodes[0x57] = function() return "reg.d = reg.a\n" end

  opcodes[0x58] = function() return "reg.e = reg.b\n" end
  opcodes[0x59] = function() return "reg.e = reg.c\n" end
  opcodes[0x5A] = function() return "reg.e = reg.d\n" end
  opcodes[0x5B] = function() return "reg.e = reg.e\n" end
  opcodes[0x5C] = function() return "reg.e = reg.h\n" end
  opcodes[0x5D] = function() return "reg.e = reg.l\n" end
  opcode_cycles[0x5E] = 8
  opcodes[0x5E] = function() return "reg.e = " .. read_at_hl() .. "\n" end
  opcodes[0x5F] = function() return "reg.e = reg.a\n" end

  opcodes[0x60] = function() return "reg.h = reg.b\n" end
  opcodes[0x61] = function() return "reg.h = reg.c\n" end
  opcodes[0x62] = function() return "reg.h = reg.d\n" end
  opcodes[0x63] = function() return "reg.h = reg.e\n" end
  opcodes[0x64] = function() return "reg.h = reg.h\n" end
  opcodes[0x65] = function() return "reg.h = reg.l\n" end
  opcode_cycles[0x66] = 8
  opcodes[0x66] = function() return "reg.h = " .. read_at_hl() .. "\n" end
  opcodes[0x67] = function() return "reg.h = reg.a\n" end

  opcodes[0x68] = function() return "reg.l = reg.b\n" end
  opcodes[0x69] = function() return "reg.l = reg.c\n" end
  opcodes[0x6A] = function() return "reg.l = reg.d\n" end
  opcodes[0x6B] = function() return "reg.l = reg.e\n" end
  opcodes[0x6C] = function() return "reg.l = reg.h\n" end
  opcodes[0x6D] = function() return "reg.l = reg.l\n" end
  opcode_cycles[0x6E] = 8
  opcodes[0x6E] = function() return "reg.l = " .. read_at_hl() .. "\n" end
  opcodes[0x6F] = function() return "reg.l = reg.a\n" end

  opcode_cycles[0x70] = 8
  opcodes[0x70] = function() return "set_at_hl(reg.b)\n" end

  opcode_cycles[0x71] = 8
  opcodes[0x71] = function() return "set_at_hl(reg.c)\n" end

  opcode_cycles[0x72] = 8
  opcodes[0x72] = function() return "set_at_hl(reg.d)\n" end

  opcode_cycles[0x73] = 8
  opcodes[0x73] = function() return "set_at_hl(reg.e)\n" end

  opcode_cycles[0x74] = 8
  opcodes[0x74] = function() return "set_at_hl(reg.h)\n" end

  opcode_cycles[0x75] = 8
  opcodes[0x75] = function() return "set_at_hl(reg.l)\n" end

  -- 0x76 is HALT, we implement that elsewhere

  opcode_cycles[0x77] = 8
  opcodes[0x77] = function() return "set_at_hl(reg.a)\n" end

  opcodes[0x78] = function() return "reg.a = reg.b\n" end
  opcodes[0x79] = function() return "reg.a = reg.c\n" end
  opcodes[0x7A] = function() return "reg.a = reg.d\n" end
  opcodes[0x7B] = function() return "reg.a = reg.e\n" end
  opcodes[0x7C] = function() return "reg.a = reg.h\n" end
  opcodes[0x7D] = function() return "reg.a = reg.l\n" end
  opcode_cycles[0x7E] = 8
  opcodes[0x7E] = function() return "reg.a = " .. read_at_hl() .. "\n" end
  opcodes[0x7F] = function() return "reg.a = reg.a\n" end

  -- ld r, n
  opcode_cycles[0x06] = 8
  opcodes[0x06] = function() return ("reg.b = 0x%02X\n"):format(read_nn()) end

  opcode_cycles[0x0E] = 8
  opcodes[0x0E] = function() return ("reg.c = 0x%02X\n"):format(read_nn()) end

  opcode_cycles[0x16] = 8
  opcodes[0x16] = function() return ("reg.d = 0x%02X\n"):format(read_nn()) end

  opcode_cycles[0x1E] = 8
  opcodes[0x1E] = function() return ("reg.e = 0x%02X\n"):format(read_nn()) end

  opcode_cycles[0x26] = 8
  opcodes[0x26] = function() return ("reg.h = 0x%02X\n"):format(read_nn()) end

  opcode_cycles[0x2E] = 8
  opcodes[0x2E] = function() return ("reg.l = 0x%02X\n"):format(read_nn()) end

  opcode_cycles[0x36] = 12
  opcodes[0x36] = function() return ("set_at_hl(0x%02X)\n"):format(read_nn()) end

  opcode_cycles[0x3E] = 8
  opcodes[0x3E] = function() return ("reg.a = 0x%02X\n"):format(read_nn()) end

  -- ld A, (xx)
  opcode_cycles[0x0A] = 8
  opcodes[0x0A] = function()
    return ("reg.a = read_byte(%s)\n"):format(reg.bc())
  end

  opcode_cycles[0x1A] = 8
  opcodes[0x1A] = function()
    return ("reg.a = read_byte(%s)\n"):format(reg.de())
  end

  opcode_cycles[0xFA] = 16
  opcodes[0xFA] = function()
    local lower = read_nn()
    local upper = lshift(read_nn(), 8)
    return ("reg.a = read_byte(0x%04X)\n"):format(upper + lower)
  end

  -- ld (xx), A
  opcode_cycles[0x02] = 8
  opcodes[0x02] = function()
    return ("write_byte(%s, reg.a)\n"):format(reg.bc())
  end

  opcode_cycles[0x12] = 8
  opcodes[0x12] = function()
    return ("write_byte(%s, reg.a)\n"):format(reg.de())
  end

  opcode_cycles[0xEA] = 16
  opcodes[0xEA] = function()
    local lower = read_nn()
    local upper = lshift(read_nn(), 8)
    return ("write_byte(0x%04X, reg.a)\n"):format(upper + lower)
  end

  -- ld a, (FF00 + nn)
  opcode_cycles[0xF0] = 12
  opcodes[0xF0] = function()
    return ("reg.a = read_byte(0x%04X)\n"):format(0xFF00 + read_nn())
  end

  -- ld (FF00 + nn), a
  opcode_cycles[0xE0] = 12
  opcodes[0xE0] = function()
    return ("write_byte(0x%04X, reg.a)\n"):format(0xFF00 + read_nn())
  end

  -- ld a, (FF00 + C)
  opcode_cycles[0xF2] = 8
  opcodes[0xF2] = function()
    return "reg.a = read_byte(0xFF00 + reg.c)\n"
  end

  -- ld (FF00 + C), a
  opcode_cycles[0xE2] = 8
  opcodes[0xE2] = function()
    return "write_byte(0xFF00 + reg.c, reg.a)\n"
  end

  -- ldi (HL), a
  opcode_cycles[0x22] = 8
  opcodes[0x22] = function() return ([[
    set_at_hl(reg.a)
    reg.set_hl(band(%s + 1, 0xFFFF))
  ]]):format(reg.hl()) end

  -- ldi a, (HL)
  opcode_cycles[0x2A] = 8
  opcodes[0x2A] = function() return ([[
    reg.a = %s
    reg.set_hl(band(%s + 1, 0xFFFF))
  ]]):format(read_at_hl(), reg.hl()) end

  -- ldd (HL), a
  opcode_cycles[0x32] = 8
  opcodes[0x32] = function() return ([[
    set_at_hl(reg.a)
    reg.set_hl(band(%s - 1, 0xFFFF))
  ]]):format(reg.hl()) end

  -- ldd a, (HL)
  opcode_cycles[0x3A] = 8
  opcodes[0x3A] = function() return ([[
    reg.a = %s
    reg.set_hl(band(%s - 1, 0xFFFF))
  ]]):format(read_at_hl(), reg.hl()) end

  -- ====== GMB 16-bit load commands ======
  -- ld BC, nnnn
  opcode_cycles[0x01] = 12
  opcodes[0x01] = function() return ([[
    reg.c = 0x%02X
    reg.b = 0x%02X
  ]]):format(read_nn(), read_nn()) end

  -- ld DE, nnnn
  opcode_cycles[0x11] = 12
  opcodes[0x11] = function() return ([[
    reg.e = 0x%02X
    reg.d = 0x%02X
  ]]):format(read_nn(), read_nn()) end

  -- ld HL, nnnn
  opcode_cycles[0x21] = 12
  opcodes[0x21] = function() return ([[
    reg.l = 0x%02X
    reg.h = 0x%02X
  ]]):format(read_nn(), read_nn()) end

  -- ld SP, nnnn
  opcode_cycles[0x31] = 12
  opcodes[0x31] = function()
    local lower = read_nn()
    local upper = lshift(read_nn(), 8)
    return ("reg.sp = 0x%04X\n"):format(band(0xFFFF, upper + lower))
  end

  -- ld SP, HL
  opcode_cycles[0xF9] = 8
  opcodes[0xF9] = function()
    return "reg.sp = " .. reg.hl() .. "\n"
  end

  -- ld HL, SP + dd
  opcode_cycles[0xF8] = 12
  opcodes[0xF8] = function() return ([[
    -- cheat
    local old_sp = reg.sp
    %s
    reg.set_hl(reg.sp)
    reg.sp = old_sp
  ]]):format(opcodes[0xE8]()) end

  -- ====== GMB Special Purpose / Relocated Commands ======
  -- ld (nnnn), SP
  opcode_cycles[0x08] = 20
  opcodes[0x08] = function()
    local lower = read_nn()
    local upper = lshift(read_nn(), 8)
    local address = upper + lower
    return ([[
      write_byte(0x%04X, band(reg.sp, 0xFF))
      write_byte(0x%04X, rshift(band(reg.sp, 0xFF00), 8))
    ]]):format(address, band(address + 1, 0xFFFF))
  end
end

return apply
