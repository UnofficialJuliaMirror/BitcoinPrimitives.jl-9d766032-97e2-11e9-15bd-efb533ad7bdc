# Copyright (c) 2019 Guido Kraemer
# Distributed under the MIT software license, see the accompanying
# file COPYING or http://www.opensource.org/licenses/mit-license.php.

include("Header.jl")

"""
    Block

Data Structure representing a Block in the Bitcoin blockchain.

Consists of a `block.header::Header` and
`block.transactions::Vector{Tx}`.
"""
struct Block
    magic               :: UInt32
    header              :: Header
    transactions        :: Vector{Tx}
end

function Block(io::IO)
    magic = read(io, UInt32)
    blocksize = read(io, UInt32)
    blockheader = Header(io)
    n_trans = CompactSizeUInt(io).value
    @assert n_trans > zero(n_trans) "Block must have at least one transaction"
    transactions = [Tx(io) for i in 1:n_trans]

    return Block(magic, blockheader, transactions)
end

function Block(x::Array{UInt8})
    block_size = length(x)

    io = IOBuffer(x)

    block_header = Header(io)

    n_trans = read_varint(io)
    @assert n_trans > zero(n_trans)
    transactions = Tx[
        Tx(io)
        for i in 1:n_trans
    ]

    return Block(
        block_size,
        block_header,
        n_trans,
        transactions
    )
end

function showcompact(io::IO, block::Block)
    print(io, "Block, %d bytes, %d transactions:\n",
            block.size, block.transaction_counter)
end

function Base.show(io::IO, block::Block)
    showcompact(io, block)
    if !get(io, :compact, false)
        show(io, block.header)
    end
end

# function Base.showall(io::IO, block::Block)
#     show(io, block)
#     println("Transactions:")
#     show(io, block.transactions)
# end

function dump_block_data(io::IO)
    block_size = read(io, UInt32)
    read!(io, Array{UInt8}(undef, block_size))
end

function dump_block_data(block::Block)

    data = Array{UInt8}(undef, block.size)

    copyto!(data, 1, block.header.data)

    transaction_counter = to_varint(block.transaction_counter)
    copyto!(data, 81, transaction_counter)
    idx = 81 + length(transaction_counter)

    for i in 1:block.transaction_counter
        idx = dump_tx_data!(data, idx, block.transactions[i])
    end

    @assert idx == length(data) + 1

    return data
end
