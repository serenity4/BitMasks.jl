using BitMasks
using Test

@bitmask Mask::UInt32 begin
  NO_BIT = 0
  BIT_A = 1
  BIT_B = 2
  BIT_AB = 3
  BIT_C = 4
  BIT_BC = BIT_B | BIT_C
  BIT_ABC = 7
end

"This is Mask2!"
@bitmask Mask2::UInt32 begin
  BIT_A_2 = 1
  "Here's some docstring."
  BIT_B_2 = 2
  BIT_AB_2 = 3
end

@bitmask Mask3::UInt32 begin
  BIT_A_3 = 0x0000000080000000
end

module TestModule
  using BitMasks
  @bitmask Mask4::UInt32 begin
    BIT_A_4 = 1
    BIT_B_4 = 2
    BIT_AB_4 = 3
  end
  @bitmask exported = true Mask5::UInt32 begin
    BIT_A_5 = 1
    BIT_B_5 = 2
    BIT_AB_5 = 3
  end
end

@bitmask Mask6::UInt32 begin
  BIT_A_6
  BIT_B_6
  BIT_C_6 = 8
  BIT_D_6
  "Here is another docstring."
  BIT_E_6
  BIT_AB_6 = BIT_A_6 | BIT_B_6
  BIT_F_6
end

@testset "BitMasks.jl" begin
  @testset "Bitmask creation & operations" begin
    @test convert(Integer, BIT_A) === 0x00000001
    @test convert(Integer, BIT_ABC) === 0x00000007
    @test Mask() == Mask(0) == zero(Mask)
    @test BIT_A & BIT_B == Mask(0) == zero(Mask) == zero(BIT_A)
    @test iszero(BIT_A & BIT_B)
    @test BIT_A | BIT_B == BIT_AB
    @test !iszero(BIT_AB)
    @test xor(BIT_A, BIT_B) == BIT_AB
    @test BIT_A < BIT_B && BIT_B < BIT_AB && BIT_A < BIT_AB
    @test BIT_A & 1 == 1 & BIT_A == BIT_A
    @test BIT_A | 2 == 2 | BIT_A == BIT_AB
    @test xor(BIT_A, 2) == xor(2, BIT_A) == BIT_AB
    @test 1 < BIT_B && BIT_B < 3
    @test BIT_A <= BIT_B <= BIT_AB
    @test BIT_A == BIT_A
    @test in(BIT_B, BIT_AB)
    @test !in(BIT_A, BIT_B)
    @test in(2, BIT_AB)
    @test in(BIT_B, 3)
    @test Int(BIT_B) == convert(Int, BIT_B) == 2
    @test convert(Mask, 2) == BIT_B
    @test typemax(Mask) == Mask(typemax(UInt32))
    @test_throws ErrorException("Bitwise operation not allowed between incompatible BitMasks 'Mask', 'Mask2'") BIT_A & BIT_A_2
    @test_throws ErrorException("Bitwise operation not allowed between incompatible BitMasks 'Mask', 'Mask2'") BIT_A ⊻ BIT_A_2
    @test_throws ErrorException("Bitwise operation not allowed between incompatible BitMasks 'Mask', 'Mask2'") BIT_A | BIT_A_2
    @test_throws ErrorException("Bitwise operation not allowed between incompatible BitMasks 'Mask', 'Mask2'") BIT_A < BIT_A_2
    @test_throws ErrorException("Operation not allowed between incompatible BitMasks 'Mask', 'Mask2'") BIT_A == BIT_A_2
    @test_throws ErrorException("Operation not allowed between incompatible BitMasks 'Mask', 'Mask2'") BIT_A in BIT_A_2
  end

  @testset "Bitmask utilities" begin
    @test isatomic(BIT_A)
    @test !isatomic(BIT_AB)
    @test isatomic(NO_BIT)
    @test first(values(Mask)) == NO_BIT
    @test length(values(Mask)) == 4
    @test instances(Mask) == values(Mask)
    @test length(combinations(Mask)) == 3
    @test (:BIT_C => BIT_C) == last(pairs(Mask))
    @test (:BIT_ABC => BIT_ABC) == last(combination_pairs(Mask))
    @test enabled_flags(BIT_AB) == [NO_BIT, BIT_A, BIT_B]
  end

  @testset "Correct printing of BitMasks" begin
    @test string(NO_BIT) == "Mask(NO_BIT)"
    @test string(zero(Mask2)) == "Mask2()"
    @test string(BIT_A) == "Mask(BIT_A)"
    @test string(BIT_C) == "Mask(BIT_C)"
    @test string(BIT_A | BIT_C) == "Mask(BIT_A | BIT_C)"
    @test string(BIT_ABC) == "Mask(BIT_ABC)"
    @test bitmask_name(BIT_A | BIT_C) == "BIT_A | BIT_C"
  end

  @testset "Automatic exportation of defined values" begin
    @test !in(:BIT_A_4, names(TestModule))
    @test [:BIT_A_5, :BIT_AB_5, :Mask5] ⊆ names(TestModule)
  end

  @testset "Filling unspecified values" begin
    @test BIT_A_6 == Mask6(1)
    @test BIT_B_6 == Mask6(2)
    @test BIT_D_6 == Mask6(16)
    @test BIT_E_6 == Mask6(32)
    @test BIT_F_6 == Mask6(64)
  end

  @testset "Docstring propagation" begin
    @test string(Core.@doc(Mask2)) == "This is Mask2!\n"
    @test string(Core.@doc(BIT_B_2)) == "Here's some docstring.\n"
    @test string(Core.@doc(BIT_E_6)) == "Here is another docstring.\n"
  end
end;
