[bits 16]
[org 0x7c00]

kernel_offset equ 0x10000;can currently only be from 0x00000 to 0xfffff due to...
;... ah=0x42 int 0x13 uses 2 words for the transfer buffer and I placed the kernel code att the sector right after the boot sector...
;...sector read code found at https://github.com/freebsd/freebsd-src/blob/main/stand/i386/boot2/boot1.S might be able to help with this

section .text

global _start

_start:

xor ax, ax
mov ds, ax
mov ss, ax
mov gs, ax
mov es, ax
mov fs, ax

sti

mov [boot_drive], dl

mov bp, 0x9000
mov sp, bp

mov bx, real_msg
call print

;get boot_drive location____
;mov dx, boot_drive
;call print_hex

;jmp $
;____________


call load_kernel
call vga_mode

jmp enter_pm

;include files
%include "print_string.asm"
;%include "print_hex_func.asm"
%include "load_disk.asm"
%include "gdt.asm"
%include "print_protected.asm"
%include "enter_pm.asm"


[bits 16]

load_kernel:

    packet:
        db 0x10 ;packet size (16 bytes)
        db 0    ;always 0
    block_count:
        dw 127  ; num sectors
    trans_buff: ;transfer buffer (segment & offset)
        dw 0   ; memory buffer destination address (0x10000:0)
        dw 0x1000
    lba:
        dd 1    ; put the lba to read in this spot (lba1) (lba0 contains our bootloader code)
        dd 0    ; more storage bytes if lba number exceeds 4 bytes

    ;______________________________________________
    mov si, packet
    mov ah, 0x42
    mov dl, [boot_drive]    ;set dl to drive num of bootable device

    int 0x13
    ;______________________________________________

    jc load_ah2  ;if carry flag set (error occured) load disk using ah=2h

    ret

load_ah2:
    mov dh, 40 ;number of sectors to read
    call disk_load

    ret

[bits 16]
vga_mode:
    pusha
    mov ah, 0x00
    mov al, 0x13
    int 0x10
    popa
    ret

[bits 32]
is_A20_on:
	pushad
	mov edi,0x112345  ;odd megabyte address.
	mov esi,0x012345  ;even megabyte address.
	mov [esi],esi     ;making sure that both addresses contain diffrent values.
	mov [edi],edi     ;(if A20 line is cleared the two pointers would point to the address 0x012345 that would contain 0x112345 (edi))
	cmpsd             ;compare addresses to see if the're equivalent.
	popad
	je enable_A20        ;if not equivalent , A20 line is set.
	ret               ;if equivalent , the A20 line is cleared.
 
;enable_A20: ;fast a20 gate
;    in al, 0x92
;    or al, 2
;    out 0x92, al

enable_A20: ;freeBSD's implementation
    cli

enable_A20.1:
    dec cx                      ; Timeout?
    jz enable_A20.3                       ; Yes
    in al, 0x64                 ; Get status
    test al, 0x2                ; Busy?
    jnz enable_A20.1                      ; Yes
    mov al, 0xd1                ; Command: write
    out 0x64, al                ;  output port
enable_A20.2:
    in al, 0x64                 ; Get status
    test al, 0x2                ; Busy?
    jnz enable_A20.2                      ; Yes
    mov al, 0xdf                ; Enable
    out 0x60, al                ;  A20

enable_A20.3:

begin:

    mov ebx, protected_msg
    call print_pm
    call is_A20_on
    call kernel_offset ;jump to kernel address
    ;call main

jmp $

;variables
boot_drive db 0x00
real_msg db "real ", 0
protected_msg db "vga 80x25 text mode (were in protected mode baby)", 0
kernel_msg db "kernel ", 0

times 510-($-$$) db  0
dw 0xaa55
