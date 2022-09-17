using BitMasks
using Test

@bitmask Mask::UInt32 begin
  NO_BIT = 0
  BIT_A = 1
  BIT_B = 2
  BIT_AB = 3
  BIT_C = 4
  BIT_BC = 6
  BIT_ABC = 7
end

@bitmask Mask2::UInt32 begin
  BIT_A_2 = 1
  BIT_B_2 = 2
  BIT_AB_2 = 3
end

@testset "BitMasks.jl" begin
  @testset "Bitmask creation & operations" begin
    @test BIT_A & BIT_B == Mask(0) == zero(Mask)
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
    @test_throws ErrorException("Bitwise operation not allowed between incompatible BitMasks 'Mask', 'Mask2'") BIT_A & BIT_A_2
    @test_throws ErrorException("Operation not allowed between incompatible BitMasks 'Mask', 'Mask2'") BIT_A == BIT_A_2
    @test_throws ErrorException("Operation not allowed between incompatible BitMasks 'Mask', 'Mask2'") BIT_A in BIT_A_2
  end

  @testset "Bitmask utilities" begin
    @test isatomic(BIT_A)
    @test !isatomic(BIT_AB)
    @test isatomic(NO_BIT)
    @test first(values(Mask)) == NO_BIT
    @test length(values(Mask)) == 4
    @test length(combinations(Mask)) == 3
    @test (:BIT_C => BIT_C) == last(pairs(Mask))
    @test (:BIT_ABC => BIT_ABC) == last(combination_pairs(Mask))
  end

  @testset "Correct printing of BitMasks" begin
    @test string(NO_BIT) == "Mask(NO_BIT)"
    @test string(zero(Mask2)) == "Mask2()"
    @test string(BIT_A) == "Mask(BIT_A)"
    @test string(BIT_C) == "Mask(BIT_C)"
    @test string(BIT_A | BIT_C) == "Mask(BIT_A | BIT_C)"
    @test string(BIT_ABC) == "Mask(BIT_ABC)"
  end
end;
