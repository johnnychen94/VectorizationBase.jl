
@inline tuplefirst(x) = x
@inline tuplefirst(x::Tuple) = first(x)
@inline tupletail(x) = x
@inline tupletail(x::Tuple) = Base.tail(x)

struct TupleLength{N} end
@inline tuple_len(::Any) = nothing
@inline tuple_len(::Tuple{Vararg{Any,N}}) where {N} = TupleLength{N}()
@inline tuple_len(::TupleLength{N}, args...) where {N} = TupleLength{N}()
@inline tuple_len(::Nothing, a, args...) = tuple_len(tuple_len(a), args...)

# unary # 2^2 - 2 = 2 definitions
@inline fmap(f::F, x::Tuple{X}) where {F,X} = (f(first(x)),)
@inline fmap(f::F, x::NTuple) where {F} = (f(first(x)), fmap(f, Base.tail(x))...)

# binary # 2^3 - 2 = 6 definitions
@inline fmap(f::F, x::Tuple{X}, y::Tuple{Y}) where {F,X,Y} = (f(first(x), first(y)),)
@inline fmap(f::F, x::Tuple{X}, y) where {F,X} = (f(first(x), y),)
@inline fmap(f::F, x, y::Tuple{Y}) where {F,Y} = (f(x, first(y)),)
@inline fmap(f::F, x::NTuple, y::NTuple) where {F} = (f(first(x), first(y)), fmap(f, Base.tail(x), Base.tail(y))...)
@inline fmap(f::F, x::NTuple, y) where {F} = (f(first(x), y), fmap(f, Base.tail(x), y)...)
@inline fmap(f::F, x, y::NTuple) where {F} = (f(x, first(y)), fmap(f, x, Base.tail(y))...)

# ternary # 2^4 - 2 = 14 definitions, or 3
@inline fmap(f::F, x, y, z) where {F} = fmap(f, tuple_len(x, y, z), x, y, z)
@inline fmap(f::F, ::TupleLength{1}, x, y, z) where {F} = (f(tuplefirst(x), tuplefirst(y), tuplefirst(z)),)
@inline fmap(f::F, ::TupleLength, x, y, z) where {F} = (f(tuplefirst(x), tuplefirst(y), tuplefirst(z)), fmap(f, tupletail(x), tupletail(y), tupletail(z))...)

# quaternary # 2^5 - 2 = 30 definitions, or 3
@inline fmap(f::F, w, x, y, z) where {F} = fmap(f, tuple_len(w, x, y, z), w, x, y, z)
@inline fmap(f::F, ::TupleLength{1}, w, x, y, z) where {F} = (f(tuplefirst(w), tuplefirst(x), tuplefirst(y), tuplefirst(z)),)
@inline fmap(f::F, ::TupleLength, w, x, y, z) where {F} = (f(tuplefirst(w), tuplefirst(x), tuplefirst(y), tuplefirst(z)), fmap(f, tupletail(w), tupletail(x), tupletail(y), tupletail(z))...)

# @inline fmap(f::F, w) where {F} = VecUnroll(fmapt(f, unrolleddata(w)))
# @inline fmap(f::F, w, x) where {F} = VecUnroll(fmapt(f, unrolleddata(w), unrolleddata(x)))
# @inline fmap(f::F, w, x, y) where {F} = VecUnroll(fmapt(f, unrolleddata(w), unrolleddata(x), unrolleddata(y)))
# @inline fmap(f::F, w, x, y, z) where {F} = VecUnroll(fmapt(f, unrolleddata(w), unrolleddata(x), unrolleddata(y), unrolleddata(z)))

for op ∈ [:(-), :abs, :floor, :ceil, :trunc, :round, :sqrt]
    @eval @inline Base.$op(v1::VecUnroll{N,W,T}) where {N,W,T} = VecUnroll(fmap($op, v1.data))
end

for op ∈ [:+,:-,:*,:/,:%,:<<,:>>,:>>>,:&,:|,:⊻,:÷,:max,:min,:copysign,:^]
    @eval begin
        @inline Base.$op(v1::VecUnroll{N,W,T}, v2::Real) where {N,W,T} = VecUnroll(fmap($op, v1.data, Vec{W,T}(v2)))
        @inline Base.$op(v1::Real, v2::VecUnroll{N,W,T}) where {N,W,T} = VecUnroll(fmap($op, Vec{W,T}(v1), v2.data))
        @inline Base.$op(v1::VecUnroll, v2::VecUnroll) = VecUnroll(fmap($op, v1.data, v2.data))
    end
end
@inline Base.copysign(v1::Signed, v2::VecUnroll{N,W,T}) where {N,W,T} = VecUnroll(fmap(copysign, Vec{W,T}(v1), v2.data))
for op ∈ [:rotate_left,:rotate_right,:funnel_shift_left,:funnel_shift_right]
    @eval begin
        @inline $op(v1::VecUnroll{N,W,T}, v2::Real) where {N,W,T} = VecUnroll(fmap($op, v1.data, Vec{W,T}(v2)))
        @inline $op(v1::Real, v2::VecUnroll{N,W,T}) where {N,W,T} = VecUnroll(fmap($op, Vec{W,T}(v1), v2.data))
        @inline $op(v1::VecUnroll, v2::VecUnroll) = VecUnroll(fmap($op, v1.data, v2.data))
    end
end

for op ∈ [:(Base.muladd), :(Base.fma), :vfmadd, :vfnmadd, :vfmsub, :vfnmsub, :vfmadd231, :vfnmadd231, :vfmsub231, :vfnmsub231]
    @eval begin
        @inline $op(v1::VecUnroll{N,W,T}, v2::Real, v3::Real) where {N,W,T} = VecUnroll(fmap($op, v1.data, Vec{W,T}(v2), Vec{W,T}(v3)))
        @inline $op(v1::Real, v2::VecUnroll{N,W,T}, v3::Real) where {N,W,T} = VecUnroll(fmap($op, Vec{W,T}(v1), v2.data, Vec{W,T}(v3)))
        @inline $op(v1::Real, v2::Real, v3::VecUnroll{N,W,T}) where {N,W,T} = VecUnroll(fmap($op, Vec{W,T}(v1), Vec{W,T}(v2), v3.data))
        @inline $op(v1::VecUnroll{N,W,T}, v2::VecUnroll{N,W,T}, v3::Real) where {N,W,T} = VecUnroll(fmap($op, v1.data, v2.data, Vec{W,T}(v3)))
        @inline $op(v1::VecUnroll{N,W,T}, v2::Real, v3::VecUnroll{N,W,T}) where {N,W,T} = VecUnroll(fmap($op, v1.data, Vec{W,T}(v2), v3.data))
        @inline $op(v1::Real, v2::VecUnroll{N,W,T}, v3::VecUnroll{N,W,T}) where {N,W,T} = VecUnroll(fmap($op, Vec{W,T}(v1), v2.data, v3.data))
        @inline $op(v1::VecUnroll, v2::VecUnroll, v3::VecUnroll) = VecUnroll(fmap($op, v1.data, v2.data, v3.data))
    end
end


