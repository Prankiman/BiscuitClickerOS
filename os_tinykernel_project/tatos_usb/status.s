;tatOS/usb/comstat.s


;functions to access the usb command and status registers
;there are seperate functions for uhci and ehci 


;**********************************************
;uhci_command  
;dump the value of the command register
;a value of 0x81 is normal after controller reset

;input:none
;return
;zf set on success, clear on error

;local
comregstr1 db 'UHCI USBCMD command register',0
comregstr2 db 'Max Packet',0
comregstr3 db 'CF flag',0
comregstr4 db 'debug',0
comregstr5 db 'global resume',0
comregstr6 db 'global suspend',0
comregstr7 db 'global reset',0
comregstr8 db 'HC reset',0
comregstr9 db 'Run/Stop',0
;***********************************************

uhci_command:

	pushad

	mov dx,[BASEADD]
	in ax,dx
	and eax,0xffff
	;STDCALL comregstr1,0,dumpeax

;%if VERBOSEDUMP

	;STDCALL comregstr2, 7,1,dumpbitfield  ;MaxPacket
	;STDCALL comregstr3, 6,1,dumpbitfield  ;CF flag
	;STDCALL comregstr4, 5,1,dumpbitfield  ;debug
	;STDCALL comregstr5, 4,1,dumpbitfield  ;global resume
	;STDCALL comregstr6, 3,1,dumpbitfield  ;global suspend
	;STDCALL comregstr7, 2,1,dumpbitfield  ;global reset
	;STDCALL comregstr8, 1,1,dumpbitfield  ;HC reset
	;STDCALL comregstr9, 0,1,dumpbitfield  ;run/stop

;%endif

.done:
	popad
	ret



;**********************************************
;ehci_command
;dump the value of the command register
;input:none
;return
;zf set on success, clear on error
ecomregstr1 db 'EHCI USBCMD command register',0
;***********************************************

ehci_command:

	pushad

	mov esi,[0x5d4]  ;get start of operational registers
	mov eax,[esi]     ;USBCMD is at opbar+0
	;STDCALL ecomregstr1,0,dumpeax

.done:
	popad
	ret




;***************************************
;uhci_status and ehci_status
;dump the USBSTS status register

;for UHCI:
;ax=00 is a normal condition
;ax=0x20 means controller is halted
;ax=0x10 means controller process error
;ax=8    means host system error
;for EHCI see below

;input:none
;return
;zf set on success, clear on error

;local
statstr1 db 'UHCI USBSTS status register',0
statstr1a db 'EHCI USBSTS status register',0
;ehci status register bits:
statstr2 db 'Asynchronous Schedule Status',0
statstr3 db 'Periodic Schedule Status',0
statstr4 db 'Reclamation',0
statstr5 db 'Halted',0
statstr6 db 'Host System Error',0
statstr7 db 'Frame List Rollover',0
statstr8 db 'Port Change Detect',0
statstr9 db 'USB Error Interrupt',0
statstr10 db 'USB Interrupt',0
statstr11 db 'Process Error',0
statstr12 db 'Resume Detect',0
;***************************************

uhci_status:

	mov dx,[BASEADD]
	add dx,0x02
	in ax,dx
	and eax,0xffff
	mov ebx,eax  ;copy
	;STDCALL statstr1,0,dumpeax

;%if VERBOSEDUMP

	;STDCALL statstr5,  5,1,dumpbitfield  ;halted
	;STDCALL statstr11, 4,1,dumpbitfield  ;Process error
	;STDCALL statstr6,  3,1,dumpbitfield  ;host system error
	;STDCALL statstr12, 2,1,dumpbitfield  ;resume detect
	;STDCALL statstr9,  1,1,dumpbitfield  ;Error Interrupt
	;STDCALL statstr10, 0,1,dumpbitfield  ;Interrupt

;%endif

	ret






ehci_status:

	;dump the entire USB2 status register
	mov esi,[0x5d4]  ;get start of oper reg
	mov eax,[esi+4]
	;STDCALL statstr1a,0,dumpeax

;%if VERBOSEDUMP

	;STDCALL statstr2, 15,1,dumpbitfield  ;asynch schedule status
	;STDCALL statstr3, 14,1,dumpbitfield  ;periodic schedule status
	;STDCALL statstr4, 13,1,dumpbitfield  ;reclamation
	;STDCALL statstr5, 12,1,dumpbitfield  ;halted
	;STDCALL statstr6,  4,1,dumpbitfield  ;host system error
	;STDCALL statstr7,  3,1,dumpbitfield  ;frame list rollover
	;STDCALL statstr8,  2,1,dumpbitfield  ;port change detect
	;STDCALL statstr9,  1,1,dumpbitfield  ;Error Interrupt
	;STDCALL statstr10, 0,1,dumpbitfield  ;Interrupt

;%endif

	ret



