;tatOS/usb/setprotocol.s


;code to issue the usb Set Protocol Request
;for low speed usb mouse only via uhci

;see /usb/interrupt.s which shows the bytes given by the mouse
;the type of protocol controls how many bytes and what their meaning is
;during interruptIN transactions

%define BOOTPROTOCOL 0
%define REPORTPROTOCOL 1

align 0x10

SetProtocolRequest:
db 0x21            ;bmRequestType
db 0x0b            ;bRequest 0b=SET_PROTOCOL
dw REPORTPROTOCOL  ;wValue boot protocol or report protocol 
dw 0               ;wIndex=InterfaceNum
dw 0               ;wLength  no bytes in data phase


;my Manhattan mouse on boot protocol does not give any wheel movement
;therefore I suggest sticking with the report protocol
;the downside of report protocol is that the byte order/content are not standardized
;for example my Manhattan mouse gives an 01 byte as the first byte of the report
;whats the point of this 01 byte ?  I dont know
;Microsoft and Logitech mice do not give an 01 byte to the report


;************************************************************************
;              LOW SPEED USB MOUSE
;************************************************************************

MouseSP_structTD_command:
dd SetProtocolRequest   ;Bufferpointer
dd 8                    ;SetProtocol Request struct is 8 bytes
dd LOWSPEED
dd PID_SETUP
dd controltoggle
dd endpoint0    
dd MOUSEADDRESS         ;because we have already issued setaddress

;no data transport
	
MouseSP_structTD_status:
dd 0      ;null BufferPointer
dd 0      ;0 byte transfer
dd LOWSPEED
dd PID_IN              ;with no data phase we use PID_IN else PID_OUT
dd controltoggle
dd endpoint0   
dd MOUSEADDRESS


mspstr1 db 'Mouse SetProtocol COMMAND Transport',0
mspstr2 db 'Mouse SetProtocol STATUS  Transport',0

;***************************************************************************
;MouseSetProtocol
;input:none
;return: none
;*****************************************************************************


MouseSetProtocol:


	;Command Transport
	;********************
	STDCALL mspstr1,dumpstr
	mov dword [controltoggle],0
	push MouseSP_structTD_command
	call uhci_prepareTDchain
	call uhci_runTDchain


	;no data transport


	;Status Transport
	;*******************
	STDCALL mspstr2,dumpstr
	mov dword [controltoggle],1
	push MouseSP_structTD_status
	call uhci_prepareTDchain
	call uhci_runTDchain


	ret

