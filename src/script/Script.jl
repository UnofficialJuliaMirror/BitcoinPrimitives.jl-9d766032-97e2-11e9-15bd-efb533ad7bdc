include("op-codes.jl")


mutable struct Script
    instructions::Vector{Vector{UInt8}}
end

Script() = Script(Vector{UInt8}[])

function show(io::IO, z::Script)
    for instruction in z.instructions
        if typeof(instruction) <: Integer
            if haskey(OP_CODE_NAMES, instruction)
                print(io, "\n", OP_CODE_NAMES[Int(instruction)])
            else
                print(io, "\n", string("OP_CODE_", Int(instruction)))
            end
        elseif typeof(instruction) <: Vector{UInt8}
            print(io, "\n", bytes2hex(instruction))
        else
            print(io, "\n", instruction)
        end
    end
end

"""
    Script(::IOBuffer) -> Script

Parse a `Script` from an IOBuffer
"""
function Script(io::IOBuffer)
    length_ = CompactSizeUInt(io).value
    instructions = Vector{UInt8}[]
    count = 0
    while count < length_
        count += 1
        current_byte = read(io, UInt8)
        if current_byte >= 0x01 && current_byte <= 0x4b
            n = current_byte
            push!(instructions, read(io, n))
            count += n
        elseif current_byte == 0x4c
            # op_pushdata1
            n = read(io, Int8)
            push!(instructions, read(io, n))
            count += n + 1
        elseif current_byte == 0x4d
            # op_pushdata2
            n = read(io, Int16)
            push!(instructions, read(io, n))
            count += n + 2
        else
            # op_code
            push!(instructions, [current_byte])
        end
    end
    @assert count == length_ "Parsing failed"
    return Script(instructions)
end

function serialize(s::Script)
    result = UInt8[]
    for instruction in s.instructions
        if typeof(instruction) == UInt8
            push!(result, instruction)
        else
            length_ = length(instruction)
            if length_ < 0x4b
                append!(result, UInt8(length_))
            elseif length_ > 0x4b && length_ < 0x100
                append!(result, 0x4c)
                append!(result, UInt8(length_))
            elseif length_ >= 0x100 && length_ <= 0x208
                append!(result, 0x4d)
                result += int2bytes(length_, 2)
            else
                error("too long an instruction")
            end
            append!(result, instruction)
        end
    end
    total = CompactSizeUInt(length(result))
    prepend!(result, serialize(total))
    return result
end

const SCRIPT_TYPE = Base.ImmutableDict(
    "P2PKH" => ()
)

"""
Takes a hash160 && returns the p2pkh scriptPubKey
"""
function p2pkh_script(h160::Vector{UInt8})
    script = Union{UInt8, Vector{UInt8}}[]
    pushfirst!(script, 0x76, 0xa9)
    push!(script, h160, 0x88, 0xac)
    return Script(script)
end

"""
Takes a hash160 && returns the p2sh scriptPubKey
"""
function p2sh_script(h160::Vector{UInt8})
    script = Union{UInt8, Vector{UInt8}}[]
    pushfirst!(script, 0xa9)
    push!(script, h160, 0x87)
    return Script(script)
end

"""
Takes a hash160 && returns the p2wpkh ScriptPubKey
"""
function p2wpkh_script(h160::Vector{UInt8})
    return Script([0x00, h160])
end

"""
Takes a hash160 && returns the p2wsh ScriptPubKey
"""
function p2wsh_script(hash256::Vector{UInt8})
    return Script([0x00, h256])
end

function scripttype(script::Script)
    if is_p2pkh(script)
        return "P2PKH"
    elseif is_p2sh(script)
        return "P2SH"
    elseif is_p2wsh(script)
        return "P2WSH"
    elseif is_p2wpkh(script)
        return "P2WPKH"
    else
        return error("Unknown Script type")
    end
end

"""
Returns whether this follows the
OP_DUP OP_HASH160 <20 byte hash> OP_EQUALVERIFY OP_CHECKSIG pattern.
"""
function is_p2pkh(script::Script)
    return length(script.instructions) == 5 &&
        script.instructions[1] == 0x76 &&
        script.instructions[2] == 0xa9 &&
        typeof(script.instructions[3]) == Vector{UInt8} &&
        length(script.instructions[3]) == 20 &&
        script.instructions[4] == 0x88 &&
        script.instructions[5] == 0xac
end

"""
Returns whether this follows the
OP_HASH160 <20 byte hash> OP_EQUAL pattern.
"""
function is_p2sh(script::Script)
    return length(script.instructions) == 3 &&
           script.instructions[1] == 0xa9 &&
           typeof(script.instructions[2]) == Vector{UInt8} &&
           length(script.instructions[2]) == 20 &&
           script.instructions[3] == 0x87
end

function is_p2wpkh(script::Script)
    length(script.instructions) == 2 &&
    script.instructions[1] == 0x00 &&
    typeof(script.instructions[2]) == Vector{UInt8} &&
    length(script.instructions[2]) == 20
end

"""
Returns whether this follows the
OP_0 <20 byte hash> pattern.
"""
function is_p2wsh(script::Script)
    length(script.instructions) == 2 &&
    script.instructions[1] == 0x00 &&
    typeof(script.instructions[2]) == Vector{UInt8} &&
    length(script.instructions[2]) == 32

end

const H160_INDEX = Dict([
    ("P2PKH", 3),
    ("P2SH", 2)
])

"""
Returns the address corresponding to the script
"""
function script2address(script::Script, testnet::Bool)
    type = scripttype(script)
    h160 = script.instructions[H160_INDEX[type]]
    return h160_2_address(h160, testnet, type)
end
