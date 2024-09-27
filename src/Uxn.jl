module Uxn

export @PEEK2, POKE2!, PAGE_PROGRAM, Stack, STACK_SIZE,
       CPU, uxn, emu_dei, emu_deo!, uxn_eval!, @JMI, @DEC, @INC, @POx, @PO1, @PO2,
       @PUx, @PU1, @OPC, @E, @OPCC

# Write your package code here.
include("uxn.h.jl")
include("uxn.c.jl")

end	
