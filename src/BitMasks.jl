module BitMasks

import Base: ~, &, |, xor, isless, ==, in, values, convert, typemax, pairs, iszero, zero, read, write

include("bitmask.jl")
include("operations.jl")

export @bitmask,
       BitMask,
       enabled_flags,
       isatomic,
       combinations,
       combination_pairs,
       print_bitmask_name,
       bitmask_name

end
