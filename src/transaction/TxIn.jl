"""
    TxIn

Each non-coinbase input spends an outpoint from a previous transaction.
Is is composed of
- The previous outpoint being spent
- A script-language script which satisfies the conditions placed in the
outpoint’s pubkey script. Should only contain data pushes
- Sequence number. Default for Bitcoin Core and almost all other programs is
`0xffffffff`
"""
struct TxIn
    previous_output     :: Outpoint
    signature_script    :: Vector{UInt8}
    sequence            :: UInt32
end

function TxIn(io::IOBuffer)
    previous_output = Outpoint(io)
    script_bytes = CompactSizeUInt(io)
    signature_script = read(io, script_bytes)
    sequence = read(io, UInt32)

    TxIn(outpoint, signature_script, sequence)
end
