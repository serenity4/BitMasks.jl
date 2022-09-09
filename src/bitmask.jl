abstract type BitMask{T<:Unsigned} end

Base.broadcastable(x::BitMask) = Ref(x)

function generate_bitmask_flag(type, decl)
  identifier, value = decl.args
  :(const $identifier = $type($value))
end

function combinations end
function combination_pairs end

"""
    @bitmask BitFlags::UInt32 begin
        FLAG_A = 1
        FLAG_B = 2
        FLAG_C = 4
    end

Enumeration of bitmask flags that can be combined with `&`, `|` and `xor`, forbidding the combination of flags from different bitmasks.
"""
macro bitmask(typedecl, expr)
  Meta.isexpr(typedecl, :(::), 2) || error("The first argument to @bitmask must be of the form 'type::eltype', got $typedecl")
  type, eltype = typedecl.args
  if !Meta.isexpr(expr, :block)
    expr = Expr(:block, expr)
  end
  decls = filter(x -> typeof(x) ≠ LineNumberNode, expr.args)
  etype = esc(type)
  pairs = Expr[]
  combination_pairs = Expr[]
  for decl in decls
    (identifier, value) = decl.args
    isa(value, Integer) || error("Expected integer value on the right-hand side, got $value.")
    dest = !iszero(log2(Int(value)) % 1.0) && !iszero(value) ? combination_pairs : pairs
    push!(dest, :($(QuoteNode(identifier)) => $etype($value)))
  end
  values = [last(pair.args) for pair in pairs]
  combinations = [last(pair.args) for pair in combination_pairs]

  ex = quote
    Base.@__doc__ struct $type <: BitMask{$eltype}
      val::$eltype
    end
    $(esc.(generate_bitmask_flag.(type, decls))...)
    Base.values(::Type{$etype}) = [$(values...)]
    Base.pairs(::Type{$etype}) = [$(pairs...)]
    $(@__MODULE__()).combinations(::Type{$etype}) = [$(combinations...)]
    $(@__MODULE__()).combination_pairs(::Type{$etype}) = [$(combination_pairs...)]
    $etype
  end

  ex
end

function Base.show(io::IO, mask::T) where {T<:BitMask}
  print(io, nameof(T), '(')
  init = mask
  first = true

  # Compact built-in combinations of flags.
  for (name, c) in reverse(combination_pairs(T))
    if in(c, mask) && !iszero(c)
      !first && print(io, " | ")
      first = false
      print(io, name)
      mask &= ~c
    end
  end

  # Print atomic flags.
  for (name, flag) in pairs(T)
    if in(flag, mask) && (!iszero(flag) || iszero(init))
      !first && print(io, " | ")
      first = false
      mask &= ~flag
      print(io, name)
    end
    iszero(mask) && iszero(flag) && break
  end

  print(io, ')')
end
