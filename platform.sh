#!/bin/sh

#=================================================================
#
# Copyright (c) 2014, Teriks
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


if [ $(echo $1 | grep 'platform_type') ]
then

	if [ $(uname | grep -i -E 'linux|freebsd|netbsd|openbsd|ghostbsd') ]
	then
		echo "NIX"

	elif [ $(uname | grep -i 'darwin') ]
	then
		echo "DARWIN"

	elif [ $(uname | grep -i 'cygwin') ]
	then
		echo "CYGWIN"

	else

		echo "UNKNOWN"

	fi


elif [ $(echo $1 | grep 'libc_pic') ]
then

	if [ $(uname | grep -i 'openbsd') ]
	then
		echo "pic"
	else
		echo "nopic"
	fi
	
elif [ $(echo $1 | grep 'abi') ]
then

	if [ $(uname | grep -i 'cygwin') ]
	then
		echo "WINDOWS"
	else
		echo "SYSTEMV"
	fi
fi
	
