module Bitmasks

import Base: ~, &, |, xor, isless, ==, in, values, convert, typemax, pairs, iszero, zero, read

include("bitmask.jl")
include("operations.jl")

export @bitmask, enabled_flags, isatomic, combinations, combination_pairs

end
