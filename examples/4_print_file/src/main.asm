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

instructions: db "Type the name of a file to display and hit enter.",10,0
error_msg: db "File could not be opened. Try again.",10,0

section .text


main:

	;set up a new stack frame, first save the old stack base pointer by pushing it
	push rbp
	
	;then slide the base of the stack down to RSP by moving RSP into RBP
	mov rbp, rsp

	;Windows requires a minimum of 32 bytes on the stack before calling any other functions
	;so this is for compatibility, its perfectly valid on Linux and Mac also
	sub rsp, 32
	
	
	
	;move a pointer to the instructions message into RDI so we can print it with print_string
	mov rdi, QWORD instructions
	call print_string

	;this is the a label for a loop that continues asking for a file name until we give a file name that is correct/exists
	;the dot in front of the label tells nasm that its a local label
	;the label is associated with the last normal label, (to make this label only available in this function basically)
	;this prevents naming clashes between labels which can cause hard to find bugs in your program
	.read_file_start:
	
		;call read_string to read a string from the console typed by the user
		;we will later need to call free_mem on the result as read_string allocates dynamic memory
		;and returns it to us
		call read_string
		
		;move the result into RDI
		mov rdi, rax      
		
		;save RDI in case read_file modifies it
		;we do this by moving it to a location on the stack, [RSP] will work since we have space for
		;four 64 bit integers allocated on the stack already and RDI constitutes just one
		mov [rsp], rdi 
		
		;read the file, the pointer to the file name of the file we want to read is in RDI
		;read_file returns a pointer to a string in RAX, we need to call free_mem on this pointer
		;later because it is dynamically allocated memory
		call read_file
		
		;first restore the result of read_string we stored earlier into RDI
		;so we can call free_mem on in
		mov rdi, [rsp]
		
		;then save the return value of read_file by putting it on the stack where the result of read_string was
		;this is safe to do, because we moved the previous value out into the register RDI
		;we need to store it in case free_mem decides to modify it
		mov [rsp], rax 
		
		
		;call free_mem on the pointer in RDI, which now contains the value returned by read_string
		;we don't need the file name string any more after the file has already been read, so we should free
		;the memory that its using
		call free_mem 

		;restore the return value of read_file we saved, (a pointer to a string, containing the file content)
		;into rax
		mov rax, [rsp] 

		;check if read_file returned 0
		;if read_file returns 0, it means the file could not be read, either because it did not exist or there
		;was some sort of read error
		cmp rax, 0

		;jump out of the loop if we successfully read the files contents (if RAX is not 0)
		;jnz means: jump if not 0
		;we need to use the dot here to, when referencing local labels
		jnz .read_file_done

		;otherwise, read_file must have returned a 0, so we should print an error message
		mov rdi, QWORD error_msg
		call print_string

		;after the error message jump to the top of the loop to request the file name again, so we can retry
		jmp .read_file_start

		
	;if we successfully read the file, this is where we jump out to
	.read_file_done:

	
	;move the pointer to the file content string into RDI, when we exited our loop
	;we left the return value of read_file in RAX
	mov rdi, rax
	
	;save RDI to a location on the stack in case print_string modifies it
	mov [rsp], rdi 
	
	;call print_string to print the string pointed to by RDI
	call print_string

	;restore the value we saved a before print_string back into RDI
	;this is the return value of read_file and we need to call free_mem on it
	;because its dynamically allocated memory
	mov rdi, [rsp]

	;call free_mem on the pointer in RDI, to free the memory allocated by read_file
	call free_mem

	
	
	;restore the stack frame of the function that called this function
	;first add back the amount that we subtracted from RSP
	;including any additional subtractions we made to RSP after the initial one (just sum them)
	add	rsp, 32
	
	;after we add what we subtracted back to RSP, the value of RBP we pushed is the only thing left
	;so we pop it back into RBP to restore the stack base pointer
	pop	rbp
	
	ret
