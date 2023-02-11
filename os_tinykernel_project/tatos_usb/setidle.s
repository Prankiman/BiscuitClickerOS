;tatOS/usb/setidle.s


;code to issue the usb Set Idle Request
;for low speed usb mouse only via uhci
;if you have ehci you must hand off to the uhci companion controller
;see the USB-HID specs for more info 

;this command limits the reporting frequency of the endpoint

;SetIdleDuration=00 
;you get one report per button down event and one for button up
;multiple reports are not given if you hold down a button for extended time
;for example right button down gives you: 
;	02 00 00 00   
;when you release the button you get:
;   00 00 00 00

;SetIdleDuration > 00 
;the mouse generates a stream of duplicate button down reports depending on
;the duration value and how long you hold down a button
;if you do not touch the mouse then a stream of 
;00 00 00 00 reports are given indicating no activity

;according to the usb-hid spec the recommended value for
;SetIdleDuration for the mouse is 00

;duration byte examples: (always multiply by 4)
;02 = 8 milliseconds reporting frequency
;0f = 60 milliseconds
;ff = 1020 milliseconds
;00 = indefinite

;I found the mouse to work perfectly fine on the older uhci controllers
;with a duration value of 00. 

;run /usb/interrupt.s usbShowMouseReport() with differant values of the set idle
;duration byte to see the behavior of the mouse


align 0x10

SetIdleRequest:
db 0x21    ;bmRequestType
db 0x0a    ;bRequest 0a=SET_IDLE
dw 0x0000  ;the hi byte is Duration, the low byte is Report ID
dw 0       ;wIndex=InterfaceNum
dw 0       ;wLength no bytes in data phase



;************************************************************************
;              LOW SPEED USB MOUSE
;************************************************************************

MouseSI_structTD_command:
dd SetIdleRequest      ;Bufferpointer
dd 8                   ;SetIdle Request struct is 8 bytes
dd LOWSPEED
dd PID_SETUP
dd controltoggle
dd endpoint0    
dd MOUSEADDRESS         ;because we have already issued setaddress

;no data transport
	
MouseSI_structTD_status:
dd 0      ;null BufferPointer
dd 0      ;0 byte transfer
dd LOWSPEED
dd PID_IN              ;with no data phase we use PID_IN else PID_OUT
dd controltoggle
dd endpoint0   
dd MOUSEADDRESS


msistr1 db 'Mouse SetIdle COMMAND Transport',0
msistr2 db 'Mouse SetIdle STATUS  Transport',0
msistr3 db 'Set Idle Duration',0

;***************************************************************************
;MouseSetIdle
;input:none
;return: none
;*****************************************************************************


MouseSetIdle:

	;dump the set idle duration and reportID
	xor eax,eax
	mov ax,[SetIdleRequest+2]
	STDCALL msistr3,0,dumpeax


	;Command Transport
	;********************
	STDCALL msistr1,dumpstr
	mov dword [controltoggle],0
	push MouseSI_structTD_command
	call uhci_prepareTDchain
	call uhci_runTDchain


	;no data transport


	;Status Transport
	;*******************
	STDCALL msistr2,dumpstr
	mov dword [controltoggle],1
	push MouseSI_structTD_status
	call uhci_prepareTDchain
	call uhci_runTDchain


	ret

