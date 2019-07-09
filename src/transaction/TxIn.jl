# Copyright (c) 2019 Guido Kraemer
# Copyright (c) 2019 Simon Castano
# Distributed under the MIT software license, see the accompanying
# file COPYING or http://www.opensource.org/licenses/mit-license.php.

"""
    TxIn

Each non-coinbase input spends an outpoint from a previous transaction.
A `TxIn` is composed of
- `prevout::Outpoint`, The previous outpoint being spent
- `signature_script::Vector{UInt8}`, which satisfies the conditions placed in
the outpoint’s pubkey script. Should only contain data pushes
- `sequence::UInt32` number. Default for Bitcoin Core and almost all other
programs is `0xffffffff`
"""
struct TxIn
    prevout     :: Outpoint
    signature_script    :: Vector{UInt8}
    sequence            :: UInt32
end

"""
    TxIn(io::IOBuffer)

Parse an `IOBuffer` to a `TxIn`
"""
function TxIn(io::IOBuffer)
    prevout = Outpoint(io)
    script_bytes = CompactSizeUInt(io).value
    signature_script = read(io, script_bytes)
    sequence = read(io, UInt32)

    TxIn(prevout, signature_script, sequence)
end

function Base.show(io::IO, input::TxIn)
    if !get(io, :compact, false)
        println(io, "Transaction input:")
        println(io, "  Hash:                  " * string(input.hash,            base = 16))
        println(io, "  Output index:          " * string(input.output_index,    base = 10))
        println(io, "  Input Sequence:        " * string(input.sequence_number, base = 10))
    end
end

# function Base.showall(io::IO, input::TxIn)
#     println(io, "Transaction input:")
#     println(io, "  Hash:                  " * input.hash)
#     println(io, "  Output index:          " * input.output_index)
#     println(io, "  Unlocking script size: " * input.unlocking_script_size)
#     println(io, "  Unlocking script:      " * hexarray(input.unlocking_script))
#     println(io, "  Input Sequence:        " * input.sequence_number)
# end
