#include "int32_test.h"
#include "utility.h"
#include "types.h"


typedef struct disc_packet{
	u8 packet_size;//packet size is 16 bytes
	u8 always_zero;
	u16 block_count;
	u16 data_transfer_buffer_adress;
	u16 data_transfer_buffer_offset;
	u32 lba_read_write_spot;
	u32 lba_spot_extra_bytes;//extra bytes for really large lba numbers

}__attribute__((packed)) packet;

// int32 test
void int32_test() {
	int y;
	regs16_t regs;

	// switch to 80x25x16 text mode
	regs.ax = 0x0003;
	int32(0x10, &regs);

	unsigned char * vidmem = (unsigned char *)0xb8000;

	char * temp = "any button to start";

	for(y = 0; y < 20; y++){
		vidmem[y*2+1] = 0x10;//black_on_blue
		vidmem[2*y] = *(temp++);
	}
	// wait for key (buggy on hardware but works most of the time)
	//regs.ax = 0x0000;
	//int32(0x16, &regs);

	// switch to 320x200x256 graphics mode
	regs.ax = 0x0013;
	int32(0x10, &regs);
	
	// full screen with blue color (1)
	memset((char *)0xA0000, 1, (320*200));

}

void int32read(u16 block_count, u16 read_adress, u32 lba_spot) {
	
	regs16_t regs;

	packet disc_packet = {0x10, 0, block_count, read_adress, 0, lba_spot, 0};

        regs.ax = 0x0042;//ah=42h, int 13h --> extended read
	
	int32(0x13, &regs);
}

void int32write(u16 block_count, u16 write_adress, u32 lba_spot) {
	
	regs16_t regs;

	packet disc_packet = {0x10, 0, block_count, write_adress, 0, lba_spot, 0};

        regs.ax = 0x0043;//ah=43h, int 13h --> extended write
	
	int32(0x13, &regs);
}
