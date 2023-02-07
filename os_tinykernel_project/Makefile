C_SOURCES = $(wildcard *.c)
HEADERS = $(wildcard *.h)

OBJ = ${C_SOURCES:.c=.o}

KERN=kernel.bin
BOOT=boot_kernel.bin

all: kernel.bin boot_kernel.bin

kernel.bin: enter_kernel.o ${OBJ} isrs.o irqs.o v8086.o int32.o#ata.o
	ld -m elf_i386 -o $@ -T "link.ld" $^

	ld -m elf_i386 -o kernel.elf -T "link.ld" $^ --oformat elf32-i386 #used for gdb debugging


%.o: %.c ${HEADERS}
	gcc -march=i386 -elf_i386 -m32 -std=c11 -O2 -g -Wall -Wextra -Wpedantic -Wstrict-aliasing -Wno-pointer-arith -Wno-unused-parameter -nostdlib -nostdinc -ffreestanding -fno-pie -fno-stack-protector -fno-builtin-function -fno-builtin -c $< -o $@

%.o: %.asm
	nasm $< -f elf32 -o $@

%.bin: %.asm
	nasm $< -o $@

clean:
	rm *.o *.bin boot.iso

iso: all
	#cat $(BOOT) $(KERN) > boot.iso
	dd if=/dev/zero of=boot.iso bs=512 count=4880
	dd if=./$(BOOT) of=boot.iso conv=notrunc bs=512 seek=0 count=1
	dd if=./$(KERN) of=boot.iso conv=notrunc bs=512 seek=1 count=2048
usb: all
	#cat $(BOOT) $(KERN) > boot.iso
	dd if=/dev/zero of=/dev/sdb bs=512 count=2880
	dd if=./$(BOOT) of=/dev/sdb conv=notrunc bs=512 seek=0 count=1
	dd if=./$(KERN) of=/dev/sdb conv=notrunc bs=512 seek=1 count=2048

