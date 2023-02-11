;tatOS/usb/prepareTD.s


;functions to prepare usb transfer descriptor TD chains:

;uhci_prepareTDchain
;ehci_prepareTDchain
;uhci_prepareInterruptTD



;***********************************************************************************
;uhci_prepareTDchain
;function to build a single TD transfer descriptor or chain of TD's
;for UHCI Usb Controller
;for control or bulk transactions
;for interrupt transactions see prepareInterruptTD below
;the TD's are written to memory starting at 0xd60000
;use runTDchain to execute

;uhci uses a 32 byte TD for 32bit operation

;structureTD (28 bytes)
;dword Address of BufferPointer to send/receive data
;dword (n) Total qty bytes to send (OUT) or receive (IN) in the chain
;dword Speed: 
;      0 = FlashDrive operating at full or hi speed 
;      1 = Mouse operating at low speed 
;dword PID Packet ID: use PID_SETUP or PID_IN or PID_OUT 
;dword Address of Data Toggle (bulktogglein, bulktoggleout, controltoggle)             
;dword Address of Endpoint  (endpoint0, BULKEPIN, BULKEPOUT, MOUSEPIN )
;dword Constant unique device address (ADDRESS0, BULKADDRESS, MOUSEADDRESS)             


;input
;push Address of structureTD    [ebp+8]   

;return:none

;note for a control xfer you must set your data toggle before calling 
;this function, for bulk transfers this is not necessary
;***************************************************************************

;locals
TDbytes        dd 0
TDmaxbytes     dd 0
haveNULLpacket dd 0
chainbytecount dd 0
LinkPointer    dd 0
BufferPointer  dd 0


uhci_prepareTDchain:

	push ebp
	mov ebp,esp
	pushad


	;init chainqtyTDs-this is needed by runTDchain
	mov dword [chainqtyTDs],0
	mov dword [haveNULLpacket],0  


	;init edi to address where first TD will be written
	mov edi,0xd60000


	;init LinkPointer to next TD which is alway 32 bytes greater than edi
	mov [LinkPointer],edi
	add dword [LinkPointer],UHCITDSPACING


	;esi holds address of structureTD
	mov esi,[ebp+8]


	;get the initial value of the buffer pointer
	mov eax,[esi]
	mov [BufferPointer],eax


	;get qty bytes for xfer
	mov eax,[esi+4] 
	mov [chainbytecount],eax



	;set TDmaxbytes
	;for control endpoint, bMaxPacketSize0 is at (DeviceDescriptor+7)
	;only 08h, 10h, 20h, 40h are valid
	;for all other endpoints wMaxPacketSize is at (EndpointDescriptor+4)
	;the usb mouse can only handle 8 byte packets on uhci or ehci
	;the usb flash drive can handle 40h byte packets on uhci and 200h on ehci
	mov dword [TDmaxbytes],8    ;set default for low speed mouse
	cmp dword [esi+8],1         ;test for low speed device
	jz .havelowspeed
	mov dword [TDmaxbytes],64   ;full speed flash drive
.havelowspeed:



	;set TDbytes if NULL packet 
	cmp eax,0
	jnz .nonullpacket
	;uhci uses n-1 qty bytes and NULL packet is 0x7ff (wierd)
	mov dword [TDbytes],0x800  ;0x7ff+1
	mov dword [haveNULLpacket],1
	jmp .FirstDword
.nonullpacket:





	;********* start of loop **************************************

	;the loop must deal with 3 sizes of TD's:
	;	NULL TD's  (TDbytes = 0x800)       i.e. 0 byte packet status stage
	;	short TD's (TDbytes < TDmaxbytes)  last packet
	;	full TD's  (TDbytes = TDmaxbytes)  most TD's
	

.buildTDchain:	

	;set TDbytes for this TD to either short or full packet
	mov eax,[TDmaxbytes]
	mov ebx,[chainbytecount]
	cmp ebx,eax
	jb .setshortpacket
	;set full packet
	mov [TDbytes],eax   ;TDbytes=TDmaxbytes
	jmp .donesetTDbytes
.setshortpacket:
	mov [TDbytes],ebx   ;TDbytes=chainbytecount
.donesetTDbytes:

	

	;in this loop:
	;eax=holds one of the dwords of the TD we are building
	;edi=destination address where TD is written
	;esi= address of structureTD


.FirstDword:

	;1st dword of TD (LinkPointer)
	;******************************
	;for both uhci and ehci the 1st dword is a pointer to the next TD
	;ehci calls this Next qTD Pointer
	;each TD holds address of next TD else 1 if terminate
	;we terminate if chainbytecount <= TDmaxbytes or on NULL packet
	cmp dword [haveNULLpacket],1
	jz .terminateLinkPointer
	mov eax,[TDmaxbytes]
	cmp [chainbytecount],eax
	jbe .terminateLinkPointer
	;TD will point to the next TD
	mov eax,[LinkPointer]
	or eax,100b            ;depth first TD (for uhci only)
	mov [edi],eax          ;write TD 1st dword
	jmp .SecondDword
.terminateLinkPointer:
	;TD will not point to another TD
	mov dword [edi],1





	;2nd dword of TD
	;****************
.SecondDword:
	;for uhci this dword is control/status
	;unlimited retries, speed, no Isochronous, no Interrupt On Complete, active
	;the actual length bits[10:0] n-1 is written by uhci at completion
	mov ebx,[esi+8]  ;0=full speed, 1=low speed
	shl ebx,26     
	mov eax,1        ;1=active
	shl eax,23      
	or eax,ebx
	mov [edi+4],eax





	;3rd dword of td  (USB PacketHeader)
	;**********************************

	;for both uhci and ehci the 3rd dword of TD contains the interesting usb stuff
	;unfortunately the bit fields are all differant

	;bit[31:21] Max Length
	;number of data bytes "allowed" for the transfer.
	;some devices allow you to set this to TDmaxbytes for each packet even the last
	;other devices will stall if you dont set this to the proper number for short packet
	;Ah the joys of hdwre programming.
	mov eax,[TDbytes]  ;n
	dec eax            ;n-1
	shl eax,21
	
	;bit[19] data toggle  (1,0,1,0...)
	;see Toggle.info for details
	mov ebx,[esi+16] ;get address of toggle        
	mov ecx,[ebx]    ;get value of toggle
	shl ecx,19
	or eax,ecx
	;toggle our global
	not dword [ebx]   ;flip all the bits
	and dword [ebx],1 ;mask off bit0
	
	;bit[18:15] endpoint 
	;must read device endpoint descriptor to get this one
	mov ebx,[esi+20]  ;get address of endpoint
	mov ecx,[ebx]     ;get value of endpoint
	shl ecx,15
	or eax,ecx
	
	;bit[14:8] device address on the usb bus
	;0 for control else 2 or 3
	mov ebx,[esi+24]
	shl ebx,8
	or eax,ebx
	
	;bit[7:0] PID Packet ID: IN=0x69, OUT=0xe1, SETUP=0x2d
	;our PID_IN, PID_OUT, PID_SETUP are defined to use the ehci values
	;so we translate them here into a uhci value
	mov ecx,[esi+12]  
	cmp ecx,PID_OUT
	jz .pidout
	cmp ecx,PID_IN
	jz .pidin
.pidsetup:
	mov al,0x2d
	jmp .writeDword3
.pidin:
	mov al,0x69
	jmp .writeDword3
.pidout:
	mov al,0xe1


.writeDword3:
	;finally write the 3rd dword of TD
	mov [edi+8],eax





	;4th dword of TD  (BufferPointer)
	;************************************
	;this is the address to send/receive data 
	;this could be the request/command/CBW
	;or this is where the device data is returned
	;or this could be the data we are sending to the device
	;or this could be 0 in status transport or the CSW
	;for ehci this pointer must be page aligned
	;because bits[11:0] are reserved for the Current Offset into the page

	mov ebx,[BufferPointer]
	mov [edi+12], ebx


	;the uhci has 4 more dwords making up the TD but they are not used
	mov dword [edi+16],0
	mov dword [edi+20],0
	mov dword [edi+24],0
	mov dword [edi+28],0





	;******done building a single TD, now prepare loop for next time around *******




	inc dword [chainqtyTDs] ;needed for runTDchain

	;preserve eax til end of loop
	mov eax,[TDbytes]   

	;quit if NULL packet
	cmp dword [haveNULLpacket],1
	jz .done

	;quit if short packet
	cmp eax,[TDmaxbytes]
	jb .done

	;if we got here we just processed a full packet

	;increment BufferPointer
	add [BufferPointer],eax   ;BufferPointer += TDbytes

	;increment where the next TD will be written
	add edi,UHCITDSPACING

	;increment LinkPointer
	add dword [LinkPointer],UHCITDSPACING

	;decrement chainbytecount
	sub dword [chainbytecount],eax   ;chainbytecount -= TDbytes
	;sets ZF if chainbytecount goes to zero
	jnz .buildTDchain           
	;*************end of loop ******************


.done:
	popad
	pop ebp
	retn 4








;******************************************************************
;ehci_prepareTDchain
;this is the same function as above only for ehci
;the code is very similar
;there is code to modify the endpoint and address in the ehci QH
;which is unique to ehci only 
;the 3rd dword which is the important usb stuff
;has bitfields that are differant than uhci
;for 64bit operation the ehci TD needs an additional 5 dwords
;for a total of 13 dwords or 52 bytes
;we space out ehci TD's every 64 bytes 
;input:see above

;note for a chain of TD's, the BufferPointer must be page aligned
;*******************************************************************

ehci_prepareTDchain:

	push ebp
	mov ebp,esp
	pushad


	;init chainqtyTDs-this is needed by runTDchain
	mov dword [chainqtyTDs],0
	mov dword [haveNULLpacket],0  


	;init edi to address where first TD will be written
	mov edi,0xd60000


	;init LinkPointer to next TD 
	mov [LinkPointer],edi
	add dword [LinkPointer],EHCITDSPACING


	;esi holds address of structureTD
	mov esi,[ebp+8]


	;get the initial value of the buffer pointer
	mov eax,[esi]
	mov [BufferPointer],eax


	;get qty bytes for xfer
	mov eax,[esi+4] 
	mov [chainbytecount],eax



	;set TDmaxbytes
	;for control endpoint, bMaxPacketSize0 is at (DeviceDescriptor+7)
	;only 08h, 10h, 20h, 40h are valid
	;for all other endpoints wMaxPacketSize is at (EndpointDescriptor+4)
	;the usb flash drive can handle 40h byte packets on uhci and 200h on ehci
	mov dword [TDmaxbytes],512  ;hi speed flash drive



	;set TDbytes if NULL packet 
	cmp eax,0
	jnz .nonullpacket
	;ehci uses n qty bytes like it should
	mov dword [TDbytes],0      ;n 
	mov dword [haveNULLpacket],1
	jmp .FirstDword
.nonullpacket:





	;Modify QH
	;the ehci controller puts the device endpoint and address
	;into the queue head so for bulk and control xfer
	;we customize the QH accordingly

	;endpoint
	mov eax,[0x1005300+4]  ;read the 2nd dword of QH
	and eax,0xfffff0ff      ;zero out the previous EPnum
	mov ebx,[esi+20]        ;get the address of our EPnum
	mov ecx,[ebx]           ;get value of EPnum
	shl ecx,8
	or eax,ecx              ;set new EPnum

	;usb address
	and eax,0xffffff80      ;zero out the previous address
	mov ebx,[esi+24]        ;get our usb address
	or eax,ebx              ;set new address

	mov [0x1005300+4],eax   ;write to QH





	;********* start of loop **************************************

	;the loop must deal with 3 sizes of TD's:
	;	NULL TD's  (TDbytes = 0x800)       i.e. 0 byte packet status stage
	;	short TD's (TDbytes < TDmaxbytes)  last packet
	;	full TD's  (TDbytes = TDmaxbytes)  most TD's
	

.buildTDchain:	

	;set TDbytes for this TD to either short or full packet
	mov eax,[TDmaxbytes]
	mov ebx,[chainbytecount]
	cmp ebx,eax
	jb .setshortpacket
	;set full packet
	mov [TDbytes],eax   ;TDbytes=TDmaxbytes
	jmp .donesetTDbytes
.setshortpacket:
	mov [TDbytes],ebx   ;TDbytes=chainbytecount
.donesetTDbytes:

	

	;in this loop:
	;eax=holds one of the dwords of the TD we are building
	;edi=destination address where TD is written
	;esi= address of structureTD


.FirstDword:

	;1st dword of TD (LinkPointer)
	;******************************
	;for both uhci and ehci the 1st dword is a pointer to the next TD
	;ehci calls this Next qTD Pointer
	;each TD holds address of next TD else 1 if terminate
	;we terminate if chainbytecount <= TDmaxbytes or on NULL packet
	cmp dword [haveNULLpacket],1
	jz .terminateLinkPointer
	mov eax,[TDmaxbytes]
	cmp [chainbytecount],eax
	jbe .terminateLinkPointer
	;TD will point to the next TD
	mov eax,[LinkPointer]
	mov [edi],eax          ;write TD 1st dword
	jmp .SecondDword
.terminateLinkPointer:
	;TD will not point to another TD
	mov dword [edi],1





	;2nd dword of TD
	;****************
.SecondDword:
	;ehci: the 2nd dword of a TD is the "Alternate Next TD pointer"
	;this is used by the controller on short packet
	;for now we just set to 1=terminate and see what happens ???
	mov dword [edi+4],1





	;3rd dword of td  (USB PacketHeader)
	;**********************************

	;for both uhci and ehci the 3rd dword of TD contains the interesting usb stuff
	;unfortunately the bit fields are all differant

	;bit[31] data toggle  (1,0,1,0...)
	mov ebx,[esi+16] ;get address of toggle        
	mov eax,[ebx]    ;init the value in eax to our data toggle
	shl eax,31
	;now toggle our global
	not dword [ebx]   ;flip all the bits
	and dword [ebx],1 ;mask off bit0

	;bit[30:16]  Total Bytes to Transfer
	mov ebx,[TDbytes]  ;n
	shl ebx,16
	or eax,ebx

	;bit[15] Interrupt on Complete    is left at zero

	;bit[14:12] Current Page (C_Page)  is left at 0
	;index into buffer pointer list, valid values are 0-4
	;we only use BufferPointerPage0 so C_Page must always be 0
	;see discussion about Buffer Pointer below

	;bit[11:10] Error Counter CERR
	mov ebx,11b ;allow up to 3 errors 
	shl ebx,10
	or eax,ebx

	;bit[9:8] PID code
	;ehci uses 0=OUT token, 1=IN token, 2=SETUP token
	mov ebx,[esi+12]
	shl ebx,8
	or eax,ebx

	;bit[7:0] Status
	;bit fields as follows
	;7=active, 6=halted, 5=DataBufferError, 4=Babble, 3=TransactError, 
	;2=MissedMicro, 1=SplitTransState, 0=PingState
	;split transactions are for low speed devices plugged into hubs-we dont support
	mov ebx,1   ;bit[7] 1=active, the controller clears on success
	shl ebx,7   
	or eax,ebx


	;finally write the 3rd dword of TD
	mov [edi+8],eax

	;note with ehci the Endpoint and Address are moved to the queue head






	;4th dword of TD  (BufferPointer)
	;************************************
	;this is the address to send/receive data 
	;this could be the request/command/CBW
	;or this is where the device data is returned
	;or this could be the data we are sending to the device
	;or this could be 0 in status transport or the CSW

	;for ehci with flash we can transfer only 512 bytes per TD
	;so we use only the first BufferPointerPage0 and ignore the rest
	;I suppose a usb hard drive can make use of the other Buffer Pointers ??
	;I suggest for ehci with a chain of TD's
	;that the initial value of BufferPointerPage0 should be page aligned 
	;otherwise you will get bad results
	;thereafter add 0x200 to the BufferPointer for each successive TD
	;and you will be alright because bits[11:0] are reserved for the Current Offset 
	;into the page and CurrentOffset applies only to BufferPointerPage0

	mov ebx,[BufferPointer]
	mov [edi+12], ebx      ;Buffer Pointer Page 0

	;for now we are not going to use these 
	mov dword [edi+16],0  ;Buffer Pointer Page 1, 5th dword
	mov dword [edi+20],0
	mov dword [edi+24],0
	mov dword [edi+28],0  ;Buffer Pointer Page 4, 8th dword


	;and if your controller uses 64bit addressing
	;the upper 32bits of each page is specified here
	mov dword [edi+32],0   ;Extended Buffer Pointer Page 0, 9th dword
	mov dword [edi+36],0
	mov dword [edi+40],0
	mov dword [edi+44],0
	mov dword [edi+48],0   ;Extended Buffer Pointer Page 4, 13th dword




	;******done building a single TD, now prepare loop for next time around *******




	inc dword [chainqtyTDs] ;needed for runTDchain

	;preserve eax til end of loop
	mov eax,[TDbytes]   

	;quit if NULL packet
	cmp dword [haveNULLpacket],1
	jz .done

	;quit if short packet
	cmp eax,[TDmaxbytes]
	jb .done

	;if we got here we just processed a full packet

	;increment BufferPointer (Memory Address)
	add [BufferPointer],eax   ;BufferPointer += TDbytes



	;increment where the next TD will be written
	add edi,EHCITDSPACING

	;increment LinkPointer
	add dword [LinkPointer],EHCITDSPACING

	;decrement chainbytecount
	sub dword [chainbytecount],eax   ;chainbytecount -= TDbytes
	;sets ZF if chainbytecount goes to zero
	jnz .buildTDchain           
	;*************end of loop ******************


.done:
	popad
	pop ebp
	retn 4












;***********************************************************************************
;uhci_prepareInterruptTD
;this function is a stripped down and hard coded version of uhci_prepareTDchain
;for low speed usb mouse interrupt IN transactions only
;which needs a single 32 byte TD
;the TD is written to "interruptTD" defined in uhci.s
;we keep this TD seperate so mouse and flash drive transactions
;can be conducted at the same time
;input:none
;return:none
;***************************************************************************


uhci_prepareInterruptTD:

	pushad

	;init edi to address where TD will be written
	mov edi,interruptTD


	;1st dword of TD (LinkPointer)
	;******************************
	mov dword [edi],1  ;terminate, no more TD's



	;2nd dword of TD (Control/Status)
	;***********************************
	mov dword [edi+4],0x4800000  ;low speed, active



	;3rd dword of td  (USB PacketHeader)
	;**********************************

	;bit[31:21] MaxLen
	;we ask for 8 bytes, the mouse report may only be 4 or 5 bytes
	mov eax,7    ;n-1
	shl eax,21
	
	;data toggle  (1,0,1,0...)
	;see Toggle.info for details
	mov ecx,[mousetogglein]    ;get value of toggle
	shl ecx,19
	or eax,ecx
	;now toggle the global variable
	not dword [mousetogglein]   ;flip all the bits
	and dword [mousetogglein],1 ;mask off bit0
	
	;endpoint 
	;must read device endpoint descriptor to get this one
	mov ecx,[MOUSEPIN]  
	shl ecx,15
	or eax,ecx
	
	;device address on the usb bus
	;0 for control else 2 or 3
	mov ebx,MOUSEADDRESS
	shl ebx,8
	or eax,ebx
	
	;PID: IN=0x69, OUT=0xe1, SETUP=0x2d for low speed uhci
	mov al,0x69  ;interrupt-IN

	;finally write the 3rd dword of TD
	mov [edi+8],eax
	



	;4th dword of TD  (BufferPointer)
	;************************************
	;mouse report 
	;Logitech or Microsoft: bb dx dy dz
	;Manhattan: 01 bb dx dy dz
	mov dword [edi+12], mousereportbuf


.done:
	popad
	ret 






