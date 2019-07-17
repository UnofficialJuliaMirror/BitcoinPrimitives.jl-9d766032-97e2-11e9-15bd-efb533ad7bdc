@testset "Block" begin
    header_raw = hex2bytes("020000208ec39428b17323fa0ddec8e887b4a7c53b8c0a0a220cfd0000000000000000005b0750fce0a889502d40508d39576821155e9c9e3f5c3157f961db38fd8b25be1e77a759e93c0118a4ffd71d")
    io = IOBuffer(header_raw)
    header = Header(io)
    @testset "Parse" begin
        @test header.version == 0x20000002
        want = hex2bytes("8ec39428b17323fa0ddec8e887b4a7c53b8c0a0a220cfd000000000000000000")
        @test header.prevhash == want
        want = hex2bytes("5b0750fce0a889502d40508d39576821155e9c9e3f5c3157f961db38fd8b25be")
        @test header.merkleroot == want
        @test header.time == 0x59a7771e
        @test header.bits == 0x18013ce9
        @test header.nonce == 0x1dd7ffa4
    end
    # @testset "Serialize" begin
    #     @test serialize(header) == header_raw
    # end
    @testset "Hash" begin
        @test hash256(header) == hex2bytes("0000000000000000007e9e4c586439b0cdbe13b1370bdd9435d76a644d047523")
    end
    @testset "BIP9" begin
        @test BitcoinPrimitives.bip9(header)
        header_raw = hex2bytes("0400000039fa821848781f027a2e6dfabbf6bda920d9ae61b63400030000000000000000ecae536a304042e3154be0e3e9a8220e5568c3433a9ab49ac4cbb74f8df8e8b0cc2acf569fb9061806652c27")
        io = IOBuffer(header_raw)
        header = Header(io)
        @test !BitcoinPrimitives.bip9(header)
    end
    @testset "BIP91" begin
        header_raw = hex2bytes("1200002028856ec5bca29cf76980d368b0a163a0bb81fc192951270100000000000000003288f32a2831833c31a25401c52093eb545d28157e200a64b21b3ae8f21c507401877b5935470118144dbfd1")
        io = IOBuffer(header_raw)
        header = Header(io)
        @test BitcoinPrimitives.bip91(header)
        header_raw = hex2bytes("020000208ec39428b17323fa0ddec8e887b4a7c53b8c0a0a220cfd0000000000000000005b0750fce0a889502d40508d39576821155e9c9e3f5c3157f961db38fd8b25be1e77a759e93c0118a4ffd71d")
        io = IOBuffer(header_raw)
        header = Header(io)
        @test !BitcoinPrimitives.bip91(header)
    end
    @testset "BIP141" begin
        header_raw = hex2bytes("020000208ec39428b17323fa0ddec8e887b4a7c53b8c0a0a220cfd0000000000000000005b0750fce0a889502d40508d39576821155e9c9e3f5c3157f961db38fd8b25be1e77a759e93c0118a4ffd71d")
        io = IOBuffer(header_raw)
        header = Header(io)
        @test BitcoinPrimitives.bip141(header)
        header_raw = hex2bytes("0000002066f09203c1cf5ef1531f24ed21b1915ae9abeb691f0d2e0100000000000000003de0976428ce56125351bae62c5b8b8c79d8297c702ea05d60feabb4ed188b59c36fa759e93c0118b74b2618")
        io = IOBuffer(header_raw)
        header = Header(io)
        @test !BitcoinPrimitives.bip141(header)
    end
    @testset "Target" begin
        header_raw = hex2bytes("020000208ec39428b17323fa0ddec8e887b4a7c53b8c0a0a220cfd0000000000000000005b0750fce0a889502d40508d39576821155e9c9e3f5c3157f961db38fd8b25be1e77a759e93c0118a4ffd71d")
        io = IOBuffer(header_raw)
        header = Header(io)
        @test target(header) == parse(BigInt, "13ce9000000000000000000000000000000000000000000", base=16)
        @test difficulty(header) == 888171856257
    end
    @testset "Check POW" begin
        header_raw = hex2bytes("04000000fbedbbf0cfdaf278c094f187f2eb987c86a199da22bbb20400000000000000007b7697b29129648fa08b4bcd13c9d5e60abb973a1efac9c8d573c71c807c56c3d6213557faa80518c3737ec1")
        io = IOBuffer(header_raw)
        header = Header(io)
        @test check_pow(header) == true
        header_raw = hex2bytes("04000000fbedbbf0cfdaf278c094f187f2eb987c86a199da22bbb20400000000000000007b7697b29129648fa08b4bcd13c9d5e60abb973a1efac9c8d573c71c807c56c3d6213557faa80518c3737ec0")
        io = IOBuffer(header_raw)
        header = Header(io)
        @test !check_pow(header)
    end
    @testset "Validate merkle root" begin
        hashes_hex = [
           "f54cb69e5dc1bd38ee6901e4ec2007a5030e14bdd60afb4d2f3428c88eea17c1",
           "c57c2d678da0a7ee8cfa058f1cf49bfcb00ae21eda966640e312b464414731c1",
           "b027077c94668a84a5d0e72ac0020bae3838cb7f9ee3fa4e81d1eecf6eda91f3",
           "8131a1b8ec3a815b4800b43dff6c6963c75193c4190ec946b93245a9928a233d",
           "ae7d63ffcb3ae2bc0681eca0df10dda3ca36dedb9dbf49e33c5fbe33262f0910",
           "61a14b1bbdcdda8a22e61036839e8b110913832efd4b086948a6a64fd5b3377d",
           "fc7051c8b536ac87344c5497595d5d2ffdaba471c73fae15fe9228547ea71881",
           "77386a46e26f69b3cd435aa4faac932027f58d0b7252e62fb6c9c2489887f6df",
           "59cbc055ccd26a2c4c4df2770382c7fea135c56d9e75d3f758ac465f74c025b8",
           "7c2bf5687f19785a61be9f46e031ba041c7f93e2b7e9212799d84ba052395195",
           "08598eebd94c18b0d59ac921e9ba99e2b8ab7d9fccde7d44f2bd4d5e2e726d2e",
           "f0bb99ef46b029dd6f714e4b12a7d796258c48fee57324ebdc0bbc4700753ab1"]
       hashes = [hex2bytes(x) for x in hashes_hex]
       io = IOBuffer(hex2bytes("00000020fcb19f7895db08cadc9573e7915e3919fb76d59868a51d995201000000000000acbcab8bcc1af95d8d563b77d24c3d19b18f1486383d75a5085c4e86c86beed691cfa85916ca061a00000000"))
       header = Header(io)
       @test BitcoinPrimitives.validate_merkle_root(header, hashes)
    end
end