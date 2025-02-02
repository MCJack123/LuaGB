local bit32 = bit32

function apply(opcodes, opcode_cycles, z80, memory)
  -- push BC
  opcode_cycles[0xC5] = 16
  opcodes[0xC5] = function() return [[
    reg.sp = band(0xFFFF, reg.sp - 1)
    write_byte(reg.sp, reg.b)
    reg.sp = band(0xFFFF, reg.sp - 1)
    write_byte(reg.sp, reg.c)
  ]] end

  -- push DE
  opcode_cycles[0xD5] = 16
  opcodes[0xD5] = function() return [[
    reg.sp = band(0xFFFF, reg.sp - 1)
    write_byte(reg.sp, reg.d)
    reg.sp = band(0xFFFF, reg.sp - 1)
    write_byte(reg.sp, reg.e)
  ]] end

  -- push HL
  opcode_cycles[0xE5] = 16
  opcodes[0xE5] = function() return [[
    reg.sp = band(0xFFFF, reg.sp - 1)
    write_byte(reg.sp, reg.h)
    reg.sp = band(0xFFFF, reg.sp - 1)
    write_byte(reg.sp, reg.l)
  ]] end

  -- push AF
  opcode_cycles[0xF5] = 16
  opcodes[0xF5] = function() return [[
    reg.sp = band(0xFFFF, reg.sp - 1)
    write_byte(reg.sp, reg.a)
    reg.sp = band(0xFFFF, reg.sp - 1)
    write_byte(reg.sp, reg.f())
  ]] end

  -- pop BC
  opcode_cycles[0xC1] = 12
  opcodes[0xC1] = function() return [[
    reg.c = read_byte(reg.sp)
    reg.sp = band(0xFFFF, reg.sp + 1)
    reg.b = read_byte(reg.sp)
    reg.sp = band(0xFFFF, reg.sp + 1)
  ]] end

  -- pop DE
  opcode_cycles[0xD1] = 12
  opcodes[0xD1] = function() return [[
    reg.e = read_byte(reg.sp)
    reg.sp = band(0xFFFF, reg.sp + 1)
    reg.d = read_byte(reg.sp)
    reg.sp = band(0xFFFF, reg.sp + 1)
  ]] end

  -- pop HL
  opcode_cycles[0xE1] = 12
  opcodes[0xE1] = function() return [[
    reg.l = read_byte(reg.sp)
    reg.sp = band(0xFFFF, reg.sp + 1)
    reg.h = read_byte(reg.sp)
    reg.sp = band(0xFFFF, reg.sp + 1)
  ]] end

  -- pop AF
  opcode_cycles[0xF1] = 12
  opcodes[0xF1] = function() return [[
    reg.set_f(read_byte(reg.sp))
    reg.sp = band(0xFFFF, reg.sp + 1)
    reg.a = read_byte(reg.sp)
    reg.sp = band(0xFFFF, reg.sp + 1)
  ]] end
end

return apply
