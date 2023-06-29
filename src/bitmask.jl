abstract type BitMask{T<:Unsigned} end

Base.broadcastable(x::BitMask) = Ref(x)

function generate_bitmask_flag(type, decl)
  if has_docstring(decl)
    identifier, value = docstring_operand(decl).args
    Expr(:macrocall, decl.args[1], decl.args[2], decl.args[3], :(const $identifier = $type($value)))
  else
    identifier, value = decl.args
    :(const $identifier = $type($value))
  end
end

"""
    combinations(T::Type{<:BitMask})

Return a vector of values of type `T` that do not define a new flag, but rather define combinations of flags.
"""
function combinations end

"""
    combination_pairs(T::Type{<:BitMask})

Return a vector of `name => combination::T` pairs for all values of type `T` that that do not define a new flag, but rather define combinations of flags.

See also: [`combinations`](@ref)
"""
function combination_pairs end

"""
    @bitmask [exported = false] BitFlags::UInt32 begin
        FLAG_A = 1
        FLAG_B = 2
        FLAG_C = 4
    end

Enumeration of bitmask flags that can be combined with `&`, `|` and `xor`, forbidding the combination of flags from different BitMasks.

If `exported` is set to true with a first argument of the form `exported = <false|true>`, then all the values and the defined type will be exported.
"""
macro bitmask(typedecl, expr) generate_bitmask(typedecl, expr, :(exported = false)) end
macro bitmask(exported, typedecl, expr) generate_bitmask(typedecl, expr, exported) end

has_docstring(ex) = Meta.isexpr(ex, :macrocall) && ex.args[1] == Core.GlobalRef(Core, Symbol("@doc"))
docstring_operand(ex::Expr) = ex.args[4]

function generate_bitmask(typedecl, expr, exported)
  Meta.isexpr(typedecl, :(::), 2) || error("The first argument to @bitmask must be of the form 'type::eltype', got $typedecl")
  exported = Meta.isexpr(exported, :(=)) && isa(exported.args[2], Bool) ? exported.args[2]::Bool : error("Expected option `exported = <false|true>`, got $(repr(exported))")
  type, eltype = typedecl.args
  if !Meta.isexpr(expr, :block)
    expr = Expr(:block, expr)
  end
  decls = filter(x -> typeof(x) ≠ LineNumberNode, expr.args)
  etype = esc(type)
  pairs = Expr[]
  combination_pairs = Expr[]
  definitions = Expr[]
  for decl in decls
    push!(definitions, decl)
    has_docstring(decl) && (decl = docstring_operand(decl))
    (identifier, value) = decl.args
    isa(value, Integer) || error("Expected integer value on the right-hand side, got $value.")
    dest = !iszero(log2(UInt64(value)) % 1.0) && !iszero(value) ? combination_pairs : pairs
    push!(dest, :($(QuoteNode(identifier)) => $etype($value)))
  end
  values = [last(pair.args) for pair in pairs]
  combinations = [last(pair.args) for pair in combination_pairs]

  ex = quote
    Base.@__doc__ struct $type <: BitMask{$eltype}
      val::$eltype
    end
    $(esc.(generate_bitmask_flag.(type, definitions))...)
    Base.values(::Type{$etype}) = [$(values...)]
    Base.pairs(::Type{$etype}) = [$(pairs...)]
    $(@__MODULE__()).combinations(::Type{$etype}) = [$(combinations...)]
    $(@__MODULE__()).combination_pairs(::Type{$etype}) = [$(combination_pairs...)]
  end

  if exported
    exp = Expr(:export, type)
    append!(exp.args, [pair.args[2].value::Symbol for pair in pairs])
    append!(exp.args, [pair.args[2].value::Symbol for pair in combination_pairs])
    push!(ex.args, exp)
  end
  push!(ex.args, etype)

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
