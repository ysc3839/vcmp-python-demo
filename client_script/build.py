#!/usr/bin/env python3
import sys
import os
from shutil import copyfile, copytree, rmtree
import os.path

FILES = [
    'main.nut'
]

def cat_files(files, out_file):
    with open(out_file, 'wb') as out:
        for name in files:
            with open(name, 'rb') as f:
                out.write(f.read())

def compile_cnut():
    os.chdir('dist')
    # Squirrel includes filename in cnut, so we name that file to '!'
    ret = os.system(os.path.normpath('../bin/sq -o _mem.nut -c !'))
    if ret != 0:
        print("compile error")
    os.remove('!')
    os.chdir('..')

def copypath(src, dst):
    if os.path.exists(dst):
        rmtree(dst)
    copytree(src, dst)

def main():
    argv = sys.argv.copy()
    if len(argv) < 2:
        argv.append('dev')
    if argv[1] == '-h':
        print('Usage: build.py [dev/prod]')
        return
    env = argv[1]
    cat_files(FILES, 'dist/!' if env == 'prod' else 'dist/_mem.nut')
    if env == 'prod':
        compile_cnut()
    copyfile('main_stub.nut', 'dist/main.nut')
    copypath('dist', '../store/script')

if __name__ == '__main__':
    main()
