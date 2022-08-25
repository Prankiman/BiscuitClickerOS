#include "types.h"
/*
u8 * VidMem;
u8 * BackBuffer;
 
unsigned short ScrW, ScrH;
unsigned char Bpp, PixelStride;
int Pitch;
 
/*
 * Initializes video, creates a back buffer, changes video modes.
 * Remember that you need some kind of memory allocation!
 */
//void InitVideo(unsigned short ScreenWidth, unsigned short ScreenHeight, unsigned char BitsPerPixel)
//{
        /* Convert bits per pixel into bytes per pixel. Take care of 15-bit modes as well */
  //      PixelStride = (BitsPerPixel | 7) >> 3;
        /* The pitch is the amount of bytes between the start of each row. This isn't always bytes * width. */
        /* This should work for the basic 16 and 32 bpp modes (but not 24) */
    //    Pitch = 	ScreenWidth * PixelStride;
 
	/* Warning: 0xEEEEEEE servces as an example, you should fill in the address of your video memory here. */
	//VidMem = ((u8 *) 0xa0000);
 
	//ScrW = ScreenWidth;
	//ScrH = ScreenHeight;
	//Bpp = BitsPerPixel;
 
	/* Switch resolutions if needed... */
	/* Do some more stuff... */
//}
 
/*
 * Draws a pixel onto the backbuffer.
 */
/*void SetPixel(unsigned short X, unsigned short Y, unsigned Colour)
{	
        int offset = X * PixelStride + Y * Pitch;
		*VidMem = Colour;
}
*/
