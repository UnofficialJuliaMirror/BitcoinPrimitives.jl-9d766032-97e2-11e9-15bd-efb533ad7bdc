# Copyright (c) 2019 Guido Kraemer
# Distributed under the MIT software license, see the accompanying
# file COPYING or http://www.opensource.org/licenses/mit-license.php.

@testset "to_byte_tuple" begin

    bt = BitcoinPrimitives.to_byte_tuple(0x1234_5678)
    @test length(bt) == 4
    @test bt[4] == 0x12
    @test bt[3] == 0x34
    @test bt[2] == 0x56
    @test bt[1] == 0x78

end
