# Copyright (c) 2019 Guido Kraemer
# Distributed under the MIT software license, see the accompanying
# file COPYING or http://www.opensource.org/licenses/mit-license.php.

"""
    TransactionOutput

Data Structure Storing Transaction Outputs
"""
struct TxOut
    # TODO: remove locking_script_size
    amount              :: UInt64 # in satoshis = 1e-8 bitcoins
    locking_script_size :: UInt64
    locking_script      :: Vector{UInt8}
end

function TxOut(io::IOBuffer)

    out_amount = read(io, UInt64)
    out_script_size = signed(read_varint(io))
    locking_script = read!(io, Array{UInt8}(undef, out_script_size))

    TransactionOutput(out_amount,
    out_script_size,
    locking_script)
end
