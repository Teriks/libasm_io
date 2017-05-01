#=================================================================
#
# Copyright (c) 2014, Teriks
#  
#
# All rights reserved.
# 
# libasm_io is distributed under the following BSD 3-Clause License
# 
# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 
# 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from
#    this software without specific prior written permission.
# 
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
#  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
#  HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
#  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
#  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
#  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#==================================================================



OBJ_DIR=obj
SRC_DIR=src
BIN_DIR=bin
INC_DIR=include



ASM_FILES:=$(wildcard $(SRC_DIR)/*.asm)
C_FILES:=$(wildcard $(SRC_DIR)/*.c)



LIB_NAME=libasm_io.a


CC_FLAGS = 
AS_FLAGS = 
LINK_FLAGS =



PLATFORM_TYPE:=$(shell ./platform.sh platform_type)

ifdef FPIC
    LIBC_PIC:='pic'
else
    LIBC_PIC:=$(shell ./platform.sh libc_pic)
endif


C_SYMBOL_UNDERSCORES=plain


export M_LINK_FLAGS:=$(LINK_FLAGS)

export CC?=cc
export AS=nasm
export OBJ_EXT=.o
export EXE_EXT=



ifeq ($(PLATFORM_TYPE),NIX)

  export OBJ_FORMAT=elf64
  export AS=nasm

  
else ifeq ($(PLATFORM_TYPE),DARWIN)

  C_SYMBOL_UNDERSCORES=underscore
  export M_LINK_FLAGS:= -Wl,-lc,-no_pie $(LINK_FLAGS)
  export OBJ_FORMAT=macho64
  
else ifeq ($(PLATFORM_TYPE),CYGWIN)

  export OBJ_EXT=.obj
  export OBJ_FORMAT=win64
  export EXE_EXT=.exe
  
else

  $(error Cannot compile on this platform, platform unknown)
  
endif




OBJ_FORMAT_UPPER:=$(shell echo $(OBJ_FORMAT)|tr 'a-z' 'A-Z')

TARGET:=$(BIN_DIR)/$(LIB_NAME)

export ASM_LIB_PATH:=${CURDIR}/$(TARGET)

export ASM_LIB_PATH_SPACE_ESCAPED:=$(shell echo $(ASM_LIB_PATH) | sed -e "s/ /\\\\ /g")

export INCLUDE_DIRECTORY_PATH:=${CURDIR}/$(INC_DIR)/

export M_CC_FLAGS:=-m64 -D _LIBASM_IO_OBJFMT_$(OBJ_FORMAT_UPPER)_ $(CC_FLAGS)


export M_AS_FLAGS:=			\
-f $(OBJ_FORMAT)			\
-D _LIBASM_IO_BUILDING_ $(AS_FLAGS)	\
-I "$(INCLUDE_DIRECTORY_PATH)"		\


OBJS:=$(subst $(SRC_DIR),$(OBJ_DIR), $(ASM_FILES:.asm=$(OBJ_EXT)) $(C_FILES:.c=$(OBJ_EXT)))




all:  $(TARGET)


.PHONY: examples
examples: $(TARGET)
	@for directory in $$(ls -d ./examples/*/) ;	\
		do  echo "=====================";	\
		$(MAKE) -f make.p -w -C $$directory ;	\
		done					\
		
	@echo "====================="
	@echo "done"
	

.PHONY: clean_examples
clean_examples:
	@for directory in $$(ls -d ./examples/*/) ;		\
		do  echo "=====================";		\
		$(MAKE) -f make.p -w -C $$directory clean ;	\
		done						\
		
	@echo "====================="
	@echo "done"

	
.PHONY: install
install: all
	cp $(TARGET) /usr/lib
	if [ ! -d /usr/local ]; then mkdir -m 755 /usr/local; fi
	if [ ! -d /usr/local/include ]; then mkdir -m 755 /usr/local/include; fi
	cp $(INC_DIR)/libasm_io.inc /usr/local/include/
	cp $(INC_DIR)/libasm_io_cdecl_$(C_SYMBOL_UNDERSCORES).inc /usr/local/include/libasm_io_cdecl.inc
	cp $(INC_DIR)/libasm_io_libc_call_$(LIBC_PIC).inc /usr/local/include/libasm_io_libc_call.inc
	cp $(INC_DIR)/libasm_io_defines.inc /usr/local/include/
	


$(OBJ_DIR) $(BIN_DIR): 
	@if [ ! -d ./$@ ]; then mkdir $@; fi
	

$(INC_DIR)/libasm_io_cdecl.inc: 
	@cp $(INC_DIR)/libasm_io_cdecl_$(C_SYMBOL_UNDERSCORES).inc $(INC_DIR)/libasm_io_cdecl.inc
	
	
$(INC_DIR)/libasm_io_libc_call.inc: 
	@cp $(INC_DIR)/libasm_io_libc_call_$(LIBC_PIC).inc $(INC_DIR)/libasm_io_libc_call.inc

	
	
	
$(INC_DIR)/libasm_io_defines.inc: 
	@echo %define _LIBASM_IO_OBJFMT_$(OBJ_FORMAT_UPPER)_ > $(INC_DIR)/libasm_io_defines.inc
	@echo %define _LIBASM_IO_ABI_$(shell ./platform.sh abi)_ >> $(INC_DIR)/libasm_io_defines.inc
	@echo %define _LIBASM_IO_PLATFORM_TYPE_$(PLATFORM_TYPE)_ >> $(INC_DIR)/libasm_io_defines.inc

	

$(TARGET) : $(OBJS)
	ar rcs $(TARGET) $(OBJS)
	
	
$(OBJS) : $(INC_DIR)/libasm_io_cdecl.inc $(INC_DIR)/libasm_io_libc_call.inc $(INC_DIR)/libasm_io_defines.inc | $(OBJ_DIR) $(BIN_DIR) 


$(OBJ_DIR)/%$(OBJ_EXT): $(SRC_DIR)/%.asm
	$(AS) $(M_AS_FLAGS) $< -o $@


$(OBJ_DIR)/%$(OBJ_EXT): $(SRC_DIR)/%.c
	$(CC) $(M_CC_FLAGS) -c $< -o $@ 
	
	
.PHONY: clean_all	
clean_all:  clean clean_examples


.PHONY: clean	
clean:
	rm -f ./$(INC_DIR)/libasm_io_defines.inc
	rm -f ./$(INC_DIR)/libasm_io_libc_call.inc
	rm -f ./$(INC_DIR)/libasm_io_cdecl.inc
	rm -rf ./$(OBJ_DIR) 2> /dev/null
	rm -rf ./$(BIN_DIR) 2> /dev/null
