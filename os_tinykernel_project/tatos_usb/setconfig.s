;tatOS/usb/setconfig.s

;code to issue the usb SetConfiguration request
;full or hi speed flash drive using uhci or ehci
;low speed usb mouse using uhci only


align 0x10

SetConfigurationRequest:
db 0       ;bmRequestType
db 9       ;bRequest=SET_CONFIGURATION
dw 1       ;wValue=set to BCONFIGURATIONVALUE from ConfigDescriptor
dw 0       ;wIndex
dw 0       ;wLength=bytes data returned


;*********************************************************************
;      FULL SPEED FLASH DRIVE
;*********************************************************************

FlashSC_structTD_command:
dd SetConfigurationRequest  ;BufferPointer
dd 8                        ;SetConfig Request struct is 8 bytes long
dd FULLSPEED
dd PID_SETUP
dd controltoggle            ;toggle address
dd endpoint0
dd BULKADDRESS              ;we now must use device address


;no data transport

	
FlashSC_structTD_status:
dd 0                        ;null BufferPointer
dd 0                        ;qty bytes transferred
dd FULLSPEED
dd PID_IN
dd controltoggle
dd endpoint0
dd BULKADDRESS



setconfigstr1 db 'Flash SetConfiguration COMMAND transport',0
setconfigstr2 db 'Flash SetConfiguration STATUS  transport',0 

;***************************************************************************
;SetConfiguration
;The DeviceDescriptor gives us bNumConfigurations
;The ConfigDescriptor gives us bConfigurationValue
;input:none
;***************************************************************************

SetConfiguration:

	;set the wValue field of the SetConfigurationRequest
	;this must be the bConfigurationValue gotten from Config Descriptor
	;generally this value is == 01 since most flash devices only have 1 config
	mov al,[BCONFIGURATIONVALUE]
	mov [SetConfigurationRequest+2],al
	

	;Command Transport
	;******************
	;STDCALL setconfigstr1,dumpstr
	mov dword [controltoggle],0
	push FlashSC_structTD_command
	call [prepareTDchain]
	call [runTDchain]



	;no Data Transport

	
	;Status Transport
	;*******************
	;STDCALL setconfigstr2,dumpstr
	mov dword [controltoggle],1
	push FlashSC_structTD_status
	call [prepareTDchain]
	call [runTDchain]


.done:
	ret



;*********************************************************************
;      LOW SPEED MOUSE 
;*********************************************************************

MouseSC_structTD_command:
dd SetConfigurationRequest  ;BufferPointer
dd 8                        ;SetConfig Request struct is 8 bytes long
dd LOWSPEED
dd PID_SETUP
dd controltoggle            ;toggle address
dd endpoint0
dd MOUSEADDRESS             ;we now must use device address


;no data transport

	
MouseSC_structTD_status:
dd 0                        ;null BufferPointer
dd 0                        ;qty bytes transferred
dd LOWSPEED
dd PID_IN
dd controltoggle
dd endpoint0
dd MOUSEADDRESS



msetconfigstr1 db 'Mouse SetConfiguration COMMAND transport',0
msetconfigstr2 db 'Mouse SetConfiguration STATUS  transport',0 

;***************************************************************************
;MouseSetConfiguration
;input:none
;***************************************************************************

MouseSetConfiguration:


	;set the wValue field of the SetConfigurationRequest
	;this must be the bConfigurationValue gotten from Config Descriptor
	mov al,[MOUSEBCONFIGVALUE]
	mov [SetConfigurationRequest+2],al
	

	;Command Transport
	;******************
	;STDCALL msetconfigstr1,dumpstr
	mov dword [controltoggle],0
	push MouseSC_structTD_command
	call uhci_prepareTDchain
	call uhci_runTDchain


	;no Data Transport

	
	;Status Transport
	;*******************
	;STDCALL msetconfigstr2,dumpstr
	mov dword [controltoggle],1
	push MouseSC_structTD_status
	call uhci_prepareTDchain
	call uhci_runTDchain


	ret



