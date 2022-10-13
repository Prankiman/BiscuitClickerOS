//http://www.osdever.net/tutorials/view/lba-hdd-access-via-pio
//https://wiki.osdev.org/ATA_PIO_Mode
#include "atapio.h"

//Error on real hardware do to floating bus (works in qemu for now)
/* Floating Bus

The disk that was selected last (by the BIOS, during boot) is supposed to maintain control of the electrical values on each IDE bus. If there is no disk connected to the bus at all, then the electrical values on the bus will all go "high" (to +5 volts). A computer will read this as an 0xFF byte -- this is a condition called a "floating" bus. This is an excellent way to find out if there are no drives on a bus. Before sending any data to the IO ports, read the Regular Status byte. The value 0xFF is an illegal status value, and indicates that the bus has no drives. The reason to read the port before writing anything is that the act of writing can easily cause the voltages of the wires to go screwy for a millisecond (since there may be nothing attached to the wires to control the voltages!), and mess up any attempt to measure "float". */

u8 primary_drive_present(){
    outb(0x1f6, 0xa0);
    __asm__("pause");
    u8 tmp = inb(0x1f7);
    if(tmp & 0x40)
        return 1;
    return 0;
}


u8 master_cont_exists(){
   outb(0x1F3, 0x88);
    if(inb(0x1F3) == 0x88)
        return 1;
    return 0;
}


void read_28(u8 sectors, u32 addr, u8 drive, u16 * buffer){

    if(!primary_drive_present() || !master_cont_exists())
        return;

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

    while (!(inb(0x1F7) & 0x08)) {//wait for DRQ bit
        if((inb(0x1F7) & 0))//if error bit is set return
            return;
    }

    for (u16 idx = 0; idx < 256; idx++) {

        u16 tmpword = inw(0x1F0);

        buffer[idx] = tmpword;

        //buffer[idx * 2] = (u8)tmpword;

        //buffer[idx * 2 + 1] = (u8)(tmpword >> 8);

    }
}

void write_28(u8 sectors, u32 addr, u8 drive, u16 * buffer){

    if(!primary_drive_present() || !master_cont_exists())
        return;

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

    while (!(inb(0x1F7) & 0x08)) {//wait for DRQ bit
        if((inb(0x1F7) & 0))//if error bit is set return
            return;
    }

    for (u16 idx = 0; idx < 256; idx++) {

        u16 tmpword = buffer[idx];

        //tmpword = buffer[8 + idx * 2] | (buffer[8 + idx * 2 + 1] << 8);

        outw(0x1F0, tmpword);

    }

    outb(0x1F7, 0xE7);//cache flush
}


void read_48(u8 secl, u8 sech, u64 addr, u8 drive, u16 * buffer){

    if(!primary_drive_present() || !master_cont_exists())
        return;

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

    while (!(inb(0x1F7) & 0x08)) {//wait for DRQ bit
        if((inb(0x1F7) & 0))//if error bit is set return
            return;
    }

    for (u16 idx = 0; idx < 256; idx++) {

        u16 tmpword = inw(0x1F0);

        buffer[idx] = tmpword;

        //buffer[idx * 2] = (u8)tmpword;

        //buffer[idx * 2 + 1] = (u8)(tmpword >> 8);

    }
}

void write_48(u8 secl, u8 sech, u64 addr, u8 drive, u16 * buffer){

    if(!primary_drive_present() || !master_cont_exists())
        return;

    //drive indicator and some magic bits to port 0x1F6
    outb(0x1F6, 0x40 | (drive << 4));//0x40 for master and 0x50 for slave

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

    while (!(inb(0x1F7) & 0x08)) {//wait for DRQ bit
        if((inb(0x1F7) & 0))//if error bit is set return
            return;
    }

    for (u16 idx = 0; idx < 256; idx++) {

        u16 tmpword = buffer[idx];

        //tmpword = buffer[8 + idx * 2] | (buffer[8 + idx * 2 + 1] << 8);

        outw(0x1F0, tmpword);

    }
    outb(0x1F7, 0xE7);//cache flush
}



