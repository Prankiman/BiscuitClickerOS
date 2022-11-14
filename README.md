# tinyOS
a very basic / bare bones operating system / kernel

## running
run `make iso` to create the image file

if running on real hardware make sure usb emulation type is set to hard drive (note that the os stores data to the boot drive using ATAPIO which won't work if booting from usb and not a ATA complient device i.e hdds)

if running on qemu ~~make sure to set boot disk storage type as usb and enable usbmouse~~ (currently not implemented usb storage and mouse driver)
```
    qemu86  -drive if=none,id=usbstick,format=raw,file=./boot.iso   \
```
    ~~-usb                                                        \~~
    -~~device usb-ehci,id=ehci                                    \~~
    ~~-device usb-storage,bus=ehci.0,drive=usbstick               \~~
    ~~-device usb-mouse,pcap=mouse.pcap~~

## RECOURSES

## OSDEV.org:

### homepage:
https://wiki.osdev.org/Main_Page

### inline assembly:
https://wiki.osdev.org/Inline_assembly

### babysteps series:
https://wiki.osdev.org/Babystep1

### VGA:
https://wiki.osdev.org/VGA_Resources

### SANiK's mouse driver:
https://forum.osdev.org/viewtopic.php?t=10247

### ISA DMA:
https://wiki.osdev.org/ISA_DMA


## Tutorialspoint assembly programming series:
https://www.tutorialspoint.com/assembly_programming/



## To Do Huangs Operating System from 0 to 1 github page:
https://github.com/tuhdo/os01



## Intel's developer manuals:
https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html

## Napalms virtual 8086 code:
http://www.rohitab.com/discuss/topic/35103-switch-between-real-mode-and-protected-mode/

## os dever:

### creating the gdt table in assembly:
http://web.archive.org/web/20190424213806/http://www.osdever.net/tutorials/view/the-world-of-protected-mode

### creating the idt:
http://web.archive.org/web/20210515200857/http://www.osdever.net/bkerndev/Docs/idt.htm

http://web.archive.org/web/20211226232232/http://www.osdever.net/bkerndev/Docs/isrs.htm

### FREE VGA:
http://www.osdever.net/FreeVGA/home.htm



## Nick Blundell's How To Write an Operating System :
https://www.cs.bham.ac.uk/~exr/lectures/opsys/10_11/lectures/os-dev.pdf



## Cfenollosa's os-tutorial project:
https://github.com/cfenollosa/os-tutorial



##  James Molloy's kernel development tutorials

### idt and gdt
https://web.archive.org/web/20160327011227/http://www.jamesmolloy.co.uk/tutorial_html/4.-The%20GDT%20and%20IDT.html


## Netwide Assembler documentation:

https://www.nasm.us/docs.php



## GNU Assembler manual:

https://sourceware.org/binutils/docs/as/



## LWN net, Linux Device Drivers:
https://lwn.net/Kernel/LDD3/
