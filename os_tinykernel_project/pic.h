#ifndef PIC_H
#define PIC_H

#include "io.h"
#include "isr.h"

#define PIC1_CMD                    0x20
#define PIC1_DATA                   0x21
#define PIC2_CMD                    0xA0
#define PIC2_DATA                   0xA1
#define PIC_READ_IRR                0x0a    /* OCW3 irq ready next CMD read */
#define PIC_READ_ISR                0x0b    /* OCW3 irq service next CMD read */

#define ICW1_ICW4	0x01		/* ICW4 (not) needed */
#define ICW1_SINGLE	0x02		/* Single (cascade) mode */
#define ICW1_INTERVAL4	0x04		/* Call address interval 4 (8) */
#define ICW1_LEVEL	0x08		/* Level triggered (edge) mode */
#define ICW1_INIT	0x10		/* Initialization - required! */

#define ICW4_8086	0x01		/* 8086/88 (MCS-80/85) mode */
#define ICW4_AUTO	0x02		/* Auto (normal) EOI */
#define ICW4_BUF_SLAVE	0x08		/* Buffered mode/slave */
#define ICW4_BUF_MASTER	0x0C		/* Buffered mode/master */
#define ICW4_SFNM	0x10		/* Special fully nested (not) */
#define PIC_EOI		0x20		/* End-of-interrupt command code */
#define PIC1		0x20		/* IO base address for master PIC */
#define PIC2		0xA0		/* IO base address for slave PIC */
#define PIC1_COMMAND	PIC1
#define PIC2_COMMAND	PIC2

void PIC_sendEOI(unsigned char irq);
/*
arguments:
	offset1 - vector offset for master PIC
		vectors on the master become offset1..offset1+7
	offset2 - same for slave PIC: offset2..offset2+7
*/
void PIC_remap(int offset1, int offset2);

void IRQ_set_mask(unsigned char IRQline);

void IRQ_clear_mask(unsigned char IRQline);

/* Helper func */
u16 __pic_get_irq_reg(int ocw3);

/* Returns the combined value of the cascaded PICs irq request register */
u16 pic_get_irr(void);

/* Returns the combined value of the cascaded PICs in-service register */
u16 pic_get_isr(void);

void irq_install_handler(int irq, void (*handler)(registers_t *r));

void irq_uninstall_handler(int irq);

#endif
