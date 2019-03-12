local bit32 = bit
bit32.lshift = bit.blshift
bit32.rshift = bit.blogic_rshift
bit32.arshift = bit.brshift
function bit32.btest(...) return bit.band(...) ~= 0 end
return bit32