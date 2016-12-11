#!/usr/bin/python3

import os
import glob
import pake
import pake.process
from concurrent.futures import ThreadPoolExecutor


make = pake.init()


compiler = make.get_define('CC', 'cc')
assembler = make.get_define('AS', 'nasm')


obj_dir='obj'
src_dir='src'
bin_dir='bin'
inc_dir='include'


lib_name = 'libasm_io.a'


platform_type = ''.join(pake.process.execute(['bash', './platform.sh', 'platform_type'])).strip()

libc_pic = ''.join(pake.process.execute(['bash', './platform.sh', 'libc_pic'])).strip()

c_symbol_underscores='plain'

obj_ext = '.o'
exe_ext = ''


if platform_type == 'NIX':
    obj_format='elf64'
    assembler='nasm'
elif platform_type == 'DARWIN':
    c_symbol_underscores='underscore'
    link_flags=['-W1','-lc','-no-pie']
    obj_format='macho64'
elif platform_type == 'CYGWIN':
    obj_ext='.obj'
    obj_format='win64'
    exe_ext='.exe'
    if compiler.lower() == 'cc':
        compiler='gcc'
else:
    print('Cannot compile on this platform, platform unknown')
    exit(1)


obj_format_upper = obj_format.upper()

library_target = os.path.join(bin_dir, lib_name)

m_asm_lib_path = os.path.join(os.getcwd(), library_target)

include_directory_path = os.path.join(os.getcwd(), inc_dir)


m_cc_flags=['-m64', '-D', '_LIBASM_IO_OBJFMT_'+obj_format_upper+'_']
m_as_flags = ['-f', obj_format, '-D', '_LIBASM_IO_BUILDING_', '-I', include_directory_path+'/']


asm_files = glob.glob(os.path.join(src_dir, '*.asm'))
c_files = glob.glob(os.path.join(src_dir, '*.c'))

asm_objects = [os.path.join(obj_dir, os.path.basename(i.replace('.asm', obj_ext))) for i in asm_files]
c_objects = [os.path.join(obj_dir, os.path.basename(i.replace('.c', obj_ext))) for i in c_files]


pake.export('AS', assembler)
pake.export('CC', compiler)
pake.export('OBJ_EXT', obj_ext)
pake.export('EXE_EXT', exe_ext)
pake.export('M_ASM_LIB_PATH', m_asm_lib_path)
pake.export('M_CC_FLAGS', m_cc_flags)
pake.export('M_AS_FLAGS', m_as_flags)


@make.target(inputs=os.path.join(inc_dir, 'libasm_io_cdecl_'+c_symbol_underscores+'.inc'),
             outputs=os.path.join(inc_dir, 'libasm_io_cdecl.inc'))
def libasm_io_cdecl(target):
    file_helper = pake.FileHelper(target)
    file_helper.copy(target.inputs[0], target.outputs[0])


@make.target(inputs=os.path.join(inc_dir, 'libasm_io_libc_call_'+libc_pic+'.inc'), 
             outputs=os.path.join(inc_dir, 'libasm_io_libc_call.inc'))
def libasm_io_libc_call(target):
    file_helper = pake.FileHelper(target)
    file_helper.copy(target.inputs[0], target.outputs[0])


@make.target(outputs=os.path.join(inc_dir, 'libasm_io_defines.inc'))
def libasm_io_defines(target):
    abi = ''.join(target.execute(['bash', 'platform.sh', 'abi'], silent=True)).strip()
    with open(target.outputs[0], 'w+') as inc_file:
        print('%define _LIBASM_IO_OBJFMT_{t}_'.format(t=obj_format_upper), file=inc_file)
        print('%define _LIBASM_IO_ABI_{t}_'.format(t=abi), file=inc_file)
        print('%define _LIBASM_IO_PLATFORM_TYPE_{t}_'.format(t=platform_type), file=inc_file)


@make.target(inputs=asm_files, outputs=asm_objects, 
             depends=[libasm_io_cdecl, libasm_io_libc_call, libasm_io_defines])
def compile_asm(target):
    file_helper = pake.FileHelper(target)
    file_helper.makedirs(obj_dir)
    for i in zip(target.outdated_inputs, target.outdated_outputs):
        target.execute([assembler] + m_as_flags + [i[0], '-o', i[1]])


@make.target(inputs=c_files, outputs=c_objects)
def compile_c(target):
    file_helper = pake.FileHelper(target)
    file_helper.makedirs(obj_dir)
    for i in zip(target.outdated_inputs, target.outdated_outputs):
        target.execute([compiler] + m_cc_flags + ['-c', i[0], '-o', i[1]])


@make.target(outputs=library_target, depends=[compile_asm, compile_c],
             info='Build the library.')
def build_library(target):
    file_helper = pake.FileHelper(target)
    file_helper.makedirs(bin_dir)
    target.execute(['ar', 'rcs', library_target]+target.dependency_outputs)


@make.target(depends=build_library, info='Build all of the library examples')
def build_examples(target):
    for d in glob.glob('examples/*/'):
        target.run_pake('examples/pakefile.py', '-C', d, '-j', make.get_max_jobs())


@make.target(info='Clean the library.')
def clean(target):
    file_helper = pake.FileHelper(target)
    file_helper.remove(os.path.join(inc_dir, 'libasm_io_defines.inc'))
    file_helper.remove(os.path.join(inc_dir, 'libasm_io_libc_call.inc'))
    file_helper.remove(os.path.join(inc_dir, 'libasm_io_cdecl.inc'))
    file_helper.rmtree('bin')
    file_helper.rmtree('obj')


@make.target(info='Clean the library examples.')
def clean_examples(target):
    for d in glob.glob('examples/*/'):
        target.run_pake('examples/pakefile.py', 'clean', '-C', d, '-j', make.get_max_jobs())


@make.target(depends=[clean, clean_examples], 
             info='Clean the library and library examples.')
def clean_all():
    pass


pake.run(make, default_targets=build_library)

