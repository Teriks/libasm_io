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





cglobal main
section .data

msg db "Enter up to 64 bits of binary and it will be converted into a number:",10,0
msg2 db "Enter a number, it will be converted into a 64 bit binary representation:",10,0
eqls db "value = ",0

section .text


;read up to 64 bits of binary from standard input,
;a new line should terminate the end of the binary number
;the number is returned in RAX
read_binary:
	push rbp
	mov rbp,rsp
	sub rsp, 32
	
	

	mov QWORD [rsp],0
	mov QWORD [rsp+8],0
	
	.loop:
	
	call read_char
	mov rdi, rax
	
	;check for a new line, if there is one then jump out of the loop
	cmp rdi,10
	je .outloop
	
	
	;shift [rsp+8] left by one and assign it to itself
	shl QWORD [rsp+8],1


	;character code 48 = '0', and 49 = '1', you can convert the character code
	;to a number by subtracting 48
	sub rdi, 48
	add QWORD [rsp+8], rdi

	jmp .loop
	
	.outloop:
	
	mov	rax, QWORD[rsp+8]

	add rsp, 32
	pop rbp
	
	ret	
	
	
	
	
	
;print the value of RDI as a 64 bit binary number
print_binary:
	push rbp
	mov rbp, rsp
	sub rsp, 32
	
	
	mov QWORD [rsp], 63
	mov [rsp+8], rdi
	mov QWORD [rsp+16], 0
	
	.loop:
	
	;load rcx, the bottom byte is CL
	;counter will not overflow CL as it only counts down from 63
	;which fits in a byte [0-255]
	mov rcx, QWORD [rsp]
	mov rax, [rsp+8]
	;shift right by the amount in the counter
	shr rax, cl
	mov QWORD [rsp+16], rax
	
	;boolean and with 1
	and rax, 1
	mov rdi, rax
	call print_int
	
	
	dec QWORD [rsp]
	cmp QWORD [rsp], 0
	jge .loop
	
	
	add rsp, 32
	pop rbp
	ret
	
	


main:
	
	push rbp
	mov rbp, rsp
	sub rsp, 32


	mov rdi, QWORD msg
	call print_string
	
	call read_binary
	mov [rsp], rax
	
	call print_nl
	
	mov rdi, QWORD eqls
	call print_string
	
	mov rdi, [rsp]
	call print_int
	call print_nl
	call print_nl
	
	
	mov rdi, QWORD msg2
	call print_string
	call read_int
	mov [rsp], rax
	
	call print_nl
	
	
	mov rdi, QWORD eqls
	call print_string
	
	mov rdi, [rsp]
	call print_binary
	call print_nl
	call print_nl
	
	
	
	add rsp, 32
	pop rbp
	
	ret
