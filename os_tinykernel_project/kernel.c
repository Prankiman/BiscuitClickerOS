#include "isr.h"
#include "idt.h"
#include "utility.h"
#include "keyboard.h"
#include "mouse.h"
#include "screen.h"

void keypressmsg(){
         char *video_address = (char*)0xb8000;
        //print interrupt num____________
        video_address[0] = 'A';//address[1] sets forground and background color of character
        video_address[2] = ':';
        video_address[4] = 'p';
        video_address[6] = 'r';
        video_address[8] = 'e';
        video_address[10] = 's';
        video_address[12] = 's';
        video_address[14] = 'e';
        video_address[16] = 'd';
}

void set_vga_mode() {
    __asm__ __volatile__(
        "mov $0x00, %ah;\
        mov $0x13, %al;\
        int $0x10"
    );
}

void main() {
    isr_install();  ///initializes the interrupt service registers
    /* Test the interrupts */
    //__asm__ __volatile__("sti");
    keyboard_init();
    mouse_install();

   // set_vga_mode();

    __asm__ __volatile__("int $2");
    //__asm__ __volatile__("int $3");
    char *video_address = (char*)0xb8010;
    *video_address = '_';

    u8 *VGA = (u8*)0xA0000;
    u16 offset;

     for (int x = 0; x <= 255; x++){
        for (int y = 0; y <= 50; y++){
            offset = x + 320 * y;

            u8 color = x;

            VGA[offset] = color;
    }

    }
}


