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

cextern write_file_impl

global write_file
global append_file

section .data

;C file write mode strings
append_mode: db "ab+",0
write_mode: db "wb",0

section .text

%ifdef _LIBASM_IO_ABI_WINDOWS_

write_file:
	;Windows uses RCX for the first parameter to C calls, RDX for the second and R8 for the third
	;Windows returns in RAX though like Unix so no need to mess with that
	push rbp
	mov rbp, rsp
	sub rsp, 32
	mov rcx, rdi
	mov rdx, rsi
	mov r8, QWORD write_mode
	call write_file_impl
	add	rsp, 32
	pop	rbp
	ret
	
	
append_file:
	;Windows uses RCX for the first parameter to C calls, RDX for the second and R8 for the third
	;Windows returns in RAX though like Unix so no need to mess with that
	push rbp
	mov rbp, rsp
	sub rsp, 32
	mov rcx, rdi
	mov rdx, rsi
	mov r8, QWORD append_mode
	call write_file_impl
	add	rsp, 32
	pop	rbp
	ret
	
%else

write_file:
	;If this is a Unix build, just pass the parameters straight through, except for RDX
	;RDX is the third parameter and needs to contain the file write mode string
	;A valid call stack is still needed
	push rbp
	mov rbp, rsp
	sub rsp, 32
	mov rdx, QWORD write_mode
	call write_file_impl
	add	rsp, 32
	pop	rbp
	ret
	
append_file:
	;If this is a Unix build, just pass the parameters straight through, except for RDX
	;RDX is the third parameter and needs to contain the file write mode string
	;A valid call stack is still needed
	push rbp
	mov rbp, rsp
	sub rsp, 32
	mov rdx, QWORD append_mode
	call write_file_impl
	add	rsp, 32
	pop	rbp
	ret
	
%endif
