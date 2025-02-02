local bit32 = bit32

function apply(opcodes, opcode_cycles, z80, memory)
  local read_at_hl = z80.read_at_hl
  local read_nn = z80.read_nn

  and_a_with = function(value) return ([[
    reg.a = band(reg.a, %s)
    flags.z = reg.a == 0
    flags.n = false
    flags.h = true
    flags.c = false
  ]]):format(value) end

  -- and A, r
  opcodes[0xA0] = function() return and_a_with("reg.b") end
  opcodes[0xA1] = function() return and_a_with("reg.c") end
  opcodes[0xA2] = function() return and_a_with("reg.d") end
  opcodes[0xA3] = function() return and_a_with("reg.e") end
  opcodes[0xA4] = function() return and_a_with("reg.h") end
  opcodes[0xA5] = function() return and_a_with("reg.l") end
  opcode_cycles[0xA6] = 8
  opcodes[0xA6] = function() return and_a_with(read_at_hl()) end
  opcodes[0xA7] = function() return [[
    --reg.a = band(reg.a, value)
    flags.z = reg.a == 0
    flags.n = false
    flags.h = true
    flags.c = false
  ]] end

  -- and A, nn
  opcode_cycles[0xE6] = 8
  opcodes[0xE6] = function() return and_a_with(read_nn()) end

  xor_a_with = function(value) return ([[
    reg.a = bxor(reg.a, %s)
    flags.z = reg.a == 0
    flags.n = false
    flags.h = false
    flags.c = false
  ]]):format(value) end

  -- xor A, r
  opcodes[0xA8] = function() return xor_a_with("reg.b") end
  opcodes[0xA9] = function() return xor_a_with("reg.c") end
  opcodes[0xAA] = function() return xor_a_with("reg.d") end
  opcodes[0xAB] = function() return xor_a_with("reg.e") end
  opcodes[0xAC] = function() return xor_a_with("reg.h") end
  opcodes[0xAD] = function() return xor_a_with("reg.l") end
  opcode_cycles[0xAE] = 8
  opcodes[0xAE] = function() return xor_a_with(read_at_hl()) end
  opcodes[0xAF] = function() return [[
    reg.a = 0
    flags.z = true
    flags.n = false
    flags.h = false
    flags.c = false
  ]] end

  -- xor A, nn
  opcode_cycles[0xEE] = 8
  opcodes[0xEE] = function() return xor_a_with(read_nn()) end

  or_a_with = function(value) return ([[
    reg.a = bor(reg.a, %s)
    flags.z = reg.a == 0
    flags.n = false
    flags.h = false
    flags.c = false
  ]]):format(value) end

  -- or A, r
  opcodes[0xB0] = function() return or_a_with("reg.b") end
  opcodes[0xB1] = function() return or_a_with("reg.c") end
  opcodes[0xB2] = function() return or_a_with("reg.d") end
  opcodes[0xB3] = function() return or_a_with("reg.e") end
  opcodes[0xB4] = function() return or_a_with("reg.h") end
  opcodes[0xB5] = function() return or_a_with("reg.l") end
  opcode_cycles[0xB6] = 8
  opcodes[0xB6] = function() return or_a_with(read_at_hl()) end
  opcodes[0xB7] = function() return [[
    flags.z = reg.a == 0
    flags.n = false
    flags.h = false
    flags.c = false
  ]] end

  -- or A, nn
  opcode_cycles[0xF6] = 8
  opcodes[0xF6] = function() return or_a_with(read_nn()) end

  -- cpl
  opcodes[0x2F] = function() return [[
    reg.a = bxor(reg.a, 0xFF)
    flags.n = true
    flags.h = true
  ]] end
end

return apply
