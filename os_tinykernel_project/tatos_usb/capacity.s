;tatOS/usb/capacity.s

;ReadCapacity
;returns 8 bytes of data to 0x5100 like this:
;00 07 b7 ff 00 00 02 00
;first 4 bytes are LBAmax
;next 4 bytes are bytes per block
;need to use bswap 
;the LBAmax is 0007b7ff=505,855  (lba 0->505,855 accessible)
;the bytes per block is 0200=512 bytes
;the total capacity is (505,855+1) * 512  or about 250 Meg

;my Toshiba 2GB pen drive returns data like this:
;00 3c 87 ff 00 00 02 00
;(0x003c87ff)(0x0200) = 2,031,091,200 bytes
;max LBA that can be addressed is 0x003c87ff=3,966,975


align 0x10


;Command Block Wrapper for SCSI ReadCapacity10 (31 bytes)
ReadCapacityRequest:
dd 0x43425355   ;dCBWSignature
dd 0xaabbccdd   ;dCBWTag  (just make it up)
dd 8            ;dCBWDataTransferLength (during tdData)
db 0x80         ;bmCBWFlags (tdData direction 0x80=IN 00=OUT)
db 0            ;bCBWLun
db 10           ;bCBWCBLength, ReadCapacity10 is a 10 byte command
;CBWCB (16 bytes) see the SCSI ReadCapacity(10) Command
db 0x25         ;SCSI operation code for ReadCapacity10
db 0            ;SCSI reserved
dd 0            ;SCSI Logical Block Address
dw 0            ;SCSI Reserved
db 0            ;SCSI Reserved
db 0            ;SCSI Control
times 6 db 0    ;USBmass CBWCB must be 16 bytes long




FlashRC_structTD_command:
dd ReadCapacityRequest  ;BufferPointer
dd 31                   ;all scsi requests are 31 bytes
dd FULLSPEED 
dd PID_OUT
dd bulktoggleout  
dd BULKEPOUT     
dd BULKADDRESS  


FlashRC_structTD_data:
dd 0x5100 ;BufferPointer-data is written here
dd 8      ;total amount of inquiry data to receive 
dd FULLSPEED  
dd PID_IN
dd bulktogglein
dd BULKEPIN
dd BULKADDRESS    


;uses same SCSI_structTD_status as inquiry for status transport


rcstr1 db 'Flash ReadCapacity  COMMAND transport',0
rcstr2 db 'Flash ReadCapacity  DATA    transport',0
rcstr3 db 'Flash ReadCapacity  STATUS  transport',0
rcstr4 db 'LBAmax',0
rcstr5 db 'bytes per block',0


ReadCapacity:


	;Command Transport
	;********************
	STDCALL rcstr1,dumpstr
	push FlashRC_structTD_command
	call [prepareTDchain]
	call [runTDchain]



	;Data Transport
	;*****************
	STDCALL rcstr2,dumpstr
	push FlashRC_structTD_data
	call [prepareTDchain]
	call [runTDchain]

	STDCALL 0x5100,8,dumpmem  ;dump the capacity bytes

	;display the LBAmax
	mov eax,[0x5100]
	bswap eax
	STDCALL rcstr4,0,dumpeax

	;display the bytes per block
	mov eax,[0x5104]
	bswap eax
	STDCALL rcstr5,0,dumpeax



	;Status Transport
	;*******************
	STDCALL rcstr3,dumpstr
	push SCSI_structTD_status
	call [prepareTDchain]
	call [runTDchain]

	STDCALL scsiCSW,13,dumpmem  ;dump the Command Status Wrapper returned
	call CheckCSWstatus

.done:
	ret





