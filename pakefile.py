#!/usr/bin/python3

import os
import subprocess
import glob
import pake
import shutil
from concurrent.futures import ThreadPoolExecutor


make = pake.init()


compiler = make.get_define("CC", "cc")
assembler = make.get_define("AS", "nasm")


obj_dir="obj"
src_dir="src"
bin_dir="bin"
inc_dir="include"


lib_name = "libasm_io.a"


platform_type = subprocess.check_output(["bash", "./platform.sh", "platform_type"]).decode('utf-8').strip()

libc_pic = subprocess.check_output(["bash", "./platform.sh", "libc_pic"]).decode('utf-8').strip()

c_symbol_underscores="plain"

obj_ext = ".o"
exe_ext = ""


if platform_type == "NIX":
    obj_format="elf64"
    assembler="nasm"
elif platform_type == "DARWIN":
    c_symbol_underscores="underscore"
    link_flags=["-W1","-lc","-no-pie"]
    obj_format="macho64"
elif platform_type == "CYGWIN":
    obj_ext=".obj"
    obj_format="win64"
    exe_ext=".exe"
    if compiler.lower() == 'cc':
        compiler='gcc'
else:
    print("Cannot compile on this platform, platform unknown")


obj_format_upper = obj_format.upper()

library_target = os.path.join(bin_dir, lib_name)

m_asm_lib_path = os.path.join(os.getcwd(), library_target)

include_directory_path = os.path.join(os.getcwd(), inc_dir)


m_cc_flags=["-m64", "-D", "_LIBASM_IO_OBJFMT_"+obj_format_upper+"_"]
m_as_flags = ["-f", obj_format, "-D", "_LIBASM_IO_BUILDING_", "-I", include_directory_path+"/"]


asm_files = glob.glob(os.path.join(src_dir, "*.asm"))
c_files = glob.glob(os.path.join(src_dir, "*.c"))

asm_objects = [os.path.join(obj_dir, os.path.basename(i.replace(".asm", obj_ext))) for i in asm_files]
c_objects = [os.path.join(obj_dir, os.path.basename(i.replace(".c", obj_ext))) for i in c_files]


pake.export("AS", assembler)
pake.export("CC", compiler)
pake.export("OBJ_EXT", obj_ext)
pake.export("EXE_EXT", exe_ext)
pake.export("M_ASM_LIB_PATH", m_asm_lib_path)
pake.export("M_CC_FLAGS", m_cc_flags)
pake.export("M_AS_FLAGS", m_as_flags)


@make.target(inputs=os.path.join(inc_dir, "libasm_io_cdecl_"+c_symbol_underscores+".inc"),
             outputs=os.path.join(inc_dir, "libasm_io_cdecl.inc"))
def libasm_io_cdecl(target):
    shutil.copyfile(target.inputs[0], target.outputs[0])


@make.target(inputs=os.path.join(inc_dir, "libasm_io_libc_call_"+libc_pic+".inc"), 
             outputs=os.path.join(inc_dir, "libasm_io_libc_call.inc"))
def libasm_io_libc_call(target):
    shutil.copyfile(target.inputs[0], target.outputs[0])


@make.target(outputs=os.path.join(inc_dir, "libasm_io_defines.inc"))
def libasm_io_defines(target):
    abi = subprocess.check_output(["bash", "platform.sh", "abi"]).decode('utf-8').strip()
    with open(target.outputs[0], 'w+') as inc_file:
        print('%define _LIBASM_IO_OBJFMT_{t}_'.format(t=obj_format_upper), file=inc_file)
        print('%define _LIBASM_IO_ABI_{t}_'.format(t=abi), file=inc_file)
        print('%define _LIBASM_IO_PLATFORM_TYPE_{t}_'.format(t=platform_type), file=inc_file)


@make.target(inputs=asm_files, outputs=asm_objects, 
             depends=[libasm_io_cdecl, libasm_io_libc_call, libasm_io_defines])
def compile_asm(target):
    pake.ensure_path_exists(obj_dir)
    with ThreadPoolExecutor(max_workers=5) as exe:
        for i in zip(target.outdated_inputs, target.outdated_outputs):
            target.print("{asm} {inp} -> {outp}".format(asm=assembler, inp=i[0], outp=i[1]))
            exe.submit(subprocess.call, [assembler] + m_as_flags + [i[0], "-o", i[1]])


@make.target(inputs=c_files, outputs=c_objects)
def compile_c(target):
    pake.ensure_path_exists(obj_dir)
    with ThreadPoolExecutor(max_workers=5) as exe:
        for i in zip(target.outdated_inputs, target.outdated_outputs):
            target.print("{cc} {inp} -> {outp}".format(cc=compiler, inp=i[0], outp=i[1]))
            exe.submit(subprocess.call, [compiler] + m_cc_flags + ["-c", i[0], "-o", i[1]])


@make.target(outputs=library_target, depends=[compile_asm, compile_c],
             info="Build the library.")
def build_library(target):
    pake.ensure_path_exists(bin_dir)
    target.print("ar {inp} -> {outp}".format(inp=target.dependency_outputs, outp=library_target))
    subprocess.call(["ar", "rcs", library_target]+target.dependency_outputs)


@make.target(depends=build_library, info="Build all of the library examples")
def build_examples(target):
    with ThreadPoolExecutor(max_workers=5) as exe:
        for d in glob.glob('examples/*/'):
            exe.submit(target.run_script, 'examples/pakefile.py', "-C", d, "-j", make.get_max_jobs())


@make.target(info="Clean the library.")
def clean(target):
    target.print("rm -rf ./bin")
    target.print("rm -rf ./obj")
    try:
        shutil.rmtree("bin")
        shutil.rmtree("obj")
    except FileNotFoundError:
        pass


@make.target(info="Clean the library examples.")
def clean_examples(target):
    with ThreadPoolExecutor(max_workers=5) as exe:
        for d in glob.glob('examples/*/'):
            exe.submit(target.run_script, 'examples/pakefile.py', "clean", "-C", d, "-j", make.get_max_jobs())


@make.target(depends=[clean, clean_examples], 
             info="Clean the library and library examples.")
def clean_all():
    pass


pake.run(make, default_targets=build_library)

