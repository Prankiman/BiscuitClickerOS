#include "utility.h"

void memcpy(u8 *source, u8 *dest, s32 numbytes) {
    int i;
    for (i = 0; i < numbytes; i++) {
        *(dest + i) = *(source + i);
    }
}

void memset(void *dest, u8 val, u32 len) {
    u8 *temp = (u8 *)dest;
    for ( ; len != 0; len--) *temp++ = val;
}
