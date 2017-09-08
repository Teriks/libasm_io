# About

libasm_io is a simple x64 bit IO library for nasm/yasm assembly programs that includes a few examples and tutorials.

It was written to assist students learning Intel style assembly language.  The API is based on Dr. Paul Carters x32 bit IO library used in his old tutorials.

# Library Documentation

see: [library-documentation.md](/library-documentation.md)

# (Make) Build Instructions

see: [build-readme.md](/build-readme.md)


# Note About -fPIC

You may need to force compilation with -fPIC to prevent errors if
./platform.sh does not guess it correctly.

If you encounter an -fPIC related linker error when building the examples
you can get around it with:

```

make clean_all
make examples FPIC=true

```

or:

```

pake clean_all
pake build_examples -D FPIC

```


# Build with pake

install python3.5+, python3-pip, nasm and gcc.

install pake:

`sudo pip3 install python-pake --upgrade`

change to the root directory.

`pake -ti` lists all documented targets:

```

# Default Tasks

build_library

# Documented Tasks

clean_examples:  Clean the library examples.
clean:           Clean the library
build_examples:  Build all of the library examples
clean_all:       Clean the library and library examples.
build_library:   Build the library.


```

Running `pake` will run the default target "build_library".

Running `pake build_examples` will build the library and examples together.


You can also specify a compiler or nasm compatible assembler using pake defines:

`pake -D CC=clang -D AS=(your assembler)`


