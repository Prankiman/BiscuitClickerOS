C_SOURCES = $(wildcard *.c)
HEADERS = $(wildcard *.h)

OBJ = ${C_SOURCES:.c=.o}

os-image: boot_kernel.bin kernel.bin
	cat $^ > os-img

kernel.bin: enter_kernel.o ${OBJ}
	ld -m elf_i386 -o $@ -Ttext 0x1000 $^ --oformat binary

%.o: %.c ${HEADERS}
	gcc -elf_i386 -m32 -nostdlib -nostdinc -Wall -ffreestanding -fno-pie -c $< -o $@
	#gcc -ffreestanding -c $< -o $@

%.o: %.asm
	nasm $< -f elf32 -o $@

%.bin: %.asm
	nasm $< -o $@

clean:
	rm *.o *.bin os-img
