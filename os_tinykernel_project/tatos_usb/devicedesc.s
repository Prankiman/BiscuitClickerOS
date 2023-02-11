;tatOS/usb/devicedesc.s


;code to issue the usb Device Descriptor Request
;full or hi speed flash drive using uhci or ehci
;low speed usb mouse using uhci only


align 0x10

DeviceDescriptorRequest:
db 0x80    ;bmRequestType
db 6       ;bRequest=06=GET_DESCRIPTOR
dw 0x0100  ;wValue=01 for DEVICE and 00 for index
dw 0       ;wIndex
dw 18      ;wLength=bytes data returned in data phase (8 or 18)


;************************************************************************
;              FULL SPEED USB FLASH DRIVE
;************************************************************************


FlashDD_structTD_command:
dd DeviceDescriptorRequest  ;BufferPointer
dd 8              ;DeviceDescriptorRequest structure is 8 bytes
dd FULLSPEED     
dd PID_SETUP
dd controltoggle  ;Address of toggle
dd endpoint0      ;Address of endpoint
dd ADDRESS0       ;device address


FlashDD_structTD_data:
dd 0x5000 ;BufferPointer-data is written to for usbmass
dd 18     ;we should get 18 bytes from the flash drive
dd FULLSPEED  
dd PID_IN
dd controltoggle
dd endpoint0  
dd ADDRESS0


;blue pen drive returns:
;12 01 00 02 00 00 00 40 a0 0e 68 21 00 02 01 02 03 01
;12=bLength=size of descriptor in bytes
;01=bDescriptorType=DEVICE descriptor
;0002=bcdUSB=usb spec release num
;00=bDeviceClass  (see interface descriptor)
;00=bDeviceSubClass
;00=bDeviceProtocol
;40=bMaxPacketSize0=max packet size for endpoint 0
;a00e=idVendor
;6821=idProduct
;0002=bcdDevice
;01=iManufacturer=index of string descriptor describing the mfg
;02=iProduct=index of string descriptor describing the product
;03=iSerielNumber=index of string descriptor describing the seriel num
;01=bNumConfigurations=number of possible configurations

	
FlashDD_structTD_status: 
dd 0      ;null BufferPointer
dd 0      ;0 byte transfer
dd FULLSPEED 
dd PID_OUT
dd controltoggle
dd endpoint0 
dd ADDRESS0


qtydevicedata dd 0


ddstr1 db 'Flash DeviceDescriptor COMMAND transport',0
ddstr2 db 'Flash DeviceDescriptor DATA    transport',0
ddstr3 db 'Flash DeviceDescriptor STATUS  transport',0
ddstr4 db 'bMaxPacket endpoint0',0
ddstr5 db 'Device Descriptor Data Transport failed to return 12 01',0
ddstr6 db 'VID VendorID',0
ddstr7 db 'PID ProductID',0

;********************************************************
;FlashGetDeviceDescriptor
;returns 18 bytes of pen drive data 
;see table 4.1 Universal Serial Bus Mass Storage Class
;Bulk-Only Transport  Rev 1.0 Sept 31, 1999
;for a detailed description of what the 18 bytes of
;data is. It is common to request just 8 bytes then do it again
;requesting 18 bytes.

;input:none
;return: none
;********************************************************


FlashGetDeviceDescriptor:


	;Command Transport
	;********************
	;STDCALL ddstr1,dumpstr
	mov dword [controltoggle],0
	push FlashDD_structTD_command
	call [prepareTDchain]
	call [runTDchain]


	;Data Transport
	;*****************
	;STDCALL ddstr2,dumpstr
	mov dword [controltoggle],1
	push FlashDD_structTD_data
	call [prepareTDchain]
	call [runTDchain]


	;STDCALL 0x5000,18,dumpmem  ;dump the descriptor bytes

	
	;dump bMaxPacketEndpoint0
	mov eax,[0x5000+7]
	and eax,0xff
	;STDCALL ddstr4,0,dumpeax

	;dump the VID Vendor ID  (we keep track of these in /doc/hardware)
	xor eax,eax
	mov ax,[0x5000+8]
	;STDCALL ddstr6,0,dumpeax

	;dump the PID Product ID
	xor eax,eax
	mov ax,[0x5000+10]
	;STDCALL ddstr7,0,dumpeax


	;check the first 2 bytes of the device descriptor
	;should be "12 01" - bail if not because the device is not responding
	cmp word [0x5000],0x0112
	jz .validDDreceived
	;STDCALL ddstr5,putshang
.validDDreceived:



	;Status Transport
	;*******************
	;STDCALL ddstr3,dumpstr
	mov dword [controltoggle],1
	push FlashDD_structTD_status
	call [prepareTDchain]
	call [runTDchain]


.done:
	ret




;************************************************************************
;              LOW SPEED USB MOUSE
;************************************************************************

MouseDD_structTD_command:
dd DeviceDescriptorRequest  ;Bufferpointer
dd 8                        ;DeviceDescriptorRequest structure is 8 bytes
dd LOWSPEED  
dd PID_SETUP
dd controltoggle  ;Address of toggle
dd endpoint0      ;Address of endpoint
dd ADDRESS0       ;device address


MouseDD_structTD_data:
dd 0x5500   ;BufferPointer 
dd 18       ;we should get 18 bytes from the mouse
dd LOWSPEED
dd PID_IN
dd controltoggle  ;Address of toggle
dd endpoint0      ;Address of endpoint
dd ADDRESS0       ;device address

;Logitech mouse 18 byte Device Descriptor (01):
;12 01 00 02 00 00 00 08 6d 04 0e c0 10 11 01 02 00 01
;(bMaxPacketSize0=08)

;Manhattan mouse 18 bytes Device Descriptor (01):
;12 01 00 02 00 00 00 08 cf 1b 07 00 10 00 00 02 00 01

	
MouseDD_structTD_status:
dd 0      ;null BufferPointer
dd 0      ;0 byte transfer
dd LOWSPEED
dd PID_OUT
dd controltoggle  ;Address of toggle
dd endpoint0      ;Address of endpoint
dd ADDRESS0       ;device address


mddstr1 db 'Mouse DeviceDescriptor COMMAND Transport',0
mddstr2 db 'Mouse DeviceDescriptor DATA    Transport',0
mddstr3 db 'Mouse DeviceDescriptor STATUS  Transport',0

;***************************************************************************
;MouseGetDeviceDescriptor
;this code is for a low speed mouse that can only transmit
;8 bytes per packet. The 18 bytes are stored starting at
;0x5500

;input:none
;return: none
;*****************************************************************************


MouseGetDeviceDescriptor:



	;Command Transport
	;********************
	;STDCALL mddstr1,dumpstr
	mov dword [controltoggle],0
	push MouseDD_structTD_command
	call uhci_prepareTDchain
	call uhci_runTDchain



	;Data Transport
	;*****************
	;STDCALL mddstr2,dumpstr
	mov dword [controltoggle],1
	push MouseDD_structTD_data
	call uhci_prepareTDchain
	call uhci_runTDchain
	;STDCALL 0x5500,18,dumpmem  ;to see the device descriptor



	;Status Transport
	;*******************
	;STDCALL mddstr3,dumpstr
	mov dword [controltoggle],1
	push MouseDD_structTD_status
	call uhci_prepareTDchain
	call uhci_runTDchain


.done:
	ret


