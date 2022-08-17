#include "isr.h"
#include "idt.h"
#include "utility.h"

void main() {
    isr_install();  //"install" the interrupt service registers
    /* Test the interrupts */
    __asm__ __volatile__("int $2");
    //__asm__ __volatile__("int $3");
    //char *video_address = (char*)0xb8000;
    /**video_address = 'X';
    for(int i = 0; i < 10; i++){
        video_address += 0xb1;
        *video_address = 'X';
    }*/

}
