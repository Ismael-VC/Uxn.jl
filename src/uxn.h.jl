#=
Copyright (c) 2021 Devine Lu Linvega
              2024 Ismael Venegal Castelló

Permission to use, copy, modify, and distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE.
=#

const var"@E" = var"@macroexpand"

macro PEEK2(d::Expr, i::UInt8) :(UInt16($d[$i + 1]) << 8 | $d[$i + 2]) end
macro POKE2!(d::Expr, i::UInt8, v::Symbol)
	quote
		$d[$i + 1] = UInt8($(esc(v)) >> 8)
		$d[$i + 2] = UInt8($(esc(v)) & 0xFF)
		nothing
	end
end

const COLUMN_SIZE = ROW_SIZE = 0x10
const PAGE_PROGRAM = PAGE_SIZE = STACK_SIZE = 0x100
const INITIAL_POINTER = 0x00

struct Stack
	dat::Vector{UInt8}
	ptr::Ref{UInt8}
end

Stack() = Stack(zeros(UInt8, STACK_SIZE), INITIAL_POINTER)

struct CPU
	ram::Array{UInt8, 3}
	dev::Matrix{UInt8}
	wst::Stack
	rst::Stack
end

CPU() = CPU(
	zeros(UInt8, ROW_SIZE, COLUMN_SIZE, PAGE_SIZE),
	zeros(UInt8, ROW_SIZE, COLUMN_SIZE), 
	Stack(), 
	Stack()
)

#= required functions =#

function emu_dei(addr::UInt8)::UInt8 end
function emu_deo!(addr::UInt8, value::UInt8)::UInt8 end
const uxn = CPU()

#= built-ins =#

function uxn_eval!(pc::UInt16)::Int end
