; BOOTFUZZ
; 
; Copyright (c) 2024 Nicholas Starke
; https://github.com/nstarke/bootfuzz
;
; assemble with `nasm -f bin -o bootfuzz.img bootfuzz.asm`
; run in qemu: `qemu-system-i386 -fda bootfuzz.img -nographic -accel kvm`

[bits 16]
org 0x7c00

start:
    ; vga video mode bios settings
    mov ah, 0x0
    mov al, 0x2 ; mov al, 0x2 for 'text mode'
                 ; mov al, 0x12 for 'vga mode'
    int 0x10

    ; vga video memory map
    mov ax, 0xb000 ; mov al, 0xb800 for 'text mode'
                   ; mov al, 0xa000 for 'vga mode'
    mov ds, ax
    mov es, ax
    
    ; set up code segment
    push cs
    
    ; set up stack
    pop ds
    
    mov bx, before
    call print_string
    mov ax, 0x$AX
    mov dx, 0x$DX
    nop
    $INSN
    nop
    mov bx, after
    call print_string
reboot:
    hlt


print_letter:
    pusha
    mov ah, 0xe
    mov bx, 0xf
    int 0x10
    popa
    ret

print_string:
    pusha
print_string_begin:
    mov al, [bx]
    test al, al
    je print_string_end
    push bx
    call print_letter
    pop bx
    inc bx
    jmp print_string_begin
print_string_end:
    popa
    ret

before:
db "Before", 0xa, 0xd, 0x0

after:
db "After", 0xa, 0xd, 0x0

times 510-($-$$) db 0
db 0x55, 0xaa 