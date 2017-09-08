All functions in the library use the System V AMD64 ABI calling convention, even on Windows.

The parameter order for integral values is:

* rdi
* rsi
* rdx
* rcx
* r8
* r9

There are no floating point parameters used in this library, however
the register order for floating point arguments while calling functions 
using the System V AMD64 ABI is:

* XMM0
* XMM1
* XMM2
* XMM3
* XMM4
* XMM5
* XMM6
* XMM7

Additional parameters are passed in order on the stack.


Any functions that return integral/pointer values will return the value in the RAX register.


The functions in this library will not save your registers before they are used,
so you should put registers your using on the stack before you call any functions defined here
then restore them afterwards.


**Note:** due to stack alignment requirements on Windows (RSP is required to be aligned to 16 bytes),
use of push and pop in Windows assembly will break your program.  On Windows, instead of using push
and pop, allocate all the space you need on the stack and use it to save registers when needed.

Make sure the space you allocated on the stack is a size in bytes that is divisible evenly by 16 (AKA: Aligned to 16 bytes).
Also, Windows will expect any function that calls other functions to have at least 32 bytes on the stack regardless of 
whether it is needed or not 


All examples in this library are programmed with 16 byte stack alignment for source compatibility with Windows (Cygwin).


# Linking to the library

Once the library is installed, you can include **"/usr/local/include/libasm_io.inc"** in your program
to include the function definitions from the library.

you must also use "-lasm_io" to link the library when you are linking all of your object files together
so that the linker knows it needs to link libasm_io.a to the program.


```bash

# an example of building a program on Linux:


# assemble it:


nasm -f elf64 my_program.asm -o my_program.o


# use gcc or cc to link it:


gcc my_program.o -lasm_io -o my_program


```



# Notes on Library entry point (main)



The library does not use a stub entry point, such as **'asm_main'** as in Dr. Paul Carters
IO library,  It just uses **'main'** for its entry point like a C program.


This allows you to write a **'main'** function in C, then link functions/objects written
in assembly that use this library to your compiled C objects;  without the library creating a duplicate
symbol definition for **'main'** (causing the linker to throw errors).


**'main'** is called by the C runtime, therefore it is a function called from C code.
You should use the library macro **'cglobal'** to define **'main'** as a global symbol for portability.

like so:

```asm

cglobal main

```

All the **'cglobal'** macro does is put an underscore in front of the symbol name **'main'**
if your platforms compiler puts underscores in front of functions compiled in C.
 
(like MacOS's compiler does by default)


It also creates a define, like:

```asm

%define main _main

```

if needed.


So you can reference the symbol as **'main'** no matter what platform you are on (when you use the cglobal macro).


# Library Defines

## _LIBASM_IO_OBJFMT_{nasm object format}_

This define indicates the object format used by nasm on the current platform.
currently it can be defined as one of the following:


```asm

; On Windows (Cygwin):
 
_LIBASM_IO_OBJFMT_WIN64_



; On Linux And *BSD platforms: 

_LIBASM_IO_OBJFMT_ELF64_



; On MacOS: 

_LIBASM_IO_OBJFMT_MACHO64_


```

## _LIBASM_IO_ABI_{ABI Specification}_

This define indicates the ABI specification used on the current platform.
The ABI determines how the compiler passes parameters to C functions (calling convention), among other things.


```asm

; On Windows (Cygwin):

_LIBASM_IO_ABI_WINDOWS_



; On Unix platforms like Linux, *BSD and MacOS: 

_LIBASM_IO_ABI_SYSTEMV_

```


## _LIBASM_IO_PLATFORM_TYPE_{Platform Type}_

This define indicates the ABI Specification used on the current platform.
The ABI determines how the compiler passes parameters to C functions (calling convention), among other things.


```asm

;On Windows (Cygwin):
 
_LIBASM_IO_PLATFORM_TYPE_CYGWIN_



; On Linux, and *BSD platforms: 
; Note: NIX is not a typo of UNIX

_LIBASM_IO_PLATFORM_TYPE_NIX_



; On MacOS: 

_LIBASM_IO_PLATFORM_TYPE_DARWIN_

```

# Library Macros


## cextern


Macro helper for externing functions compiled in C.  It may or may not add a leading underscore
to the label being externed, and then define the label name as being equal to the resulting value.

example: 


```asm

cextern mycfunction


; may expand to:

extern _mycfunction
%define mycfunction _mycfunction


; or:

extern mycfunction

```


Depending on your platform, GCC may add underscores to function names when it compiles C code to object files.
The cextern macro of this library will add an underscore to the name for you if it needs one so you don't
have to worry about it.  It helps keep extern portable across different platforms.

Windows and Linux do not add the underscore by default while compiling C files, while Mac does.


## cglobal


cglobal is is similar to cextern, except it uses the global keyword.


Example:


```asm

cglobal main


; may expand to:

global _main


; or:

global main

```

depending on your platform...

It's useful because Mac will expect **'_main'** as the entry point, while Windows and Linux will expect **'main'**.


## call_libc


When linking with GCC using its default linker parameters, some platforms require you to use **'WRT ..plt'**
after function calls to call dynamically into the Standard C Library.
The extra syntax generates code to call the function using the 'procedure linkage table'.

For example:

```asm

call printf WRT ..plt

```

The libc_call macro just helps keep calls into the standard C library portable across platforms, 
it's a macro that will add **'WTR ..plt'** after a call if its required on the platform you compiled this library for.

You use it like this:

```asm

call_libc printf

```

**Note:** calling conventions/parameter passing will still vary across platform for raw C functions in general.

# Library Functions

## print_nl


Print a new line, takes no parameters.

```print_nl```


## print_string

Print a string, RDI must contain a pointer to the null terminated string.


```
print_string (RDI str_pointer)
```

## print_int


Print the signed 64 bit integer value contained in the RDI register.

```
print_int (RDI integer)
```


## print_uint


Print the unsigned 64 bit integer value contained in the RDI register.

```
print_uint (RDI unsigned_integer)
```


## print_address


Print the pointer value contained in the RDI register (in hex decimal).

```
print_address (RDI pointer)
```


## print_char


Print an ASCII character using an ASCII character code stored in the RDI register.

```
print_char (RDI ascii_code)
```

## read_string


Read a string from console input, and put a pointer to it in RAX.
When you are done with the string, you must call free_mem (mov the value from RAX into RDI and call free_mem)
to free up the dynamical allocated memory used for the string.


```
RAX <- read_string 
```


## read_file


Read a file as a string into memory, and return the pointer to the string in RAX.
The RDI register should point to a null terminated string containing a file name before the call.
Ehen your done with the returned string, you need to call **'free_mem'** on it to dispose of the allocated memory.

read_file will return 0 in RAX if the file could not be opened, if the file is empty, 
it will point to an empty string and you will still have to call **'free_mem'** on it.
If read_file returns 0, do not call **'free_mem'** on the return value.


```
RAX <- read_file (RDI ptr_to_string_filename)
```

## write_file


Attempts to write a file, a boolean success code is return in RAX 0 for failure, 1 for success.
RDI must contain a pointer to a string containing the file name.
RSI must contain a pointer to a string containing the data you want to write to the file.

```
RAX <- write_file (RDI ptr_to_string_filename, RSI ptr_to_string_data)
```

## append_file


Attempts to append data to a file, a boolean success code is return in RAX 0 for failure, 1 for success.
RDI must contain a pointer to a string containing the file name.
RSI must contain a pointer to a string containing the data you want to write to the file.

```
RAX <- append_file (RDI ptr_to_string_filename, RSI ptr_to_string_data)
```


## alloc_mem


Allocate dynamic memory (Byte count in RDI, returned Pointer in RAX), this is just a stub for the C library call **'malloc'**.

```
RAX <- alloc_mem (RDI byte_count)
```

## free_mem


Free dynamic memory at the pointer in RDI, this is just a stub for the C library call **'free'**.

```
free_mem (RDI pointer_to_allocated_memory)
```

## read_char


Read an ASCII character code from console input into RAX (will be the first character if more than one).

```
RAX <- read_char
```

## read_int


Read a signed 64 bit integer value from the console and store the result in the RAX register.

```
RAX <- read_int
```


## read_uint


Read a unsigned 64 bit integer value from the console and store the result in the RAX register.

```
RAX <- read_uint
```

## read_kb


Read an ASCII character code from the keyboard and store it in RAX, (waits for keypress).

```
RAX <- read_kb
```

