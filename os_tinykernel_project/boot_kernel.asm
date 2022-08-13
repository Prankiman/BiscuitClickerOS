[bits 16]
[org 0x7c00]
kernel_offset equ 0x1000

xor ax, ax
mov ds, ax
mov ss, ax

mov [boot_drive], dl

mov bp, 0x9000
mov sp, bp

mov bx, real_msg
call print


call load_kernel

jmp enter_pm

;jmp $

;include files
%include "print_string.asm"
%include "load_disk.asm"
%include "gdt.asm"
%include "idt.asm"
%include "print_protected.asm"
%include "enter_pm.asm"


[bits 16]

load_kernel:

    mov bx, kernel_msg
    call print

    mov bx, kernel_offset
    mov dh, 15;number of sectors to read
    mov dl, [boot_drive]
    call disk_load

    ret


[bits 32]
;[extern main]

begin:

    mov ebx, protected_msg
    call print_pm

    call kernel_offset ;jump to kernel address
    ;call main

jmp $

;variables
boot_drive db 0x80
real_msg db "real ", 0
protected_msg db " protected ", 0
kernel_msg db "kernel ", 0


times 510-($-$$) db 0x0
dw 0xaa55
