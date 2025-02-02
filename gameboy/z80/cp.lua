function apply(opcodes, opcode_cycles, z80, memory)
  local read_at_hl = z80.read_at_hl
  local read_nn = z80.read_nn

  cp_with_a = function(value) return ([[do
    -- half-carry
    flags.h = (reg.a %% 0x10) - (%s %% 0x10) < 0

    local temp = reg.a - %s

    -- carry (and overflow correction)
    flags.c = temp < 0 or temp > 0xFF
    temp  = (temp + 0x100) %% 0x100

    flags.z = temp == 0
    flags.n = true
  end ]]):format(value, value) end

  -- cp A, r
  opcodes[0xB8] = function() return cp_with_a("reg.b") end
  opcodes[0xB9] = function() return cp_with_a("reg.c") end
  opcodes[0xBA] = function() return cp_with_a("reg.d") end
  opcodes[0xBB] = function() return cp_with_a("reg.e") end
  opcodes[0xBC] = function() return cp_with_a("reg.h") end
  opcodes[0xBD] = function() return cp_with_a("reg.l") end
  opcode_cycles[0xBE] = 8
  opcodes[0xBE] = function() return cp_with_a(read_at_hl()) end
  opcodes[0xBF] = function() return cp_with_a("reg.a") end

  -- cp A, nn
  opcode_cycles[0xFE] = 8
  opcodes[0xFE] = function() return cp_with_a(read_nn()) end
end

return apply
