#=
Copyright (u) 2022-2024 Devine Lu Linvega, Andrew Alderwick, Andrew Richards, 
                        Ismael Venegas Castelló

Permission to use, copy, modify, and distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE.
=#

using CSyntax: @cswitch

macro OPC(opc::UInt8, init::Expr, body::Expr)
	quote
		Symbol("@case")((0x20|$opc; let _2=1,_r=0; $init; $body end; break))
		Symbol("@case")((0x40|$opc; let _2=0,_r=1; $init; $body end; break))
		Symbol("@case")((0x00|$opc; let _2=0,_r=0; $init; $body end; break))
		Symbol("@case")((0x60|$opc; let _2=1,_r=1; $init; $body end; break))
		Symbol("@case")((0x80|$opc; let _2=0,_r=0; k=uxn.wst.ptr; $init; uxn.wst.ptr=k; $body end; break))
		Symbol("@case")((0xa0|$opc; let _2=1,_r=0; k=uxn.wst.ptr; $init; uxn.wst.ptr=k; $body end; break))
		Symbol("@case")((0xc0|$opc; let _2=0,_r=1; k=uxn.rst.ptr; $init; uxn.rst.ptr=k; $body end; break))
		Symbol("@case")((0xe0|$opc; let _2=1,_r=1; k=uxn.rst.ptr; $init; uxn.rst.ptr=k; $body end; break))
	end
end

macro OPCC()
	quote
        Symbol("@case")((2; println("This is a"); break))
        Symbol("@case")((3; println("This is b"); break))
	end
end

#= Microcode =#
 
macro JMI() :(a = UInt16(uxn.ram[pc+1]) << 8 | uxn.ram[pc+2]; pc += a + 2; nothing) |> esc end
# #define JMP(i) if(_2) pc = i; else pc += (Sint8)i;
# #define REM if(_r) uxn.rst.ptr -= 1 + _2; else uxn.wst.ptr -= 1 + _2;
macro INC(s::Symbol, rhs::Union{Expr,Symbol}) :(p = uxn.$s.ptr[]; uxn.$s.ptr[] += 1; uxn.$s.dat[p+1] = $(esc(rhs)); nothing) end
macro DEC(s::Symbol) :(uxn.$s.ptr[] -= 0x01; uxn.$s.dat[uxn.$s.ptr[]+1]) end
macro POx(o::Symbol) :(if Bool(_2); @PO2($o) else @PO1($o) end; nothing) |> esc end
macro PO1(o::Union{Expr, Symbol}) :($o = Bool(_r) ? @DEC(rst) : @DEC(wst); nothing) |> esc end
macro PO2(o::Symbol) :(@PO1($o); $o |= (Bool(_r) ? @DEC(rst) : @DEC(wst)) << 8; nothing) |> esc end
macro PUx(i::Expr) :(if Bool(_2); c = $i; @PU1(UInt8(c >> 8)); @PU1(c) else @PU1($i) end) |> esc end
macro PU1(i::Union{Expr, Symbol}) :(if Bool(_r); @INC(rst, $i) else @INC(wst, $i) end; nothing) |> esc end
# #define RP1(i) if(_r) INC(wst) = i; else INC(rst) = i;
# #define GET(o) if(_2) PO1(o[1]) PO1(o[0])
# #define PUT(i) PU1(i[0]) if(_2) { PU1(i[1]) }
# #define DEI(i,o) o[0] = emu_dei(i); if(_2) o[1] = emu_dei(i + 1); PUT(o)
# #define DEO(i,j) emu_deo(i, j[0]); if(_2) emu_deo(i + 1, j[1]);
# #define PEK(i,o,m) o[0] = uxn.ram[i]; if(_2) o[1] = uxn.ram[(i + 1) & m]; PUT(o)
# #define POK(i,j,m) uxn.ram[i] = j[0]; if(_2) uxn.ram[(i + 1) & m] = j[1];
# 
function uxn_eval!(pc::UInt16)::Int
	let a::UInt16, b::Int, c::UInt16, x::Vector{Int}, y::Vector{Int}, z::Vector{UInt8}
	  	if (!pc || uxn.dev[0x0f]) return 0 end
		while true
			@cswitch uxn.ram[pc] begin
			#= BRK =# @case 0x00; return 1
			#= JCI =# @case 0x20; if @DEC(wst); @JMI(); break end; pc += 2; break
			#= JMI =# @case 0x40; JMI(); break
			#= JSI =# @case 0x60; c = pc + 2; @INC(rst, c >> 8); @INC(rst, c); @JMI(); break
			#= LI2 =# @case 0xa0; pc += 1; INC(wst, uxn.ram[p])
			#= LIT =# @case 0x80; pc += 1; INC(wst, uxn.ram[p]); break
			#= L2r =# @case 0xe0; pc += 1; INC(rst, uxn.ram[p]);
			#= LIr =# @case 0xc0; pc += 1; INC(rst, uxn.ram[p]); break
			#= INC =# @E @OPC(0x01, POx(a), PUx(a + 1))
	# 		#= POP =# @E OPC(0x02, REM, {})
	# 		#= NIP =# @E OPC(0x03, GET(x) REM,PUT(x))
	# 		#= SWP =# @E OPC(0x04, GET(x) GET(y),PUT(x) PUT(y))
	# 		#= ROT =# @E OPC(0x05, GET(x) GET(y) GET(z),PUT(y) PUT(x) PUT(z))
	# 		#= DUP =# @E OPC(0x06, GET(x),PUT(x) PUT(x))
	# 		#= OVR =# @E OPC(0x07, GET(x) GET(y),PUT(y) PUT(x) PUT(y))
	# 		#= EQU =# @E OPC(0x08, POx(a) POx(b),PU1(b == a))
	# 		#= NEQ =# @E OPC(0x09, POx(a) POx(b),PU1(b != a))
	# 		#= GTH =# @E OPC(0x0a, POx(a) POx(b),PU1(b > a))
	# 		#= LTH =# @E OPC(0x0b, POx(a) POx(b),PU1(b < a))
	# 		#= JMP =# @E OPC(0x0c, POx(a),JMP(a))
	# 		#= JCN =# @E OPC(0x0d, POx(a) PO1(b), if(b) { JMP(a) })
	# 		#= JSR =# @E OPC(0x0e, POx(a),RP1(pc >> 8) RP1(pc) JMP(a))
	# 		#= STH =# @E OPC(0x0f, GET(x),RP1(x[0]) if(_2) { RP1(x[1]) })
	# 		#= LDZ =# @E OPC(0x10, PO1(a),PEK(a, x, 0xff))
	# 		#= STZ =# @E OPC(0x11, PO1(a) GET(y),POK(a, y, 0xff))
	# 		#= LDR =# @E OPC(0x12, PO1(a),PEK(pc + (Sint8)a, x, 0xffff))
	# 		#= STR =# @E OPC(0x13, PO1(a) GET(y),POK(pc + (Sint8)a, y, 0xffff))
	# 		#= LDA =# @E OPC(0x14, PO2(a),PEK(a, x, 0xffff))
	# 		#= STA =# @E OPC(0x15, PO2(a) GET(y),POK(a, y, 0xffff))
	# 		#= DEI =# @E OPC(0x16, PO1(a),DEI(a, x))
	# 		#= DEO =# @E OPC(0x17, PO1(a) GET(y),DEO(a, y))
	# 		#= ADD =# @E OPC(0x18, POx(a) POx(b),PUx(b + a))
	# 		#= SUB =# @E OPC(0x19, POx(a) POx(b),PUx(b - a))
	# 		#= MUL =# @E OPC(0x1a, POx(a) POx(b),PUx(b * a))
	# 		#= DIV =# @E OPC(0x1b, POx(a) POx(b),PUx(a ? b / a : 0))
	# 		#= AND =# @E OPC(0x1c, POx(a) POx(b),PUx(b & a))
	# 		#= ORA =# @E OPC(0x1d, POx(a) POx(b),PUx(b | a))
	# 		#= EOR =# @E OPC(0x1e, POx(a) POx(b),PUx(b ^ a))
	# 		#= SFT =# @E OPC(0x1f, PO1(a) POx(b),PUx(b >> (a & 0xf) << (a >> 4)))
			end
			pc += 1
		end
	end
end
