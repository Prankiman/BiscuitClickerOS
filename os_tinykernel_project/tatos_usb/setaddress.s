;tatOS/usb/setaddress.s

;code to issue the usb Set Address Request
;full or hi speed flash drive using uhci or ehci
;low speed usb mouse using uhci only


align 0x10

SetAddressRequest:  ;8 bytes like all control requests
db 0            ;bmRequestType
db 5            ;bRequest
dw 0            ;wValue=The unique USB DEVICE ADDRESS (see below)
dw 0            ;wIndex
dw 0            ;wLength=bytes data returned


;***************************************************************************
;         FULL SPEED USB FLASH DRIVE
;***************************************************************************

FlashSA_structTD_command:
dd SetAddressRequest  ;BufferPointer
dd 8                  ;SetAddressRequest struct is 8 bytes
dd FULLSPEED
dd PID_SETUP
dd controltoggle   
dd endpoint0          
dd ADDRESS0           ;use address=0 to issue command

	
FlashSA_structTD_status:
dd 0                ;null BufferPointer
dd 0                ;no data xfer
dd 0           
dd PID_IN
dd controltoggle
dd endpoint0
dd ADDRESS0    


setaddstr1 db 'Flash SetAddress COMMAND transport',0
setaddstr2 db 'Flash SetAddress STATUS  transport',0

;***********************************************************
;SetAddress
;set unique address for usb device
;input:none
;***********************************************************

SetAddress:

	;assign device address
	mov word [SetAddressRequest+2],BULKADDRESS


	;Command Transport
	;********************
	;STDCALL setaddstr1,dumpstr
	mov dword [controltoggle],0
	push FlashSA_structTD_command
	call [prepareTDchain]
	call [runTDchain]


	;Data Transport
	;****************
	;there is no data transport for this command
	

	;Status Transport
	;******************
	;STDCALL setaddstr2,dumpstr
	mov dword [controltoggle],1
	push FlashSA_structTD_status
	call [prepareTDchain]
	call [runTDchain]


	ret



;***************************************************************************
;         LOW SPEED USB MOUSE
;***************************************************************************

MouseSA_structTD_command:
dd SetAddressRequest  ;BufferPointer
dd 8                  ;SetAddress request structure is 8 bytes
dd LOWSPEED
dd PID_SETUP
dd controltoggle   
dd endpoint0          
dd ADDRESS0           ;use address=0 to issue command

	
MouseSA_structTD_status:
dd 0                ;null BufferPointer
dd 0                ;no data xfer
dd LOWSPEED
dd PID_IN
dd controltoggle   
dd endpoint0          
dd ADDRESS0           ;use address=0 to issue command


msastr1 db 'Mouse SetAddress COMMAND transport',0
msastr2 db 'Mouse SetAddress STATUS  transport',0

;***********************************************************
;MouseSetAddress
;set unique address for usb device
;input:none
;***********************************************************

MouseSetAddress:

	;assign device address
	mov word [SetAddressRequest+2],MOUSEADDRESS


	;Command Transport
	;********************
	;STDCALL msastr1,dumpstr
	mov dword [controltoggle],0
	push MouseSA_structTD_command
	call uhci_prepareTDchain
	call uhci_runTDchain


	;Data Transport
	;****************
	;there is no data transport for this command
	

	;Status Transport
	;******************
	;STDCALL msastr2,dumpstr
	mov dword [controltoggle],1
	push MouseSA_structTD_status
	call uhci_prepareTDchain
	call uhci_runTDchain


	ret



