;tatOS/usb/run.s



;****************************************************
;uhci_runTDchain and ehci_runTDchain
;here we tell the controller to do its thing
;the chain of TD's was built by prepareTDchain
;the first TD starts at 0xd60000
;this function needs global dword chainqtyTDs 
;which is set by prepareTDchain
;verbose output of the results of each TD can be obtained
;see "call TDstatus" at the end

;input:none

;return
;zf is set on success, clear on error
;success is if the packet is no longer active
runuhcistr1 db 'td Control/Status-uhci',0
runehcistr1 db 'td Control/Status-ehci',0
;bitfields:
tdstatus2 db 'data toggle',0
tdstatus3 db 'total bytes to transfer',0
tdstatus4 db 'Current Page',0
tdstatus5 db 'Error Counter/Detection',0
tdstatus6 db 'PID code',0
tdstatus7 db 'Active bit',0
tdstatus8 db 'Halted/Stalled bit',0
tdstatus9 db 'Data Buffer Error',0
tdstatus10 db 'Babble Detected',0
tdstatus11 db 'Transaction Error',0
tdstatus12 db 'Missed Micro Frame',0
tdstatus13 db 'Split Transaction State',0
tdstatus14 db 'Ping State',0
tdstatus15 db 'NAK',0
tdstatus16 db 'CRC/Time Out Error',0
tdstatus17 db 'Bitstuff error',0
tdstatus18 db 'Actual Length',0

;****************************************************


uhci_runTDchain:
	pushad

	;to begin transaction for uhci attach td to 2nd dword of queue head
	mov dword [0x1005100+4],0xd60000


	;now that the TD is attached to the QH
	;the usb controller can do its thing
	

	;get esi=address of last TD in chain
	mov esi,[chainqtyTDs] ;value saved by prepareTDchain
	dec esi
	shl esi,5  ;esi*32
	add esi,0xd60000

	;set poll counter - waiting for the controller to do its thing 
	mov ecx,10  ;10*100ms per = 1000ms = 1 seconds


.topofloop:

	;get the Status dword of the last TD in the chain  (control/status)
	;we ignore the previous TD's, if this one doesnt pass the previous wont
	;all we do is test if the controller set the stall bit or if TD is still active


	;uhci status is 2nd dword of td
	mov eax,[esi+4]

	test eax,10000000000000000000000b ;bit22 set if stall
	jz .1  ;no stall
	jmp .decrement
.1:	test eax,100000000000000000000000b ;bit23 set if active
	jz .success  ;no active



.decrement:
	mov eax,100
	call sleep ;for 1/10 sec
	dec ecx
	jnz .topofloop

	or eax,1     ;clear zf on error
	mov dword [USBERROR],4
	jmp .done

.success:
	xor eax,eax  ;set zf on success
.done:



	;dump the status of all TD's in the chain
	;the 1st td starts at 0xd60000 and the TDstatus is the 2nd dword
	mov esi,0xd60004
	mov ecx,[chainqtyTDs]

.dumpTDstatus:
	mov eax,[esi]  ;get the td status
	STDCALL runuhcistr1,0,dumpeax

%if VERBOSEDUMP  ;bitfields in eax, 2nd dword of TD
	STDCALL tdstatus5, 27,3,dumpbitfield  ;error detection
	STDCALL tdstatus7, 23,1,dumpbitfield  ;active
	STDCALL tdstatus8, 22,1,dumpbitfield  ;stalled
	STDCALL tdstatus9, 21,1,dumpbitfield  ;data buffer error
	STDCALL tdstatus10,20,1,dumpbitfield  ;babble
	STDCALL tdstatus15,19,1,dumpbitfield  ;NAK
	STDCALL tdstatus16,18,1,dumpbitfield  ;CRC/Time out
	STDCALL tdstatus17,17,1,dumpbitfield  ;bitstuff
	STDCALL tdstatus18,0,0x7ff,dumpbitfield  ;actual length
%endif

	add esi,UHCITDSPACING  ;increment to address of next TD status dword
	dec ecx
	jnz near .dumpTDstatus


	popad
	ret







ehci_runTDchain:
	pushad

	;to begin transaction for ehci attach td to 5th dword of queue head
	mov dword [0x1005300+16],0xd60000

	;now that the TD is attached to the QH
	;the usb controller can do its thing

	;get esi=address of last TD in chain
	;this code modified from uhci_runTDchain to work with 64bit addressing
	mov eax,[chainqtyTDs] ;value saved by prepareTDchain
	dec eax
	mov ebx,EHCITDSPACING
	mul ebx              ;eax=(chainqtyTDs-1)*EHCITDSPACING
	add eax,0xd60000
	mov esi,eax

	;set poll counter - waiting for the controller to do its thing 
	mov ecx,10  ;10*100ms per = 1000ms = 1 seconds


.topofloop:

	;poll the Status dword of the last TD in the chain  (control/status)
	;we ignore the previous TD's, if this one doesnt pass the previous wont
	;all we do is test if the controller set the stall bit or if TD is still active


	;ehci status is 3rd dword of td
	mov eax,[esi+8]

	test eax,1000000b ;bit6 set if stall/halted
	jz .1  ;no stall
	jmp .decrement
.1:	test eax,10000000b ;bit7 set if active
	jz .success  ;no active


	
.decrement:
	mov eax,100
	call sleep ;for 1/10 sec
	dec ecx
	jnz .topofloop

	or eax,1     ;clear zf on error
	mov dword [USBERROR],4
	jmp .done

.success:
	xor eax,eax  ;set zf on success
.done:


	;dump the status of all TD's in the chain
	;0=just report dword TDstatus
	;1=give us verbose output of each bitfield in the TD
	;the 1st td starts at 0xd60000 and the TDstatus is the 3rd dword
	mov esi,0xd60008
	mov ecx,[chainqtyTDs]

.dumpTDstatus:
	mov eax,[esi]  ;get the td status
	STDCALL runehcistr1,0,dumpeax

%if VERBOSEDUMP  ;bitfields in eax, 3rd dword of TD
	STDCALL tdstatus2,31,1,dumpbitfield  ;data toggle
	STDCALL tdstatus3,16,0x7fff,dumpbitfield  ;total bytes 2 xfer
	STDCALL tdstatus4,12,7,dumpbitfield  ;C_Page current page
	STDCALL tdstatus5,10,3,dumpbitfield  ;CERR error counter
	STDCALL tdstatus6, 8,3,dumpbitfield  ;pid code
	STDCALL tdstatus7, 7,1,dumpbitfield  ;active bit
	STDCALL tdstatus8, 6,1,dumpbitfield  ;halted bit
	STDCALL tdstatus9, 5,1,dumpbitfield  ;data buffer error
	STDCALL tdstatus10,4,1,dumpbitfield  ;babble
	STDCALL tdstatus11,3,1,dumpbitfield  ;transaction error
	STDCALL tdstatus12,2,1,dumpbitfield  ;missed microframe
	STDCALL tdstatus13,1,1,dumpbitfield  ;split transaction state
	STDCALL tdstatus14,0,1,dumpbitfield  ;ping state
%endif

	;ehci TD's are 52 bytes but must be aligned on 32 byte boundary
	add esi,EHCITDSPACING  ;increment to address of next TD status dword
	dec ecx
	jnz near .dumpTDstatus

	popad
	ret


