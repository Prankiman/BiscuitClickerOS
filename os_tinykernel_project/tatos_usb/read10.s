;tatOS/usb/read10.s

;code to read blocks off the usb flash drive via the UHCI/EHCI controller
;before attempting this function or write10
;you have to go thru the entire init sequence in initusbmass.s successfullys

align 0x10

;note the bmCBWFlags byte is important for some devices but not
;others. For example my SimpleTech Bonzai pen drive I can set
;bmCBWFlags=0 and it will still read but with my Toshiba
;I must set bmCBWFlags=0x80 otherwise it will except the CBW
;but NAK every data request. Learned this the hard way.

Read10Request:

;the Command Block Wrapper
;the dCBWDataTransferLength, LBA, and TransferLength
;get overwritten below
dd 0x43425355   ;dCBWSignature
dd 0xaabbccdd   ;dCBWTag  (just make it up)
dd 0            ;dCBWDataTransferLength (total bytes Data Transport=written below)
db 0x80         ;bmCBWFlags (TD direction 0x80=IN 00=OUT)
db 0            ;bCBWLun
db 10           ;bCBWCBLength,Read10 is a 10 byte CBWCB
;CBWCB  10 bytes  (see Working Draft SCSI Block Commands SBC-2)
db 0x28         ;operation code for scsi Read10 
db 0            ;RDPROTECT/DPO/FUA/FUA_NV
db 0            ;LBA to read (msb)   filled in below
db 0            ;LBA
db 0            ;LBA
db 0            ;LBA (lsb) 
db 0            ;groupnum ?
db 0            ;TransferLength MSB in blocks  filled in below
db 0            ;TransferLength LSB 
db 0            ;control
times 6 db 0    ;pad to give a 31 byte CBW



Read10_structTD_command:
dd Read10Request    ;BufferPointer
dd 31               ;all scsi requests are 31 bytes 
dd FULLSPEED 
dd PID_OUT
dd bulktoggleout   ;Address of toggle
dd BULKEPOUT       ;Address of endpoint
dd BULKADDRESS     ;device address on bus


Read10_structTD_data:
dd 0                ;BufferPointer-set by edi arg below-data is read to here
dd 0                ;dCBWDataTransferLength total qty bytes for transfer-set below
dd FULLSPEED  
dd PID_IN
dd bulktogglein
dd BULKEPIN
dd BULKADDRESS    



readstr1 db 'Read10 COMMAND Transport',0
readstr2 db 'Read10 DATA    Transport',0
readstr3 db 'Read10 STATUS  Transport',0
readstr4 db 'Read10 total qty bytes to transfer',0
readstr5 db 'Flash Drive Not Ready',0


;*****************************************************************
;read10

;the scsi read10 command permits reading by blocks
;the assumption here is that block size = 512 bytes
;see the dump for the output of the ReadCapacity command

;input:
;ebx = lba of first block/sector to read  (0->LBAmax)
;ecx = amount of blocks to read
;edi = destination memory address

;return
;see the dump td control/status 
;should = n-1 bytes xfered for UHCI
;*************************************************************

read10:

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
	;STDCALL readstr4,0,dumpeax
	mov [Read10Request+8],eax
	mov [Read10_structTD_data+4],eax


	;copy the lba of the first block to the CBWCB
	;reverse the byte order because we need lsb last
	bswap ebx
	mov [Read10Request+17],ebx


	;copy the word qty blocks to read to the CBWCB
	mov [Read10Request+22],ch
	mov [Read10Request+23],cl


	;set the BufferPointer 
	mov [Read10_structTD_data],edi


	;clear out the 13 byte scsiCSW
	mov ecx,13
	mov edi,scsiCSW
	mov al,0xff
	cld         
	rep stosb   




	;Command Transport
	;*********************
	;STDCALL readstr1,dumpstr
	push Read10_structTD_command
	call [prepareTDchain]
	call [runTDchain]




	;Data Transport
	;*****************
	;STDCALL readstr2,dumpstr
	push Read10_structTD_data
	call [prepareTDchain]
	call [runTDchain]



	;Status Transport
	;*****************
	;STDCALL readstr3,dumpstr
	push SCSI_structTD_status
	call [prepareTDchain]
	call [runTDchain]


	;STDCALL scsiCSW,13,dumpmem  ;dump the Command Status Wrapper returned
	call CheckCSWstatus
	

.done:
	popad
	ret





