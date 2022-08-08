;this code is from Nick Blundells 'Writing a Simple Operating System from Scratch
;---------------------------------------------
; Read some sectors from the boot disk using our disk_read function
[bits 16]
[org 0x7c00]
;mov [BOOT_DRIVE] , dl ; BIOS stores our boot drive in DL , so it ’s
; best to remember this for later.
mov bp , 0x8000 ; Here we set our stack safely out of the
mov sp , bp ; way , at 0x8000
mov bx , 0x9000 ; Load 5 sectors to 0x0000 ( ES ):0x9000 ( BX )
mov dh , 5 ; from the boot disk.
;mov dl , [BOOT_DRIVE]
call disk_load
mov dx , [0x9000] ; Print out the first loaded word , which
call print_hex ; we expect to be 0xdada , stored
; at address 0x9000
mov dx, [0x9200] ; Also , print the first word from the
call print_hex ; 2nd loaded sector : should be 0xface
jmp $
;_____including the files I\ve written containing pointers to needed/useful instructions
%include "print_string.asm" ; Re - use our print_string routine
%include "print_hex_func.asm" ; Re - use our print_hex function
%include "load_disk.asm"
;_____________________

; Include our new disk_load function
; Global variables
;BOOT_DRIVE: db 0x00
; Bootsector padding
times 510-($-$$) db 0x00
dw 0xaa55
; We know that BIOS will load only the first 512 - byte sector from the disk ,
; so if we purposely add a few more sectors to our code by repeating some
; familiar numbers , we can prove to ourselfs that we actually loaded those
; additional two sectors from the disk we booted from.
times 256 dw 0xdada
times 256 dw 0xface
;--------------------------------------------------------
