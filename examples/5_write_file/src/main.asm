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

instructions: db "Type the name of a file to write to and hit enter.",10,0
instructions2: db 10,"Type what you want to write to the file and hit enter.",10,0

failure_message: 
db 10,"The file was not written successfully.",10
db "maybe you don't have permission to write to the specified location?",10,0

section .text


main:

	;set up a new stack frame, first save the old stack base pointer by pushing it
	push rbp
	
	;then slide the base of the stack down to RSP by moving RSP into RBP
	mov rbp, rsp

	;Windows requires a minimum of 32 bytes on the stack before calling any other functions
	;so this is for compatibility, its perfectly valid on Linux and Mac also
	sub rsp, 32


	;move a pointer to our initial instructions string into RDI so we can print it with print_string
	;this just tells the user to type the name of the file they want to write to
	mov rdi, QWORD instructions
	call print_string
	

	;read a string from the console using read_string, this string will be the file name
	;we will have to call free_mem on the pointer it returns later when we are done with it
	call read_string
	
	;save the file name pointer on the stack at RSP so we can access it later
	mov [rsp], rax

	;move our second instructions message into RDI so we can print it
	;this message tells the user to type in some text to write to the file
	mov rdi, QWORD instructions2
	call print_string

	;call read_string so we can read some text from the console, to be written to the file
	call read_string
	
	;save the result of read_string (the file content string)
	;on the stack in a second location, so we can access it later
	mov [rsp+8], rax


	;move the file name string pointer we stored on the stack into RDI, so it can be
	;used as the first parameter of write_file
	mov rdi, [rsp]
	
	;move the file content string pointer we stored on the stack into RSI, so it can be
	;used as the second parameter to write_file
	mov rsi, [rsp+8]
	
	;call write_file to write the file
	;the first parameter of write_file is RDI (pointer to file name string)
	;and the second parameter of write_file is RSI (pointer to file content string)
	call write_file

	;move the success code into memory, so we can tell the user if the file was written successfully or not
	mov [rsp+16], rax
	
	;write_file may have modified RDI and RSI so we need to move the file name string and file content string
	;back into registers from the stack so we can call free_mem on them, as they both use dynamically allocated memory
	
	;move the file name pointer into RDI and call free_mem on it
	mov rdi, [rsp]
	call free_mem
	
	;move the file content pointer into RDI and call free_mem on it
	mov rdi, [rsp+8]
	call free_mem

	
	;print a failure message if the file was not written successfully
	cmp QWORD [rsp+16],1   ; 1 = success
	je .success
	
	mov rdi, QWORD failure_message
	call print_string
	
	.success:
	
	

	;restore the stack frame of the function that called this function
	;first add back the amount that we subtracted from RSP
	;including any additional subtractions we made to RSP after the initial one (just sum them)
	add	rsp, 32
	
	;after we add what we subtracted back to RSP, the value of RBP we pushed is the only thing left
	;so we pop it back into RBP to restore the stack base pointer
	pop	rbp
	
	ret
