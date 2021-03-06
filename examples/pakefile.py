import os
import glob
import pake
from functools import partial


pk = pake.init()

src_dir='src'
obj_dir='obj'
bin_dir='bin'


assembler = pk.get_define('AS', 'nasm')

compiler = pk.get_define('CC', 'cc')

exe_ext = pk.get_define('EXE_EXT', '.exe')

exe_target=os.path.join(bin_dir, 'main'+exe_ext)

obj_ext = pk.get_define('OBJ_EXT', '.o')

link_flags = pk.get_define('M_LINK_FLAGS', [])

asm_lib_path = pk.get_define('M_ASM_LIB_PATH', '')

cc_flags = pk.get_define('M_CC_FLAGS', [])

as_flags = pk.get_define('M_AS_FLAGS', [])


@pk.task(i=pake.glob('src/*.asm'),
         o=pake.pattern(os.path.join(obj_dir,'%'+obj_ext)))
def compile_asm(ctx):
    file_helper = pake.FileHelper(ctx)
    file_helper.makedirs(obj_dir)

    assembler_args = ([assembler, as_flags, i, '-o', o] for i, o in ctx.outdated_pairs)
    sync_call = partial(ctx.call, collect_output=pk.max_jobs > 1)
    
    with ctx.multitask() as mt:
        list(mt.map(sync_call, assembler_args))
        

@pk.task(i=pake.glob('src/*.c'),
         o=pake.pattern(os.path.join(obj_dir,'%'+obj_ext)))
def compile_c(ctx):
    file_helper = pake.FileHelper(ctx)
    file_helper.makedirs(obj_dir)

    compiler_args = ([compiler, cc_flags, i, '-o', o] for i, o in ctx.outdated_pairs)
    sync_call = partial(ctx.call, collect_output=pk.max_jobs > 1)
    
    with ctx.multitask() as mt:
        list(mt.map(sync_call, compiler_args))


@pk.task(compile_asm, compile_c, o=exe_target)
def build_example(ctx):
    file_helper = pake.FileHelper(ctx)
    file_helper.makedirs(bin_dir)
    ctx.call(
        compiler, link_flags, ctx.dependency_outputs, asm_lib_path, '-o', exe_target
    )


@pk.task
def clean(ctx):
    file_helper = pake.FileHelper(ctx)
    file_helper.rmtree('bin')
    file_helper.rmtree('obj')


pake.run(pk, tasks=build_example)
