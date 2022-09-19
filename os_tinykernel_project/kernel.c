#include "isr.h"
#include "idt.h"
#include "utility.h"
#include "keyboard.h"
#include "mouse.h"
#include "screen.h"
#include "pic.h"


u8 lclick = 0;
u8 keypress = 0;
u32 clicks = 0;

void keypressed(){
        keypress = 1;
}
void left_click(){
        if(!lclick){
            lclick = 1;
            clicks++;
        }
}

void main_loop(){
    while(1){
        clear_screen(0);
        switch(lclick){
            case 1:
                disp_biscuit_large(108, 48, 0, 0x06);
                break;
            default:
                disp_biscuit(120, 60, 0, 0x06);
                break;
        }
        if(keypress)    disp_string("keyboard working bre", 1, 2, 0x67);
        disp_char_absolute('+', mouse_x, mouse_y, 0x6f);
        disp_string("score:", 1, 3, 0x6f);
        disp_int(clicks, 48, 24, 0x6f);
        draw_screen();
    }
}


void main() {

    isr_install();


    keyboard_init();
    mouse_install();

     clear_screen(0x0e);
    __asm__ __volatile__("int $19");
     draw_screen();

    main_loop();
}


