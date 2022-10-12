#include "isr.h"
#include "idt.h"
#include "utility.h"
#include "keyboard.h"
#include "mouse.h"
#include "screen.h"
#include "pic.h"
#include "atapio.h"

u8 lclick = 0;
u8 keypress = 0;

u16* clicks = (u16 *)0xa000;

void keypressed(){
        keypress = 1;
}
void left_click(){
        if(!lclick){
            lclick = 1;
            (*clicks)++;
        }
}

//__defined in ata.asm__
extern void ata_lba_read();
extern void ata_lba_write();
//______________________

void main_loop(){
    while(1){
        clear_screen(0xb9);
        switch(lclick){
            case 1:
                disp_biscuit_large(108, 48, 0xb9, 0x06);
                break;
            default:
                disp_biscuit(120, 60, 0xb9, 0x06);
                break;
        }
        if(keypress){
            //if(lclick)clicks = inb(0x03);
            if(lclick)  {
                /*__asm__ __volatile__ ("mov $0xa000, %edi");
                __asm__ __volatile__ ("mov $70, %eax");
                __asm__ __volatile__ ("mov $1, %cl");
                ata_lba_read();
                __asm__ __volatile__ ("pause");*/
                //read_28((u8)1,(u32)0x38, (u8) 0, clicks);
                read_48((u8)1,(u8)0, (u64)0x38, (u8) 0, clicks);
            }
            else{
                /*__asm__ __volatile__ ("mov $0xa000, %edi");
                __asm__ __volatile__ ("mov $70, %eax");
                __asm__ __volatile__ ("mov $1, %cl");
                ata_lba_write();
                __asm__ __volatile__ ("pause");*/
                //write_28((u8)1,(u32)0x38, (u8) 0, clicks);
                write_48((u8)1,(u8)0, (u64)0x38, (u8) 0, clicks);
            }
            disp_string("keybawd...", 1, 2, 0x67);
            //outb (0x03, clicks); // 0x03 used for Count Register channel 1/5
        }
        disp_char_absolute('+', mouse_x, mouse_y, 0x6f);
        disp_string("score:", 1, 3, 0x6f);
        disp_int(*clicks, 48, 24, 0x6f);
        draw_screen();
    }
}

void main() {
    //clicks = inb(0x03);
    //__asm__ __volatile__ ("mov %0, %1" : : "r"(0xa0), "r"(clicks) );

    isr_install();


    keyboard_init();
    mouse_install();

     clear_screen(0xb9);
    //__asm__ __volatile__("int $19");
     draw_screen();

    /*__asm__ __volatile__ ("mov $0xa000, %edi");
    __asm__ __volatile__ ("mov $70, %eax");
    __asm__ __volatile__ ("mov $1, %cl");
    ata_lba_read();
    __asm__ __volatile__ ("pause");*/

    //read_28((u8)1,(u32)0x38, (u8) 0, clicks);
    read_48((u8)1,(u8)0, (u64)0x38, (u8) 0, clicks);

    main_loop();
}


