# Bootfuzz

![Bootfuzz Screenshot](/bootfuzz-screenshot.png "Bootfuzz Screenshot")

A small fuzzer written to test motherboards / system BIOS for MBR-based hosts

## What does this test?
This fuzzer will test Port IO using the x86 `in` and `out` instructions. It uses a BIOS Service Timer to generate random word values and then supply those random word values as operands to the `in` and `out` instructions.  

There are also testing modes for BIOS Services provided by `int 0x13` - specifically disk read/write.

## Contributing
If you are able to run this on actual hardware, please open an issue and let us know your system specs and your results.

## Assembling
You can assemble `bootfuzz.asm` with NASM thusly:

```
nasm -f bin -o bootfuzz.img bootfuzz.asm
```

## Running

![https://img.youtube.com/vi/_j66cVXjqEk/0.jpg](https://www.youtube.com/watch?v=_j66cVXjqEk "Bootfuzz Running on Physical Hardware")

_Bootfuzz running on physical hardware_

After you have assembled the fuzzer into `bootfuzz.img`, you can run the fuzzer in qemu thusly:

```
qemu-system-i386 -fda bootfuzz.img -nographic -accel kvm
```

In VirtualBox, you will need to add a "Floppy" controller in the VM settings and then add a floppy drive.  After the floppy drive is created, you can point it at `bootfuzz.img` and then boot up.

## Precompiled
You can also use the provided `bootfuzz.img` in this repository as a precompiled mbr for fuzzing.

## Crashing Test Cases
I have seen repeatable crashes in QEMU, VirtualBox, and VMWare Workstation Player already, but I do not have the time or interest in triaging them.  I'm more interested in getting it running on physical hardware.

**Crashing Testcase 1: QEMU and VirtualBox**

* `QEMU emulator version 8.0.4 (Debian 1:8.0.4+dfsg-1ubuntu3.23.10.3)`
* `VirtualBox Version 7.0.14 r161095`

```
org 0x7c00

start:
    mov dx, 0x03ff
    in ax, dx

times 510-($-$$) db 0
db 0x55, 0xaa 
```

**Crashing Testcase 2: VMWare Player**

* `VMWare Workstation Player Version 17.5.1 build-23298084`

```
org 0x7c00

start:
    mov dx, 0x04ba
    mov ax, 0x00a8
    out dx, ax

times 510-($-$$) db 0
db 0x55, 0xaa 
```

**Crashing Testcase 3: VMWare Player**

* `VMWare Workstation Player Version 17.5.1 build-23298084`

```
org 0x7c00

start:
    mov ax, 0x163e
    mov dx, 0x043e
    in ax, dx

times 510-($-$$) db 0
db 0x55, 0xaa 
```

## Bugs
If you find bugs using this fuzzer I would appreciate a shout out or a link back to this project.  
