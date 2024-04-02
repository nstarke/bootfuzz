#!/bin/sh

ACCELERATION=""

if [[ $(cat /proc/cpuinfo | grep -i intel) ]]; then
	ACCELERATION="-accel kvm"
fi

nasm -f bin -o bootfuzz.img -l bootfuzz.lst bootfuzz.asm
xxd bootfuzz.img > hexdump.txt
qemu-system-i386 -fda bootfuzz.img -nographic $ACCELERATION
# CTRL-A + X will exit out of the qemu console