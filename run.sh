#!/bin/sh

nasm -f bin -o bootfuzz.img bootfuzz.asm
xxd bootfuzz.img > hexdump.txt
qemu-system-i386 -fda bootfuzz.img -nographic -accel kvm
# CTRL-A + X will exit out of the qemu console