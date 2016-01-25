/**=================================================================
**
** Copyright (c) 2014, Teriks
**
** All rights reserved.
** 
** libasm_io is distributed under the following BSD 3-Clause License
** 
** Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
** 
** 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
** 
** 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the
**    documentation and/or other materials provided with the distribution.
** 
** 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from
**    this software without specific prior written permission.
** 
**  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
**  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
**  HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
**  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
**  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
**  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**
**==================================================================*/



#ifdef _LIBASM_IO_OBJFMT_WIN64_

#include <windows.h>

#else

#include <termios.h>
#include <unistd.h>

#endif


#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <inttypes.h>

// Functions in this file without parameters do not need an assembly stub,
// because both Windows and *Nix systems return in the RAX Register.
// and since we are not passing them parameters we do not have to
// create an adapter for the different calling conventions.

#ifdef _LIBASM_IO_OBJFMT_WIN64_

int read_kb()
{

    TCHAR ch;
    DWORD mode;
    DWORD count;
    HANDLE hstdin = GetStdHandle(STD_INPUT_HANDLE);

    // Switch to raw mode
    GetConsoleMode(hstdin, &mode);
    SetConsoleMode(hstdin, 0);

    // Wait for the user's response
    WaitForSingleObject(hstdin, INFINITE);

    // Read the (single) key pressed
    ReadConsole(hstdin, &ch, 1, &count, NULL);

    // Restore the console to its previous state
    SetConsoleMode(hstdin, mode);

    // Return the key code
    return ch;
}



#else

int read_kb()
{

    struct termios oldattr, newattr;
    int ch;
    tcgetattr(STDIN_FILENO, &oldattr);
    newattr = oldattr;
    newattr.c_lflag &= ~(ICANON | ECHO);
    tcsetattr(STDIN_FILENO, TCSANOW, &newattr);
    ch = getchar();
    tcsetattr(STDIN_FILENO, TCSANOW, &oldattr);
    return ch;
}

#endif




int64_t read_int()
{
    int64_t buffer;
    scanf("%" PRId64, &buffer);
    return buffer;
}


int64_t read_uint()
{
    uint64_t buffer;
    scanf("%" PRIu64, &buffer);
    return buffer;
}




char read_char()
{
    return getchar();
}



char *read_string()
{

    char *line = malloc(100), *linep = line;
    size_t lenmax = 100, len = lenmax;
    int c;

    if (line == NULL) {
	return NULL;
    }

    for (;;) {
	c = fgetc(stdin);

	if (c == EOF) {
	    *line = 0;
	    break;
	}

	if (--len == 0) {
	    len = lenmax;
	    char *linen = realloc(linep, lenmax *= 2);

	    if (linen == NULL) {
		free(linep);
		return NULL;
	    }

	    line = linen + (line - linep);
	    linep = linen;
	}

	if ((*line++ = c) == '\n') {
	    *(line - 1) = 0;
	    break;
	}
    }

    return linep;
}



// need an assembly stub, because it has a parameter
char *read_file_impl(char *filename)
{

    char *file_contents = 0;
    long input_file_size;

    FILE *input_file = fopen(filename, "rb");

    if (input_file != NULL) {

	fseek(input_file, 0, SEEK_END);

	input_file_size = ftell(input_file);

	rewind(input_file);

	file_contents = malloc(input_file_size * (sizeof(char)));

	fread(file_contents, sizeof(char), input_file_size, input_file);

	fclose(input_file);
    }

    return file_contents;
}
