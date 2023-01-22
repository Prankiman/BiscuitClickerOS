//The C Programming Language Brian W. Kernighan, Dennis M. Ritchie

#define ALLOCSIZE 0x100000 /* size of available space */
//static char allocbuf[ALLOCSIZE]; /* storage for alloc */
static char *allocbuf = (char *) 0xf000; //temporary *fix*
//static char *allocp = allocbuf; /* next free position*/
static char *allocp = (char *) 0xf000; //temporary

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
