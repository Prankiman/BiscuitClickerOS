#include "isr.h"
#include "idt.h"
#include "utility.h"
#include "keyboard.h"

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
void main() {
    isr_install();  ///initializes the interrupt service registers
    /* Test the interrupts */
    __asm__ __volatile__("sti");
    keyboard_init();
    __asm__ __volatile__("int $2");
    //__asm__ __volatile__("int $3");
    char *video_address = (char*)0xb800a;
    *video_address = '_';
    for(int i = 0; i < 10; i++){
        video_address ++;
        *video_address = (char)0xe1;//blue on yellow
        video_address ++;
        *video_address = '#';
    }
}


