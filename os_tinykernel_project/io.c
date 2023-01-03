#include "types.h"
#include "io.h"

 //in -> read from port, out -> write to port,
void outb(u16 port, u8 val)
{
    __asm__ __volatile__ ("outb %0, %1" : : "a"(val), "Nd"(port) );
    /* There's an outb %al, $imm8  encoding, for compile-time constant port numbers that fit in 8b.  (N constraint).
     * Wider immediate constants would be truncated at assemble-time (e.g. "i" constraint).
     * The  outb  %al, %dx  encoding is the only option for all other cases.
     * %1 expands to %dx because  port  is a uint16_t.  %w1 could be used if we had the port number a wider C type */
}


u8 inb(u16 port)
{
    u8 ret;

    __asm__ __volatile__ ( "inb %1, %0"
                   : "=a"(ret)
                   : "Nd"(port) );
    return ret;
}

void outw(u16 port, u16 val)
{
    __asm__ __volatile__ ("outw %0, %1" : : "a"(val), "Nd"(port) );
    /* There's an outb %al, $imm8  encoding, for compile-time constant port numbers that fit in 8b.  (N constraint).
     * Wider immediate constants would be truncated at assemble-time (e.g. "i" constraint).
     * The  outb  %al, %dx  encoding is the only option for all other cases.
     * %1 expands to %dx because  port  is a uint16_t.  %w1 could be used if we had the port number a wider C type */
}


u16 inw(u16 port)
{
    u16 ret;

    __asm__ __volatile__ ( "inw %1, %0"
                   : "=a"(ret)
                   : "Nd"(port) );
    return ret;
}

void outl(u16 port, u32 val)
{
    __asm__ __volatile__ ("outl %0, %1" : : "a"(val), "Nd"(port) );
    /* There's an outb %al, $imm8  encoding, for compile-time constant port numbers that fit in 8b.  (N constraint).
     * Wider immediate constants would be truncated at assemble-time (e.g. "i" constraint).
     * The  outb  %al, %dx  encoding is the only option for all other cases.
     * %1 expands to %dx because  port  is a uint16_t.  %w1 could be used if we had the port number a wider C type */
}


u32 inl(u16 port)
{
    u16 ret;

    __asm__ __volatile__ ( "inl %1, %k0"
                   : "=a"(ret)
                   : "Nd"(port) ); //k modifier to select 32-bit sub register
    return ret;
}

void io_wait(void)
{
    outb(0x80, 0);//basically a no-op
}
