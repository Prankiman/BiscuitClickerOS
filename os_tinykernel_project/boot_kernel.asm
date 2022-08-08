[bits 16]
[org 0x7c00]
kernel_offset equ 0x1000

;mov

xor ax, ax
mov ds, ax

mov bp, 0x9000
mov sp, bp

mov bx, real_msg
call print


call load_kernel

call enter_pm

;include files
%include "print.asm"
%include "load_disk.asm"
%include "gdt_seg.asm"
%include "print_pm.asm"
%include "enter_pm_seg.asm"




mov dh, 15;number of sectors to read


[bits 32]

protected:

    mov ebx, protected_msg
    call print_pm

    call kernel_offset

jmp $

;variables
;boot_drive db 0x80
real_msg db "real"
protected_msg db "protected"
kernel_msg db "kernel"


times 510-($-$$) db 0x0
dw 0xaa55
