#include "utility.h"

void memcpy(void *source, void *dest, s32 numbytes) {
    int i;
    u8 *tmpd = (u8 *)dest;
    u8 *tmps = (u8 *)source;
    for (i = 0; i < numbytes; i++) {
        *(tmpd + i) = *(tmps + i);
    }
}

void memset(void *dest, u8 val, u32 len) {
    u8 *temp = (u8 *)dest;
    for ( ; len != 0; len--) *temp++ = val;
}
