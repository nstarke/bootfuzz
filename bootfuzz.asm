; BOOTFUZZ
; 
; Copyright (c) 2024 Nicholas Starke
; https://github.com/nstarke/bootfuzz
;
; assemble with `nasm -f bin -o bootfuzz.img bootfuzz.asm`
; run in qemu: `qemu-system-i386 -fda bootfuzz.img -nographic -accel kvm`

[bits 16]

; MBR boot sector address
org 0x7c00

start:

    ; vga video mode bios settings
    mov al, 0x2
    mov ah, 0x12
    int 0x10

    ; vga video memory map
    mov ax, 0xb800
    mov ds, ax
    mov es, ax
    
    ; set up code segment
    push cs
    
    ; set up stack
    pop ds
    
    ; print banner / options
    mov bx, banner_str
    call print_string
    
    ; read user selection
    call read_keyboard
    
    ; check if user entered "1" (ASCII - 0x31)
    cmp al, 0x31
    je fuzz_in
    
    ; check if user entered "2" (ASCII - 0x32)
    cmp al, 0x32
    je fuzz_out
    
    ; set INT13 operation mode to disk read (0x2)
    mov ah, 0x2
    
    ; check if user entered "3" (ASCII - 0x33)
    cmp al, 0x33
    je fuzz_int13
    
    ; set INT13 operation mode to disk write
    mov ah, 0x3
    
    ; check if user entered "4" (ASCII - 0x34)
    cmp al, 0x34
    je fuzz_int13
    
    ; if the user enters anything else, reboot
    int 0x19

fuzz_in:
    ; print "IN"
    mov bx, in_str
    call print_string
fuzz_in_begin:
    ; print '\r'
    mov al, 0xd
    call print_letter
    
    ; print '\n'
    mov al, 0xa
    call print_letter
    
    ; put random value in ax
    call get_random
    
    ; copy first random value into dx so it can be 
    ; supplied to IN later as the 'src' operand.
    ; also so it can be printed to console
    mov dx, ax
    call print_hex
    
    ; put random value in ax.  This will be used as 
    ; the 'dest' operand for IN later.
    call get_random
    
    ; move random value into dx so it can be hex 
    ; printed out to console.
    mov dx, ax
    
    ; save ax for later
    push ax
    
    ; print out '-' (dash) character
    mov al, 0x2d
    call print_letter
    
    ; prints out second random value
    call print_hex
    
    ; restore ax so we can pass it to in
    pop ax
    
    ; perform the test by executing IN
    in ax, dx
    
    ; loop forever
    jmp fuzz_in_begin

fuzz_out:
    ; print to console "OUT"
    mov bx, out_str
    call print_string
fuzz_out_begin:
    ; print to console '\r'
    mov al, 0xd
    call print_letter
    
    ; print to console '\n'
    mov al, 0xa
    call print_letter
    
    ; get first random value that will eventually
    ; be used as the 'dest' operand to OUT
    call get_random
    
    ; move first random value into dx so it will be
    ; the 'dest operand to OUT
    mov dx, ax
    
    ; print first random value
    call print_hex
    
    ; get second random value
    call get_random
    
    ; save second random value for later
    push ax
    
    ; move second random value into dx
    mov dx, ax
    
    ; print '-' (dash) character to delimit two random
    ; values
    mov al, 0x2d
    call print_letter
    
    ; print second random value currently stored in dx
    call print_hex
    
    ; restore ax so it can be used as 'src' operand to 
    ; OUT
    pop ax
    
    ; execute out instruction
    out dx, ax
    
    ; loop forever
    jmp fuzz_out_begin

fuzz_int13:
    ; print int string
    mov bx, int_str
    call print_string
    
    ; save ah argument for later
    ; ah is passed in to determine read or write
    mov bh, ah
fuzz_int13_begin:
    ; print '\r'
    mov al, 0xd
    call print_letter

    ; 'print '\n'
    mov al, 0xa
    call print_letter

    ; 'get first random value'
    call get_random
    mov dx, ax

    ; 'print first random value'.
    call print_hex

    ; generate second random value
    call get_random

    ; save second random value for later
    push ax

    ; move second random value into dx for printing
    mov dx, ax

    ; print '-' (dash) character to console
    mov al, 0x2d
    call print_letter

    ; print second random hex value
    call print_hex

    ; restore second random value
    pop ax

    ; copy second random value into cx as arguments
    ; for int13 invocation
    mov cx, ax

    ; copy int13 argument into ah to determine 
    ; read or write
    mov ah, bh

    ; invoke the BIOS service (int13)
    int 0x13

    ; loop forever
    jmp fuzz_int13_begin

; relies on BIOS Services timer to create
; 'random' values returned in ax.
get_random:
    push bx
    push cx
    push dx
    push si
    push di
    xor ax, ax
    in al, (0x40)
    mov cl, 2
    mov ah, al
    in al, (0x40)
    pop bx
    pop cx
    pop dx
    pop si
    pop di
    ret

; Utility functions that aren't very interesting
; Collected from:
; * https://stackoverflow.com/questions/27636985/printing-hex-from-dx-with-nasm
; * https://github.com/nanochess/book8088
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

print_hex:
    pusha
    mov si, hex_str + 2
    mov cx, 0

next_character:
    inc cx
    mov bx, dx
    and bx, 0xf000
    shr bx, 4
    add bh, 0x30
    cmp bh, 0x39
    jg add_7

add_character_hex:
    mov [si], bh
    inc si
    shl dx, 4
    cmp cx, 4
    jnz next_character
    jmp _done

_done:
    mov bx, hex_str
    call print_string
    popa
    ret

add_7:
    add bh, 0x7
    jmp add_character_hex

read_keyboard:
    push bx
    push cx
    push dx
    push si
    push di
    mov ah, 0x0
    int 0x16
    pop bx
    pop cx
    pop dx
    pop si
    pop di
    ret
    
hex_str:
    db '0x0000', 0x0

banner_str:
    db "Bootfuzz By Nick Starke (https://github.com/nstarke)", 0xa, 0xd, 0xa
    db "Select a Target:", 0xa, 0xd
    db "1) IN", 0xa, 0xd
    db "2) OUT", 0xa, 0xd
    db "3) INT13 (Read)", 0xa, 0xd
    db "4) INT13 (Write)", 0xa, 0xd, 0xa
    db "Enter a Number 1-4", 0xa, 0xd, 0x0

in_str:
    db "In: ", 0xa, 0xd, 0x0

out_str:
    db "Out: ", 0xa, 0xd, 0x0

int_str:
    db "Interrupt: ", 0xa, 0xd, 0x0

times 510-($-$$) db 0
db 0x55,0xaa 