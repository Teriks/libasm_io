;=================================================================
;
; Copyright (c) 2014, Teriks
;
; All rights reserved.
; 
; libasm_io is distributed under the following BSD 3-Clause License
; 
; Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
; 
; 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
; 
; 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the
;    documentation and/or other materials provided with the distribution.
; 
; 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from
;    this software without specific prior written permission.
; 
;  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
;  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
;  HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
;  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
;  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
;  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
;
;==================================================================





;the following is defined when the library examples are being built with the library
%ifdef _LIBASM_IO_BUILDING_ 

;if the library build system is building the examples, then an option to NASM specifies the directory
;to find this include, so we can include it by its name only
%include "libasm_io.inc"    
 
%else

;otherwise if this code is compiled against the already installed library
;it's header needs to be included from its installed location
%include "/usr/local/include/libasm_io.inc"

%endif





;main gets called by the c runtime library, so it needs to be global to let the linker find it
;the cglobal macro from the library will add an underscore to the 'main' symbol name in the global statement
;and define main as _main if the platform we are on uses underscores in front of its C symbols

cglobal main


section .data

message_1: db "this",0
message_2: db "is",0
message_3: db "how",0
message_4: db "to",0
message_5: db "use",0
message_6: db "the",0
message_7: db "stack",0


message_1a: db "this : ",0
message_2a: db "is : ",0
message_3a: db "how : ",0
message_4a: db "to : ",0
message_5a: db "use : ",0
message_6a: db "the : ",0
message_7a: db "stack : ",0


example_1: db "printing output from example 1:",0

example_2: db "printing output from example 2:",0

example_3: db "printing output from the 'fun_with_lea' function:",0

section .text


print_messages_example:
	;set up a new stack frame
	push rbp
	mov rbp, rsp
	
	;subtract RSP by 56+8 to make room for 7x 8-byte pointer values on the stack, 7*8=56
	;the +8 is to align the stack pointer to 16 bytes, 56/16 = 3.5 and (56+8)/16=4.0
	;to align to 16 bytes, the value has to be divisible by 16 evenly
	
	;64 bit windows requires the stack pointer be aligned to 16 bytes
	;and also that the stack contains at least 32 bytes of space in all function calls that 
	;call other functions, so this is for portability
	
	sub rsp, (56+8)
	
	;================================
	;the keyword QWORD stands for QUAD WORD, a WORD is 16 bits (or two bytes)
	;so a QWORD has 64 bits, which is big enough to hold the 64bit pointer
	;to a message string (or any other memory)

	;we need to specify the size so mov knows how many bytes of data its going to move into a memory location
	;some possible sizes are :
	
	;BYTE -> 8 bits 
	;WORD -> 16 bits
	;DWORD -> 32 bits 
	;TWORD -> 48 bits (three words)
	;QWORD -> 64 bits

	;we want to count by 8's in our offset, because we are moving 64 bit values which are 8 bytes long
	;and they should not overlap at all
	
	
	;we need to use lea, or just mov, to put the 64 bit address into a register
	;because you cannot move a 64 bit immediate label into memory directly without it being
	;turnicated to 32 bits, which will possibly cause the linker to complain, or worse cause your program to crash
	;and be a hard to find bug
	
	;we can however, move a 64 bit immediate label (A pointer basically) into a register
	;then move the 64 bit register into memory
	
	lea rax, [rel message_1]
	mov QWORD [rsp],	 rax
	
	
	;mov accomplishes the same thing here
	;except we have no option of doing arithmetic on the right hand operand like lea can
	
	mov rax, QWORD message_2
	mov QWORD [rsp+8],	 rax
	
	
	lea rax, [rel message_3]
	mov QWORD [rsp+16],	 rax
	
	lea rax, [rel message_4]
	mov QWORD [rsp+24],	 rax
	
	lea rax, [rel message_5]
	mov QWORD [rsp+32],	 rax
	
	lea rax, [rel message_6]
	mov QWORD [rsp+40],	 rax
	
	lea rax, [rel message_7]
	mov QWORD [rsp+48],	 rax



	;================================

	
	mov rdi, [rsp]
	call print_string
	call print_nl

	mov rdi, [rsp+8]
	call print_string
	call print_nl

	mov rdi, [rsp+16]
	call print_string
	call print_nl

	mov rdi, [rsp+24]
	call print_string
	call print_nl

	mov rdi, [rsp+32]
	call print_string
	call print_nl

	mov rdi, [rsp+40]
	call print_string
	call print_nl

	mov rdi, [rsp+48]
	call print_string
	call print_nl
	
	;restore the previous stack frame
	;we just add to rsp and equal amount to what we subtracted when we entered the function
	;then restore the stack base pointer rbp by popping it
	add rsp, (56+8)
	pop rbp
	ret



print_messages_example_v2:
	;this sets up a new stack frame
	push rbp
	mov rbp, rsp
	



	;subtract RSP by (56+8) to make room for 7x	 8-byte pointer values on the stack 7*8=56
	;the +8 is to align it, because 56 is not aligned to 16 bytes 
	;(we need a value that divides by 16 evenly)
	sub rsp, (56+8)
	

	;================================
	; you can also use RBP with a negative offset to address stack values, we use subtract because we are storing values
	; in the direction in memory that moves towards RSP, (RSP resides at a lower address than RBP)
	; we need to start at an offset equal in size to the data we are moving to memory
	;
	; otherwise, if we use [RBP] as the first address this will happen:
	;
	; -- (etc..)	
	; -- (contains another byte of pointer)
	; -- (rbp) high pointer address (contains a byte of a pointer)
	; --   ..
	; --   ..
	; -- (rsp) low pointer address
	;
	;
	; we would write into the calling functions stack frame and make it mad at us
	; probably crashing the program
	
	; x86_64 is a little-endian architecture, it lays out the bytes of integers from low address to high address
	; starting with the least significant byte
	;=================================

	lea rax, [rel message_1a]
	mov QWORD [rbp-8],	   rax
	
	lea rax, [rel message_2a]
	mov QWORD [rbp-16],	  rax
	
	lea rax, [rel message_3a]
	mov QWORD [rbp-24],	 rax
	
	lea rax, [rel message_4a]
	mov QWORD [rbp-32],	 rax
	
	lea rax, [rel message_5a]
	mov QWORD [rbp-40],	 rax
	
	lea rax, [rel message_6a]
	mov QWORD [rbp-48],	 rax
	
	lea rax, [rel message_7a]
	mov QWORD [rbp-56],	 rax


	;================================

	; its safe to address [RSP] directly
	; because all register values in x86_x64 are in little-endian format
	; (they are laid out from low byte to high byte in memory and in registers) 
	;
	; right now the stack is something like this (thinking in terms of individual bytes in memory):
	;
	;
	; -- (rbp) high address
	; --   ..
	; --   (etc..)
	; --   (third byte of pointer to message_7)
	; --   (second byte of pointer to message_7)
	; -- (rsp) low address	(has the first byte of pointer to message_7)
	; 
	;
	; also, when we address RSP and move it into RDI nasm knows we need to pull a quad word from memory (64 bits)
	; because RDI is a 64bit register
	; 
	; if your moving a byte of memory into a byte register like AL
	; you could just do:
	; 
	; mov AL, [rsp]
	;
	; and nasm will figure out that you want a byte because AL is a byte long
	;

	
	;if we start at RSP now we will be printing in reverse order
	;we aligned our stack to 16 bytes using +8 though, so we need to start at [RSP+8],
	;which is equal to [RBP-56] at this point

	mov rdi, [rsp+8]
	call print_string

	;print RSP+8 as an unsigned 64 bit integer, so we see the address of the string, after the string that's being printed
	lea rdi, [(rsp+8)]
	call print_uint
	call print_nl



	;=========READ ABOUT LEA HERE===========
	
	;we are adding 8 to the end of our effective address to keep up with the fact that RSP was aligned to 16 bytes using +8
	
	mov rdi, [(rsp+8) +8]
	call print_string

	; lea stands for LOAD EFFECTIVE ADDRESS, and it means:
	; 1. take the effective address calculation on the RIGHT and compute the actual pointer value from it
	; 2. put the calculated pointer value in the register on the LEFT 

	lea rdi, [(rsp+8) +8]
	
	;print the address in RDI, which is equal to [(RSP+8) +8]
	call print_uint
	
	call print_nl
	;===================================



	mov rdi, [(rsp+16) +8]
	call print_string

	lea rdi, [(rsp+16) +8]
	call print_uint

	call print_nl


	mov rdi, [(rsp+24) +8]
	call print_string

	lea rdi, [(rsp+24) +8]
	call print_uint 

	call print_nl



	mov rdi, [(rsp+32) +8]
	call print_string

	lea rdi, [(rsp+32) +8]
	call print_uint 

	call print_nl



	mov rdi, [(rsp+40) +8]
	call print_string

	lea rdi, [(rsp+40) +8]
	call print_uint

	call print_nl


	mov rdi, [(rsp+48) +8]
	call print_string

	lea rdi, [(rsp+48) +8]
	call print_uint

	call print_nl
	
	;restore the previous stack frame, add an equal amount to what we subtracted before
	add rsp, (56+8)
	pop rbp
	
	ret




fun_with_lea:
	; I am using LEA here to show you some of the fancy expressions that can be used to address memory 
	; there are some constraints to memory addressing, but nasm can occasionally factor your math down
	; to meet these constraints
	;
	; if your affective address for memory operations do not meet processor constraints
	; you will get an 'invalid effective address' error from nasm
	; the constraints are a bit to long to describe here.
	;
	; but you can read about effective addresses in nasm here:
	;
	; http://www.nasm.us/doc/nasmdoc3.html#section-3.3
	;

	push rbp
	mov rbp, rsp
	sub rsp, 32	 
	
	;calculate a bogus address and print the result.
	;lea can be used for arithmetic on values that are not actually pointers
	;but that's sort of hacky and has limited usage due to constraints on effective addressing calculations
	
	mov rdi, 5
	lea rdi, [rdi+10*2-6]
	
	call print_int
	call print_nl


	;here we add together two registers and multiply by 8
	mov rsi, 8
	mov rdi, 5
	lea rdi, [rsi+rdi*8]
	
	
	call print_int
	call print_nl


	mov rdi, 5
	lea rdi, [rdi-10*8]
	call print_int
	call print_nl
	
	add rsp, 32
	pop rbp

	ret



main:

	;create a new stack frame
	
	;we first save the 'stack base pointer' which is the high address of the stack
	;the stack is like this:
	;
	; -- (rbp) high pointer address
	; --   ..probably local variable/parameter in stack memory from the function that called this one..
	; --   ..maybe another local variable/function parameter from the calling function..
	; -- (rsp) low pointer address
	;

	;save the 'stack base pointer'
	push rbp

	;we effectively slide the bottom of the stack down (RBP) to RSP and make it empty
	;by setting the 'stack base pointer' to the 'stack pointer'
	;
	;it makes the stack like this:
	;
	; -- (rbp) high pointer address = (rsp) low pointer address
	;

	;slide the base of the stack down to RSP, so its empty
	mov rbp, rsp
	
	
	;On windows, we need a minimum of 32 bytes of stack space before calling
	;any functions, RSP also always needs to be aligned to 16 bytes
	;32/16 = 2,	 2 is a whole number which means 32 is indeed aligned to 16 bytes
	
	;this is for compatibility, Linux and Mac can run programs with or without the stack pointer being aligned
	;but on Windows if the stack is not aligned the program will crash
	sub rsp, 32 
	
	
	
	

	
	;print a message describing what the following output is from
	mov rdi, QWORD example_1
	call print_string
	call print_nl
	call print_nl
	
	;call the first example
	call print_messages_example

	;make some space with a new line
	call print_nl



	;print a message saying the following output is from example 2
	mov rdi, QWORD example_2
	call print_string
	call print_nl
	call print_nl

	;call the second example
	call print_messages_example_v2

	;make some space with a new line
	call print_nl


	;print a message saying we are going to output the results of the fun_with_lea example
	mov rdi, QWORD example_3
	call print_string
	call print_nl
	call print_nl

	call fun_with_lea

	call print_nl
	


	;restore the stack to its previous state
	;first an equal amount to RSP as what we subtracted when we entered this function
	;this includes the sum of all additional subtractions made after the first subtraction (if there are any)
	;then restore the base pointer (RBP) by popping it back into itself
	add rsp, 32
	
	;once we do the subtraction, the value of RBP we pushed at the beginning of the function
	;should be the only thing left on the stack
	pop rbp

	ret
