#!/usr/bin/env python3

import argparse, subprocess, datetime

def run_test(insn, ax, dx):
    with open('pio.asm', 'r') as pio_poc:
        program = pio_poc.read()
        program = program.replace('$INSN', insn)
        program = program.replace('$AX', ax)
        program = program.replace('$DX', dx)
        today = datetime.datetime.now()
        today = today.strftime("%Y%m%d%H%M%S")
        
        with open(today + ".test.asm", 'w') as tmp_file:
            tmp_file.write(program)
        
        with subprocess.Popen(["nasm", "-f", "bin", "-o", today + '.test.img', today + '.test.asm']) as assemble:
            print("test program assembled")

        with subprocess.Popen("qemu-system-i386 -nographic -boot a -fda " + today + '.test.img', shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True) as proc:
            for line in proc.stdout:
                print(line)

        print("Created two files: " + today + ".test.img and " + today + ".test.asm.  Do you want to keep these files?")

def main():
    parser = argparse.ArgumentParser('Bootfuzz test-pio.py')
    parser.add_argument('-i', '--instruction', help='The instruction to test.  Valid values are "in" and "out"')
    parser.add_argument('-a', '--ax', help='The value for AX to test')
    parser.add_argument('-d', '--dx', help='The value for DX to test')

    args = parser.parse_args()
    insn = args.__dict__["instruction"]
    ax = args.__dict__["ax"].replace('0x', '')
    dx = args.__dict__["dx"].replace('0x', '')

    if insn not in ['in', 'out']:
        print("Invalid instruction option")
        exit(1)

    if not ax:
        print("Invalid ax value")
        exit(1)

    if not dx:
        print("Invalid dx option")
        exit(1)

    if insn == 'in':
        insn = "in ax, dx"
    elif insn == "out":
        insn = "out dx, ax"

    run_test(insn, ax, dx)

if __name__ == '__main__':
    main()