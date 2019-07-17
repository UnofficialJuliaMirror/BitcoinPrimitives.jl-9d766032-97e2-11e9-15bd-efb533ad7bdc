# Copyright (c) 2019 Guido Kraemer
# Copyright (c) 2019 Simon Castano
# Distributed under the MIT software license, see the accompanying
# file COPYING or http://www.opensource.org/licenses/mit-license.php.

include("../script/Script.jl")
include("../script/Witness.jl")
include("Outpoint.jl")
include("TxIn.jl")
include("TxOut.jl")


abstract type Transaction end

"""
Bitcoin transactions are broadcast between peers in a serialized byte format,
called raw format. It is this form of a transaction which is SHA256(SHA256())
hashed to create the TXID and, ultimately, the merkle root of a block
containing the transaction—making the transaction format part of the consensus
rules.

A raw transaction has the following top-level format:

- Transaction version number; currently version 1 or 2. Programs creating
transactions using newer consensus rules may use higher version numbers.
Version 2 means that BIP 68 applies.
- A marker which MUST be a 1-byte zero value: `0x00` (BIP 141)
- A flag which MUST be a 1-byte non-zero value: `0x01` (BIP 141)
- Transaction inputs
- Transaction outputs
- A time (Unix epoch time) or block number (BIP 68)

A transaction may have multiple inputs and outputs, so the `TxIn` and `TxOut`
structures may recur within a transaction.
"""
struct Tx <: Transaction
    version     :: UInt32
    marker      :: UInt8
    flag        :: UInt8
    inputs      :: Vector{TxIn}
    outputs     :: Vector{TxOut}
    witnesses   :: Vector{Witness}
    locktime    :: UInt32
end

function Tx(io::IOBuffer)

    version         =   ltoh(read(io, UInt32))

    x               =   CompactSizeUInt(io).value
    x == zero(x)    ?   segwit = true : segwit = false

    if segwit
        marker, flag    =   x, read(io, UInt8)
        @assert flag    ==  0x01
        txin_count      =   CompactSizeUInt(io).value
    else
        marker, flag    =   0xff, 0xff
        txin_count      =   x
    end

    inputs  = TxIn[TxIn(io)     for i ∈ 1:txin_count]
    outputs = TxOut[TxOut(io)   for i ∈ 1:CompactSizeUInt(io).value]

    if segwit
        witness_count = txin_count
        @assert witness_count > 0
        witnesses = Witness[Witness(io) for i ∈ 1:witness_count]
    else
        witnesses = [Witness()]
    end

    locktime = ltoh(read(io, UInt32))

    return Tx(version, marker, flag, inputs, outputs, witnesses, locktime)
end

# TODO: is this the same as bytes2hex?
hexarray(x::Array{UInt8}) = mapreduce(x -> string(x, base = 16), *, x)

function Base.show(io::IO, transaction::Tx)
    # TODO: add id here
    if !get(io, :compact, false)
        println(io, "Transaction: ")
        println(io, "  Version:        " * string(transaction.version, base = 10))
        println(io, "  Input counter:  " * string(transaction.input_counter, base = 10))
        println(io, "  Output counter: " * string(transaction.output_counter, base = 10))
        println(io, "  Lock time:      " * string(transaction.lock_time, base = 10))
    end
end

# function Base.showall(io::IO, transaction::Tx)
#     # TODO: add id here
#     println(io, "Transaction: ")
#     println(io, "  Version:        " * string(transaction.version, base = 10))
#     println(io, "  Input counter:  " * string(transaction.input_counter, base = 10))
#     for i ∈ 1:transaction.input_counter
#         show(transaction.inputs[i])
#     end
#     println(io, "  Output counter: " * string(transaction.output_counter, base = 10))
#     for i ∈ 1:transaction.output_counter
#         show(transaction.outputs[i])
#     end
#     println(io, "  Lock time:      " * string(transaction.lock_time, base = 10))
# end


"""
    serialize(tx::Tx) -> Vector{UInt8}

Returns the byte serialization of the transaction
"""
function serialize(tx::Tx)
    result = bytes(tx.version, len=4, little_endian=true)

    (tx.marker, tx.flag) == (0xff, 0xff) ? bip141 = false : bip141 = true
    bip141 ? append!(result, [tx.marker, tx.flag]) : nothing

    l = CompactSizeUInt(length(tx.inputs))
    append!(result, serialize(l))
    for input in tx.inputs
        append!(result, serialize(input))
    end

    l = CompactSizeUInt(length(tx.outputs))
    append!(result, serialize(l))
    for output in tx.outputs
        append!(result, serialize(output))
    end

    if bip141
        for i ∈ 1:length(tx.inputs)
            append!(result, serialize(tx.witnesses[i]))
        end
    end
    append!(result, bytes(tx.locktime, len=4, little_endian=true))
    return result
end

# TODO: little endian only:
function sha256(tx::Tx)

    ctx = SHA.SHA256_CTX()

    SHA.update!(ctx, to_byte_tuple(tx.version))
    SHA.update!(ctx, to_varint(tx.input_counter))
    for i ∈ 1:tx.input_counter
        SHA.update!(ctx, to_byte_tuple(tx.inputs[i].hash))
        SHA.update!(ctx, to_byte_tuple(tx.inputs[i].output_index))
        SHA.update!(ctx, to_varint(tx.inputs[i].unlocking_script_size))
        SHA.update!(ctx, tx.inputs[i].unlocking_script)
        SHA.update!(ctx, to_byte_tuple(tx.inputs[i].sequence_number))
    end
    SHA.update!(ctx, to_varint(tx.output_counter))
    for i ∈ 1:tx.output_counter
        SHA.update!(ctx, to_byte_tuple(tx.outputs[i].amount))
        SHA.update!(ctx, to_varint(tx.outputs[i].locking_script_size))
        SHA.update!(ctx, tx.outputs[i].locking_script)
    end
    SHA.update!(ctx, to_byte_tuple(tx.lock_time))

    return SHA.digest!(ctx)
end

function double_sha256(tx::Tx)::UInt256
    tx |> sha256 |> sha256 |> x -> reinterpret(UInt256, x)[1]
end

# TODO: copyto! is save, right?
# TODO: find an allocation free version for these: copyto!(x, i, to_byte_tuple(y))
"""
mutates data in place, advances idx and returns it.
"""
function dump_txin_data!(data, idx, txin::TxIn)
    copyto!(data, idx, to_byte_tuple(txin.hash))
    idx += sizeof(txin.hash)

    copyto!(data, idx, to_byte_tuple(txin.output_index))
    idx += sizeof(txin.output_index)

    unlocking_script_size = to_varint(txin.unlocking_script_size)
    copyto!(data, idx, unlocking_script_size)
    idx += sizeof(unlocking_script_size)

    copyto!(data, idx, txin.unlocking_script)
    idx += sizeof(txin.unlocking_script)

    copyto!(data, idx, to_byte_tuple(txin.sequence_number))
    idx += sizeof(txin.sequence_number)

    return idx
end

# TODO: copyto! is save, right?
# TODO: find an allocation free version for these: copyto!(x, i, to_byte_tuple(y))
"""
mutates data in place, advances idx and returns it.
"""
function dump_txout_data!(data, idx, txout::TxOut)
    copyto!(data, idx, to_byte_tuple(txout.amount))
    idx += sizeof(txout.amount)

    locking_script_size = to_varint(txout.locking_script_size)
    copyto!(data, idx, locking_script_size)
    idx += sizeof(locking_script_size)

    copyto!(data, idx, txout.locking_script)
    idx += sizeof(txout.locking_script)

    return idx
end

# TODO: copyto! is save, right?
# TODO: find an allocation free version for these: copyto!(x, i, to_byte_tuple(y))
"""
mutates data in place, advances idx and returns it.
"""
function dump_tx_data!(data, idx, tx::Tx)
    copyto!(data, idx, to_byte_tuple(tx.version))
    idx += sizeof(tx.version)

    is_segwit = tx.marker == 0x00
    if is_segwit
        data[idx] = tx.marker
        idx += 1
        data[idx] = tx.flag
        idx += 1
    end

    input_counter = to_varint(tx.input_counter)
    copyto!(data, idx, input_counter)
    idx += sizeof(input_counter)
    for i in 1:tx.input_counter
        idx = dump_txin_data!(data, idx, tx.inputs[i])
    end

    output_counter = to_varint(tx.output_counter)
    copyto!(data, idx, output_counter)
    idx += sizeof(output_counter)
    for i in 1:tx.output_counter
        idx = dump_txout_data!(data, idx, tx.outputs[i])
    end

    if is_segwit
        for i in 1:tx.input_counter
            n_items = length(tx.witnesses[i].data)
            n_items_bytes = to_varint(n_items)
            copyto!(data, idx, n_items_bytes)
            idx += length(n_items_bytes)

            for j in 1:n_items
                l = length(tx.witnesses[i].data[j])
                l_bytes = to_varint(l)
                copyto!(data, idx, l_bytes)
                idx += length(l_bytes)

                copyto!(data, idx, tx.witnesses[i].data[j])
                idx += l
            end
        end
    end

    copyto!(data, idx, to_byte_tuple(tx.lock_time))
    idx += sizeof(tx.lock_time)

    return idx
end

total_output(tx::Tx) = sum(x -> x.amount, tx.outputs)

"""
    iscoinbase(tx::Tx) -> Bool

Returns whether this transaction is a coinbase transaction or not
"""
function iscoinbase(tx::Tx)
    outpoint = tx.inputs[1].prevout
    length(tx.inputs) == 1 && outpoint.txid == fill(0x00, 32) && outpoint.index == 0xffffffff
end

"""
    coinbase_height(tx::Tx) ->

Returns the height of the block this coinbase transaction is in
Returns an `AssertionError` if `tx` isn't a coinbase transaction
"""
function coinbase_height(tx::Tx)
    @assert iscoinbase(tx) "This is not a coinbase transaction"
    height_bytes = tx.inputs[1].scriptsig.data[1]
    return to_int(height_bytes, little_endian=true)
end
