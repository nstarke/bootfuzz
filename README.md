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
After you have assembled the fuzzer into `bootfuzz.img`, you can run the fuzzer in qemu thusly:

```
qemu-system-i386 -fda bootfuzz.img -nographic -accel kvm
```

In VirtualBox, you will need to add a "Floppy" controller in the VM settings and then add a floppy drive.  After the floppy drive is created, you can point it at `bootfuzz.img` and then boot up.

## Precompiled
You can also use the provided `bootfuzz.img` in this repository as a precompiled mbr for fuzzing.

## Bugs
If you find bugs using this fuzzer I would appreciate a shout out or a link back to this project.  

I have seen repeatable crashes in QEMU and VirtualBox already, but I do not have the time or interest in triaging them.  I'm more interested in getting it running on physical hardware.