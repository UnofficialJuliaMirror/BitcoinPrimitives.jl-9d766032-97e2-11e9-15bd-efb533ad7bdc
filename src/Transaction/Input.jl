# Copyright (c) 2019 Guido Kraemer
# Copyright (c) 2019 Simon Castano
# Distributed under the MIT software license, see the accompanying
# file COPYING or http://www.opensource.org/licenses/mit-license.php.

"""
    TransactionInput

Data Structure Storing Transaction Inputs
"""
struct TxIn
    # TODO: remove unlocking_script_size
    previous_output       :: Outpoint
    unlocking_script_size :: UInt64
    unlocking_script      :: Vector{UInt8}
    sequence_number       :: UInt32
end

function TxIn(io::IOBuffer)

    in_hash = read!(io, Array{UInt256}(undef, 1))[1]
    # in_hash = read(io, UInt256)
    output_index = read(io, UInt32)
    unlocking_script_size = signed(read_varint(io))

    unlocking_script = read!(io, Array{UInt8}(undef, unlocking_script_size))
    sequence_number = read(io, UInt32)

    TransactionInput(
    in_hash,
    output_index,
    unlocking_script_size,
    unlocking_script,
    sequence_number
    )
end
