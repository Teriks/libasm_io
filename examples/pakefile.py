import os
import glob
import pake


make = pake.init()

src_dir='src'
obj_dir='obj'
bin_dir='bin'


assembler = make.get_define('AS', 'nasm')

compiler = make.get_define('CC', 'cc')

exe_ext = make.get_define('EXE_EXT', '.exe')

exe_target=os.path.join(bin_dir, 'main'+exe_ext)

obj_ext = make.get_define('OBJ_EXT', '.o')

link_flags = make.get_define('M_LINK_FLAGS', [])

asm_lib_path = make.get_define('M_ASM_LIB_PATH', '')

cc_flags = make.get_define('M_CC_FLAGS', [])

as_flags = make.get_define('M_AS_FLAGS', [])


@make.task(i=pake.glob('src/*.asm'), 
           o=pake.pattern(os.path.join(obj_dir,'%'+obj_ext)))
def compile_asm(target):
    file_helper = pake.FileHelper(target)
    file_helper.makedirs(obj_dir)
    for i, o in zip(target.outdated_inputs, target.outdated_outputs):
        target.call([assembler] + as_flags + [i, '-o', o])
        

@make.task(i=pake.glob('src/*.c'), 
           o=pake.pattern(os.path.join(obj_dir,'%'+obj_ext)))
def compile_c(target):
    file_helper = pake.FileHelper(target)
    file_helper.makedirs(obj_dir)
    for i, o in zip(target.outdated_inputs, target.outdated_outputs):
        target.call([compiler] + cc_flags + [i, '-o', o])


@make.task(compile_asm, compile_c, o=exe_target)
def build_library(target):
    file_helper = pake.FileHelper(target)
    file_helper.makedirs(bin_dir)
    target.call(
    [compiler] + link_flags + target.dependency_outputs + [asm_lib_path, '-o', exe_target]
    )


@make.task	
def clean(target):
    file_helper = pake.FileHelper(target)
    file_helper.rmtree('bin')
    file_helper.rmtree('obj')


pake.run(make, tasks=build_library)
