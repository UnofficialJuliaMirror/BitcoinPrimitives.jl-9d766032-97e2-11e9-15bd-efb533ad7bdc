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

@inline function Base.getproperty(x::Header, d::Symbol)
    if     d == :version    ltoh(reinterpret(UInt32, x.data[1:4])[1])
    elseif d == :prevhash   x.data[5:36]
    elseif d == :merkleroot x.data[37:68]
    elseif d == :time       ltoh(reinterpret(UInt32, x.data[69:72])[1])
    elseif d == :bits       ltoh(reinterpret(UInt32, x.data[73:76])[1])
    elseif d == :nonce      ltoh(reinterpret(UInt32, x.data[77:80])[1])
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


"""
    bip9(block::Header) -> Bool

Returns whether this block is signaling readiness for BIP9

    BIP9 is signalled if the top 3 bits are 001
    remember version is 32 bytes so right shift 29 (>> 29) and see if
    that is 001
"""
bip9(block::Header) = block.version >> 29 == 0b001

"""
    bip91(block::Header) -> Bool

Returns whether this block is signaling readiness for BIP91

    BIP91 is signalled if the 5th bit from the right is 1
    shift 4 bits to the right and see if the last bit is 1
"""
bip91(block::Header) = block.version >> 4 & 1 == 1

"""
    bip141(block::Header) - > Bool

Returns whether this block is signaling readiness for BIP141

    BIP91 is signalled if the 2nd bit from the right is 1
    shift 1 bit to the right and see if the last bit is 1
"""
bip141(block::Header) = block.version >> 1 & 1 == 1

"""
    target(block::Header) -> BigInt

Returns the proof-of-work target based on the bits

    last byte is exponent
    the first three bytes are the coefficient in little endian
    the formula is: coefficient * 256**(exponent-3)
"""
function target(block::Header)
    exponent = block.bits >> 24
    coefficient = block.bits & 0x00ffffff
    return coefficient * big(256)^(exponent - 3)
end

"""
    difficulty(block::Header) -> BigInt

Returns the block difficulty based on the bits

    difficulty is (target of lowest difficulty) / (block's target)
    lowest difficulty has bits that equal 0xffff001d
"""
function difficulty(block::Header)
    lowest = 0xffff * big(256)^(0x1d - 3)
    return div(lowest, target(block))
end

"""
    check_pow(block::Header) -> Bool

Returns whether this block satisfies proof of work

    get the hash256 of the serialization of this block
    interpret this hash as a little-endian number
    return whether this integer is less than the target
"""
function check_pow(block::Header)
    block_hash = hash256(block)
    proof = to_int(block_hash, little_endian=true)
    return proof < target(block)
end
