local bit32 = bit32

local lshift = bit32.lshift

function apply(opcodes, opcode_cycles, z80, memory)
  local read_nn = z80.read_nn
  local reg = z80.registers

  -- ====== GMB Jumpcommands ======
  local jump_to_nnnn = function()
    local lower = read_nn()
    local upper = lshift(read_nn(), 8)
    return ("return z80.jit[0x%04X]()"):format(upper + lower)
  end

  -- jp nnnn
  opcode_cycles[0xC3] = 16
  opcodes[0xC3] = function()
    return jump_to_nnnn(), true
  end

  -- jp HL
  opcodes[0xE9] = function()
    return ("return z80.jit[%s]()"):format(reg.hl()), true
  end

  -- jp nz, nnnn
  opcode_cycles[0xC2] = 16
  opcodes[0xC2] = function() return ([[
    if not flags.z then
      %s
    else
      %s
    end
  ]]):format(jump_to_nnnn(), z80.add_cycles(-4)) end

  -- jp nc, nnnn
  opcode_cycles[0xD2] = 16
  opcodes[0xD2] = function() return ([[
    if not flags.c then
      %s
    else
      %s
    end
  ]]):format(jump_to_nnnn(), z80.add_cycles(-4)) end

  -- jp z, nnnn
  opcode_cycles[0xCA] = 16
  opcodes[0xCA] = function() return ([[
    if flags.z then
      %s
    else
      %s
    end
  ]]):format(jump_to_nnnn(), z80.add_cycles(-4)) end

  -- jp c, nnnn
  opcode_cycles[0xDA] = 16
  opcodes[0xDA] = function() return ([[
    if flags.c then
      %s
    else
      %s
    end
  ]]):format(jump_to_nnnn(), z80.add_cycles(-4)) end

  local function jump_relative_to_nn()
    local offset = read_nn()
    if offset > 127 then
      offset = offset - 256
    end
    return ("return z80.jit[0x%04X]()"):format((reg.pc + offset) % 0x10000)
  end

  -- jr nn
  opcode_cycles[0x18] = 12
  opcodes[0x18] = function()
    return jump_relative_to_nn(), true
  end

  -- jr nz, nn
  opcode_cycles[0x20] = 12
  opcodes[0x20] = function() return ([[
    if not flags.z then
      %s
    else
      %s
    end
  ]]):format(jump_relative_to_nn(), z80.add_cycles(-4)) end

  -- jr nc, nn
  opcode_cycles[0x30] = 12
  opcodes[0x30] = function() return ([[
    if not flags.c then
      %s
    else
      %s
    end
  ]]):format(jump_relative_to_nn(), z80.add_cycles(-4)) end

  -- jr z, nn
  opcode_cycles[0x28] = 12
  opcodes[0x28] = function() return ([[
    if flags.z then
      %s
    else
      %s
    end
  ]]):format(jump_relative_to_nn(), z80.add_cycles(-4)) end

  -- jr c, nn
  opcode_cycles[0x38] = 12
  opcodes[0x38] = function() return ([[
    if flags.c then
      %s
    else
      %s
    end
  ]]):format(jump_relative_to_nn(), z80.add_cycles(-4)) end
end

return apply
