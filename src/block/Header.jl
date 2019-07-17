# Copyright (c) 2019 Guido Kraemer
# Distributed under the MIT software license, see the accompanying
# file COPYING or http://www.opensource.org/licenses/mit-license.php.

# struct Header
#     version           ::UInt32
#     previous_hash     ::UInt256 #Vector{UInt8} # length 32
#     merkle_root       ::UInt256 #Vector{UInt8} # length 32
#     timestamp         ::UInt32
#     difficulty_target ::UInt32
#     nonce            ::UInt32
# end
#
# The following implementation hopefully is
# more efficient, because no conversions at reading time have to be made:

"""
    Header

Data Structure representing the Header of a Block in the Bitcoin blockchain.

Data are store as an `NTuple{80, UInt8}` without parsinf per se.
The elements of the `Header` can be accessed by `header.element`.

```julia
header.version
header.prevhash
header.merkleroot
header.time
header.bits
header.nonce
```
"""
struct Header
    data :: Vector{UInt8}
end

"""
    Header(x::IO) -> Header

Parse `Header` from an `IO`
"""
Header(io::IO) = Header(read(io, 80))

@inline Base.getindex(x::Header, r) = x.data[r]

@inline function gidx(x, ::Val{from}, ::Val{to}) where from where to
    ntuple(i -> x[i + from - 1], to - from + 1)
end

@inline function Base.getproperty(x::Header, d::Symbol)
    if     d == :version    reinterpret(UInt32, x.data[1:4])[1]
    elseif d == :prevhash   x.data[5:36]
    elseif d == :merkleroot x.data[37:68]
    elseif d == :time       reinterpret(UInt32, x.data[69:72])[1]
    elseif d == :bits       reinterpret(UInt32, x.data[73:76])[1]
    elseif d == :nonce      reinterpret(UInt32, x.data[77:80])[1]
    else getfield(x, d)
    end
end

function Base.propertynames(::Type{Header}, private = false)
    (:version, :previous_hash, :merkle_root,
     :timestamp, :difficulty_target, :nonce,
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
        println(io, "  Nounce:     " * string(header.nonce,            base = 10))
    end
end
# Base.showall(io::IO, header::Header) = show(io, header)

function double_sha256(x::Header)::UInt256
    x.data |> sha256 |> sha256 |>
        x -> reinterpret(UInt256, x)[1]
end
