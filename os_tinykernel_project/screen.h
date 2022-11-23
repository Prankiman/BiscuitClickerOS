#ifndef SCREEN_H
#define SCREEN_H

#define VGA_CTRL_REGISTER 0x3d4
#define VGA_DATA_REGISTER 0x3d5
#define VGA_OFFSET_LOW 0x0f
#define VGA_OFFSET_HIGH 0x0e

#define vid_mem 0xa0000

#include "types.h"
#include "utility.h"

void disp_char(char c, u8 xx, u8 yy, u8 cc);
void disp_char_absolute(char c, u16 xx, u16 yy, u8 cc);
void disp_string_absolute(char *ch, u16 x, u16 y, u8 cc);
void disp_string(char *ch, u8 x, u8 y, u8 cc);
void disp_int(u32 n, u8 x, u8 y, u8 cc);

void clear_screen(u8 color);
void draw_screen();


void disp_biscuit(u8 xx, u8 yy, u8 background, u8 forground);
void disp_biscuit_large(u8 xx, u8 yy, u8 background, u8 forground);



#endif
