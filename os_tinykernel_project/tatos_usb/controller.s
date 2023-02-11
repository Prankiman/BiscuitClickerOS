;tatOS/boot/controller.s

;Dec09 Code will check for and save 2 uhci companion controllers to the ehci

;functions to init the usb UHCI and EHCI controller
;Get the base address needed for usb transactions. 
;Also resets the usb controller and sets up the frame list and 
;queue heads for usbmass/bulk and usbmouse/interrupt transactions
;the bus:dev:fun:00 of the UHCI controller is saved at 0x560
;the bus:dev:fun:00 of the EHCI controller is saved at 0x568 
;the bios got these for us in boot2.s

;Nov 2009 EHCI
;we note here a few differances between EHCI and UHCI
;UHCI has a single frame list for all transaction types 
;EHCI has two differant lists:
;	* asynchronous circular link list for control/bulk transactions
;	* frame list for interrupt transactions
;Queue Heads
;	* UHCI are a simple pair of dwords 
;	* EHCI are a 68 byte structure
;	* EHCI queue heads contain device/endpoint specific data
;Transfer descriptors for both uhci and ehci are 32 bytes 
;but the bitfields are organized differantly
;ehci is memory mapped which is cleaner than port i/o 





;*******************************
;          DATA
;*******************************

usbUstr0 db 'UHCI USB Controller Init',0
usbUstr1 db 'UHCI PCI DID:VID',0
usbUstr2 db 'UHCI PCI ClassCode:revID',0
usbUstr3 db 'UHCI PCI reserv:latency:header:reserv',0
usbUstr4 db 'UHCI PCI USB i/o space base address, USBBA',0
usbUstr5 db 'UHCI PCI Index Register Base Address',0
usbUstr6 db 'UHCI PCI Command Register',0
usbUstr7 db 'UHCI PCI Status Register',0


usbinitstr0 db 'EHCI USB Controller Init',0
usbinitstr2 db 'EHCI Init',0
usbinitstr3 db 'EHCI DID:VID',0
usbinitstr4 db 'EHCI ClassCode:revID',0
usbinitstr5 db 'EHCI MemoryBaseAddress BAR',0
usbinitstr6 db 'EHCI bist:headertype:latency:cachelinesize',0
usbinitstr7 db 'EHCI Capabilities Registers Length',0
usbinitstr8 db 'EHCI Structural Parameters',0
usbinitstr9 db 'EHCI pci config Status:Command',0
usbinitstr10 db 'EHCI N_CC Number of companion controllers',0
usbinitstr11 db 'EHCI N_PCC Number of ports per companion controller',0
usbinitstr11a db 'EHCI Port Routing Rules',0
usbinitstr11b db 'EHCI PPC Port Power Control',0
usbinitstr12 db 'EHCI N_PORTS Number of hi speed 2.0 ports',0
usbinitstr13 db 'EHCI Legacy Extended Capability (bios-os control)',0
usbinitstr14 db 'EHCI Legacy Control/Status (SystemManagementInterrupts)',0
usbinitstr15 db 'EHCI HCCPARAMS Capability Parameters',0
usbinitstr16 db 'EHCI USB2 Command Register',0
usbinitstr17 db 'EHCI USB2 Status Register',0
usbinitstr18 db 'EHCI USBINTR USB2 Interrupt Enable Register',0
usbinitstr19 db 'EHCI 64 bit addressing reqd',0
usbinitstr20 db 'EHCI PORTSC(n)',0
usbinitstr24 db 'EHCI CONFIGFLAG 1=all ports route to ehci',0 
usbinitstr25 db 'EHCI PPC Port Power Control',0
usbinitstr26 db 'EHCI HCHalted bit of USBSTS is not 1',0


usbcompstr1 db 'CompanionController pciconfig FUN#',0
usbcompstr2 db 'CompanionController DID:VID',0
usbcompstr3 db 'CompanionController ClassCode:revID',0
usbcompstr4 db 'checking for CompanionController BUS:DEV:FUN',0
usbcompstr5 db 'Warning.....N_CC==0, No Companion Controllers',0


usbtestflag db 'usb test flag *******************************',0


FUN       dd 0
BUSDEV    dd 0
BUSDEVFUN dd 0



;**************************************************************
;initUHCI
;prepare the uhci controller for usb transactions
;this function is used to init the "primary" uhci
;and may also be used to init "companion" uhci controllers

;input:
;push pci_config_address             [ebp+8]
;return:none

;the pci_config_address is the bus:dev:fun number of the 
;uhci controller with bit31 set to enable and bits[7:0] clear
;see tlib/pci.s for details
;the pci_config_address of the primary uhci is stored at 0x560
;the primary uhci is the one found by the bios in boot2.s
;**************************************************************


initUHCI:

	push ebp
	mov ebp,esp
	pushad


	;init UHCI
	;STDCALL usbUstr0,dumpstr


	mov eax,[ebp+8]
	call dumpBusDevFun



	;PCI Config: controller DID:VID  (byte offset 0)
	;returns eax=0x71128086 for intel uhci
	;VID is in loword and DID is in hiword
	mov eax,[ebp+8]
	mov ebx,0  ;register/offset 
	call pciReadDword
	;STDCALL usbUstr1,0,[DUMPEAX]




	;PCI Config: command register  (byte offset 4-5)
	mov eax,[ebp+8]
	mov ebx,4  ;register/offset 
	call pciReadDword
	;returns status reg in hiword and command reg in loword

	;set bus master enable and i/0 space enable bits
	or eax,101b  

	;write new value to the pci Config Command Register
	mov ecx,eax       ;ecx=value to be written
	mov eax,[ebp+8]   ;pci_config_address
	mov ebx,4         ;register/offset 
	call pciWriteDword

	;as a test see if it worked
	mov eax,[ebp+8]  
	mov ebx,4           ;register/offset 
	call pciReadDword
	mov ebx,eax         ;copy
	and eax,0xffff
	;STDCALL usbUstr6,0,[DUMPEAX]


	;PCI Config: status register (byte offset 6-7)
	mov eax,ebx
	shr eax,16
	;STDCALL usbUstr7,0,[DUMPEAX]




	;PCI Config: RevisionID and CLASSC Class Code Register (byte offset 8)
	mov eax,[ebp+8]
	mov ebx,0x8  ;address offset 
	call pciReadDword
	;returns class in hibyte then subclass then interface then revisionID
	;we expect 0c0300 for SerielBusController/usb/uhci
	;STDCALL usbUstr2,0,[DUMPEAX]



	;PCI Config: Master Latency Timer Register and Header Type (byte offset 0x0c)
	;the lowbyte is reserved
	;the next byte is latency timer
	;the next byte is pci header type
	;the hibyte is reserved
	mov eax,[ebp+8]
	mov ebx,0xc  ;address offset
	call pciReadDword
	;STDCALL usbUstr3,0,[DUMPEAX]
	


	;PCI Config: USBBA usb i/o space base address (byte offset 0x20)
	;the USBBA is a dword at Address Offset 20-23h
	;then we extract from this the BASEADD
	;this is the important one needed for usb transactions
	;on my CBS homebuilt USBBA=0x7121
	;the BASEADD is then 0x7120  (USBBA with bit0 cleared)
	mov eax,[ebp+8]
	mov ebx,0x20  ;20=address offset for USBBA
	call pciReadDword
	mov [0x52c],eax  ;save USBBA
	;STDCALL usbUstr4,0,[DUMPEAX]


	;save the "Index Register Base Address" for usb transactions
	;this is bits15-5 of USBBA with bit0 cleared
	;I guess the bios sets this value but we could change it
	and eax,0xfffffffe
	mov [BASEADD],ax
	;STDCALL usbUstr5,0,[DUMPEAX]




	;done with PCI Config registers
	;now we deal with the controller i/0 space registers



;********************************************************
;resetuhcicontroller
;the controller runs all the time
;like a wild horse
;cycling thru the frame list
;a transaction occurs 
;when you connect the first td in a linked list of td's
;to a qh which is pointed to by an entry in the frame list
;at first we make all entries in the frame list
;point to the same qh
;later you can get fancy by mixing control, bulk, iso
;a transaction ends when the tds making up the transaction
;are marked "inactive" by the controller
;or marked "stall" or the 5sec timeout expires
;********************************************************



	;first we HCRESET the controller
	;this stops the controller
	;also affects bits 8,3:0 of PORTSC
	mov dx,[BASEADD]
	in ax,dx    ;read it in
	or ax,10b   ;enable bit1 for HCRESET
	out dx,ax   ;send it back


	;pause for 1 sec
	mov eax,1000

	call sleep
	;call [0x10060]  ;sleep


	;Sep 2009-init our Queue Heads QH
	;QH1 = 0x1005000 reserved for interrupt transfers (usb mouse)
	;it holds the address of the next QH (horizontal move)
	;QH2 = 0x1005100 reserved for control & bulk transfers 
	mov dword [0x1005000],0x1005102  ;QH1 1st dword holds address of QH2 w/bit1 set for QH
	mov dword [0x1005000+4],1        ;QH1 2nd dword is terminate - no more QH's in list
	mov dword [0x1005100],1          ;QH2 1st dword terminate - no horizontal TD's 
	mov dword [0x1005100+4],1        ;QH2 2nd dword terminate - no TD chain to execute

	
	;fill each entry in the frame list 
	;with the address of our first QH
	;our FRAMELIST starts at 0x1000000
	;there are 1024 dword entries in the list
	cld
	mov ecx,1024
	mov eax,0x1005000   ;address of our first QH goes in the frame list
	or eax,10b          ;item points to qh, valid ptr
	mov edi,0x1000000   ;start address of framelist
	rep stosd


	;now assign FRAMELIST to FLBASEADD 
	;this tells the controller where the list starts in memory
	mov dx,[BASEADD]
	add dx,0x08        ;i/o address=base+8
	mov eax,0x1000000  ;start address of framelist
	out dx,eax     


	;zero out FRNUM
	mov dx,[BASEADD]
	add dx,0x06  ;i/o address=base+6
	in ax,dx
	and ax,1111100000000000b
	out dx,ax     


	;set max packet size=64 bytes for FULL speed
	mov dx,[BASEADD]
	in ax,dx
	or ax,10000000b  ;bit7=1 for 64 byte packet max
	out dx,ax


	;restart the controller
	mov dx,[BASEADD]
	in ax,dx
	or ax,1  ;bit0=1 for run
	out dx,ax

	;done with setting up the usb UHCI controller



	;read the command register
	call uhci_command


	;read the status register
	call uhci_status


	;read PORTSC-0
	mov eax,0
	call uhci_portread

	;read PORTSC-1
	mov eax,1
	call uhci_portread
	


.done:
	popad
	pop ebp
	retn 4
	;end UHCI init code










;**************************************************************
;initEHCI
;prepare the ehci controller for usb transactions
;input:pci_config_address stored at 0x568
;return:none
;**************************************************************


initEHCI:


	;init EHCI
	;STDCALL usbinitstr0,dumpstr


	mov eax,[0x568]
	call dumpBusDevFun


	;PCI Config: controller VID and DID
	mov eax,[0x568]  ;we store the EHCI bus:dev:fun dword @ 0x568
	mov ebx,0  ;register/offset 
	call pciReadDword
	;dump the vid:did
	;STDCALL usbinitstr3,0,[DUMPEAX]

	;returns eax=0x31041106 for our Via VT6212 addon card EHCI controller 
	;VID=0x1106 and DID=0x3104



	;PCI Config: Command Register
	;bit[2]=bus master enable/disable
	;bit[1]=memory space enable/disable
	;bit[0]=i/0 space enable/disable
	mov eax,[0x568]  
	mov ebx,4  ;register/offset 
	call pciReadDword
	;we get the Status in the hiword and the Command in the Loword
	;STDCALL usbinitstr9,0,[DUMPEAX]

	;set bus master enable and memory space enable bits
	or eax,110b  

	;write new value to the pci Config Command Register
	mov ecx,eax
	mov eax,[0x568]  
	mov ebx,4  ;register/offset 
	call pciWriteDword

	;as a test see if it worked
	;if you do not set the memory space enable bit
	;then any attempt to read the Capability registers below will result in ffffffff
	mov eax,[0x568]  
	mov ebx,4  ;register/offset 
	call pciReadDword
	;STDCALL usbinitstr9,0,[DUMPEAX]




	;PCI Config: CLASSC Class Code Register
	mov eax,[0x568]
	mov ebx,0x8  ;address offset 
	call pciReadDword
	;returns class in hibyte then subclass then interface then revisionID
	;for Via VT6212 ehci we get 0c032065 
	;STDCALL usbinitstr4,0,[DUMPEAX]




	;PCI Config: PCI header type
	;there are a couple differant types but 00 is most std
	mov eax,[0x568]
	mov ebx,0x0c  ;offset
	call pciReadDword
	;STDCALL usbinitstr6,0,[DUMPEAX]



	;PCI Config: Memory Base Address (BAR) 
	;unlike the uhci controller which use port i/o
	;the ehci controller is memory mapped like video
	mov eax,[0x568]
	mov ebx,0x10  ;10=address offset for MemoryBaseAddress
	call pciReadDword
	mov [0x5d0],eax  ;save the EHCIBAR
	;STDCALL usbinitstr5,0,[DUMPEAX]
	;Via VT6212 returns 0xf4008000 (this is page aligned)
	;the bios should give us a huge virtual memory address
	;thats outside the range of real memory



	;PCI Config: Legacy Support EHCI Extended Capability Register
	;this tells if bios or os gets control of ehci
	;bit24 must be set and bit16 must be clear for os to have control
	mov eax,[0x568]
	mov ebx,0x68 
	call pciReadDword
	;STDCALL usbinitstr13,0,[DUMPEAX]

	;set bit24 to tell bios that the OS wants control of ehci
	or eax,0x1000000

	;write is back
	mov ecx,eax
	mov eax,[0x568]  
	mov ebx,0x68  ;register/offset 
	call pciWriteDword

	;pause 
	mov eax,50
	call sleep;[0x10060]  ;sleep

	;see what we got
	mov eax,[0x568]
	mov ebx,0x68 
	call pciReadDword
	;STDCALL usbinitstr13,0,[DUMPEAX]



	;PCI Config: Legacy Support Control/Status Register
	;this register controls all the SMI's (System Management Interrupts)
	mov eax,[0x568]
	mov ebx,0x6c 
	call pciReadDword
	;STDCALL usbinitstr14,0,[DUMPEAX]



	;done with ehci PCI Config registers
	;now we deal with the ehci memory mapped registers


	;EHCI Capability Registers
	;***************************
	;00 = capabilities register length
	;04-07 = sturctural parameters
	;08-0b = capability parameters


	;Capabilities Registers Length (offset 00)
	mov esi,[0x5d0]
	mov al,[esi]
	and eax,0xff
	;STDCALL usbinitstr7,0,[DUMPEAX]


	;compute and save the start of the operational registers
	;the operational registers begin after the capability registers
	;operational registers are read/write dword access only
	add esi,eax
	mov [0x5d4],esi





	;Get the Structural Parameters (offset 04)
	;some controllers may not give good values here
	;my Via Vt6212 gives N_CC=2, N_PCC=2, N_PORTS=4  great!
	;E-machines    gives N_CC=1, N_PCC=8, N_PORTS=0 
	;the last 2 are invalid as there are only 5 ports on the computer
	;and the 4 on back are for ehci and the 1 on front is for ohci
	mov esi,[0x5d0]
	mov eax,[esi+4]
	mov ebx,eax   ;save a copy 
	;STDCALL usbinitstr8,0,[DUMPEAX]

	;bits[15:12]=Number of companion controllers  N_CC
	mov eax,ebx
	shr eax,12
	and eax,111b
	;STDCALL usbinitstr10,0,[DUMPEAX]


	;display an error message if N_CC==0
	;if N_CC == 0 then there are in theory no companion controllers
	;and you may not plug a low or full speed device into a root port
	;and since tatOS depends on a uhci companion controller for the mouse...
	cmp eax,0
	jnz .haveCompanions
	;STDCALL usbcompstr5,dumpstr
.haveCompanions:


	;bits[11:8] =Number of ports per companion controller N_PCC
	mov eax,ebx
	shr eax,8
	and eax,1111b
	;STDCALL usbinitstr11,0,[DUMPEAX]

	;bits[7]  = Port Routing Rules
	mov eax,ebx
	shr eax,7
	and eax,1
	;STDCALL usbinitstr11a,0,[DUMPEAX]

	;bits[4] = Port Power Control 
	mov eax,ebx
	shr eax,4
	and eax,1
	;STDCALL usbinitstr11b,0,[DUMPEAX]

	;bits[3:0] = Number of hispeed 2.0 ports  N_Ports
	mov eax,ebx
	and eax,111b
	;STDCALL usbinitstr12,0,[DUMPEAX]




	;HCCPARAMS
	;Get the Capability Parameters (offset 08)
	mov esi,[0x5d0]
	mov eax,[esi+8]
	;STDCALL usbinitstr15,0,[DUMPEAX]

	
	;dump bit0 which indicates if this controller uses 64 bit addressing
	and eax,1
	;STDCALL usbinitstr19,0,[DUMPEAX]


	
	;EHCI Operational Registers
	;***************************
	;we saved the start of oper regs at 0x5d4
	;00 = USB2 command 
	;04 = USB2 status
	;08 = USB2 interrupt enable
	;0c = USB2 frame index
	;10 = 4gb segment selector
	;14 = frame list base address
	;18 = next asynchronous list address
	;1c-3f reserved
	;40 = configure flag register
	;44 = PORTSC(0) status/control
	;48 = PORTSC(1) status/control
	;4c = PORTSC(2) status/control
	;50 = PORTSC(3) status/control
	


	;first make sure the ehci controller is halted
	;a running controller must not be reset
	;I have found some controllers are running at this point and some are not
	mov esi,[0x5d4]
	mov eax,[esi+0]
	and eax,0xfffffffe ;clear bit0
	mov [esi+0],eax    ;write it back
	

	;pause-hc must halt within 16 microframes, I hope 500ms is enough
	mov eax,500
	call sleep






	;reset EHCI thru the USB2 command register
	;the reset bit is set to zero by the controller when reset is complete
	;the controller must be halted (HCHalted bit of USBSTS = 1)before resetting
	;the reset causes port ownership to revert to companion controllers
	mov esi,[0x5d4]
	mov eax,[esi+0]   ;read current value
	or eax,10b        ;HCRESET
	mov [esi+0],eax   ;write it back



.EHCI_in_reset:
	;loop until reset bit is set to zero by the controller
	mov eax,[esi+0]   ;read current value
	bt eax,1
	jc .EHCI_in_reset


	
	;CTRLDSSEGMENT
	;Control Data Structure Segment Register (64 addressing)
	;if bit0 of HCCPARAMS=0 then 32bit addressing is default and this write will fail
	;otherwise controllers likes Intels ICHn which uses 64 bit addressing
	;use the value of this register as the hi 32bits of a 64bit address
	mov esi,[0x5d4]
	mov dword [esi+10h],0



	;USBINTR-Usb Interrupt Enable Register
	mov esi,[0x5d4]
	mov dword [esi+08h],0  ;disable all interrupts




	;for now we ignore the Periodic Frame list base address register
	;the periodic list is for interrupt transactions only (usb mouse)
	;we will not enable this list for now


	;ASYNCLISTADDR
	;the asynchronous list is a circular link list of queue heads (QH) 
	;for control and bulk xfers
	;the list will initially contain only 1 QH that points to itself
	;this QH is setup for control xfer (enumerating the flash drive)
	;after SetAddress we modify the QH address BULKADDRESS
	;after SetConfiguration we modify the QH endpoint for BULKEPIN or BULKEPOUT
	;our async QH starts at  0x1005300
	;so we dont conflict with uhci


	;QH 1st dword-Horiz Link Pointer
	mov dword [0x1005300],0x1005302  ;points to itself


	;QH 2nd dword-Endpoint Characteristics
	;5=NAK reload counter
	;200=max packet, typically us 0x40 for control xfer, 0x200 for mass xfer
	;e0=head of reclaim list, dt from TD, hi speed endpoint
	;00=epnum and deviceadd are 0 for control endpoint
	mov dword [0x1005304],0x5200e000 


	;QH 3rd dword - Endpoint Capabilities
	;40=1 transaction per microframe (Mult)
	;PortNum=HubAddr=C-Mask=S-mask=0
	mov dword [0x1005308],0x40000000

	
	;QH overlay 4th, 5th, 6th, 7th, 8th, 9th, 10th, 11th, 12th dwords
	;the ehci overwrites this area but you must init Next qTD to 1 or a valid pointer
	mov dword [0x100530c],0  ;4th dword Current qTD Pointer 
	mov dword [0x1005310],1  ;5th dword Next qTD Pointer    (1=terminate)
	mov dword [0x1005314],0  
	mov dword [0x1005318],0
	mov dword [0x100531c],0
	mov dword [0x1005320],0
	mov dword [0x1005324],0
	mov dword [0x1005328],0
	mov dword [0x100532c],0

	;dwords 13-17 of QH
	;if your controller uses 64bit addressing like the Intel ICHn
	;then you need to specify the upper 32bits here
	mov dword [0x1005330],0  ;Extended Buffer Pointer Page 0
	mov dword [0x1005334],0
	mov dword [0x1005338],0
	mov dword [0x100533c],0
	mov dword [0x1005340],0  ;Extended Buffer Pointer Page 4



	;write address of control QH to ASYNCLISTADDR
	mov esi,[0x5d4]
	mov dword [esi+18h],0x1005300



	;CONFIGFLAG
	;00=port routing to classic controller
	;01=port routing to EHCI controller
	mov esi,[0x5d4]
	mov eax,[esi+40h]
	or eax,1          ;set bit0 for EHCI port routing
	mov [esi+40h],eax


	mov eax,250
	call sleep


	;dump the port routing
	mov eax,[esi+40h]
	;STDCALL usbinitstr24,0,[DUMPEAX]



	;PORTSC
	;dump the value of each PORTSC register
	;at this point we have no device configured and no ports reset
	;0x10000 = nothing plugged into the ehci port
	;0x14000 = low speed device connected
	;0x18000 = hi speed device connected
	;note here I call the ports 0,1,2,3 where ehci uses 1,2,3,4
	;we dump PORTSC for 4 ports only since each ehci can commonly control 4 ports
	mov ecx,0 
	mov esi,[0x5d4]
.portCheck:
	mov eax,[esi+44h+ecx*4]    ;get PORTSC(ecx) register value
	;STDCALL usbinitstr20,0,dumpeax
	inc ecx
	cmp ecx,4   ;max qty ports to dump
	jb .portCheck




	;enable the async list
	;to avoid the controller needlessly flooding the bus with
	;memory accesses, we should enable/disable the async schedule on demand
	;tatOS does not do this yet but maybe someday.
	mov esi,[0x5d4]
	mov eax,[esi+0]
	or eax,100000b      ;set bit5 to enable async schedule for bulk/control
	mov [esi+0],eax



	;start the controller
	mov esi,[0x5d4]
	mov eax,[esi+0]
	or eax,1       ;set bit0 to start
	mov [esi+0],eax


	mov eax,500
	call sleep;[0x10060]  ;sleep



	;read the USB2 status register
	mov esi,[0x5d4]
	mov eax,[esi+4]
	;STDCALL usbinitstr17,0,[DUMPEAX]


	;read the command register
	mov esi,[0x5d4]
	mov eax,[esi]
	;STDCALL usbinitstr16,0,[DUMPEAX]
	;via reports 0x80021 = run, async enable



	;end of setting up the EHCI controller




	;test for Companion Controllers
	;***********************************
	;if there are Companion Controllers they would have
	;the same bus:dev but have a smaller fun number
	;Via has ehci fun=2 and companion controllers fun=1,0
	;Intel ICHn series has ehci dev:fun= d29:f7 and companions f0,f1,f2,f3
	;we start at fun=ehci and dump all companions down to 0
	;we save the bus:dev:fun of only one of the uhci controllers we find
	
	mov eax,[0x568]      ;start with eax=bus:dev:fun of ehci
	mov [BUSDEV],eax
	mov dword [0x5e0],0  ;qty uhci companion controllers found
	mov edi,0x5d8        ;address to save BUS:DEV:FUN of uhci companion

	;extract out the FUN
	shr eax,8
	and eax,111b
	mov [FUN],eax

	;get BUSDEV with zero FUN
	and dword [BUSDEV],0xfffff8ff

	;init bus:dev:Fun of 1st companion to invalid
	mov dword [0x5d8],0xffffffff 
	

.CompanionController:

	dec dword [FUN]
	js near .doneCheckingCompanionControllers    ;loop exit-negative FUN not allowed

	;dump the FUN
	mov eax,[FUN]
	;STDCALL usbcompstr1,0,dumpeax

	;build new bus:dev:Fun 
	mov eax,[BUSDEV]
	mov ebx,[FUN]
	shl ebx,8
	or eax,ebx
	mov [BUSDEVFUN],eax
	;STDCALL usbcompstr4,0,dumpeax

	;check for valid VID:DID of companion controller
	mov ebx,0  ;register/offset 
	call pciReadDword
	cmp eax,0xffffffff  ;if we get this the device does not exist
	jz .CompanionController

	;read the Revisions ID and CLASSC Class Code Register
	;0x0c030062 is for my Via VT6212 ehci addon card
	mov eax,[BUSDEVFUN] 
	mov ebx,0x8  ;address offset 
	call pciReadDword
	;STDCALL usbcompstr3,0,dumpeax

	;clear out the revID and check for 0c0300=uhci
	mov ebx,eax               ;ebx=0c0300xx if uhci companion
	shr ebx,8
	cmp ebx,0x0c0300          ;0c0300=uhci, 0c0310=ohci, 0c0320=ehci
	jnz .CompanionController  ;sorry-unsupported companion controller

	;we have a uhci companion controller
	;save the pci_config_address of uhci companion controller
	mov eax,[BUSDEVFUN]
	mov [edi],eax

	;increment address to save next companion controller BUS:DEV:FUN
	add edi,4
	;increment qty uhci companion controllers found
	add dword [0x5e0],1

	;we can only save 2 companion controller BUS:DEV:FUN
	cmp dword [0x5e0],2
	jb .CompanionController


.doneCheckingCompanionControllers:




.done:
	ret




