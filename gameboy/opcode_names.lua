function generate()
opcode_names = {}

opcode_names[0x00] = "nop"
opcode_names[0x01] = "ld BC, d16"
opcode_names[0x02] = "ld (BC), A"
opcode_names[0x03] = "inc BC"
opcode_names[0x04] = "inc B"
opcode_names[0x05] = "dec B"
opcode_names[0x06] = "ld B, d8"
opcode_names[0x07] = "rlca"
opcode_names[0x08] = "ld (a16), SP"
opcode_names[0x09] = "add HL, BC"
opcode_names[0x0A] = "ld A, (BC)"
opcode_names[0x0B] = "dec BC"
opcode_names[0x0C] = "inc C"
opcode_names[0x0D] = "dec C"
opcode_names[0x0E] = "ld C, d8"
opcode_names[0x0F] = "rrca"

opcode_names[0x10] = "STOP d8" -- Should ALWAYS be followed by 0x00
opcode_names[0x11] = "ld DE, d16"
opcode_names[0x12] = "ld (DE), A"
opcode_names[0x13] = "inc DE"
opcode_names[0x14] = "inc D"
opcode_names[0x15] = "dec D"
opcode_names[0x16] = "ld D, d8"
opcode_names[0x17] = "rla"
opcode_names[0x18] = "jr r8"
opcode_names[0x19] = "add HL, DE"
opcode_names[0x1A] = "ld A, (DE)"
opcode_names[0x1B] = "dec DE"
opcode_names[0x1C] = "inc E"
opcode_names[0x1D] = "dec E"
opcode_names[0x1E] = "ld E, d8"
opcode_names[0x1F] = "rra"

opcode_names[0x20] = "jr NZ, r8"
opcode_names[0x21] = "ld HL, d16"
opcode_names[0x22] = "ld (HL+), A"
opcode_names[0x23] = "inc HL"
opcode_names[0x24] = "inc H"
opcode_names[0x25] = "dec H"
opcode_names[0x26] = "ld H, d8"
opcode_names[0x27] = "dda"
opcode_names[0x28] = "jr Z, r8"
opcode_names[0x29] = "add HL, HL"
opcode_names[0x2A] = "ld A, (HL+)"
opcode_names[0x2B] = "dec HL"
opcode_names[0x2C] = "inc L"
opcode_names[0x2D] = "dec L"
opcode_names[0x2E] = "ld L, d8"
opcode_names[0x2F] = "cpl"

opcode_names[0x30] = "jr NC, r8"
opcode_names[0x31] = "ld SP, d16"
opcode_names[0x32] = "ld (HL-), A"
opcode_names[0x33] = "inc SP"
opcode_names[0x34] = "inc (HL)"
opcode_names[0x35] = "dec (HL)"
opcode_names[0x36] = "ld (HL), d8"
opcode_names[0x37] = "scf"
opcode_names[0x38] = "jr C, r8"
opcode_names[0x39] = "add HL, SP"
opcode_names[0x3A] = "ld A, (HL-)"
opcode_names[0x3B] = "dec SP"
opcode_names[0x3C] = "inc A"
opcode_names[0x3D] = "dec A"
opcode_names[0x3E] = "ld A, d8"
opcode_names[0x3F] = "ccf"

opcode_names[0x40] = "ld B, B"
opcode_names[0x41] = "ld B, C"
opcode_names[0x42] = "ld B, D"
opcode_names[0x43] = "ld B, E"
opcode_names[0x44] = "ld B, H"
opcode_names[0x45] = "ld B, L"
opcode_names[0x46] = "ld B, (HL)"
opcode_names[0x47] = "ld B, A"
opcode_names[0x48] = "ld C, B"
opcode_names[0x49] = "ld C, C"
opcode_names[0x4A] = "ld C, D"
opcode_names[0x4B] = "ld C, E"
opcode_names[0x4C] = "ld C, H"
opcode_names[0x4D] = "ld C, L"
opcode_names[0x4E] = "ld C, (HL)"
opcode_names[0x4F] = "ld C, A"

opcode_names[0x50] = "ld D, B"
opcode_names[0x51] = "ld D, C"
opcode_names[0x52] = "ld D, D"
opcode_names[0x53] = "ld D, E"
opcode_names[0x54] = "ld D, H"
opcode_names[0x55] = "ld D, L"
opcode_names[0x56] = "ld D, (HL)"
opcode_names[0x57] = "ld D, A"
opcode_names[0x58] = "ld E, B"
opcode_names[0x59] = "ld E, C"
opcode_names[0x5A] = "ld E, D"
opcode_names[0x5B] = "ld E, E"
opcode_names[0x5C] = "ld E, H"
opcode_names[0x5D] = "ld E, L"
opcode_names[0x5E] = "ld E, (HL)"
opcode_names[0x5F] = "ld E, A"

opcode_names[0x60] = "ld H, B"
opcode_names[0x61] = "ld H, C"
opcode_names[0x62] = "ld H, D"
opcode_names[0x63] = "ld H, E"
opcode_names[0x64] = "ld H, H"
opcode_names[0x65] = "ld H, L"
opcode_names[0x66] = "ld H, (HL)"
opcode_names[0x67] = "ld H, A"
opcode_names[0x68] = "ld L, B"
opcode_names[0x69] = "ld L, C"
opcode_names[0x6A] = "ld L, D"
opcode_names[0x6B] = "ld L, E"
opcode_names[0x6C] = "ld L, H"
opcode_names[0x6D] = "ld L, L"
opcode_names[0x6E] = "ld L, (HL)"
opcode_names[0x6F] = "ld L, A"

opcode_names[0x70] = "ld (HL), B"
opcode_names[0x71] = "ld (HL), C"
opcode_names[0x72] = "ld (HL), D"
opcode_names[0x73] = "ld (HL), E"
opcode_names[0x74] = "ld (HL), H"
opcode_names[0x75] = "ld (HL), L"
opcode_names[0x76] = "halt"
opcode_names[0x77] = "ld (HL), A"
opcode_names[0x78] = "ld A, B"
opcode_names[0x79] = "ld A, C"
opcode_names[0x7A] = "ld A, D"
opcode_names[0x7B] = "ld A, E"
opcode_names[0x7C] = "ld A, H"
opcode_names[0x7D] = "ld A, L"
opcode_names[0x7E] = "ld A, (HL)"
opcode_names[0x7F] = "ld A, A"

opcode_names[0x80] = "add A, B"
opcode_names[0x81] = "add A, C"
opcode_names[0x82] = "add A, D"
opcode_names[0x83] = "add A, E"
opcode_names[0x84] = "add A, H"
opcode_names[0x85] = "add A, L"
opcode_names[0x86] = "add A, (HL)"
opcode_names[0x87] = "add A, A"
opcode_names[0x88] = "adc A, B"
opcode_names[0x89] = "adc A, C"
opcode_names[0x8A] = "adc A, D"
opcode_names[0x8B] = "adc A, E"
opcode_names[0x8C] = "adc A, H"
opcode_names[0x8D] = "adc A, L"
opcode_names[0x8E] = "adc A, (HL)"
opcode_names[0x8F] = "adc A, A"

opcode_names[0x90] = "sub B"
opcode_names[0x91] = "sub C"
opcode_names[0x92] = "sub D"
opcode_names[0x93] = "sub E"
opcode_names[0x94] = "sub H"
opcode_names[0x95] = "sub L"
opcode_names[0x96] = "sub (HL)"
opcode_names[0x97] = "sub A"
opcode_names[0x98] = "sbc A, B"
opcode_names[0x99] = "sbc A, C"
opcode_names[0x9A] = "sbc A, D"
opcode_names[0x9B] = "sbc A, E"
opcode_names[0x9C] = "sbc A, H"
opcode_names[0x9D] = "sbc A, L"
opcode_names[0x9E] = "sbc A, (HL)"
opcode_names[0x9F] = "sbc A, A"

opcode_names[0xA0] = "and B"
opcode_names[0xA1] = "and C"
opcode_names[0xA2] = "and D"
opcode_names[0xA3] = "and E"
opcode_names[0xA4] = "and H"
opcode_names[0xA5] = "and L"
opcode_names[0xA6] = "and (HL)"
opcode_names[0xA7] = "and A"
opcode_names[0xA8] = "xor B"
opcode_names[0xA9] = "xor C"
opcode_names[0xAA] = "xor D"
opcode_names[0xAB] = "xor E"
opcode_names[0xAC] = "xor H"
opcode_names[0xAD] = "xor L"
opcode_names[0xAE] = "xor (HL)"
opcode_names[0xAF] = "xor A"

opcode_names[0xB0] = "or B"
opcode_names[0xB1] = "or C"
opcode_names[0xB2] = "or D"
opcode_names[0xB3] = "or E"
opcode_names[0xB4] = "or H"
opcode_names[0xB5] = "or L"
opcode_names[0xB6] = "or (HL)"
opcode_names[0xB7] = "or A"
opcode_names[0xB8] = "cp B"
opcode_names[0xB9] = "cp C"
opcode_names[0xBA] = "cp D"
opcode_names[0xBB] = "cp E"
opcode_names[0xBC] = "cp H"
opcode_names[0xBD] = "cp L"
opcode_names[0xBE] = "cp (HL)"
opcode_names[0xBF] = "cp A"

opcode_names[0xC0] = "ret NZ"
opcode_names[0xC1] = "pop BC"
opcode_names[0xC2] = "jp NZ, a16"
opcode_names[0xC3] = "jp a16"
opcode_names[0xC4] = "call NZ, a16"
opcode_names[0xC5] = "push BC"
opcode_names[0xC6] = "add A, d8"
opcode_names[0xC7] = "rst 0x00"
opcode_names[0xC8] = "ret Z"
opcode_names[0xC9] = "ret"
opcode_names[0xCA] = "jp Z, a16"
opcode_names[0xCB] = "xCB d8"
opcode_names[0xCC] = "call Z, a16"
opcode_names[0xCD] = "call a16"
opcode_names[0xCE] = "adc A, d8"
opcode_names[0xCF] = "rst 0x08"

opcode_names[0xD0] = "ret NC"
opcode_names[0xD1] = "pop DE"
opcode_names[0xD2] = "jp NC, a16"
opcode_names[0xD3] = "-- undefined --"
opcode_names[0xD4] = "call NC, a16"
opcode_names[0xD5] = "push DE"
opcode_names[0xD6] = "sub d8"
opcode_names[0xD7] = "rst 0x10"
opcode_names[0xD8] = "ret C"
opcode_names[0xD9] = "reti"
opcode_names[0xDA] = "jp C, a16"
opcode_names[0xDB] = "-- undefined --"
opcode_names[0xDC] = "call C, a16"
opcode_names[0xDD] = "-- undefined --"
opcode_names[0xDE] = "sbc A, d8"
opcode_names[0xDF] = "rst 0x18"

opcode_names[0xE0] = "ldh (a8), A"
opcode_names[0xE1] = "pop HL"
opcode_names[0xE2] = "ld (C), A"
opcode_names[0xE3] = "-- undefined --"
opcode_names[0xE4] = "-- undefined --"
opcode_names[0xE5] = "push HL"
opcode_names[0xE6] = "and d8"
opcode_names[0xE7] = "rst 0x20"
opcode_names[0xE8] = "add SP, r8"
opcode_names[0xE9] = "jp HL"
opcode_names[0xEA] = "ld (a16), A"
opcode_names[0xEB] = "-- undefined --"
opcode_names[0xEC] = "-- undefined --"
opcode_names[0xED] = "-- undefined --"
opcode_names[0xEE] = "xor d8"
opcode_names[0xEF] = "rst 0x28"

opcode_names[0xF0] = "ldh A, (a8)"
opcode_names[0xF1] = "pop AF"
opcode_names[0xF2] = "ld (C), A"
opcode_names[0xF3] = "di"
opcode_names[0xF4] = "-- undefined --"
opcode_names[0xF5] = "push AF"
opcode_names[0xF6] = "or d8"
opcode_names[0xF7] = "rst 0x30"
opcode_names[0xF8] = "ld HL, SP + r8"
opcode_names[0xF9] = "ld SP, HL"
opcode_names[0xFA] = "ld A, (a16)"
opcode_names[0xFB] = "ei"
opcode_names[0xFC] = "-- undefined --"
opcode_names[0xFD] = "-- undefined --"
opcode_names[0xFE] = "cp d8"
opcode_names[0xFF] = "rst 0x38"

_G.opcode_names = opcode_names
_ENV.opcode_names = opcode_names

return opcode_names
end

return generate
