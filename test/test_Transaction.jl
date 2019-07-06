# Copyright (c) 2019 Simon Castano
# Distributed under the MIT software license, see the accompanying
# file COPYING or http://www.opensource.org/licenses/mit-license.php.

@testset "Transaction" begin
    @testset "Outpoint" begin
        tests = [([0x01], 1),
                 ([0xfd, 0xd0, 0x24], 9424),
                 ([0xff, 0x70, 0x9a, 0xeb, 0xb4, 0xbb, 0x7f, 0x00, 0x00], 140444170951280)]
        for t in tests
            n = CompactSizeUInt(IOBuffer(t[1]))
            @test n.value == t[2]
        end
    end
end
