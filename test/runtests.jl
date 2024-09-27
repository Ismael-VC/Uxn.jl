using Uxn: uxn, @PEEK2, @POKE2!, @JMI, @DEC, @INC, @POx, @PO1, @PO2, @PUx,
           @PU1, @OPC, @E, @OPCC
using CSyntax: @cswitch
using Test

@testset "Uxn.jl" begin
    # @PEEK2(::Expr, ::UInt8)::UInt16 =#
    uxn.dev[1:2] = [0x01, 0x02]
    @test @PEEK2(uxn.dev, 0x00)::UInt16 == 0x0102

    # @POKE2!(::Expr, ::UInt8, ::Symbol)::Nothing =#
    res = 0x1337
    @POKE2!(uxn.dev, 0x00, res)::Nothing
    @test uxn.dev[1:2] == [0x13, 0x37]

    #= Microcode =#

	#= @JMI()::Nothing =#
	pc = 0x0000
	uxn.ram[1:2] = [0x12, 0x34]
	@JMI()::Nothing
	@test pc == 0x1236

	#= @DEC(::Symbol)::UInt8 =#
	uxn.wst.ptr[] = 0x00
	uxn.wst.dat[end] = 0xff
	@test @DEC(wst)::UInt8 == 0xff
	@test uxn.wst.ptr[] == 0xff

	#= @INC(::Symbol, ::Symbol)::Nothing =#
	uxn.rst.ptr[] = 0x00
	c = 0xff
	@INC(rst, c)::Nothing
	@test uxn.rst.dat[1] == 0xff
	@test uxn.rst.ptr[] == 0x01

	#= @INC(::Symbol, ::Expr)::Nothing =#
	uxn.rst.ptr[] = 0x00
	uxn.rst.dat[0x42] = 0x42
	@INC(rst, uxn.rst.dat[0x42])::Nothing
	@test uxn.rst.dat[1] == 0x42
	@test uxn.rst.ptr[] == 0x01
	
	#= @PO1(::Expr)::Nothing =#
	_r = 0x01
	o = [0x01, 0x00]
	uxn.rst.ptr[] = 0x00
	uxn.rst.dat[end] = 0xff
	@PO1(o[1])::Nothing
	@test uxn.rst.ptr[] == 0xff
    @test uxn.rst.dat[uxn.rst.ptr[]+1] == 0xff
	@test o[1] == 0xff

    #= @PO1(::Symbol)::Nothing =#
    _r = 0x00
    a = 0x00
    uxn.wst.ptr[] = 0x00
    uxn.wst.dat[end] = 0xff
    @PO1(a)::Nothing
    @test uxn.wst.ptr[] == 0xff
    @test uxn.wst.dat[uxn.wst.ptr[]+1] == 0xff
    @test a == 0xff

	#= @PO2(::Symbol)::Nothing =#
    _r = 0x00
    a = 0x00
    uxn.wst.ptr[] = 0x00
    uxn.wst.dat[end-1:end] = [0x13, 0x37]
    @PO2(a)::Nothing
    @test uxn.wst.ptr[] == 0xfe
    @test uxn.wst.dat[uxn.wst.ptr[]+1] == 0x13
    @test a == 0x37

	#= @POx(::Symbol)::Nothing =#
	_r = 0x01
	_2 = 0x01
	a = 0x00
    uxn.rst.ptr[] = 0x00
    uxn.rst.dat[end-1:end] = [0x37, 0x13]
	@POx(a)::Nothing
    @test uxn.rst.ptr[] == 0xfe
    @test uxn.rst.dat[uxn.rst.ptr[]+1] == 0x37
    @test a == 0x13

    _r = 0x00
    _2 = 0x00
    a = 0x00
    uxn.wst.ptr[] = 0x00
    uxn.wst.dat[end-1:end] = [0x37, 0x13]
    @POx(a)::Nothing
    @test uxn.wst.ptr[] == 0xff
    @test uxn.wst.dat[uxn.wst.ptr[]+1] == 0x13
    @test a == 0x13

	#= @PU1(::Expr)::Nothing =#
    _r = 0x01
    a = 0x01
	b = 0x02
    uxn.rst.ptr[] = 0x00
    @PU1(a + b)::Nothing
    @test uxn.rst.ptr[] == 0x01
    @test uxn.rst.dat[uxn.rst.ptr[]] == 0x03

    #= @PUx(::Expr)::Nothing =#
    #= @PU1(::Symbol)::Nothing =#
    _2 = 0x01
    _r = 0x00
    a = 0x0005
    b = 0x0002
	c = 0x00
    uxn.wst.ptr[] = 0x00
    @PUx(a + b)::Nothing
    @test uxn.wst.ptr[] == 0x02
    @test uxn.wst.dat[uxn.wst.ptr[]] == 0x0007
	@test c == 0x0007
	@test typeof(c) == UInt16

	#= @OPC() =#
    # _2 = 0x01
    # _r = 0x00
    # a = 0x0005
    # b = 0x0002
    # c = 0x00
    # uxn.wst.ptr[] = 0x00
	# @cswitch 0x01 begin
	# 	@case 0xff; break
	# 	# @E @OPC(0x01, POx(a), PUx(a + 1))
	# end
    # @test uxn.wst.ptr[] == 0x02
    # @test uxn.wst.dat[uxn.wst.ptr[]] == 0x0007
    # @test c == 0x0007
    # @test typeof(c) == UInt16

	# @cswitch 1 begin
	# 	$@OPCC
	# end
end
