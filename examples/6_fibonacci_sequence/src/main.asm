;=================================================================
;
; Copyright (c) 2014, Teriks
;  
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





cglobal main

section .data
start_msg: db "Enter a number to calculate all the fibonacci numbers from 0 up to and including that number.",0

rec_msg: db "Calculating recursively...",0

itr_msg: db "Calculating iteratively...",0

section .text




;===============================================================================


;fibs takes a number in RDI and calculates the Fibonacci number for it recursively 
;fibs returns the result in RAX

fibs:
	
	;set up a new stack frame for this functions
	push rbp
	mov rbp, rsp
	
	;we need 3 local variables, each of them 8 bytes wide (64bit)
	;3*8=24 so we move RSP down by 24 bytes to make space for them, we align it to 16 bytes by adding 8, because (24+8)/16 = 2 which is even
	sub rsp, 24+8
	
	
	;there will be three local variables
	;[rsp] = variable 1  =  RDI-1
	;[rsp+8] = variable 2  = RDI-2
	;[rsp+16] = variable 3  = fibs([rsp])
	;
	;there is not a fourth variable to hold fibs([rsp+8]) but we dont need one
	;we are just going to use the value returned from fibs([rsp+8]) directly from RAX (see line 77 and 82)
	
	
	cmp rdi,0		;check for 0, fibs(0) = 0 so jump to fibs_0, it returns 0 in RAX and exits this function
	je .fibs_0		;jump if equal
	
	cmp rdi,1		;check for 1, fibs(1) = 1 so jump to fibs_1, it returns 1 in RAX and exits this function
	je .fibs_1		;jump if equal
	
	cmp rdi,2		;check for 2, fibs(2) = 1 so jump to fibs_1 just like if we encounter a 1
	je .fibs_1		;jump if equal
	
	
	mov [rsp], rdi		;these two instructions set [RSP] to N-1 (N is in RDI, so we need to move RDI into [rsp] on the stack first)
	sub QWORD [rsp], 1	;sub subtracts the right operand from the left, and puts the result in the left. 
				;the QWORD before the memory address tells the assembler [rsp] contains a 64 bit quadword type, the type specification is required here
	
	
	mov [rsp+8], rdi	;these two instructions set [RSP] to N-2 in a similar manner as above
	sub QWORD [rsp+8], 2
	
	
	
	mov rdi, [rsp]		;move N-1 from [RSP] (variable 1) into RDI, and call fibs on it to get the first term
	call fibs
	mov [rsp+16], rax	;move the result from to [RSP+16] on the stack (variable 3)
	
	mov rdi, [rsp+8]	;move N-2 from [RSP+8] (variable 2) into RDI, and call fibs on it to get the second term
	call fibs
	
							;add the two terms, RAX already contains the second term, the call to fibs right above set RAX for us (on line 68)
	add rax, QWORD [rsp+16]				;and [rsp+16] (variable 3) contains the first term because we moved it there above (on line 65)
							;so we add them together, making sure RAX is on the left, so that RAX contains the result of the addition
							;again, the QWORD before the memory address is required to tell the ADD insruction [rsp+16] is a pointer to a 64 bit quadword type
	
		
	add rsp, 24+8
	pop rbp
	
	ret		;return, leaving the result of fibs in the RAX register



;the dot in front of the fibs_0 label makes it local to fibs, so the label name can be reused elsewhere if needed
;without causing a symbol naming conflict
.fibs_0:
	mov rax, 0	;RAX is the return value for fibs, return 0

	;return the stack to its state prior to calling fibs, we could also use 'leave'
	mov rsp, rbp
	pop rbp

	ret



.fibs_1:
	mov rax, 1	;RAX is the return value for fibs, return 1

	;return the stack to its state prior to calling fibs, we could also use 'leave'
	mov rsp, rbp
	pop rbp

	ret



;===============================================================================


;calculate all the Fibonacci numbers up to N
;the parameter for this function is RDI

print_fibs_up_to_n:
	push rbp		;set up a new stack frame for this functions
	mov rbp, rsp
	
	;we need 2x  64bit integer variables, they are 8 bytes a piece so we need 16 bytes of space on the stack, we can subtract 32, because that is the minimum on windows
	;and we want to be compatible
	sub rsp, 32
	
	;we are going to do a loop like this: 
	;FOR([RSP+8]=0; [RSP+8] <= [RSP]; [RSP+8]++) { RDI=[RSP+8]; fibs(RDI); }
	
	mov [rsp], rdi		;[RSP] will be our upper limit for our for loop, move the parameter from rdi into it
	mov QWORD [rsp+8], 0	;[RSP+8] will be our counter, we also need to specify the datatype (QWORD here) when moving an immediate value (0) into memory
	
	;the dot in front of .loop makes it local to print_fibs_up_n so we can use the label in other functions
	.loop:
	
	
		mov rdi, [rsp+8]	;make the parameter to fibs the value of the counter
		call fibs		;call fibs on the RDI parameter (which is the set to the value of the counter)
		
		mov rdi, rax		;put the result of fibs in RDI so we can print it, we dont need to push or pop anything before our calls
					;because we are using stack memory for our counter and upper limit variable, which should never be modified by a calling function

		call print_int		;print the result
		call print_nl		;print new line
		
		inc QWORD [rsp+8]	;increment the counter in memory by 1, we need the data type QWORD keyword here to tell INC we are incrementing a 64 bit value in memory
		
		mov rcx, [rsp]		;we cannot compare two memory operands like this: CMP [RSP], [RSP+8]
					;that would be a syntax error, one of the two operands must be a register, it can be either one (left or right but not both)
					;therefore we are going to move our upper limit variable into the rcx register, so we can compare it to [RSP+8] which is our counter
		
		cmp [rsp+8], rcx	;compare the counter to the upper limit, [RSP+8] is the counter, RCX now contains the upper limit from the instruction above
		jle .loop		;jump to fib_loop if counter less than or equal to upper limit
	
	;end fib_loop
	
	add rsp, 32
	pop rbp
	ret




;calculate all the Fibonacci numbers up to N without using recursion
;the parameter for this function is RDI

print_fibs_up_to_n_without_recursion:
	
	; this is the algorithm we are going to use, as written in C code
	;
	;int n, first = 0, second = 1, next, c;
	;for ( c = 0 ; c < n ; c++ )
	;{
	;   if ( c <= 1 )
	;   {
	;      next = c;
	;   }
	;   else
	;   {
	;      next = first + second;
	;      first = second;
	;      second = next;
	;   }
	;   printf("%d\n",next);
	;}
	
	push rbp	;set up a new stack frame for this functions
	mov rbp, rsp
	
	sub rsp, 40+8		;room for 5x 64 bit variables, 8*5=40, we add 8 to align 40 to 16 bytes, because 48/16=3 which is even
	
	mov [rsp], rdi		;[RSP] is the upper limit (n)
	mov QWORD [rsp+8], 0	;[RSP+8] is the counter (c)
	mov QWORD [rsp+16], 0	;[RSP+16] is  (next)
	mov QWORD [rsp+24], 0	;[RSP+24] is  (first)
	mov QWORD [rsp+32], 1	;[RSP+32] is  (second)
	
	
	.loop:
		cmp QWORD [RSP+8], 1		;compare [RSP+8] (c) to 1 
		jnle .else			;if !(c<=1), jump to the else branch, jnle stands for 'jump if not less than or equal to'
						;this is a bit of an inversion to whats seen in the C code above, but it accomplishes the same thing
		
			mov rcx, [rsp+8]	;this moves [rsp+8] into [rsp+16], this represents: next=c; in the C code
			mov [rsp+16], rcx
			jmp .end_else
		
		.else:				;this is the else branch
		
			mov rcx, [rsp+24]	;mov [rsp+24] (first) into RCX so we can add it to [rsp+32] (second)
			add rcx, QWORD [rsp+32]
		
			mov [rsp+16], rcx	;assign the result of the addition to [rsp+16], this represents: next = first+second; in the C code
		
			mov rcx, [rsp+32]	;mov [rsp+32] (second) into RCX, so we can assign RCX to [rsp+24] (first), this represents:  first = second; in the C code
			mov [rsp+24], rcx
		
			mov rcx, [rsp+16]	;mov [rsp+16] (next) into RCX, so we can assign RCX to [rsp+32] (second), this represents:  second = next; in the C code
			mov [rsp+32], rcx
		
		.end_else:
		
		mov rdi, [rsp+16]	;mov [rsp+16] (next) into RDI so we can print it with print_int, this represents: printf("%d\n",next); in the C code
		call print_int		;prints the value in RDI
		call print_nl		;print a new line
		
		inc QWORD [rsp+8]	;increment [rsp+8] (counter) by 1 after the comparison
		
		mov rcx, [rsp+8]	;mov [rsp+8] (c) into rcx, (its the counter)
		cmp rcx, [rsp]		;compare [rsp+8] (c) counter to [rsp] (n)  (the upper limit)
		
		jle .loop		;if RCX (c) is less than or equal to [rsp] (n) jump to .loop
	
	
	add rsp, 40+8		;restore the stack to its previous state, before we called print_fibs_up_n, we could also use the 'leave' opcode
	pop rbp
	ret
   
	

;===============================================================================


main:
	
	
	push rbp		;set up a new stack frame for this functions
	mov rbp, rsp
	sub rsp, 32
	
	mov rdi, QWORD start_msg
	call print_string
	call print_nl
	
	call read_int
	
	mov [rsp], rax
	
	
	mov rdi, QWORD itr_msg
	call print_string
	call print_nl
	
	mov rdi,[rsp]
	call print_fibs_up_to_n_without_recursion
	
	mov rdi, QWORD rec_msg
	call print_string
	call print_nl
	
	mov rdi,[rsp]
	call print_fibs_up_to_n
	
	
	add rsp, 32
	pop rbp
	
	ret
	
