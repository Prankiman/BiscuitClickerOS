;tatOS/usb/configdesc.s

;code to issue the usb Configuration Descriptor Request
;full or hi speed flash drive using uhci or ehci
;low speed usb mouse using uhci only


align 0x10

ConfigDescriptorRequest:
db 0x80    ;bmRequestType
db 6       ;bRequest=06=GET_DESCRIPTOR
dw 0x0200  ;wValue=02=CONFIGURATION and 00=index
dw 0       ;wIndex
dw 9       ;wLength=bytes data returned,9 or WTOTALLENGTH



;*****************************************************************
;      FULL SPEED USB FLASH DRIVE
;*****************************************************************


FlashCD_structTD_command:
dd ConfigDescriptorRequest  ;BufferPointer
dd 8              ;ConfigDescriptorRequest structure is 8 bytes 
dd FULLSPEED
dd PID_SETUP
dd controltoggle 
dd endpoint0  
dd ADDRESS0   


FlashCD_structTD_data:
dd 0x5020 ;BufferPointer-data is written to
dd 0      ;qtybytes2get is passed as arg to function
dd FULLSPEED 
dd PID_IN
dd controltoggle
dd endpoint0
dd ADDRESS0


;results from my blue pen drive
;**********************************

;9 byte config descriptor (02):
;09 02 27 00 01 01 00 80 fa 
;09=bLength=length of descriptor
;02=bDescriptor type = CONFIGURATION descriptor
;2700=wTotalLength=total length of all config/interface/endpoint descriptors
;01=bNumInterfaces
;01=bConfigurationValue
;00=iConfiguration=index of string descriptor
;80=bmAttributes
;fa=bMaxPower


;9 byte interface descriptor (04):
;the 6th byte of this descriptor tells you its a flash drive 08=MASS STORAGE class
;see below the 6th byte of the mouse interface desc is 03=HID class
;09 04 00 00 03 08 06 50 00 
;09=bLength
;04=bDescriptor type = INTERFACE descriptor
;00=bInterfaceNumber
;00=bAlternateSetting
;03=bNumEndpoints
;08=bInterfaceClass=MASS STORAGE class
;06=bInterfaceSubclass=SCSI
;50=bInterfaceProtocol=BULK-ONLY-TRANSPORT
;00=iInterface,index to string descriptor describing this interface


;We have (3) 7 byte endpoint descriptors (05):
;the endpoint descriptor changes depending on which controller is used
;for UHCI:
;07 05 81 02 40 00 00   (81 IN endpoint 0x40 wMaxPacket)
;07 05 02 02 40 00 00   (02 OUT endpoint 0x40 wMaxPacket)
;07 05 83 03 02 00 01
;for EHCI
;07 05 81 02 00 02 00   (0x0200 wMaxPacket)
;07 05 02 02 00 02 00
;07 05 83 03 02 00 01
;07=bLength=length of descriptor
;05=bDescriptorType=ENDPOINT descriptor
;83=bEndpointAddress, 8=IN endpoint and 3=address
;03=bmAttributes, 02=bulkendpoint and 03=?
;0200=wMaxPacketSize
;01=bInterval,does not apply to bulk endpoints



	
FlashCD_structTD_status:
dd 0        ;null BufferPointer
dd 0        ;0 byte transfer
dd FULLSPEED 
dd PID_OUT
dd controltoggle
dd endpoint0
dd ADDRESS0

	
configstr1 db 'Flash ConfigDescriptor COMMAND Transport',0
configstr2 db 'Flash ConfigDescriptor DATA    Transport',0
configstr3 db 'Flash ConfigDescriptor STATUS  Transport',0
configstr4 db 'Config Descriptor wTotalLength',0
configstr5 db 'bConfigurationValue for SetConfiguration',0
configstr6 db 'bNumInterfaces',0
qtyconfigdata dd 0




;**********************************************************
;FlashGetConfigDescriptor
;run this 2 times
;the first time request 9 bytes of data
;this is the Configuration Descriptor
;we store this starting at 0x5020
;then examine the wTotalLength field offset 2
;this field gives the total qty bytes which includes the 
;config + all interface + all endpoint descriptors
;then run GetConfigDescriptor again 
;requesting wTotalLength bytes in the tdData packet

;input:
;edx = qty bytes for device to return in tdData packet
;    = 9 or WTOTALLENGTH
;***********************************************************


FlashGetConfigDescriptor:


	;qty bytes device should return 
	mov [qtyconfigdata],edx 
	mov [ConfigDescriptorRequest+6],dx
	mov [FlashCD_structTD_data+4],edx



	;Command Transport
	;*********************
	STDCALL configstr1,dumpstr
	mov dword [controltoggle],0
	push FlashCD_structTD_command
	call [prepareTDchain]
	call [runTDchain]



	;Data Transport
	;*******************
	STDCALL configstr2,dumpstr
	mov dword [controltoggle],1
	push FlashCD_structTD_data
	call [prepareTDchain]
	call [runTDchain]


	;lets dump some important stuff
	STDCALL 0x5020,[qtyconfigdata],dumpmem  ;to see all the config data
	mov ax,[WTOTALLENGTH]
	STDCALL configstr4,1,dumpeax 
	mov al,[BCONFIGURATIONVALUE]
	STDCALL configstr5,2,dumpeax
	mov al,[BNUMINTERFACES]
	STDCALL configstr6,2,dumpeax



	;Status Transport
	;*****************
	STDCALL configstr3,dumpstr
	mov dword [controltoggle],1
	push FlashCD_structTD_status
	call [prepareTDchain]
	call [runTDchain]


	ret




;*****************************************************************
;      LOW SPEED USB MOUSE
;*****************************************************************



MouseCD_structTD_command:
dd ConfigDescriptorRequest  ;BufferPointer
dd 8                        ;ConfigDescriptorRequest structure is 8 bytes 
dd LOWSPEED
dd PID_SETUP
dd controltoggle
dd endpoint0
dd ADDRESS0


MouseCD_structTD_data:
dd 0x5520 ;BufferPointer-data is written to
dd 0      ;qtybytes2get is passed as arg to function
dd LOWSPEED
dd PID_IN
dd controltoggle
dd endpoint0
dd ADDRESS0

;0x5520
;Manhattan usb mouse device returns 34 bytes of data in 5 packets:
;9 byte config descriptor (02):
;09 02 22 00 01 01 00 a0 31 
;(wTotalLength=22, bNumInterfaces=01, bConfigurationValue=01)

;0x5529
;9 byte interface descriptor (04):
;09 04 00 00 01 03 01 02 00 
;(bInteraceNumber=00,bNumEndpoints=01, class=03 HID,subclass=01 boot,protocol=02 mouse)
;subclass=01 is boot interface, we issue Set_Protocol(Boot Interface)
;this standardizes the report given by the mouse

;0x5532
;9 byte HID descriptor (21):
;09 21 10 01 00 01 22 57 00 
;(01 HID class descriptors follow, type=0x22 Report, length=0x57 bytes)

;0x553b
;7 byte HID endpoint descriptor (05):
;07 05 81 03 06 00 0a
;(81=IN endpoint #1, 03=attributes interrupt, 06=wMaxPacketSize, 0a=polling interval)
;the wMaxPacketSize tells us the mouse gives a 6 byte report if SetProtocol=report


;Logitech Mouse Config Descriptor
;09 02 22 00 01 01 00 a0 31 
;Logitech Mouse Interface Descriptor
;09 04 00 00 01 03 01 02 00 
;Logitech Mouse HID Descriptor
;09 21 10 01 00 01 22 34 00 
;Logitech Mouse Endpoint Descriptor
;07 05 81 03 04 00 0a


MouseCD_structTD_status:
dd 0        ;null BufferPointer
dd 0        ;0 byte transfer
dd LOWSPEED
dd PID_OUT
dd controltoggle
dd endpoint0
dd ADDRESS0

	
mconfigstr1 db 'Mouse ConfigDescriptor COMMAND Transport',0
mconfigstr2 db 'Mouse ConfigDescriptor DATA    Transport',0
mconfigstr3 db 'Mouse ConfigDescriptor STATUS  Transport',0
mconfigstr4 db 'Mouse Interface Subclass (0x01=boot)',0
mconfigstr5 db 'MOUSEPIN',0




;**********************************************************
;MouseGetConfigDescriptor
;first time we ask for the 9 bytes Config Descriptor
;this gets us the WTOTALLENGTH value at offset 2
;then we call again asking for WTOTALLENGTH bytes
;which includes the Config, Interface, HID and Endpoint
;descriptors for the device

;input:
;edx = qty bytes for device to return in tdData packet
;    = 9 or MOUSEWTOTALLENGTH
;***********************************************************


MouseGetConfigDescriptor:

	;qty bytes device should return 
	mov [qtyconfigdata],edx 
	mov [ConfigDescriptorRequest+6],dx
	mov [MouseCD_structTD_data+4],edx


	;Command Transport
	;*********************
	STDCALL mconfigstr1,dumpstr
	mov dword [controltoggle],0
	push MouseCD_structTD_command
	call uhci_prepareTDchain
	call uhci_runTDchain


	;Data Transport
	;*******************
	STDCALL mconfigstr2,dumpstr
	mov dword [controltoggle],1
	push MouseCD_structTD_data
	call uhci_prepareTDchain
	call uhci_runTDchain

	;dump some data
	STDCALL 0x5520,[qtyconfigdata],dumpmem  ;to see the data
	mov ax,[MOUSEWTOTALLENGTH]
	and eax,0xffff
	STDCALL configstr4,0,dumpeax ;dump the WTOTALLENGTH
	mov al,[MOUSEBCONFIGVALUE]
	and eax,0xff
	STDCALL configstr5,0,dumpeax
	mov al,[MOUSEBNUMINTERFACES]
	and eax,0xff
	STDCALL configstr6,0,dumpeax
	mov al,[0x552f]  ;interface subclass, 01=boot
	and eax,0xff
	STDCALL mconfigstr4,0,dumpeax




	;Status Transport
	;*****************
	STDCALL mconfigstr3,dumpstr
	mov dword [controltoggle],1
	push MouseCD_structTD_status
	call uhci_prepareTDchain
	call uhci_runTDchain


	;save the address of the mouse endpoint
	;its the 3rd byte of the endpoint descriptor
	;and it better be an IN endpoint 0x8?
	mov al,[0x553d]
	and al,0xf  ;mask off bits3:0
	mov [MOUSEPIN],al 
	and eax,0xff
	STDCALL mconfigstr5,0,dumpeax


.done:
	ret


