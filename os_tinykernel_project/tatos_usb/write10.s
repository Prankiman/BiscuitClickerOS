;tatOS/usb/write10.s


;code to copy an array of bytes from memory to your pen drive

align 0x10


Write10Request:
;the Command Block Wrapper  31 bytes
;the byte order of the dCBWDataTransferLength is LSB FIRST
db 0x55,0x53,0x42,0x43, 0xdd,0xcc,0xbb,0xaa, 0,2,0,0, 0,0,10
;the CBWCB which is the scsi command block
;here the byte order for the Logical Block Address
;and the Transfer Length is LSB LAST !!!
;here we write to lba=3 which is the 4th block
db 0x2a,0, 0,0,0,3, 0, 0,1, 0,0,0,0,0,0,0



Write10_structTD_command:
dd Write10Request  ;BufferPointer
dd 31              ;all scsi requests are 31 bytes 
dd FULLSPEED 
dd PID_OUT
dd bulktoggleout   ;Address of toggle
dd BULKEPOUT       ;Address of endpoint
dd BULKADDRESS     ;device address on bus


Write10_structTD_data:
dd 0                ;BufferPointer-set by edi arg below-data is read to here
dd 0                ;dCBWDataTransferLength total qty bytes for transfer-set below
dd FULLSPEED  
dd PID_OUT
dd bulktoggleout
dd BULKEPOUT
dd BULKADDRESS    



wrtstr1 db 'Write10 COMMAND Transport',0
wrtstr2 db 'Write10 DATA    Transport',0
wrtstr3 db 'Write10 STATUS  Transport',0
wrtstr4 db 'Write10 total qty bytes to transfer',0


;*********************************************************************
;write10
;code to write blocks to a usb pen drive
;via the UHCI or EHCI usb controller

;input:
;ebx = destination LBAstart on pendrive
;ecx = qty blocks to write
;esi = source address of memory 

;return:none

;this code is based on and almost identical to read10
;only differance is endpoint and esi/edi for passing memory address
;********************************************************************

write10:

	pushad



	;is the flash drive ready ?
	cmp dword [FLASHDRIVEREADY],1
	jz .flashisready
	;STDCALL readstr5,putshang
.flashisready:



	;compute eax = dCBWDataTransferLength = total qty bytes to transfer
	mov edx,0
	mov eax,512  ;bytes per block
	mul ecx      ;ecx=qty blocks
	;eax = qtyblocks * 512 = dCBWDataTransferLength
	;STDCALL wrtstr4,0,dumpeax
	mov [Write10Request+8],eax
	mov [Write10_structTD_data+4],eax


	;copy the lba of the first block to the CBWCB
	;reverse the byte order because we need lsb last
	bswap ebx
	mov [Write10Request+17],ebx


	;copy the word qty blocks to read to the CBWCB
	mov [Write10Request+22],ch
	mov [Write10Request+23],cl


	;set the BufferPointer 
	mov [Write10_structTD_data],esi




	;Command Transport
	;*********************
	;STDCALL wrtstr1,dumpstr
	push Write10_structTD_command
	call [prepareTDchain]
	call [runTDchain]



	;Data Transport
	;*****************
	;STDCALL wrtstr2,dumpstr
	push Write10_structTD_data
	call [prepareTDchain]
	call [runTDchain]



	;Status Transport
	;*****************
	;STDCALL wrtstr3,dumpstr
	push SCSI_structTD_status
	call [prepareTDchain]
	call [runTDchain]


	;STDCALL scsiCSW,13,dumpmem  ;dump the Command Status Wrapper returned
	call CheckCSWstatus
	

.done:
	popad
	ret






