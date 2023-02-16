;tatOS/usb/initusbmass.s

;this file is included in usb.s

;code to prepare the flash drive for read10/write10
;we bundle this all in one function "initusbmass"
;you can call this function from the shell (f12)

;the following actions are performed in summary:
;	* detect port
;	* reset port
;	* GetDeviceDescriptor
;	* GetConfigDescriptor
;	* SetAddress
;	* SetConfiguration ...


;we store the various usbmass descriptors
;(device,condiguration,interface,endpoint)
;starting at 0x5000
;see /doc/memorymap for details

;GetMaxLun
;we dont support this command
;we assume the device (pendrive) does not support multiple luns
;the usbmass spec states a device that does not 
;support multiple luns may stall this command
;all our SCSI CBW use bCBWLUN=0

;prior to calling this function the usb controller must be setup
;including populating the framelist and async list
;see /boot/usbinit.s

mpdstr1 db 'USB device is not 0x08 mass storage class',0
mpdstr2 db 'USB device subclass is not 0x06 for SCSI commands',0
mpdstr3 db 'USB device protocol is not 0x50 bulk-only transport',0
mpdstr4 db 'USB configured device EPIN=0',0
mpdstr5 db 'USB configured device EPOUT=0',0
mpdstr6 db 'USB device has more than 1 interface',0
mpdstr7 db 'Endpoint wMaxPacketSize',0
mpdstr8 db 'Sorry-unable to detect EHCI or UHCI usb controller',0
mpdstr9 db 'Sorry-unable to detect Flash Drive Port',0
mpdstr11 db 'Assigning UHCI function pointers',0
mpdstr12 db 'Assigning EHCI function pointers',0
mpdstr13 db 'Port Reset',0
mpdstr14 db 'Device Descriptor',0
mpdstr15 db 'Configuration Descriptor',0
mpdstr16 db 'Set Address',0
mpdstr17 db 'Set Configuration',0
mpdstr18 db 'Inquiry',0
mpdstr19 db 'TestUnitReady',0
mpdstr20 db 'RequestSense',0
mpdstr21 db 'ReadCapacity',0
mpdstr22 db 'Done initusbmass',0



;*******************************************************************

initusbmass:


	;since I have added an ehci pci card to an old computer
	;I have in affect two primary usb controllers to choose from
	;in this case our code will select ehci for the flash by default
	;if you wish to force the use of uhci uncomment this jmp
	;I use the term "primary" because these controllers are detected by 
	;bios during our startup. Companion controllers are not detected by bios
	;I think this is because companion controllers do not have bus master
	;and enable bits set in the pci config registers
	;jmp .useUHCI

	jmp .useEHCI



	;test for which USB controller to use
	;the primary UHCI and EHCI controllers 
	;were setup for our needs in /boot/usbinit.s


	;if we have an ehci controller 
	;the flash drive must be plugged into 1 of its 4 ports 
	;the bios saved the pci_config_address for us in /boot/usbinit.s
	;if not found, the pci_config_address was set to ffffffff
	cmp dword [0x568],0xffffffff
	jnz near .useEHCI

	;so we dont have EHCI, do we have UHCI ?
	cmp dword [0x560],0xffffffff
	jnz near .useUHCI


	;if we got here we have neither EHCI or UHCI - out of luck
	;the only other choice is OHCI which we dont support
	;STDCALL mpdstr8,putshang




	;**************************************
	;          EHCI Controller
	;*************************************
.useEHCI:
	;set up pointers to EHCI specific functions
	;STDCALL mpdstr12,dumpstr
	;STDCALL mpdstr12,putmessage
	mov dword [portreset],     ehci_portreset
	mov dword [portscan],      ehci_portscan
	mov dword [portdump],      ehci_portdump
	mov dword [status],        ehci_status
	mov dword [prepareTDchain],ehci_prepareTDchain
	mov dword [runTDchain],    ehci_runTDchain
	mov dword [maxPortNum],3  ;we support ehci with 4 ports: 0,1,2,3

	jmp .FlashPortEnumeration



	;**************************************
	;          UHCI Controller
	;*************************************

.useUHCI:
	;set up pointers to UHCI specific functions
	;STDCALL mpdstr11,dumpstr
	;STDCALL mpdstr11,putmessage
	mov dword [portreset],     uhci_portreset
	mov dword [portscan],      uhci_portscan
	mov dword [portdump],      uhci_portdump
	mov dword [status],        uhci_status
	mov dword [prepareTDchain],uhci_prepareTDchain
	mov dword [runTDchain],    uhci_runTDchain
	mov dword [maxPortNum],1   ;uhci only has 2 ports, 0,1 



.FlashPortEnumeration:

	;STDCALL mpdstr13,putmessage

	call [portdump]

	call [portscan]
	mov eax,edi
	;edi=portnum of flash else 0xffffffff

	cmp eax,0xffffffff
	jnz .resetport

	;Fatal-could not find the flash
	;STDCALL mpdstr9,putshang

.resetport:
	call [portreset]


	

	;*********************************
	;   proceed with usb transactions
	;**********************************


		
	;Device Descriptor
	;Some drivers request just 8 bytes then check bMaxPacketSize0=0x40 for endpoint 0
	;after getting the 18 bytes you might want to make sure that bNumConfigurations=1
	;sometimes this fails the first time
	;STDCALL mpdstr14,putmessage
	call FlashGetDeviceDescriptor



	;so we do it again
	call FlashGetDeviceDescriptor





.getConfigDescriptor:
	;first we request the 9 byte Configuration Descriptor
	;this will give us the BNUMINTERFACES and WTOTALLENGTH
	mov edx,9
	call FlashGetConfigDescriptor


	;make sure the device has only one interface
	;we dont know how to handle anything else
	cmp byte [BNUMINTERFACES],1
	jz .getremainingdescriptors
	;STDCALL mpdstr6,putshang
.getremainingdescriptors:


	;now we get the configuration, interface and
	;all endpoint descriptors all in one shot
	;STDCALL mpdstr15,putmessage
	xor edx,edx
	mov dx,[WTOTALLENGTH]
	call FlashGetConfigDescriptor


	;make sure usb device is mass storage class
	cmp byte [BINTERFACECLASS],0x08
	jz .checkSCSI
	;STDCALL mpdstr1,putshang


.checkSCSI:
	;make sure device responds to SCSI commands
	cmp byte [BINTERFACESUBCLASS],0x06
	jz .checkProtocol
	;STDCALL mpdstr2,putshang


.checkProtocol:
	;make sure device is "bulk only transport"
	cmp byte [BINTERFACEPROTOCOL],0x50
	jz .getEndpointNums
	;STDCALL mpdstr3,putshang


	

.getEndpointNums:
	;the first endpoint descriptor starts at 0x5032
	;the bEndpointAddress field is at 0x5034
	mov al, [0x5034]
	call SaveEPnum

	;the second endpoint descriptor starts at 0x5039
	;the bEndpointAddress field is at 0x503b
	mov al, [0x503b]
	call SaveEPnum


	;make sure that EPIN and EPOUT are not zero default pipe
	mov al,[BULKEPIN]
	mov bl,[BULKEPOUT]
	cmp al,0
	jnz .checkEPOUT
	;STDCALL mpdstr4,putshang


.checkEPOUT:
	cmp bl,0
	jnz .checkforEquality
	;STDCALL mpdstr5,putshang



.checkforEquality:
	;make sure that EPIN != EPOUT
	;I used to make this check
	;until I found the SanDisk Micro Cruzer
	;uses epin=epout=1  :)



	;dump the wMaxPacketSize for each endpoint
	;control endpoint0 is 64 bytes and configured endpoints IN/OUT are 0x0200
	;we saved the first endpoint wMaxPacketSize at [0x5032+4]
	mov ax,[0x5032+4]
	and eax,0xffff
	;STDCALL mpdstr7,0,dumpeax
	;we saved the 2nd endpoint wMaxPacketSize at [0x5039+4]
	mov ax,[0x5039+4]
	and eax,0xffff
	;STDCALL mpdstr7,0,dumpeax

	


	;STDCALL mpdstr16,putmessage
	call SetAddress

	;STDCALL mpdstr17,putmessage
	call SetConfiguration



	;now we start on the SCSI commands
	;the order of the commands and redundancy is important
	;we init the flash toggles here and then let prepareTDchain touch them only
	mov dword  [bulktogglein] ,0
	mov dword  [bulktoggleout],0

	;STDCALL mpdstr18,putmessage
	call Inquiry

	;STDCALL mpdstr19,putmessage
	call TestUnitReady

	;STDCALL mpdstr20,putmessage
	call RequestSense

	;STDCALL mpdstr19,putmessage
	call TestUnitReady

	;STDCALL mpdstr20,putmessage
	call RequestSense

	;STDCALL mpdstr21,putmessage
	call ReadCapacity

	;done-ready for read10/write10 
	;STDCALL mpdstr22,putmessage
	mov dword [FLASHDRIVEREADY],1
	
.done:
	ret
	



