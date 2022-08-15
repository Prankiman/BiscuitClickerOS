C_SOURCES = $(wildcard *.c)
HEADERS = $(wildcard *.h)

OBJ = ${C_SOURCES:.c=.o isrs.o}
#OBJ = ${C_SOURCES:.c=.o}

# Change this if your cross-compiler is somewhere else
#CC = /usr/local/i386elfgcc/bin/i386-elf-gcc
#GDB = /usr/local/i386elfgcc/bin/i386-elf-gdb
# -g: Use debugging symbols in gcc
#CFLAGS = -g

os-image: boot_kernel.bin kernel.bin
	cat $^ > os-img

kernel.bin: enter_kernel.o ${OBJ}
	i386-elf-ld -o $@ -Ttext 0x1000 $^ --oformat binary

%.o : %.c ${HEADERS}
	i386-elf-gcc -ffreestanding -c $< -o $@

%.o : %.asm
	nasm $< -f elf -o $@

%.bin : %.asm
	nasm $< -o $@

clean:
	rm *.o *.bin os-img
