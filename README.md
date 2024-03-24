# Bootfuzz

![Bootfuzz Screenshot](/bootfuzz-screenshot.png "Bootfuzz Screenshot")

A small fuzzer written to test motherboards / system BIOS for MBR-based hosts

## Contributing
If you are able to run this on actual hardware, please open an issue and let us know your system specs and your results.

## Assembling
You can assemble `fuzz.asm` with NASM thusly:

```
nasm -f bin -o boot.img fuzz.asm
```

## Running
After you have assembled the fuzzer into `boot.img`, you can run the fuzzer in qemu thusly:

```
qemu-system-i386 -fda boot.img -nographic -accel kvm
```

In VirtualBox, you will need to add a "Floppy" controller in the VM settings and then add a floppy drive.  After the floppy drive is created, you can point it at `boot.img` and then boot up.