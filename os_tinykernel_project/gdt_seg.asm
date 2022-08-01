;gdt in assembly tutorial: http://web.archive.org/web/20190424213806/http://www.osdever.net/tutorials/view/the-world-of-protected-mode

gdt:

gdt_null:
   dq 0
gdt_code:
   dw 0xffff    ;setting the limit
   dw 0         ;base address to 0

   ;segment descriptor
   db 0         ;base continuation (i start the bit counting for the segment descriptor bits here)
   db 10011010b ;bits: 8 -> access flag, 9 -> read, 10 -> conforming, 11 -> code or data segment, 12 -> code or data segment, 13-14 -> privilage level, 15 -> present flag
   db 11001111b ; bits 16-19 -> last bits in segment limit, bit 20 -> available to system programmers flag (ignored by cpu), bit 21 -> always 0, bit 22 -> size (1 for 32 bit and 0 for 16-bit), 23 -> multiply segment limit by 4kb
   db 0

gdt_data:
   dw 0xffff
   dw 0

   db 0

   db 10010010b ;same as for gdt-code but bit 9 enables write access instead of read and the 10th bit enables expand direction (0=down, 1=up)

   db 11001111b ;almost same as for code-segment, bit 22 -> related to segment limit (1 to allow 4gb limit)

   db 0

gdt_end

gtd_desc:
   db gdt_end - gdt
   dw gdt
