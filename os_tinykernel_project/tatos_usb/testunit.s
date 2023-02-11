;tatOS/usb/testunit.s

align 0x10


;on my pen drive the CSW status is usually 01 fail
;but if I run the transaction a 2nd time it passes
;I found a couple other pen drives need RequestSense called
;after TestUnitReady fails so we now automatically do
;TestUnitReady->RequestSense->TestUnitReady->RequestSense


TestUnitReadyRequest:
dd 0x43425355   ;dCBWSignature
dd 0xaabbccdd   ;dCBWTag
dd 0            ;dCBWDataTransferLength
db 0            ;bmCBWFlags 0x80=Device2Host, 00=Host2Device
db 0            ;bCBWLun
db 6            ;bCBWCBLength 
;CBWCB refer to spc2r20.pdf from t10
db 0            ;operation code for TEST UNIT READY
db 0            ;reserved
db 0            ;reserved
db 0            ;reserved
db 0            ;reserved
db 0            ;control ?? whats this
times 15 db 0   ;pad out 



FlashTUR_structTD_command:
dd TestUnitReadyRequest ;BufferPointer
dd 31                   ;all scsi structures are 31 bytes
dd FULLSPEED 
dd PID_OUT
dd bulktoggleout        ;Address of toggle
dd BULKEPOUT            ;Address of endpoint
dd BULKADDRESS          ;device address on bus

;no data transport
;uses same SCSI_structTD5_status as inquiry for status transport

tustr1 db 'Flash TestUnitReady  COMMAND transport',0
tustr2 db 'Flash TestUnitReady  STATUS  transport',0



TestUnitReady:


	;Command Transport
	;********************
	;STDCALL tustr1,dumpstr
	push FlashTUR_structTD_command
	call [prepareTDchain]
	call [runTDchain]


	;Data Transport
	;*****************
	;there is no data transport


	;Status Transport
	;*******************
	;STDCALL tustr2,dumpstr
	push SCSI_structTD_status
	call [prepareTDchain]
	call [runTDchain]


	;STDCALL scsiCSW,13,dumpmem  ;dump the Command Status Wrapper returned
	call CheckCSWstatus

.done:
	ret





