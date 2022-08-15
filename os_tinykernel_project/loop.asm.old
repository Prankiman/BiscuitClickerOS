mov ah, 0x0e;tele-type mode
mov al, 0ah ;new line
int 0x10
mov al, 'E'
int 0x10

jmp $;jump to current adress(infinite loop)     
times 510-($-$$) db 0
dw 0xaa55 