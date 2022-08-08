kernel.bin: kernel_entry.o kernel.o
	ld -o kernel.bin -Ttext 0x1000 $^ --oformat binary

kernel.o : kernel.c
	gcc -ffreestanding -c $< -o $@

kernel_entry.o : kernel_entry.asm
	nasm $< -f elf -o $@

boot_sect.bin : boot_sect.asm
	nasm $ < -f bin -o $@

kernel.dis : kernel.bin
	ndisasm -b 32 $< > $@
