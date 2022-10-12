//http://www.osdever.net/tutorials/view/lba-hdd-access-via-pio
//https://wiki.osdev.org/ATA_PIO_Mode
#include "atapio.h"

/**/

void read_28(u8 sectors, u32 addr, u8 drive, u16 * buffer){
     //drive indicator and some magic bits to port 0x1F6
    outb(0x1F6, 0xE0 | (drive << 4) | ((addr >> 24) & 0x0F));

    //send two NULL byte
    outb(0x1F1, 0x00);

    //sector count
    outb(0x1F2, sectors);

    //low 8 bits of the block address to port 0x1F3
    outb(0x1F3, (u8)addr);

    //next 8 bits of the block address to port 0x1F4
    outb(0x1F4, (u8)(addr >> 8));

    //next 8 bits of the block address to port 0x1F5
    outb(0x1F5, (u8)(addr >> 16));

    //read command(0x20) to port 0x1F7
    outb(0x1F7, 0x20);

    while (!(inb(0x1F7) & 0x08)) {}

    for (u16 idx = 0; idx < 256; idx++) {

        u16 tmpword = inw(0x1F0);

        buffer[idx] = tmpword;

        //buffer[idx * 2] = (u8)tmpword;

        //buffer[idx * 2 + 1] = (u8)(tmpword >> 8);

    }
}

void write_28(u8 sectors, u32 addr, u8 drive, u16 * buffer){
    //drive indicator and some magic bits to port 0x1F6
    outb(0x1F6, 0xE0 | (drive << 4) | ((addr >> 24) & 0x0F));

    //send two NULL byte
    outb(0x1F1, 0x00);

    //sector count
    outb(0x1F2, sectors);

    //low 8 bits of the block address to port 0x1F3
    outb(0x1F3, (u8)addr);

    //next 8 bits of the block address to port 0x1F4
    outb(0x1F4, (u8)(addr >> 8));

    //next 8 bits of the block address to port 0x1F5
    outb(0x1F5, (u8)(addr >> 16));

    //write command(0x30) to port 0x1F7
    outb(0x1F7, 0x30);

    while (!(inb(0x1F7) & 0x08)) {}

    for (u16 idx = 0; idx < 256; idx++) {

        u16 tmpword = buffer[idx];

        //tmpword = buffer[8 + idx * 2] | (buffer[8 + idx * 2 + 1] << 8);

        outw(0x1F0, tmpword);

    }

    outb(0x1F7, 0xE7);//cache flush
}


void read_48(u8 secl, u8 sech, u64 addr, u8 drive, u16 * buffer){
    //drive indicator and some magic bits to port 0x1F6
    outb(0x1F6, 0x40 | (drive << 4));


    //send two NULL bytes
    outb(0x1F1, 0x00);
    outb(0x1F1, 0x00);

    //16 bit sector count
    outb(0x1F2, sech);
    outb(0x1F2, secl);

    //bits 24-31 to port 0x1F3
    outb(0x1F3, (u8)(addr >> 24));

    //bits 0-7 to port 0x1F3
    outb(0x1F3, (u8)addr);

    //bits 32-39 to port 0x1F4
    outb(0x1F4, (u8)(addr >> 32));

    //bits 8-15 to port 0x1F4
    outb(0x1F4, (u8)(addr >> 8));

    //bits 40-47 to port 0x1F5
    outb(0x1F5, (u8)(addr >> 40));

    //bits 16-23 to port 0x1F5
    outb(0x1F5, (u8)(addr >> 16));

    //read command(0x24) to port 0x1F7
    outb(0x1F7, 0x24);

    while (!(inb(0x1F7) & 0x08)) {}

    for (u16 idx = 0; idx < 256; idx++) {

        u16 tmpword = inw(0x1F0);

        buffer[idx] = tmpword;

        //buffer[idx * 2] = (u8)tmpword;

        //buffer[idx * 2 + 1] = (u8)(tmpword >> 8);

    }
}

void write_48(u8 secl, u8 sech, u64 addr, u8 drive, u16 * buffer){
    //drive indicator and some magic bits to port 0x1F6
    outb(0x1F6, 0x40 | (drive << 4));

    //send two NULL bytes
    outb(0x1F1, 0x00);
    outb(0x1F1, 0x00);

    //16 bit sector count
    outb(0x1F2, sech);
    outb(0x1F2, secl);

    //bits 24-31 to port 0x1F3
    outb(0x1F3, (u8)(addr >> 24));

    //bits 0-7 to port 0x1F3
    outb(0x1F3, (u8)addr);

    //bits 32-39 to port 0x1F4
    outb(0x1F4, (u8)(addr >> 32));

    //bits 8-15 to port 0x1F4
    outb(0x1F4, (u8)(addr >> 8));

    //bits 40-47 to port 0x1F5
    outb(0x1F5, (u8)(addr >> 40));

    //bits 16-23 to port 0x1F5
    outb(0x1F5, (u8)(addr >> 16));

    //write command(0x34) to port 0x1F7
    outb(0x1F7, 0x34);

    while (!(inb(0x1F7) & 0x08)) {}

    for (u16 idx = 0; idx < 256; idx++) {

        u16 tmpword = buffer[idx];

        //tmpword = buffer[8 + idx * 2] | (buffer[8 + idx * 2 + 1] << 8);

        outw(0x1F0, tmpword);

    }
    outb(0x1F7, 0xE7);//cache flush
}



