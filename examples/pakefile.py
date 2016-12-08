import os
import pake
import glob
import subprocess
import shutil


make = pake.init()

src_dir="src"
obj_dir="obj"
bin_dir="bin"


assembler = make.get_define("AS", "nasm")

compiler = make.get_define("CC", "cc")

exe_ext = make.get_define("EXE_EXT", ".exe")

exe_target=os.path.join(bin_dir, "main"+exe_ext)

obj_ext = make.get_define("OBJ_EXT", ".o")

link_flags = make.get_define("M_LINK_FLAGS", [])

asm_lib_path = make.get_define("M_ASM_LIB_PATH", "")

cc_flags = make.get_define("M_CC_FLAGS", [])

as_flags = make.get_define("M_AS_FLAGS", [])


asm_files = glob.glob("src/*.asm")
c_files = glob.glob("src/*.c")


asm_objects = [os.path.join(obj_dir, os.path.basename(i.replace(".asm", obj_ext))) for i in asm_files]
c_objects = [os.path.join(obj_dir, os.path.basename(i.replace(".c", obj_ext))) for i in c_files]


@make.target(inputs=asm_files, outputs=asm_objects)
def compile_asm(target):
    file_helper = pake.FileHelper(target)
    file_helper.makedirs(obj_dir)
    for i in zip(target.outdated_inputs, target.outdated_outputs):
        target.execute([assembler] + as_flags + [i[0], "-o", i[1]])
        

@make.target(inputs=c_files, outputs=c_objects)
def compile_c(target):
    file_helper = pake.FileHelper(target)
    file_helper.makedirs(obj_dir)
    for i in zip(target.outdated_inputs, target.outdated_outputs):
        target.execute([compiler] + cc_flags + [i[0], "-o", i[1]])

library_depends = []

if len(c_files) > 0:
    library_depends.append(compile_c)

if len(asm_files) > 0:
    library_depends.append(compile_asm)


@make.target(outputs=exe_target, depends=library_depends)
def build_library(target):
    file_helper = pake.FileHelper(target)
    file_helper.makedirs(bin_dir)
    target.execute(
    [compiler] + link_flags + target.dependency_outputs + [asm_lib_path, "-o", exe_target]
    )


@make.target	
def clean(target):
    file_helper = pake.FileHelper(target)
    file_helper.removedirs("bin")
    file_helper.removedirs("obj")


pake.run(make, default_targets=build_library)
