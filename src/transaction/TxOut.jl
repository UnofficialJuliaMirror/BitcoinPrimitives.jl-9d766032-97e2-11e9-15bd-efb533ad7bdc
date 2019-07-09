# Copyright (c) 2019 Guido Kraemer
# Copyright (c) 2019 Simon Castano
# Distributed under the MIT software license, see the accompanying
# file COPYING or http://www.opensource.org/licenses/mit-license.php.

"""
    TxOut

Each output spends a certain number of satoshis, placing them under control of
anyone who can satisfy the provided pubkey script.
A `TxOut` is composed of
- `value::UInt64`, number of satoshis to spend. May be zero; the sum of all
outputs may not exceed the sum of satoshis previously spent to the outpoints
provided in the input section. (Exception: coinbase transactions spend the
block subsidy and collected transaction fees.)
- `pk_script::Vector{UInt8}` which defines the conditions which must be
satisfied to spend this output.

"""
struct TxOut
    value       :: UInt64
    pk_script   :: Vector{UInt8}
end

"""
    TxOut(io::IOBuffer)

Parse an `IOBuffer` to a `TxOut`
"""
function TxOut(io::IOBuffer)
    value = read(io, UInt64)
    script_bytes = CompactSizeUInt(io)
    pk_script = read(io, script_bytes)

    TxOut(value, pk_script)
end

function Base.show(io::IO, output::TxOut)
    println(io, "Transaction output: " * string(output.amount, base = 10))
end

# function Base.showall(io::IO, output::TxOut)
#     println(io, "Transaction output: "    * string(output.amount,              base = 10))
#     println(io, "  Locking script size: " * string(output.locking_script_size, base = 10))
#     println(io, "  Locking script:      " * hexarray(output.locking_script))
# end
