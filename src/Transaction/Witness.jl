# Copyright (c) 2019 Guido Kraemer
# Distributed under the MIT software license, see the accompanying
# file COPYING or http://www.opensource.org/licenses/mit-license.php.

"""
    Witness

The `Witness` is a serialization of all witness data of the transaction.
Each `TxIn` is associated with a witness field. A witness field starts with a
`CompactSizeUInt` to indicate the number of stack items for the `TxIn`.
It is followed by stack items, with each item starts with a `CompactSizeUInt`
to indicate the length.
Witness data is NOT script.

A non-witness program (defined hereinafter) `TxIn` MUST be associated with an
empty witness field, represented by a `0x00`. If all `TxIn`s are not witness
program, a transaction's `wtxid` is equal to its `txid`.
    """
struct Witness
    data :: Vector{Vector{UInt8}}
end

function Witness(io::IO)
    n_items = CompactSizeUInt(io).value
    data = Vector{Vector{UInt8}}(undef, n_items)

    for i in 1:n_items
        l = read_varint(io)
        data[i] = read!(io, Array{UInt8, 1}(undef, l))
    end

    Witness(data)
end
