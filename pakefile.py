import os
import pake
import glob
from pake import process
from pake import returncodes
from functools import partial

pk = pake.init()

force_fpic = pk.get_define('FPIC', False)

compiler = pk.get_define('CC', 'cc')
assembler = pk.get_define('AS', 'nasm')


obj_dir='obj'
src_dir='src'
bin_dir='bin'
inc_dir='include'


lib_name = 'libasm_io.a'


platform_type = process.check_output('bash', './platform.sh', 'platform_type').decode().strip()

if force_fpic:
    libc_pic = 'pic'
else:
    libc_pic = process.check_output('bash', './platform.sh', 'libc_pic').decode().strip()

c_symbol_underscores='plain'

obj_ext = '.o'
exe_ext = ''


if platform_type == 'NIX':
    obj_format='elf64'
    assembler='nasm'
    link_flags=['-no-pie']
elif platform_type == 'DARWIN':
    c_symbol_underscores='underscore'
    link_flags=['-W1','-lc','-no_pie']
    obj_format='macho64'
elif platform_type == 'CYGWIN':
    obj_ext='.obj'
    obj_format='win64'
    exe_ext='.exe'
    if compiler.lower() == 'cc':
        compiler='gcc'
else:
    print('Cannot compile on this platform, platform unknown.')
    pk.terminate(returncodes.ERROR)


obj_format_upper = obj_format.upper()

library_target = os.path.join(bin_dir, lib_name)

m_asm_lib_path = os.path.join(os.getcwd(), library_target)

include_directory_path = os.path.join(os.getcwd(), inc_dir)


m_cc_flags=['-m64', '-D', '_LIBASM_IO_OBJFMT_'+obj_format_upper+'_']
m_as_flags = ['-f', obj_format, '-D', '_LIBASM_IO_BUILDING_', '-I', include_directory_path+'/']


asm_files = pake.glob(os.path.join(src_dir, '*.asm'))
c_files = pake.glob(os.path.join(src_dir, '*.c'))

asm_objects = pake.pattern(os.path.join(obj_dir,'%'+obj_ext))
c_objects = pake.pattern(os.path.join(obj_dir,'%'+obj_ext))


pake.export('AS', assembler)
pake.export('CC', compiler)
pake.export('OBJ_EXT', obj_ext)
pake.export('EXE_EXT', exe_ext)
pake.export('M_ASM_LIB_PATH', m_asm_lib_path)
pake.export('M_CC_FLAGS', m_cc_flags)
pake.export('M_AS_FLAGS', m_as_flags)
pake.export('M_LINK_FLAGS', link_flags)


@pk.task(i=os.path.join(inc_dir, 'libasm_io_cdecl_'+c_symbol_underscores+'.inc'),
           o=os.path.join(inc_dir, 'libasm_io_cdecl.inc'))
def libasm_io_cdecl(ctx):
    file_helper = pake.FileHelper(ctx)
    file_helper.copy(ctx.inputs[0], ctx.outputs[0])


@pk.task(i=os.path.join(inc_dir, 'libasm_io_libc_call_'+libc_pic+'.inc'), 
           o=os.path.join(inc_dir, 'libasm_io_libc_call.inc'))
def libasm_io_libc_call(ctx):
    file_helper = pake.FileHelper(ctx)
    file_helper.copy(ctx.inputs[0], ctx.outputs[0])


@pk.task(o=os.path.join(inc_dir, 'libasm_io_defines.inc'))
def libasm_io_defines(ctx):
    abi = process.check_output('bash', 'platform.sh', 'abi').decode().strip()
    with open(ctx.outputs[0], 'w+') as inc_file:
        print('%define _LIBASM_IO_OBJFMT_{t}_'.format(t=obj_format_upper), file=inc_file)
        print('%define _LIBASM_IO_ABI_{t}_'.format(t=abi), file=inc_file)
        print('%define _LIBASM_IO_PLATFORM_TYPE_{t}_'.format(t=platform_type), file=inc_file)


@pk.task(libasm_io_cdecl, libasm_io_libc_call, libasm_io_defines,
           i=asm_files, o=asm_objects)
def compile_asm(ctx):
    file_helper = pake.FileHelper(ctx)
    file_helper.makedirs(obj_dir)

    assembler_args = ([assembler, m_as_flags, i, '-o', o] for i, o in ctx.outdated_pairs)
    sync_call = partial(ctx.call, collect_output=pk.max_jobs > 1)
    
    with ctx.multitask() as mt:
        list(mt.map(sync_call, assembler_args))


@pk.task(i=c_files, o=c_objects)
def compile_c(ctx):
    file_helper = pake.FileHelper(ctx)
    file_helper.makedirs(obj_dir)

    compiler_args = ([compiler, m_cc_flags, '-c', i, '-o', o] for i, o in ctx.outdated_pairs)
    sync_call = partial(ctx.call, collect_output=pk.max_jobs > 1)
    
    with ctx.multitask() as mt:
        list(mt.map(sync_call, compiler_args))


@pk.task(compile_asm, compile_c, o=library_target)
def build_library(ctx):
    """Build the library."""

    file_helper = pake.FileHelper(ctx)
    file_helper.makedirs(bin_dir)
    ctx.call('ar', 'rcs', library_target, ctx.dependency_outputs)


@pk.task(build_library)
def build_examples(ctx):
    """Build all of the library examples"""

    subpake_args = (['examples/pakefile.py', '-C', d] for d in glob.glob('examples/*/'))
    sync_subpake = partial(ctx.subpake, collect_output=pk.max_jobs > 1)
    
    with ctx.multitask() as mt:
        list(mt.map(sync_subpake, subpake_args))


@pk.task
def clean(ctx):
    """Clean the library"""
    
    file_helper = pake.FileHelper(ctx)
    file_helper.remove(os.path.join(inc_dir, 'libasm_io_defines.inc'))
    file_helper.remove(os.path.join(inc_dir, 'libasm_io_libc_call.inc'))
    file_helper.remove(os.path.join(inc_dir, 'libasm_io_cdecl.inc'))
    file_helper.rmtree('bin')
    file_helper.rmtree('obj')


@pk.task
def clean_examples(ctx):
    """Clean the library examples."""
    subpake_args = (['examples/pakefile.py', 'clean', '-C', d] for d in glob.glob('examples/*/'))
    sync_subpake = partial(ctx.subpake, collect_output=pk.max_jobs > 1)
    
    with ctx.multitask() as mt:
        list(mt.map(sync_subpake, subpake_args))


@pk.task(clean, clean_examples)
def clean_all():
    """Clean the library and library examples."""
    pass


pake.run(pk, tasks=build_library)
