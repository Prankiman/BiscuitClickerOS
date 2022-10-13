#ifndef ATAPIO_H
#define ATAPIO_H

#include "io.h"

void read_48(u8 secl, u8 sech, u64 addr, u8 drive, u16 * buffer);
void write_48(u8 secl, u8 sech, u64 addr, u8 drive, u16 * buffer);
void write_28(u8 sectors, u32 addr, u8 drive, u16 * buffer);
void read_28(u8 sectors, u32 addr, u8 drive, u16 * buffer);

u8 master_cont_exists();

#endif
