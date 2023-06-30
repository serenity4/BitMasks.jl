# BitMasks

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://serenity4.github.io/BitMasks.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://serenity4.github.io/BitMasks.jl/dev/)
[![Build Status](https://github.com/serenity4/BitMasks.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/serenity4/BitMasks.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/serenity4/BitMasks.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/serenity4/BitMasks.jl)
[![ColPrac: Contributor's Guide on Collaborative Practices for Community Packages](https://img.shields.io/badge/ColPrac-Contributor's%20Guide-blueviolet)](https://github.com/SciML/ColPrac)

Lightweight package with zero dependencies aimed at manipulating BitMasks using an `@enum` like interface. BitMasks are combinations of boolean flags encoded as specific bits of an integer type. For example, 8 flags can be represented with a `UInt8`, from `0b1000000` to `0b00000001`. A bitmask instance could then have a value of `0b10101101` in this case.

This package provides a way to define BitMasks from flag values and mask presets, and operators to manipulate them. First, you can create a bitmask type with

```julia
julia> using BitMasks

julia> @bitmask Mask::UInt32 begin
  # Flags.
  BIT_A = 1
  BIT_B = 2
  BIT_C = 4

  # Mask presets.
  BIT_AB = BIT_A | BIT_B
  BIT_BC = BIT_B | BIT_C
  BIT_ABC = BIT_A | BIT_B | BIT_C
end
Mask
```

Mask presets are optional, but can be handy to group parameters especially when specific masks have a strong semantic meaning or when the number of flags is very large. The right-hand sides of the `=` assignments are required to be integer literals at the moment.

It is also possible to combine flags or masks to create new masks, for example

```julia
julia> BIT_A | BIT_C
Mask(BIT_A | BIT_C)

julia> BIT_A | BIT_B
Mask(BIT_AB)

julia> ~BIT_A
Mask(BIT_BC)

julia> BIT_BC ⊻ BIT_AB
Mask(BIT_A | BIT_C)

julia> BIT_BC & BIT_C
Mask(BIT_C)
```

where `|` performs the union of different flags or masks, `&` their intersection, `~` their complement and `xor` the complement of their intersection. Note that `|` should be read as `and` instead of `or` from a semantic perspective.

You will have noticed that a specific printing is defined which will try to compact all combinations based on the provided presets to reduce verbosity.

Other utilities are defined, such as the extraction of all flags from a mask, conversion to/from integers and bits of extra type safety to avoid mixing flags coming from different masks:

```julia
julia> enabled_flags(BIT_ABC)
3-element Vector{Mask}:
 Mask(BIT_A)
 Mask(BIT_B)
 Mask(BIT_C)

julia> Int(BIT_A)
1

julia> Mask(1)
Mask(BIT_A)

julia> @bitmask Mask2::UInt32 begin
         BIT_A_2 = 1
         BIT_B_2 = 2
         BIT_AB_2 = BIT_A_2 | BIT_B_2
       end
Mask2

julia> BIT_A | BIT_B_2
ERROR: Bitwise operation not allowed between incompatible BitMasks 'Mask', 'Mask2'
```

Finally, a few common `Base` methods were added for convenience:

```julia
julia> zero(Mask)
Mask()

julia> iszero(zero(Mask))
true

julia> typemax(Mask)
Mask(BIT_ABC)
```

You can also choose to export all defined symbols (and the defined type) with the parameter `export = true` (which is `false` by default):
```julia
@bitmask exported = true Mask3::UInt32 begin
    BIT_A_3 = 1
    BIT_B_3 = 2
    BIT_AB_3 = BIT_A_3 | BIT_B_3
  end
```

### Related packages

This package aims to be relatively simple and designed to work with integers only. Similar packages with slightly different feature sets include:
- [FlagSets.jl](https://github.com/jessymilare/FlagSets.jl)
- [BitFlags.jl](https://github.com/jmert/BitFlags.jl)
