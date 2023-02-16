#include "usbmass.h"
void read_usb(u16 lba, u16 block_count, u16 destination_address){
    __asm__ __volatile__ ("movl %k0, %%ebx" : : "Nd"(lba));
    __asm__ __volatile__ ("movl %k0, %%ecx" : : "Nd"(block_count));
    __asm__ __volatile__ ("movl %k0, %%edi" : : "Nd"(destination_address));

    read10();
}

void write_usb(u16 lba, u16 block_count, u16 source_address){
    __asm__ __volatile__ ("movl %k0, %%ebx" : : "Nd"(lba));
    __asm__ __volatile__ ("movl %k0, %%ecx" : : "Nd"(block_count));
    __asm__ __volatile__ ("movl %k0, %%edi" : : "Nd"(source_address));

    write10();
}
