# Copyright (c) 2019 Guido Kraemer
# Copyright (c) 2019 Simon Castano
# Distributed under the MIT software license, see the accompanying
# file COPYING or http://www.opensource.org/licenses/mit-license.php.

module BitcoinPrimitives

using Printf, BitConverter, Secp256k1
using Ripemd: ripemd160
using SHA: sha1

import SHA: sha256

export
    CompactSizeUInt, Outpoint,
    TxIn, TxOut, Tx,
    Block, Header,
    Script, Witness,
    serialize, iscoinbase, coinbase_height,
    script, type

const HEADER_SIZE = 80

# This reads reversed compared to the byte order
# TODO: big endian little endian
const MAGIC = 0xd9b4_bef9
const MAGIC_SIZE = sizeof(eltype(MAGIC))

include("lib/CompactSizeUInt.jl")
include("transaction/Tx.jl")
include("block/Block.jl")

end # module
