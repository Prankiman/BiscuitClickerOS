;tatOS/usb/reportdesc.s


;code to issue the usb Report Descriptor Request
;for low speed usb mouse only via uhci


align 0x10

ReportDescriptorRequest:
db 0x81    ;bmRequestType, HID Class Descriptor
db 6       ;bRequest=06=GET_DESCRIPTOR
dw 0x2200  ;wValue=22 for Report Descriptor and 00 for index
dw 0       ;wIndex=InterfaceNum
dw 0       ;wLength=bytes data=MOUSEREPORTLENGTH from HID descriptor



;************************************************************************
;              LOW SPEED USB MOUSE
;************************************************************************

MouseRD_structTD_command:
dd ReportDescriptorRequest  ;Bufferpointer
dd 8                        ;ReportDescriptorRequest structure is 8 bytes
dd LOWSPEED
dd PID_SETUP
dd controltoggle  ;Address of toggle
dd endpoint0      ;Address of endpoint
dd ADDRESS0       ;device address


MouseRD_structTD_data:
dd 0x5600   ;BufferPointer 
dd 0        ;set to MOUSEREPORTLENGTH below
dd LOWSPEED
dd PID_IN
dd controltoggle  ;Address of toggle
dd endpoint0      ;Address of endpoint
dd ADDRESS0       ;device address


;Manhattan mouse returns 0x57 bytes of report data
;05 01 09 02 a1 01 85 01 09 01 a1 00 05 09 19 01 29 03 15 00 25 01 95 03 75 01
;81 02 95 01 75 05 81 03 05 01 09 30 09 31 09 38 15 81 25 7f 75 08 95 03 81 06
;05 0c 0a 38 02 95 01 81 06 c0 c0 06 f3 f1 0a f3 f1 a1 01 85 02 09 00 95 01 75
;08 15 00 26 ff 00 81 02 c0

;see the usb hid spec for how to decipher this mess
;see also the USB "HID Usage Tables" ver 1.11
;tatOS has no code parser for this-instead see /uhci/mousereport.s where we 
;have the ShowMouseReport function which gets the bytes from the mouse and 
;dumps to screen so you can see live what the mouse is doing

;line1 09 10 usage pointer
;line1 05 09 usage page buttons
;line1 09 01 29 03 there are 3 buttons
;line1 15 00 25 01 each button represented by 1 bit
;line2 09 30 09 31 09 38 Usage (x) Usage (y) Usage (wheel)
;line2 15 81 25 7f Logical min (-127) Logical max (127)
;line2 75 08 95 03 Report size (8) Report Count (3) 3@ 8bits each for x,y



	
MouseRD_structTD_status:
dd 0      ;null BufferPointer
dd 0      ;0 byte transfer
dd LOWSPEED
dd PID_OUT
dd controltoggle  ;Address of toggle
dd endpoint0      ;Address of endpoint
dd ADDRESS0       ;device address


mrdstr1 db 'Mouse ReportDescriptor COMMAND Transport',0
mrdstr2 db 'Mouse ReportDescriptor DATA    Transport',0
mrdstr3 db 'Mouse ReportDescriptor STATUS  Transport',0
mrdstr4 db 'Mouse Length of Report Descriptor',0

;***************************************************************************
;MouseGetReportDescriptor
;input:none
;return: none
;*****************************************************************************


MouseGetReportDescriptor:

	xor eax,eax
	mov ax,[MOUSEREPORTLENGTH]
	mov [ReportDescriptorRequest+6],ax
	mov [MouseRD_structTD_data+4],eax
	mov edx,eax  ;save for later


	;Command Transport
	;********************
	STDCALL mrdstr1,dumpstr
	mov dword [controltoggle],0
	push MouseRD_structTD_command
	call uhci_prepareTDchain
	call uhci_runTDchain



	;Data Transport
	;*****************
	STDCALL mrdstr2,dumpstr
	mov dword [controltoggle],1
	push MouseRD_structTD_data
	call uhci_prepareTDchain
	call uhci_runTDchain

	;dump the report descriptor
	mov eax,edx
	and eax,0xffff
	STDCALL mrdstr4,0,dumpeax
	STDCALL 0x5600,eax,dumpmem 



	;Status Transport
	;*******************
	STDCALL mrdstr3,dumpstr
	mov dword [controltoggle],1
	push MouseRD_structTD_status
	call uhci_prepareTDchain
	call uhci_runTDchain


	ret

