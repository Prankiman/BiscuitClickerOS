#ifndef INT32_TESTH
#define INT32_TESTH

#include "types.h"

// define our structure
typedef struct __attribute__ ((packed)) {
	unsigned short di, si, bp, sp, bx, dx, cx, ax;
	unsigned short gs, fs, es, ds, eflags;
} regs16_t;

// tell compiler our int32 function is external
extern void int32(unsigned char intnum, regs16_t *regs);

// int32 test
void int32_test();

void int32write(u16 block_count, u16 write_adress, u32 lba_spot);

void int32read(u16 block_count, u16 read_adress, u32 lba_spot);

#endif
