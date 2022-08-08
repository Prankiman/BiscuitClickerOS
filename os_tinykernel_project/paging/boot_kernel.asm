[bits 16]
[org 0x7c00]
kernel_offset equ 0x1000

mov [boot_drive], dl

xor ax, ax
mov ds, ax
mov ss, ax

mov bp, 0x9000
mov sp, bp

mov bx, real_msg
call print


call load_kernel

jmp enter_pm

;include files
%include "print_string.asm"
%include "load_disk.asm"
%include "gdt_seg.asm"
%include "print_protected.asm"
%include "enter_pm_seg.asm"



load_kernel:

    mov bx, kernel_msg

    mov dh, 15;number of sectors to read
    mov dl, [boot_drive]
    call disk_load

    ret


[bits 32]

begin:

    mov ebx, protected_msg
    call print_pm

    call kernel_offset ;jump to kernel address

jmp $

;variables
boot_drive db 0x80
real_msg db "real"
protected_msg db "protected"
kernel_msg db "kernel"


times 510-($-$$) db 0x0
dw 0xaa55


;times 15*256 dw 0x0
