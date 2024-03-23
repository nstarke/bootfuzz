org 0x7c00

start:
    push cs
    pop ds
    mov bx, banner_str
    call print_string
    call read_keyboard
    cmp al, 0x31
    je fuzz_in
    cmp al, 0x32
    je fuzz_out
    mov ah, 0x2
    cmp al, 0x33
    je fuzz_int13
    mov ah, 0x3
    cmp al, 0x34
    je fuzz_int13
    int 0x19
    
fuzz_in:
    mov bx, in_str
    call print_string
    xor dx, dx
fuzz_in_begin:
    mov al, 0xd
    call print_letter
    mov al, 0xa
    call print_letter
    call get_random
    mov dx, ax
    call print_hex
    call get_random
    mov dx, ax
    push ax
    mov al, 0x2d
    call print_letter
    call print_hex
    pop ax
    nop 
    nop
    in ax, dx
    jmp fuzz_in_begin

fuzz_out:
    mov bx, out_str
    call print_string
    xor dx, dx
fuzz_out_begin:
    mov al, 0xd
    call print_letter
    mov al, 0xa
    call print_letter
    call get_random
    mov dx, ax
    call print_hex
    call get_random
    push ax
    mov dx, ax
    mov al, 0x2d
    call print_letter
    call print_hex
    pop ax
    out dx, ax
    jmp fuzz_out_begin

fuzz_int13:
    mov bx, int_str
    call print_string
    xor dx, dx
    mov bh, ah
fuzz_int13_begin:
    mov al, 0xd
    call print_letter
    mov al, 0xa
    call print_letter
    call get_random
    mov dx, ax
    call print_hex
    call get_random
    push ax
    mov dx, ax
    mov al, 0x2d
    call print_letter
    call print_hex
    pop ax
    mov cx, ax
    mov ah, bh
    int 0x13
    jmp fuzz_int13_begin

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

print_hex:
    pusha
    mov si, HEX_OUT + 2
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
    mov bx, HEX_OUT
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
    

HEX_OUT:
    db '0x0000', 0x0

banner_str:
    db "Bootfuzz", 0xa, 0xd, 0xa
    db "Select a Target:", 0xa, 0xd
    db "1) IN", 0xa, 0xd
    db "2) OUT", 0xa, 0xd
    db "3) INT13 (Read)", 0xa, 0xd
    db "4) INT13 (Write)", 0xa, 0xd, 0xa
    db "Select a Number 1-4", 0xa, 0xd, 0x0

in_str:
    db "In: ", 0xa, 0xd, 0x0

out_str:
    db "Out: ", 0xa, 0xd, 0x0

int_str:
    db "Interrupt: ", 0xa, 0xd, 0x0

times 510-($-$$) db 0
db 0x55,0xaa 