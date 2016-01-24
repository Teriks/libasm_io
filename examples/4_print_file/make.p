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


SRC_DIR=src
OBJ_DIR=obj
BIN_DIR=bin


ASM_FILES:=$(wildcard $(SRC_DIR)/*.asm)
C_FILES:=$(wildcard $(SRC_DIR)/*.c)


OBJS:=$(subst $(SRC_DIR),$(OBJ_DIR), $(ASM_FILES:.asm=$(OBJ_EXT)) $(C_FILES:.c=$(OBJ_EXT)))


TARGET:=$(BIN_DIR)/main$(EXE_EXT)



.PHONY: create_dirs


all:  $(TARGET) 



$(ASM_LIB_PATH_SPACE_ESCAPED):


$(OBJ_DIR) $(BIN_DIR): 
	@if [ ! -d ./$@ ]; then mkdir $@; fi
	

$(OBJS) : $(ASM_LIB_PATH_SPACE_ESCAPED) |  $(OBJ_DIR) $(BIN_DIR)


$(TARGET) : $(OBJS) 
	$(CC) $(M_LINK_FLAGS) $(OBJS) "$(ASM_LIB_PATH)" -o $(TARGET)


$(OBJ_DIR)/%$(OBJ_EXT): $(SRC_DIR)/%.asm
	$(AS) $(M_AS_FLAGS)  $< -o $@


$(OBJ_DIR)/%$(OBJ_EXT): $(SRC_DIR)/%.c
	$(CC) $(M_CC_FLAGS) -c $< -o $@ 

	
.PHONY: clean
clean:
	rm -f ./$(OBJ_DIR)/* 2> /dev/null
	rm -f ./$(BIN_DIR)/* 2> /dev/null
