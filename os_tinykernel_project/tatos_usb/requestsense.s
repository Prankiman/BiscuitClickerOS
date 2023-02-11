;tatOS/usb/requestsense.s


;use this immediately after a failed bulk transfer
;to get some status 
;this command has some magical affects
;for example on my Toshiba pen drive
;the TestUnitReady always failed the status transport first time
;so if I try to issue TestUnitReady a second time I get a stall
;but issuing RequestSense after the first TestUnitReady "frees"
;up the device then a second call to TestUnitReady passes

;the bytes look something like this if there is a problem:
;70 00 06 00 00 00 00 0a 00 00 00 00 28 00 00 00 00 00
;and if no problem:
;70 00 00 00 00 00 00 0a 00 00 00 00 00 00 00 00 00 00

;70= response code
;06= "unit attention" sense key per table 107 of spc-2
;0a= 10 more bytes of sense data
;28= additional sense code per table 108 of spc-2
;    28 stands for "not ready to ready change,medium may have changed"


align 0x10

;Command Block Wrapper for SCSI RequestSense (31 bytes)
RequestSenseRequest:
dd 0x43425355   ;dCBWSignature
dd 0xaabbccdd   ;dCBWTag  (just make it up)
dd 18           ;dCBWDataTransferLength (during TD)
db 0x80         ;bmCBWFlags (TD direction 0x80=IN 00=OUT)
db 0            ;bCBWLun
db 6            ;bCBWCBLength, ReadCapacity10 is a 10 byte command
;CBWCB
db 0x03         ;operation code for RequestSense
db 0            
dd 0            
db 0            
dw 18             
db 0            
times 6 db 0



FlashRS_structTD_command:
dd RequestSenseRequest  ;BufferPointer
dd 31                   ;all scsi structures are 31 bytes
dd FULLSPEED 
dd PID_OUT
dd bulktoggleout        ;Address of toggle
dd BULKEPOUT            ;Address of endpoint
dd BULKADDRESS          ;device address on bus


FlashRS_structTD_data:
dd 0x5400 ;BufferPointer-data is written here
dd 18     ;total amount of sense data to receive 
dd FULLSPEED  
dd PID_IN
dd bulktogglein
dd BULKEPIN
dd BULKADDRESS    


;uses same SCSI_structTD5_status as inquiry for status transport

rsstr1 db 'Flash RequestSense  COMMAND transport',0
rsstr2 db 'Flash RequestSense  DATA    transport',0
rsstr3 db 'Flash RequestSense  STATUS  transport',0



RequestSense:


	;Command Transport
	;********************
	STDCALL rsstr1,dumpstr
	push FlashRS_structTD_command
	call [prepareTDchain]
	call [runTDchain]


	;Data Transport
	;*****************
	STDCALL rsstr2,dumpstr
	push FlashRS_structTD_data
	call [prepareTDchain]
	call [runTDchain]

	STDCALL 0x5400,18,dumpmem  ;dump the sense bytes



	;Status Transport
	;*******************
	STDCALL rsstr3,dumpstr
	push SCSI_structTD_status
	call [prepareTDchain]
	call [runTDchain]

	STDCALL scsiCSW,13,dumpmem  ;dump the Command Status Wrapper returned
	call CheckCSWstatus

.done:
	ret









