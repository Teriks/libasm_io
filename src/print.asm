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



%include "libasm_io_cdecl.inc"
%include "libasm_io_libc_call.inc"
%include "libasm_io_defines.inc"

global print_string
global print_int
global print_nl
global print_char
global print_address
global print_uint


cextern printf
cextern print_int_impl
cextern print_uint_impl

section .data

print_str_fmt: db '%s',0
print_char_fmt: db '%c',0
print_int_fmt: db '%d',0
print_addr_fmt: db '%p',0
print_uint_fmt: db '%u',0
new_line: db 10,0

section .text



printf_portable:

%ifdef _LIBASM_IO_ABI_WINDOWS_

	; Converts the windows calling convention for 'printf' into the System V calling convention
   
	push rbp
	mov rbp, rsp
	sub rsp, 32
	mov rcx, rdi
	mov rdx, rsi
	call printf
	add rsp, 32
	pop rbp
	ret
	
%else

	; Otherwise, just pass the parameters in the registers straight through

	push rbp
	mov rbp, rsp
	sub rsp, 32
	xor rax,rax
	libc_call printf
	add rsp, 32
	pop rbp
	ret
	
%endif





; print_int and print_uint are done in C to make the format specifier draw from
; inttypes.h, for portability

%ifdef _LIBASM_IO_ABI_WINDOWS_

print_int:

	push rbp
	mov rbp, rsp
	sub rsp, 32
	mov rcx, rdi
	call print_int_impl
	add rsp, 32
	pop rbp
	ret
	
	
print_uint:

	push rbp
	mov rbp, rsp
	sub rsp, 32
	mov rcx, rdi
	call print_uint_impl
	add rsp, 32
	pop rbp
	ret
	
%else

print_int:
	push rbp
	mov rbp, rsp
	sub rsp, 32
	call print_int_impl
	add rsp, 32
	pop rbp
	ret
	
print_uint:
	push rbp
	mov rbp, rsp
	sub rsp, 32
	call print_uint_impl
	add rsp, 32
	pop rbp
	ret
	
%endif





print_string:
	push rbp
	mov rbp, rsp
	sub rsp, 32
	mov rsi, rdi
	mov rdi, QWORD print_str_fmt
	call printf_portable
	add rsp, 32
	pop rbp
	ret

	
	

; print a character, using the character code in rdi

print_char:
	push rbp
	mov rbp, rsp
	sub rsp, 32
	mov rsi, rdi
	mov rdi, QWORD print_char_fmt
	call printf_portable
	add rsp, 32
	pop rbp
	ret



; print a new line character

print_nl:
	push rbp
	mov rbp, rsp
	sub rsp, 32
	mov rsi, QWORD new_line
	mov rdi, QWORD print_str_fmt
	call printf_portable
	add rsp, 32
	pop rbp
	ret




; print the address contained in the rdi register

print_address:
	push rbp
	mov rbp, rsp
	sub rsp, 32
	mov rsi, rdi
	mov rdi, QWORD print_addr_fmt
	call printf_portable
	add rsp, 32
	pop rbp
	ret




	
	

