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

;we are going to print out the source code to this program when it runs
;so we need a string for our filename, the '../src' means 'up one directory' inside the 'src' directory 
filename: db "../src/main.asm",0


section .text


main:

	;set up a new stack frame, first save the old stack base pointer by pushing it
	push rbp
	
	;then slide the base of the stack down to RSP by moving RSP into RBP
	mov rbp, rsp

	;Windows requires a minimum of 32 bytes on the stack before calling any other functions
	;so this is for compatibility, its perfectly valid on Linux and Mac also
	sub rsp, 32
	
	
	

	;move the filename pointer into RDI then call read_file to read the file into a string
	;the string is in dynamical allocated memory so we will need to call free_mem on it later
	mov rdi, QWORD filename
	call read_file

	;mov the pointer to the string containing the file content into RDI, (its returned in RAX)
	mov rdi, rax
	
	;save the pointer to the string so we can call free_mem on it later
	;we do this by moving it to a location on the stack, [RSP] will work since we have space for
	;four 64 bit integers allocated on the stack already, and we are only placing one into memory
	mov [rsp], rdi

	;print the string at the pointer in RDI
	call print_string
	
	;print a new line to the console
	call print_nl

	;move the pointer to the file content string back into RDI so we can call free_mem on it
	mov rdi, [rsp]

	;call free on the string pointer, to free the dynamic memory read_file allocated for it 
	call free_mem


	;restore the stack frame of the function that called this function
	;first add back the amount that we subtracted from RSP
	;including any additional subtractions we made to RSP after the initial one (just sum them)
	add	rsp, 32
	
	;after we add what we subtracted back to RSP, the value of RBP we pushed is the only thing left
	;so we pop it back into RBP to restore the stack base pointer
	pop	rbp

	ret
