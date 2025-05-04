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
        FLAG_C = 2^2 # == 4 (if you didn't know)
        FLAG_AB = FLAG_A | FLAG_B
    end

    @bitmask [exported = false] BitFlags::UInt32 begin
        FLAG_A = 1
        FLAG_B # unspecified, will have the mask after 0x01, i.e. 0x02.
        FLAG_C = 4
        FLAG_AB = FLAG_A | FLAG_B
    end

Enumeration of bitmask flags that can be combined with `&`, `|` and `xor`, forbidding the combination of flags from different BitMasks.

If `exported` is set to true with a first argument of the form `exported = <false|true>`, then all the values and the defined type will be exported.

If a flag is left unspecified, it will inherit the value after the previous declaration that is not a combination of other flags.

!!! warn
    If there are any unspecified flags, all non-combination values should be declared in an ascending order to guarantee that the
    flags generated automatically will not alias another one.
"""
macro bitmask(typedecl, expr) generate_bitmask(typedecl, expr, :(exported = false)) end
macro bitmask(exported, typedecl, expr) generate_bitmask(typedecl, expr, exported) end

has_docstring(ex) = Meta.isexpr(ex, :macrocall) && ex.args[1] == Core.GlobalRef(Core, Symbol("@doc"))
docstring_operand(ex::Expr) = ex.args[4]

function generate_bitmask(typedecl, expr, exported)
  Meta.isexpr(typedecl, :(::), 2) || error("The first argument to @bitmask must be of the form 'type::eltype', got $typedecl")
  exported = Meta.isexpr(exported, :(=)) && isa(exported.args[2], Bool) ? exported.args[2]::Bool : error("Expected option `exported = <false|true>`, got $(repr(exported))")
  type, eltype = typedecl.args
  eltype = esc(eltype)
  if !Meta.isexpr(expr, :block)
    expr = Expr(:block, expr)
  end
  decls = filter(x -> typeof(x) ≠ LineNumberNode, expr.args)
  etype = esc(type)
  pairs = Expr[]
  combination_pairs = Expr[]
  definitions = Expr[]
  previous = nothing
  for decl in decls
    docstring = nothing
    if has_docstring(decl)
      docstring = copy(decl)
      decl = docstring_operand(decl)
    end
    if isa(decl, Symbol)
      identifier = decl
      value = previous === nothing ? 1 : :($next_flag($previous))
      previous = identifier
      dest = pairs
    else
      Meta.isexpr(decl, :(=)) || throw(ArgumentError("Expected assignment or symbol expression, got $decl"))
      (identifier, value) = decl.args
      if !isa(value, Integer) || !iszero(log2(UInt64(value)) % 1.0) && !iszero(value)
        dest = combination_pairs
      else
        previous = identifier
        dest = pairs
      end
    end
    if docstring === nothing
      decl = :($identifier = $value)
    else
      docstring.args[4] = :($identifier = $value)
      decl = docstring
    end
    push!(definitions, decl)
    push!(dest, :($(QuoteNode(identifier)) => $etype($(esc(value)))))
  end
  values = [last(pair.args) for pair in pairs]
  combinations = [last(pair.args) for pair in combination_pairs]

  ex = quote
    Base.@__doc__ struct $type <: BitMask{$eltype}
      val::$eltype
    end
    $(esc(:($type(x::$type) = x)))
    $(esc.(generate_bitmask_flag.(type, definitions))...)
    Base.values(::Type{$etype}) = [$(values...)]
    Base.instances(::Type{$etype}) = Base.values($etype)
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

function next_flag(prev::BitMask{T}) where {T}
  flag = prev.val
  flag === typemax(T) && error("Integer overflow detected while generating a flag after $prev")
  flag << 1
end

function print_bitmask_name(io::IO, mask::T) where {T<:BitMask}
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
end

function Base.show(io::IO, mask::T) where {T<:BitMask}
  print(io, nameof(T), '(')
  print_bitmask_name(io, mask)
  print(io, ')')
end

bitmask_name(mask::BitMask) = sprint(print_bitmask_name, mask)
