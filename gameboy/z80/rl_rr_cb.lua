local bit32 = bit32

local lshift = bit32.lshift
local rshift = bit32.rshift
local band = bit32.band
local bxor = bit32.bxor
local bor = bit32.bor
local bnor = bit32.bnor

function apply(opcodes, opcode_cycles, z80, memory)
  local read_nn = z80.read_nn
  local reg = z80.registers

  -- ====== GMB Rotate and Shift Commands ======
  local reg_rlc = function(value) return ([[do local value = %s
    value = lshift(value, 1)
    -- move what would be bit 8 into the carry
    flags.c = band(value, 0x100) ~= 0
    value = band(value, 0xFF)
    -- also copy the carry into bit 0
    if flags.c then
      value = value + 1
    end
    flags.z = value == 0
    flags.h = false
    flags.n = false
    %s = value
  end
  ]]):format(value, value) end

  local reg_rl = function(value) return ([[do local value = %s
    value = lshift(value, 1)
    -- move the carry into bit 0
    if flags.c then
      value = value + 1
    end
    -- now move what would be bit 8 into the carry
    flags.c = band(value, 0x100) ~= 0
    value = band(value, 0xFF)

    flags.z = value == 0
    flags.h = false
    flags.n = false
    %s = value
  end
  ]]):format(value, value) end

  local reg_rrc = function(value) return ([[do local value = %s
    -- move bit 0 into the carry
    flags.c = band(value, 0x1) ~= 0
    value = rshift(value, 1)
    -- also copy the carry into bit 7
    if flags.c then
      value = value + 0x80
    end
    flags.z = value == 0
    flags.h = false
    flags.n = false
    %s = value
  end
  ]]):format(value, value) end

  local reg_rr = function(value) return ([[do local value = %s
    -- first, copy the carry into bit 8 (!!)
    if flags.c then
      value = value + 0x100
    end
    -- move bit 0 into the carry
    flags.c = band(value, 0x1) ~= 0
    value = rshift(value, 1)
    -- for safety, this should be a nop?
    -- value = band(value, 0xFF)
    flags.z = value == 0
    flags.h = false
    flags.n = false
    %s = value
  end
  ]]):format(value, value) end

  local reg_hl = function(f, c) return ([[do
    local hl = %s
    local v = read_byte(hl)
    %s
    write_byte(hl, v)
    %s
  end
  ]]):format(reg.hl(), f("v"), z80.add_cycles(c)) end

  -- rlc a
  opcodes[0x07] = function() return ("%sflags.z = false\n"):format(reg_rlc("reg.a")) end

  -- rl a
  opcodes[0x17] = function() return ("%sflags.z = false\n"):format(reg_rl("reg.a")) end

  -- rrc a
  opcodes[0x0F] = function() return ("%sflags.z = false\n"):format(reg_rrc("reg.a")) end

  -- rr a
  opcodes[0x1F] = function() return ("%sflags.z = false\n"):format(reg_rr("reg.a")) end

  -- ====== CB: Extended Rotate and Shift ======

  cb = {}

  -- rlc r
  cb[0x00] = function() return ("%s; %s \n"):format(reg_rlc("reg.b"), z80.add_cycles(4)) end
  cb[0x01] = function() return ("%s; %s \n"):format(reg_rlc("reg.c"), z80.add_cycles(4)) end
  cb[0x02] = function() return ("%s; %s \n"):format(reg_rlc("reg.d"), z80.add_cycles(4)) end
  cb[0x03] = function() return ("%s; %s \n"):format(reg_rlc("reg.e"), z80.add_cycles(4)) end
  cb[0x04] = function() return ("%s; %s \n"):format(reg_rlc("reg.h"), z80.add_cycles(4)) end
  cb[0x05] = function() return ("%s; %s \n"):format(reg_rlc("reg.l"), z80.add_cycles(4)) end
  cb[0x06] = function() return reg_hl(reg_rlc, 12) end
  cb[0x07] = function() return ("%s; %s \n"):format(reg_rlc("reg.a"), z80.add_cycles(4)) end

  -- rl r
  cb[0x10] = function() return ("%s; %s \n"):format(reg_rl("reg.b"), z80.add_cycles(4)) end
  cb[0x11] = function() return ("%s; %s \n"):format(reg_rl("reg.c"), z80.add_cycles(4)) end
  cb[0x12] = function() return ("%s; %s \n"):format(reg_rl("reg.d"), z80.add_cycles(4)) end
  cb[0x13] = function() return ("%s; %s \n"):format(reg_rl("reg.e"), z80.add_cycles(4)) end
  cb[0x14] = function() return ("%s; %s \n"):format(reg_rl("reg.h"), z80.add_cycles(4)) end
  cb[0x15] = function() return ("%s; %s \n"):format(reg_rl("reg.l"), z80.add_cycles(4)) end
  cb[0x16] = function() return reg_hl(reg_rl, 12) end
  cb[0x17] = function() return ("%s; %s \n"):format(reg_rl("reg.a"), z80.add_cycles(4)) end

  -- rrc r
  cb[0x08] = function() return ("%s; %s \n"):format(reg_rrc("reg.b"), z80.add_cycles(4)) end
  cb[0x09] = function() return ("%s; %s \n"):format(reg_rrc("reg.c"), z80.add_cycles(4)) end
  cb[0x0A] = function() return ("%s; %s \n"):format(reg_rrc("reg.d"), z80.add_cycles(4)) end
  cb[0x0B] = function() return ("%s; %s \n"):format(reg_rrc("reg.e"), z80.add_cycles(4)) end
  cb[0x0C] = function() return ("%s; %s \n"):format(reg_rrc("reg.h"), z80.add_cycles(4)) end
  cb[0x0D] = function() return ("%s; %s \n"):format(reg_rrc("reg.l"), z80.add_cycles(4)) end
  cb[0x0E] = function() return reg_hl(reg_rrc, 12) end
  cb[0x0F] = function() return ("%s; %s \n"):format(reg_rrc("reg.a"), z80.add_cycles(4)) end

  -- rl r
  cb[0x18] = function() return ("%s; %s \n"):format(reg_rr("reg.b"), z80.add_cycles(4)) end
  cb[0x19] = function() return ("%s; %s \n"):format(reg_rr("reg.c"), z80.add_cycles(4)) end
  cb[0x1A] = function() return ("%s; %s \n"):format(reg_rr("reg.d"), z80.add_cycles(4)) end
  cb[0x1B] = function() return ("%s; %s \n"):format(reg_rr("reg.e"), z80.add_cycles(4)) end
  cb[0x1C] = function() return ("%s; %s \n"):format(reg_rr("reg.h"), z80.add_cycles(4)) end
  cb[0x1D] = function() return ("%s; %s \n"):format(reg_rr("reg.l"), z80.add_cycles(4)) end
  cb[0x1E] = function() return reg_hl(reg_rr, 12) end
  cb[0x1F] = function() return ("%s; %s \n"):format(reg_rr("reg.a"), z80.add_cycles(4)) end

  local reg_sla = function(value) return ([[do local value = %s
    -- copy bit 7 into carry
    flags.c = band(value, 0x80) == 0x80
    value = band(lshift(value, 1), 0xFF)
    flags.z = value == 0
    flags.h = false
    flags.n = false
    %s
    %s = value
  end
  ]]):format(value, z80.add_cycles(4), value) end

  local reg_srl = function(value) return ([[do local value = %s
    -- copy bit 0 into carry
    flags.c = band(value, 0x1) == 1
    value = rshift(value, 1)
    flags.z = value == 0
    flags.h = false
    flags.n = false
    %s
    %s = value
  end
  ]]):format(value, z80.add_cycles(4), value) end

  local reg_sra = function(value) return ([[do local value = %s
    local arith_value = value
    %s
    -- if bit 6 is set, copy it to bit 7
    if band(arith_value, 0x40) ~= 0 then
      arith_value = arith_value + 0x80
    end
    %s
    %s = value
  end
  ]]):format(value, reg_srl("arith_value"), z80.add_cycles(4), value) end

  local reg_swap = function(value) return ([[do local value = %s
    value = rshift(band(value, 0xF0), 4) + lshift(band(value, 0xF), 4)
    flags.z = value == 0
    flags.n = false
    flags.h = false
    flags.c = false
    %s
    %s = value
  end
  ]]):format(value, z80.add_cycles(4), value) end

  -- sla r
  cb[0x20] = function() return ("%s \n"):format(reg_sla("reg.b")) end
  cb[0x21] = function() return ("%s \n"):format(reg_sla("reg.c")) end
  cb[0x22] = function() return ("%s \n"):format(reg_sla("reg.d")) end
  cb[0x23] = function() return ("%s \n"):format(reg_sla("reg.e")) end
  cb[0x24] = function() return ("%s \n"):format(reg_sla("reg.h")) end
  cb[0x25] = function() return ("%s \n"):format(reg_sla("reg.l")) end
  cb[0x26] = function() return reg_hl(reg_sla, 8) end
  cb[0x27] = function() return ("%s \n"):format(reg_sla("reg.a")) end

  -- swap r (high and low nybbles)
  cb[0x30] = function() return ("%s \n"):format(reg_swap("reg.b")) end
  cb[0x31] = function() return ("%s \n"):format(reg_swap("reg.c")) end
  cb[0x32] = function() return ("%s \n"):format(reg_swap("reg.d")) end
  cb[0x33] = function() return ("%s \n"):format(reg_swap("reg.e")) end
  cb[0x34] = function() return ("%s \n"):format(reg_swap("reg.h")) end
  cb[0x35] = function() return ("%s \n"):format(reg_swap("reg.l")) end
  cb[0x36] = function() return reg_hl(reg_swap, 8) end
  cb[0x37] = function() return ("%s \n"):format(reg_swap("reg.a")) end

  -- sra r
  cb[0x28] = function() return ("%s; %s \n"):format(reg_sra("reg.b"), z80.add_cycles(-4)) end
  cb[0x29] = function() return ("%s; %s \n"):format(reg_sra("reg.c"), z80.add_cycles(-4)) end
  cb[0x2A] = function() return ("%s; %s \n"):format(reg_sra("reg.d"), z80.add_cycles(-4)) end
  cb[0x2B] = function() return ("%s; %s \n"):format(reg_sra("reg.e"), z80.add_cycles(-4)) end
  cb[0x2C] = function() return ("%s; %s \n"):format(reg_sra("reg.h"), z80.add_cycles(-4)) end
  cb[0x2D] = function() return ("%s; %s \n"):format(reg_sra("reg.l"), z80.add_cycles(-4)) end
  cb[0x2E] = function() return reg_hl(reg_sra, 4) end
  cb[0x2F] = function() return ("%s; %s \n"):format(reg_sra("reg.a"), z80.add_cycles(-4)) end

  -- srl r
  cb[0x38] = function() return ("%s \n"):format(reg_srl("reg.b")) end
  cb[0x39] = function() return ("%s \n"):format(reg_srl("reg.c")) end
  cb[0x3A] = function() return ("%s \n"):format(reg_srl("reg.d")) end
  cb[0x3B] = function() return ("%s \n"):format(reg_srl("reg.e")) end
  cb[0x3C] = function() return ("%s \n"):format(reg_srl("reg.h")) end
  cb[0x3D] = function() return ("%s \n"):format(reg_srl("reg.l")) end
  cb[0x3E] = function() return reg_hl(reg_srl, 8) end
  cb[0x3F] = function() return ("%s \n"):format(reg_srl("reg.a")) end

  -- ====== GMB Singlebit Operation Commands ======
  local reg_bit = function(value, bit) return ([[
    flags.z = band(%s, 0x%02x) == 0
    flags.n = false
    flags.h = true
  ]]):format(value, lshift(1, bit)) end

  opcodes[0xCB] = function()
    local cb_op = read_nn()
    if cb[cb_op] ~= nil then
      return cb[cb_op]()
    end
    local source = z80.add_cycles(4)
    local high_half_nybble = rshift(band(cb_op, 0xC0), 6)
    local reg_index = band(cb_op, 0x7)
    local bit = rshift(band(cb_op, 0x38), 3)
    if high_half_nybble == 0x1 then
      -- bit n,r
      if reg_index == 0 then source = source .. reg_bit("reg.b", bit) end
      if reg_index == 1 then source = source .. reg_bit("reg.c", bit) end
      if reg_index == 2 then source = source .. reg_bit("reg.d", bit) end
      if reg_index == 3 then source = source .. reg_bit("reg.e", bit) end
      if reg_index == 4 then source = source .. reg_bit("reg.h", bit) end
      if reg_index == 5 then source = source .. reg_bit("reg.l", bit) end
      if reg_index == 6 then source = source .. reg_bit("read_byte(" .. reg.hl() .. ")", bit) .. z80.add_cycles(4) end
      if reg_index == 7 then source = source .. reg_bit("reg.a", bit) end
    end
    if high_half_nybble == 0x2 then
      -- res n, r
      -- note: this is REALLY stupid, but it works around some floating point
      -- limitations in Lua.
      if reg_index == 0 then source = source .. ("reg.b = band(reg.b, bxor(reg.b, 0x%02X))\n"):format(lshift(0x1, bit)) end
      if reg_index == 1 then source = source .. ("reg.c = band(reg.c, bxor(reg.c, 0x%02X))\n"):format(lshift(0x1, bit)) end
      if reg_index == 2 then source = source .. ("reg.d = band(reg.d, bxor(reg.d, 0x%02X))\n"):format(lshift(0x1, bit)) end
      if reg_index == 3 then source = source .. ("reg.e = band(reg.e, bxor(reg.e, 0x%02X))\n"):format(lshift(0x1, bit)) end
      if reg_index == 4 then source = source .. ("reg.h = band(reg.h, bxor(reg.h, 0x%02X))\n"):format(lshift(0x1, bit)) end
      if reg_index == 5 then source = source .. ("reg.l = band(reg.l, bxor(reg.l, 0x%02X))\n"):format(lshift(0x1, bit)) end
      if reg_index == 6 then source = source .. ("do local hl = %s; local b = read_byte(hl); write_byte(hl, band(b, bxor(b, 0x%02X))); %s end\n"):format(reg.hl(), lshift(0x1, bit), z80.add_cycles(8)) end
      if reg_index == 7 then source = source .. ("reg.a = band(reg.a, bxor(reg.a, 0x%02X))\n"):format(lshift(0x1, bit)) end
    end

    if high_half_nybble == 0x3 then
      -- set n, r
      if reg_index == 0 then source = source .. ("reg.b = bor(0x%02X, reg.b)\n"):format(lshift(0x1, bit)) end
      if reg_index == 1 then source = source .. ("reg.c = bor(0x%02X, reg.c)\n"):format(lshift(0x1, bit)) end
      if reg_index == 2 then source = source .. ("reg.d = bor(0x%02X, reg.d)\n"):format(lshift(0x1, bit)) end
      if reg_index == 3 then source = source .. ("reg.e = bor(0x%02X, reg.e)\n"):format(lshift(0x1, bit)) end
      if reg_index == 4 then source = source .. ("reg.h = bor(0x%02X, reg.h)\n"):format(lshift(0x1, bit)) end
      if reg_index == 5 then source = source .. ("reg.l = bor(0x%02X, reg.l)\n"):format(lshift(0x1, bit)) end
      if reg_index == 6 then source = source .. ("do local hl = %s; local b = read_byte(hl); write_byte(hl, bor(0x%02X, b)); %s end\n"):format(reg.hl(), lshift(0x1, bit), z80.add_cycles(8)) end
      if reg_index == 7 then source = source .. ("reg.a = bor(0x%02X, reg.a)\n"):format(lshift(0x1, bit)) end
    end
    return source
  end
end

return apply
