# Copyright (c) 2019 Simon Castano
# Distributed under the MIT software license, see the accompanying
# file COPYING or http://www.opensource.org/licenses/mit-license.php.

@testset "Transaction" begin
    @testset "TxIn" begin
        txin_hex = "7b1eabe0209b1fe794124575ef807057c77ada2138ae4fa8d6c4de0398a14f3f00000000494830450221008949f0cb400094ad2b5eb399d59d01c14d73d8fe6e96df1a7150deb388ab8935022079656090d7f6bac4c9a94e0aad311a4268e082a725f8aeae0573fb12ff866a5f01ffffffff"
        raw = hex2bytes(txin_hex)
        txin = TxIn(IOBuffer(raw))
        @test typeof(txin.previous_output) == Outpoint
        @test bytes2hex(txin.previous_output.txid) == "7b1eabe0209b1fe794124575ef807057c77ada2138ae4fa8d6c4de0398a14f3f"
        @test txin.previous_output.index == 0
        @test txin.signature_script == hex2bytes("4830450221008949f0cb400094ad2b5eb399d59d01c14d73d8fe6e96df1a7150deb388ab8935022079656090d7f6bac4c9a94e0aad311a4268e082a725f8aeae0573fb12ff866a5f01")
        @test txin.sequence == 0xffffffff
    end
    @testset "TxOut" begin
        txout_hex = "f0ca052a010000001976a914cbc20a7664f2f69e5355aa427045bc15e7c6c77288ac"
        raw = hex2bytes(txout_hex)
        txout = TxOut(IOBuffer(raw))
        @test txout.value == 4999990000
        @test txout.pk_script == hex2bytes("76a914cbc20a7664f2f69e5355aa427045bc15e7c6c77288ac")
    end
end
