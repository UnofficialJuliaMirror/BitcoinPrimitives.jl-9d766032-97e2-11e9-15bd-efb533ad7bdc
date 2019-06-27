# Copyright (c) 2019 Guido Kraemer
# Distributed under the MIT software license, see the accompanying
# file COPYING or http://www.opensource.org/licenses/mit-license.php.

# struct Header
#     version           ::UInt32
#     previous_hash     ::UInt256 #Vector{UInt8} # length 32
#     merkle_root       ::UInt256 #Vector{UInt8} # length 32
#     timestamp         ::UInt32
#     difficulty_target ::UInt32
#     nounce            ::UInt32
# end
#
# The following implementation hopefully is
# more efficient, because no conversions at reading time have to be made:
"""
    Header

Data Structure representing the Header of a Block in the Bitcoin blockchain.

The elements of the `Header` can be accessed by `header.element`.

```julia
header.version
header.previous_hash
header.merkle_root
header.timestamp
header.difficulty_target
header.nounce
```

The hash of the `Header` can be retrieved with
```julia
double_sha256(header)
```
"""
struct Header
    data :: NTuple{80, UInt8}
end

Header(x::IO) = Header(ntuple((i) -> read(x, UInt8), 80))

@inline Base.getindex(x::Header, r) = x.data[r]

@inline function gidx(x, ::Val{from}, ::Val{to}) where from where to
    ntuple(i -> x[i + from - 1], to - from + 1)
end

@inline function Base.getproperty(x::Header, d::Symbol)
    if     d == :version           to_unsigned(gidx(x, Val( 1), Val( 4)))
    elseif d == :previous_hash     to_unsigned(gidx(x, Val( 5), Val(36)))
    elseif d == :merkle_root       to_unsigned(gidx(x, Val(37), Val(68)))
    elseif d == :timestamp         to_unsigned(gidx(x, Val(69), Val(72)))
    elseif d == :difficulty_target to_unsigned(gidx(x, Val(73), Val(76)))
    elseif d == :nounce            to_unsigned(gidx(x, Val(77), Val(80)))
    else getfield(x, d)
    end
end

function Base.propertynames(::Type{Header}, private = false)
    (:version, :previous_hash, :merkle_root,
     :timestamp, :difficulty_target, :nounce,
     fieldnames(Header)...)
end

function showcompact(io::IO, header::Header)
    println(io, "Header, " * string(header.timestamp, base = 10) * ":")
end

function Base.show(io::IO, header::Header)
    showcompact(io, header)
    if !get(io, :compact, false)
        # TODO: add leading zeroes where necessary
        println(io, "  Version:    " * string(header.version,           base = 16))
        println(io, "  Prev Hash:  " * string(header.previous_hash,     base = 16))
        println(io, "  Root:       " * string(header.merkle_root,       base = 16))
        println(io, "  Time:       " * string(header.timestamp,         base = 10))
        println(io, "  Difficulty: " * string(header.difficulty_target, base = 16))
        println(io, "  Nounce:     " * string(header.nounce,            base = 10))
    end
end
# Base.showall(io::IO, header::Header) = show(io, header)

function double_sha256(x::Header)::UInt256
    x.data |> sha256 |> sha256 |>
        x -> reinterpret(UInt256, x)[1]
end
