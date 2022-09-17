read(io::IO, T::Type{<:BitMask{_T}}) where {_T} = T(read(io, _T))

iszero(a::BitMask) = iszero(a.val)
zero(a::T) where {T<:BitMask} = zero(T)
zero(T::Type{<:BitMask{U}}) where {U} = T(zero(U))
(~)(a::T) where {T<:BitMask} = T(~a.val)

(&)(a::BitMask, b::BitMask) = error("Bitwise operation not allowed between incompatible BitMasks '$(typeof(a))', '$(typeof(b))'")
(|)(a::BitMask, b::BitMask) = error("Bitwise operation not allowed between incompatible BitMasks '$(typeof(a))', '$(typeof(b))'")
xor(a::BitMask, b::BitMask) = error("Bitwise operation not allowed between incompatible BitMasks '$(typeof(a))', '$(typeof(b))'")
isless(a::BitMask, b::BitMask) = error("Bitwise operation not allowed between incompatible BitMasks '$(typeof(a))', '$(typeof(b))'")
(==)(a::BitMask, b::BitMask) = error("Operation not allowed between incompatible BitMasks '$(typeof(a))', '$(typeof(b))'")
in(a::BitMask, b::BitMask) = error("Operation not allowed between incompatible BitMasks '$(typeof(a))', '$(typeof(b))'")

(&)(a::T, b::T) where {T<:BitMask} = T(a.val & b.val)
(|)(a::T, b::T) where {T<:BitMask} = T(a.val | b.val)
xor(a::T, b::T) where {T<:BitMask} = T(xor(a.val, b.val))
isless(a::T, b::T) where {T<:BitMask} = isless(a.val, b.val)
(==)(a::T, b::T) where {T<:BitMask} = a.val == b.val
in(a::T, b::T) where {T<:BitMask} = a & b == a

(&)(a::T, b::Integer) where {T<:BitMask} = T(a.val & b)
(|)(a::T, b::Integer) where {T<:BitMask} = T(a.val | b)
xor(a::T, b::Integer) where {T<:BitMask} = T(xor(a.val, b))
isless(a::T, b::Integer) where {T<:BitMask} = isless(a.val, b)
in(a::T, b::Integer) where {T<:BitMask} = a & b == a

(&)(a::Integer, b::T) where {T<:BitMask} = b & a
(|)(a::Integer, b::T) where {T<:BitMask} = b | a
xor(a::Integer, b::T) where {T<:BitMask} = xor(b, a)
isless(a::Integer, b::T) where {T<:BitMask} = isless(a, b.val) # need b.val to prevent stackoverflow
in(a::Integer, b::T) where {T<:BitMask} = a | b == b

(::Type{T})(bm::BitMask) where {T<:Integer} = T(bm.val)

convert(T::Type{<:Integer}, bm::BitMask) = T(bm.val)
convert(T::Type{<:BitMask}, val::Integer) = T(val)

typemax(T::Type{<:BitMask{_T}}) where {_T} = T(typemax(_T))

isatomic(mask::BitMask) = isinteger(log2(mask.val)) || iszero(mask)

"""
Return the bitmask flags present in `mask`; that is, all the `BitMask` flags for which `in(flag, mask)`.
"""
function enabled_flags(mask::T) where {T<:BitMask}
  res = T[]
  for flag in values(T)
    iszero(mask) && return res
    if in(flag, mask)
      push!(res, flag)
      mask &= ~flag
    end
  end
  res
end
