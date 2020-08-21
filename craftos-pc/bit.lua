local bit32 = {}
function bit32.band(a, b, ...) if #{...} == 0 then return bit.band(a, b) else return bit.band(bit32.band(b, ...), a) end end
function bit32.bor(a, b, ...) if #{...} == 0 then return bit.bor(a, b) else return bit.bor(bit32.bor(b, ...), a) end end
function bit32.bxor(a, b, ...) if #{...} == 0 then return bit.bxor(a, b) else return bit.bxor(bit32.bxor(b, ...), a) end end
bit32.bnot = bit.bnot
bit32.lshift = bit.blshift
bit32.rshift = bit.blogic_rshift
bit32.arshift = bit.brshift
function bit32.bnor(...) return bit.bnot(bit32.bor(...)) end
function bit32.btest(...) return bit32..band(...) ~= 0 end
return bit32