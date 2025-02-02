function apply(opcodes, opcode_cycles, z80, memory)
  local reg = z80.registers

  set_inc_flags = function(value) return ([[
    flags.z = %s == 0
    flags.h = %s %% 0x10 == 0x0
    flags.n = false
  ]]):format(value, value) end

  set_dec_flags = function(value) return ([[
    flags.z = %s == 0
    flags.h = %s %% 0x10 == 0xF
    flags.n = true
  ]]):format(value, value) end

  -- inc r
  opcodes[0x04] = function() return ("reg.b = band(reg.b + 1, 0xFF);\n%s"):format(set_inc_flags("reg.b")) end
  opcodes[0x0C] = function() return ("reg.c = band(reg.c + 1, 0xFF);\n%s"):format(set_inc_flags("reg.c")) end
  opcodes[0x14] = function() return ("reg.d = band(reg.d + 1, 0xFF);\n%s"):format(set_inc_flags("reg.d")) end
  opcodes[0x1C] = function() return ("reg.e = band(reg.e + 1, 0xFF);\n%s"):format(set_inc_flags("reg.e")) end
  opcodes[0x24] = function() return ("reg.h = band(reg.h + 1, 0xFF);\n%s"):format(set_inc_flags("reg.h")) end
  opcodes[0x2C] = function() return ("reg.l = band(reg.l + 1, 0xFF);\n%s"):format(set_inc_flags("reg.l")) end
  opcode_cycles[0x34] = 12
  opcodes[0x34] = function() return ([[do
    local hl = %s
    write_byte(hl, band(read_byte(hl) + 1, 0xFF))
    local v = read_byte(hl)
    %s
  end ]]):format(reg.hl(), set_inc_flags("v")) end
  opcodes[0x3C] = function() return ("reg.a = band(reg.a + 1, 0xFF);\n%s"):format(set_inc_flags("reg.a")) end

  -- dec r
  opcodes[0x05] = function() return ("reg.b = band(reg.b - 1, 0xFF);\n%s"):format(set_dec_flags("reg.b")) end
  opcodes[0x0D] = function() return ("reg.c = band(reg.c - 1, 0xFF);\n%s"):format(set_dec_flags("reg.c")) end
  opcodes[0x15] = function() return ("reg.d = band(reg.d - 1, 0xFF);\n%s"):format(set_dec_flags("reg.d")) end
  opcodes[0x1D] = function() return ("reg.e = band(reg.e - 1, 0xFF);\n%s"):format(set_dec_flags("reg.e")) end
  opcodes[0x25] = function() return ("reg.h = band(reg.h - 1, 0xFF);\n%s"):format(set_dec_flags("reg.h")) end
  opcodes[0x2D] = function() return ("reg.l = band(reg.l - 1, 0xFF);\n%s"):format(set_dec_flags("reg.l")) end
  opcode_cycles[0x35] = 12
  opcodes[0x35] = function() return ([[do
    local hl = %s
    write_byte(hl, band(read_byte(hl) - 1, 0xFF))
    local v = read_byte(hl)
    %s
  end ]]):format(reg.hl(), set_dec_flags("v")) end
  opcodes[0x3D] = function() return ("reg.a = band(reg.a - 1, 0xFF);\n%s"):format(set_dec_flags("reg.a")) end
end

return apply
