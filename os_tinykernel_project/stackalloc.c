//The C Programming Language Brian W. Kernighan, Dennis M. Ritchie

#include "stackalloc.h"

#define ALLOCSIZE 300000 /* size of available space */
static char *allocbuf = (char *) 0x1e000;//allocbuf[ALLOCSIZE]; /* storage for alloc */
static char *allocp = (char *) 0x1e000;//allocbuf; /* next free position*/

char *alloc(int n) /* return pointer to n characters */
{
    if (allocbuf + ALLOCSIZE - allocp >= n) { /* it fits */
        allocp += n;
        return allocp - n; /* old p */
    } else /* not enough room */
    return 0;
}

void afree(char *p) /* free storage pointed to by p */
{
    if (p >= allocbuf && p < allocbuf + ALLOCSIZE)
        allocp = p;
}
