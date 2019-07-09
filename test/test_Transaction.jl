# Copyright (c) 2019 Simon Castano
# Distributed under the MIT software license, see the accompanying
# file COPYING or http://www.opensource.org/licenses/mit-license.php.

@testset "Transaction" begin
    @testset "Outpoint" begin
        raw = hex2bytes("7b1eabe0209b1fe794124575ef807057c77ada2138ae4fa8d6c4de0398a14f3f00000000")
        outpoint = Outpoint(IOBuffer(raw))
        @test bytes2hex(outpoint.txid) == "7b1eabe0209b1fe794124575ef807057c77ada2138ae4fa8d6c4de0398a14f3f"
        @test outpoint.index == 0
    end
end
