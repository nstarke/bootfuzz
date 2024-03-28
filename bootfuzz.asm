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
    
    ; check if user entered "3" (ASCII - 0x33)
    cmp al, 0x33
    je fuzz_read

fuzz_read:    
    ; set INT13 operation mode to disk read (0x2)
    mov bx, 0x2
    push bx
    je fuzz_int13
    
    ; check if user entered "4" (ASCII - 0x34)
    cmp al, 0x34
    jne reboot

fuzz_write:
    ; set INT13 operation mode to disk write
    mov bx, 0x3
    push bx
    je fuzz_int13
    
    ; if the user enters anything else, reboot
reboot:
    int 0x19

fuzz_in:
    ; print '\r'
    mov al, 0xd
    call print_letter
    
    ; print '\n'
    mov al, 0xa
    call print_letter

    ; print "IN"
    mov bx, in_str
    call print_string
    
    ; put random value in ax
    call get_random
    
    ; copy first random value into dx so it can be 
    ; supplied to IN later as the 'src' operand.
    ; also so it can be printed to console
    mov dx, ax
    call print_hex

    ; save dx for later to be used with 'in'
    push dx

    ; create second random value
    call get_random

    ; move second random value into cx
    mov cx, ax
    
    ; put third random value in ax.  This will be used as 
    ; the 'dest' operand for IN later, after multiplying by cx.
    call get_random
    
    ; multiply ax and cx.  This is to 'spread' the operand values 
    ; for 'in'.  since the BIOS service timer is deterministic, 
    ; it will always produce values that are proximate.  
    ; multiplying helps redistribute the operand values.
    mul cx

    ; take multiplied value and save it on the stack for later
    push ax

    ; move random value into dx so it can be hex 
    ; printed out to console.
    mov dx, ax
    
    ; print out '-' (dash) character
    mov al, 0x2d
    call print_letter
    
    ; prints out second random value
    call print_hex
    
    ; restore ax so we can pass it to 'in'
    pop ax    

    ; restore dx so we can pass it to 'in'
    pop dx
    
    ; perform the test by executing 'in'
    in ax, dx
    
    ; loop forever
    jmp fuzz_in

fuzz_out:
    ; print to console '\r'
    mov al, 0xd
    call print_letter
    
    ; print to console '\n'
    mov al, 0xa
    call print_letter

    ; print to console "OUT"
    mov bx, out_str
    call print_string
    
    ; get first random value that will eventually
    ; be used as the 'dest' operand to 'out'
    call get_random
    
    ; move first random value into dx so it will be
    ; the 'dest operand to 'out'
    mov dx, ax
    
    ; print first random value
    call print_hex

    ; save first random value for later. will be 
    ; pop'd into dx before executing 'in'
    push dx
 
    ; get second random value
    call get_random

    ; move second random value into cx.
    mov cx, ax

    ; get third random value
    call get_random

    ; multiply second and third random values to 
    ; redistribute operand ranges.
    mul cx

    ; save multiplied random value for later
    push ax
    
    ; move muliplied random value into dx for printing
    mov dx, ax

    ; print '-' (dash) character to delimit two random
    ; values
    mov al, 0x2d
    call print_letter 
    
    ; print second random value currently stored in dx
    call print_hex
    
    ; restore ax so it can be used as 'src' operand to 
    ; 'out' instruction.
    pop ax

    ; restore dx so it can be used as the 'dest' operand
    ; to the 'out' instruction
    pop dx
    
    ; execute 'out' instruction
    out dx, ax
    
    ; loop forever
    jmp fuzz_out

fuzz_int13:

    ; print '\r'
    mov al, 0xd
    call print_letter

    ; print '\n'
    mov al, 0xa
    call print_letter

    ; pop the read/write type into bh.
    pop bx

    cmp bx, 0x2
    ; check if we are 'reading' or 'writing'
    ; and print out the proper string.
   
    je print_read

print_write:
    push bx

    ; print 'write' string
    mov bx, write_str
    call print_string

    ; skip 'print_read' logic
    jmp continue_disk_fuzz

print_read:
    push bx

    ; print 'read'
    mov bx, read_str
    call print_string

continue_disk_fuzz:
    ; get first random value
    call get_random
    mov dx, ax

    ; save first random value for later
    push dx

    ; print first random value.
    call print_hex

   ; get second random value
    call get_random

    ; move second random value into cx.
    mov cx, ax

    ; get third random value
    call get_random

    ; multiply second and third random values to 
    ; redistribute operand ranges.
    mul cx

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

    ; restoring dx to first random value
    pop dx

    ; copy read/write arg into ah
    pop bx

    ; moving BIOS Service type (read/write) to 'ah'
    ; which is a parameter to the BIOS Service.
    mov ah, bl

    ; save bx for next iteration
    push bx

    ; invoke the BIOS service (int13)
    int 0x13

    ; loop forever
    jmp fuzz_int13

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
    pop di
    pop si
    pop dx
    pop cx
    pop bx
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
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    ret
    
hex_str:
    db '0x0000', 0x0

banner_str:
    db "Bootfuzz By Nick Starke (https://github.com/nstarke)", 0xa, 0xd, 0xa
    db "Select Target:", 0xa, 0xd
    db "1) IN", 0xa, 0xd
    db "2) OUT", 0xa, 0xd
    db "3) Read", 0xa, 0xd
    db "4) Write", 0xa, 0xd, 0xa
    db "Enter 1-4", 0xa, 0xd, 0x0

in_str:
    db "In:", 0x0

out_str:
    db "Out:", 0x0

read_str:
    db "Read:", 0x0

write_str:
    db "Write:", 0x0

times 510-($-$$) db 0
db 0x55,0xaa 