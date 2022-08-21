#include "isr.h"
#include "utility.h"
#include "io.h"
#include "pic.h"
#include "keyboard.h"
#include "kernel.h"

#define ENTER 0x1c

void keyboard_handler(registers_t *regs) {
    u8 scancode = inb(0x60);


    if (scancode == ENTER){
       keypressmsg();
    }
}

void keyboard_init() {
    irq_install_handler(IRQ1, keyboard_handler);//irq 1 is reserved for keyboard input
}
