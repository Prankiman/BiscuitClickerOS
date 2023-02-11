;tatOS/tlib/pci.s


;code to read/write pci configuration space registers
;originally written for usb uhci controller

;format of the pci configuration space address
;the pci config_address is a dword as follows
;see boot2.s where we get the bus:dev:fun value for uhci
;this already has the enable bit set
;bit31    = enable
;bit30-24 = reserved
;bit23-16 = bus
;bit15-11 = device
;bit10-8  = function
;bit 7-2  = register
;bit1-0   = 00

;each device on the pci bus must have a unique bus:dev:fun number
;the first step to init any device is to read the pci headers
;the headers are a structure in memory which describe the device
;there are 3 (or more) differant pci configuration space "headers"
;I am really only familiar with type=00 header which is quite common
;see the osdev wiki for info on pci

;00=Standard PCI Header
;01=PCI-to-PCI Bridge Header
;02=CardBus Bridge Header
;08=????

;examples for a type=00 header which is quite common:
;offset  Information
;00      DID    in hiword and VID in loword
;04      Status in hiword and Command in loword
;08      Class code in hibyte then Subclass then Interface then RevID
;0c      BIST in hibyte then HeaderType then LatTimer then CacheLineSize
;10      Base Address #0 BAR0
;14      Base Address #1 BAR1
;2c      SubsystemID in hiword and SubVID in loword
;after this what is returned depends on the mfg and device


;**************************************************************
;pciReadDword
;uses port I/O to read from pci configuration space
;input
;eax = pci_config_address with register=00
;ebx = offset/register 
;      you should only use ebx values on dword boundries
;      i.e. ebx=00,04,08,0c,10,14,18,1c,20,24,28,2c... (all hex)
;      this ensures bit0 and bit1 of the pci config space address are 00
;return
;eax=dword read from port
;**************************************************************

pciReadDword:
	push edx

	or eax,ebx
	mov dx,0xcf8  
	out dx,eax    ;send to command port 
	mov dx,0xcfc  
	in  eax,dx    ;read dword from data port 

	pop edx
	ret



;******************************************
;pciWriteDword
;input
;eax and ebx same as above
;ecx=dword value to be written
;******************************************
pciWriteDword:
	push edx
	push eax

	or eax,ebx
	mov dx,0xcf8  
	out dx,eax    ;send to command port 
	mov dx,0xcfc  
	mov eax,ecx
	out dx,eax    ;write dword to data port 

	pop eax
	pop edx
	ret



;******************************************************************
;dumpBusDevFun
;small routine to split apart the pic_config_address
;and display the bus:dev:fun individually
;we store UHCI at 0x560 and EHCI at 0x568

;input:
;eax = pci_config_address with register=00

;return:none

;examples:                  bus:dev:fun
;Intel onboard UHCI          00:07:02
;Via VT6212 EHCI addon card  00:0d:02
;Emachines w/nVidia EHCI     00:0b:01
;Intel EHCI on HP Pavillion  00:1a:07
;Intel UHCI on HP Pavillion  00:1a:00

pcistr1 db 'PCI Config Address BUS',0
pcistr2 db 'PCI Config Address DEV',0
pcistr3 db 'PCI Config Address FUN',0
;*****************************************************************

dumpBusDevFun:

	mov ebx,eax  ;save

	;dump the bus:dev:fun individually
	shr eax,16
	and eax,0xff
	;STDCALL pcistr1,0,[DUMPEAX]  ;bus
	mov eax,ebx
	shr eax,11
	and eax,11111b
	;STDCALL pcistr2,0,[DUMPEAX]  ;dev
	mov eax,ebx
	shr eax,8
	and eax,111b
	;STDCALL pcistr3,0,[DUMPEAX]  ;fun

	ret


