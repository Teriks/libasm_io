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



%include "libasm_io.inc"

;we are making this function/label 'public' to other object files during linking
;sort of like public on a C# class or a c++ class member

;we don't need to use cglobal here, we wrote this function in assembly and it will never
;be assembled by nasm with an underscore in the front
global read_and_print_number

section .data

echo_number: db "You entered the number: ",0
goodbye: db "Now I'm going to exit",0

section .text

read_and_print_number:
	;set up a new stack frame, first save the old stack base pointer by pushing it
	push rbp
	
	;then slide the base of the stack down to RSP by moving RSP into RBP
	mov rbp, rsp

	;Windows requires a minimum of 32 bytes on the stack before calling any other functions
	;so this is for compatibility, its perfectly valid on Linux and Mac also
	sub rsp, 32
	
	
	;read an integer value from the console and store it in RAX
	call read_int

	;make sure we keep the return value of call read_int, in-case print_string modifies RAX
	;we can mov it into a location on the stack to save it
	mov [rsp], rax

	;print_string prints the string at the pointer contained in RDI
	;first we move the message label (a 64bit pointer) into RDI
	mov rdi, QWORD echo_number

	;then call the print function	
	call print_string
	
	;restore the return value of read_int into RDI
	mov rdi, [rsp]


	
	;we want to print the value returned by read_int
	;print_int uses RDI for the parameter, and we just restored the return value of read_int into RDI 
	call print_int
	
	;print a new line after the integer
	call print_nl

	;move a pointer to the goodbye message into RDI
	mov rdi, QWORD goodbye
	
	;print the goodbye message
	call print_string
	
	;then print a new line
	call print_nl
	
	;restore the stack frame of the function that called this function
	;first add back the amount that we subtracted from RSP
	;including any additional subtractions we made to RSP after the initial one (just sum them)
	add	rsp, 32
	
	;after we add what we subtracted back to RSP, the value of RBP we pushed is the only thing left
	;so we pop it back into RBP to restore the stack base pointer
	pop	rbp

	ret
	
