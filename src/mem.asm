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

global free_mem
global alloc_mem

cextern free
cextern malloc



section .text




%ifdef _LIBASM_IO_ABI_WINDOWS_
;Converts the windows calling convention for 'malloc' and 'free' into the System V calling convention
;so the API is consistent across platforms

free_mem:
	push rbp
	mov rbp, rsp
	sub rsp, 32  
	mov	rcx, rdi
	call free
	add	rsp, 32
	pop	rbp
	ret
	
	
alloc_mem:
	push rbp
	mov rbp, rsp
	sub rsp, 32  
	mov	rcx, rdi
	call malloc
	add	rsp, 32
	pop	rbp
	ret
%else

;Otherwise, just pass the parameters in the registers straight through

free_mem:
	push rbp
	mov rbp, rsp
	sub rsp, 32  
	libc_call free
	add	rsp, 32
	pop	rbp
	ret
	
	
alloc_mem:
	push rbp
	mov rbp, rsp
	sub rsp, 32  
	libc_call malloc
	add	rsp, 32
	pop	rbp
	ret
	
%endif
   