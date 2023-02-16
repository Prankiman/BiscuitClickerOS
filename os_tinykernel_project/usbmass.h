#ifndef USBMASS_H
#define USBMASS_H

#include "types.h"

extern void read10();
extern void write10();
extern void initusbmass();

void read_usb(u16 lba, u16 block_count, u16 destination_address);
void write_usb(u16 lba, u16 block_count, u16 source_address);

#endif
