#include "int32_test.h"
#include "utility.h"

// int32 test
void int32_test()
{
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
