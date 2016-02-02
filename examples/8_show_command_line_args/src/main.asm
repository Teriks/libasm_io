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





;main gets called by the C runtime library, so it needs to be global to let the linker find it
;the cglobal macro from the library is used to add an underscore to the front of main if needed
;some platforms (Like Mac) use underscores in front of all their C library symbols
;the macro also defines main as _main if an underscore is needed, so we can reference it as 'main'
;consistently across platforms
cglobal main


section .data


arg_str: db "arg ",0
eql_str: db " = ",0


section .text


main:


	;set up a new stack frame, first save the old stack base pointer by pushing it
	push rbp
	
	;then slide the base of the stack down to RSP by moving RSP into RBP
	mov rbp, rsp

	;Windows requires a minimum of 32 bytes on the stack before calling any other functions
	;so this is for compatibility, its perfectly valid on Linux and Mac also
	sub rsp, 32
	
	
	
	%ifdef _LIBASM_IO_ABI_WINDOWS_
	;we are on windows using windows ABI, so the parameters of main are passed in RCX(1) and RDX(2), not RDI(1) and RSI(2)
	;we fix it if the libasm_io library defines _LIBASM_ABI_WINDOWS_ for us
	
	mov rdi, rcx
	mov rsi, rdx
	
	%endif
	
	
	;RDI contains an element count for the items in RSI
	;RSI contains pointer to an array of pointers, (array of pointers to strings)
	
	mov QWORD [rsp], 0 ;[RSP] is our loop counter here
	mov [rsp+8], rdi   ;[RSP+8] is our upper limit
	mov [rsp+16], rsi  ;[RSP+16] is our array pointer
	
	.for:
	
	mov rdi, QWORD arg_str     ;"arg "
	call print_string
	
	mov rdi, [rsp]             ;index
	call print_int
	
	
	mov rdi, QWORD eql_str     ;" = "
	call print_string
	
	
	mov rdi, [rsp]       ;index
	mov rsi, [rsp+16]    ;array pointer
	mov rdi, [rsi+rdi*8] ;grab an 8 byte pointer value from the C array of pointers, it points to a string
	
	call print_string ;print the string at the pointer
	call print_nl     ;print a new line
	
	
	inc QWORD [rsp]
	mov rdi, [rsp+8]
	cmp [rsp], rdi
	jl .for
	
	
	
	
	;restore the stack frame of the function that called this function
	;first add back the amount that we subtracted from RSP
	;including any additional subtractions we made to RSP after the initial one (just sum them)
	add	rsp, 32
	
	;after we add what we subtracted back to RSP, the value of RBP we pushed is the only thing left
	;so we pop it back into RBP to restore the stack base pointer
	pop	rbp
	

	ret
	
