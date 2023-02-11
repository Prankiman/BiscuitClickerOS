;tatOS/usb/inquiry.s

;SCSI inquiry command for usb flash drive
;returns 36 bytes of info to 0x5200
;most of it seems useless
;there is an ascii vendor string that on my pen drive by SimpleTech
;says "Simple Flash Disk 2.00"


align 0x10

;Command Block Wrapper for SCSI Inquiry (31 bytes)
InquiryRequest:
dd 0x43425355   ;dCBWSignature
dd 0xaabbccdd   ;dCBWTag (device will copy this into CSW)
dd 0x24         ;dCBWDataTransferLength (for tdData)
db 0x80         ;bmCBWFlags 0x80=Device2Host, 00=Host2Device
db 0            ;bCBWLun
db 6            ;bCBWCBLength (of CBWCB)
;CBWCB (16 bytes) see SCSI Inquiry Command
db 0x12         ;SCSI operation code
db 0            ;SCSI reserved
db 0            ;SCSI page or operation code
db 0            ;SCSI reserved
db 0x24         ;SCSI allocation length
db 0            ;SCSI control 
times 15 db 0   ;USBmass CBWCB must be 16 bytes long  (we add alittle extra 0)



FlashINQ_structTD_command:
dd InquiryRequest  ;BufferPointer
dd 31              ;InquiryRequest structure is 31 bytes
dd FULLSPEED 
dd PID_OUT
dd bulktoggleout   ;Address of toggle
dd BULKEPOUT       ;Address of endpoint
dd BULKADDRESS     ;device address on bus


FlashINQ_structTD_data:
dd 0x5200 ;BufferPointer-data is written here
dd 36     ;total amount of inquiry data to receive 
dd FULLSPEED  
dd PID_IN
dd bulktogglein
dd BULKEPIN
dd BULKADDRESS    


;my simpletech flash drive returns the following ascii string:
;00 80 02 1f 00 00 00 53 69 6d 70 6c 65 20 20 46 6c 61 73 68 20 44 69 73 6b 20 32 2e 30
;                     S  i  m  p  l  e        F  l  a  s  h     D  i  s  k
;20 20 32 2e 30 30
;      2  .  0  0

	
;this structure is used for all scsi status transports
SCSI_structTD_status: 
dd scsiCSW       ;BufferPointer
dd 13            ;all scsi should return 13 byte transfer
dd FULLSPEED 
dd PID_IN
dd bulktogglein
dd BULKEPIN
dd BULKADDRESS


;a successful scsi status will return the CSW as follows:
;55 53 42 53 dd cc bb aa 00 00 00 00 00
;55 53 42 53 is the dCSWSignature
;dd cc bb aa is my arbitrary dCSWTag I put in every CBW
;the last byte is the status code 00=pass, 01=fail, 02=phase error



fistr1 db 'Flash Inquiry  COMMAND transport',0
fistr2 db 'Flash Inquiry  DATA    transport',0
fistr3 db 'Flash Inquiry  STATUS  transport',0


Inquiry:



	;Command Transport
	;********************
	STDCALL fistr1,dumpstr
	push FlashINQ_structTD_command
	call [prepareTDchain]
	call [runTDchain]



	;Data Transport
	;*****************
	STDCALL fistr2,dumpstr
	push FlashINQ_structTD_data
	call [prepareTDchain]
	call [runTDchain]


	STDCALL 0x5200,36,dumpmem  ;dump the inquiry bytes

	;a portion of the returned data can be displayed as ASCII
	mov byte [0x5200+36],0  ;0 terminate offset 36
	STDCALL 0x5208,dumpstr



	;Status Transport
	;*******************
	STDCALL fistr3,dumpstr
	push SCSI_structTD_status
	call [prepareTDchain]
	call [runTDchain]


	STDCALL scsiCSW,13,dumpmem  ;dump the Command Status Wrapper returned
	call CheckCSWstatus


.done:
	ret





