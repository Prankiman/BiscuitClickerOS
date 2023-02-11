;tatOS/usb/initusbmouse.s

;code to init a usb mouse with the UHCI controller
;you must have a primary uhci controller as found by the bios
;or you must have an ehci with uhci companion controller

;I guess my definition of a primary uhci controller
;is the bios can only find it if it has its bus master enable bit
;and its i/o space enable bit set in the PCI command register

;I do not know how to make an ehci controller work with the mouse
;when the mouse is plugged directly into one of the ehci "root" ports
;it seems you have to plug the mouse into a hub which acts as a
;"Transaction translator".
;if you plug the mouse directly into a root port of ehci the only way
;tatoS can handle this is to handoff the port to a low speed uhci companion
;controller and let the uhci control the mouse.

;if your ehci controller does not have uhci companion controllers then tatOS
;cant handle the mouse. My VIA VT6212 has ehci with 2 uhci companion controllers.
;the Intel ICHn integrated chips also use ehci w/uhci companion controllers
;nVidia ehci uses ohci which tatOS does not support


usbmousestr1 db 'Init usb mouse',0
usbmousestr2 db 'UHCI companion controller not available',0
usbmousestr4 db 'Unable to detect mouse on lo speed port',0
usbmousestr5 db 'Scanning primary UHCI ports',0
usbmousestr6 db 'Report Descriptor',0
usbmousestr7 db 'Set Protocol',0
usbmousestr8 db 'Set Idle',0
usbmousestr9 db 'Could not find mouse on ehci port',0
usbmousestr10 db 'Trying UHCI companion controller',0
usbmousestr11 db 'Releasing ownership of hi speed port',0
usbmousestr12 db 'PORTSC after release',0
usbmousestr13 db 'Resetting 1st uhci companion controller',0
usbmousestr14 db 'Resetting 2nd uhci companion controller',0
usbmousestr15 db 'Failed to find mouse on uhci companion controller port',0
usbmousestr16 db 'USBMOUSEREPORTHAS01BYTE',0


usbinitmouse:


	;STDCALL usbmousestr1,putmessage
	;STDCALL usbmousestr1,dumpstr


	;do we have a primary UHCI controller ?
	;bios checked for this in boot2
	cmp dword [0x560],0xffffffff    ;ffffffff indicates non-existant
	jz .tryUHCIcompanionController




	;*****************************************
	;    Work with primary UHCI controller
	;*****************************************

	;STDCALL usbmousestr5,putmessage
	;STDCALL usbmousestr5,dumpstr

	call uhci_portdump

	call uhci_portscan
	mov eax,esi
	;esi=portnum of mouse else 0xffffffff

	cmp eax,0xffffffff
	jz .tryUHCIcompanionController  ;mouse not plugged into uhci primary port

.resetport:
	call uhci_portreset

	jmp .doUSBtransactions







	;*****************************************
	;    Work with EHCI Companion controller
	;    (which must be an UHCI)
	;*****************************************

.tryUHCIcompanionController:

	;STDCALL usbmousestr10,putmessage
	;STDCALL usbmousestr10,dumpstr

	;do we have any companion uhci controllers ?
	;detect routine is in /usb/controller.s at the end
	cmp dword [0x5e0],0
	jnz .setupUHCIcompanion

	;if we got here we have no UHCI companion controllers - out of luck
	;STDCALL usbmousestr2,putshang

.setupUHCIcompanion:

	call ehci_portdump

	call ehci_portscan
	mov eax,esi

	cmp eax,0xffffffff
	jnz .releaseOwnership

	;Fatal-no mouse plugged into ehci port  
	;STDCALL usbmousestr9,putshang

.releaseOwnership:

	;STDCALL usbmousestr11,putmessage
	;STDCALL usbmousestr11,dumpstr
	call ehci_portread      ;eax=portnum

	;if we got here we found a mouse connected to an ehci port
	;release ownership of ehci port to companion controller
	mov esi,[0x5d4]         ;get start of ehci operational regs
	mov edi,[esi+44h+eax*4] ;read PORTSC=1 (ports are 44h, 48h, 4ch, 50h)
	or edi,10000000000000b  ;set bit13 port owner = companion controller
	mov [esi+44h+eax*4],edi ;write it back

	;STDCALL usbmousestr12,dumpstr
	call ehci_portread      ;eax=portnum


	;now we dont know which companion controller will take the port
	;since ehci usually has 4 ports with 2 companion controllers


	;try the 1st uhci companion controller
	;STDCALL usbmousestr13,dumpstr
	push dword [0x5d8]   ;BUS:DEV:FUN of 1st uhci companion
	call initUHCI


	;check for low speed device attached
	call uhci_portscan
	mov eax,esi
	;esi=portnum of mouse else 0xffffffff

	cmp eax,0xffffffff
	jnz .uhciCompanionSuccess 


	;if we got here we failed to find the mouse
	;on either port of the 1st uhci companion
	;so try the 2nd uhci companion 

	;is there a 2nd uhci companion ?
	cmp dword [0x5e0],2
	jnz .uhciCompanionFailed


	;STDCALL usbmousestr14,dumpstr
	push dword [0x5dc]   ;BUS:DEV:FUN of 1st uhci companion
	call initUHCI


	;check for low speed device attached
	call uhci_portscan
	mov eax,esi
	;esi=portnum of mouse else 0xffffffff

	cmp eax,0xffffffff
	jnz .uhciCompanionSuccess 



.uhciCompanionFailed:
	;if we got here we failed to find the mouse
	;on any port of either the 1st or 2nd uhci companion
	;STDCALL usbmousestr15,putshang


.uhciCompanionSuccess:
	;if we got here we found a uhci companion with a mouse attached
	call uhci_portreset






	;*********************************
	;   proceed with usb transactions
	;**********************************
	
.doUSBtransactions:

	;returns 18 bytes at 0x5500
	;STDCALL mpdstr14,putmessage
	call MouseGetDeviceDescriptor

	;read just the configuration descriptor to get MOUSEWTOTALLENGTH
	;STDCALL mpdstr15,putmessage
	mov edx,9
	call MouseGetConfigDescriptor

	;now we get the Config+Interface+HID+Endpoint Descriptors all in 1 shot
	xor edx,edx
	mov dx,[MOUSEWTOTALLENGTH]
	call MouseGetConfigDescriptor

	;STDCALL usbmousestr6,putmessage
	call MouseGetReportDescriptor

	;STDCALL mpdstr16,putmessage
	call MouseSetAddress

	;STDCALL usbmousestr7,putmessage
	call MouseSetProtocol

	;STDCALL usbmousestr8,putmessage
	call MouseSetIdle

	;STDCALL mpdstr17,putmessage
	call MouseSetConfiguration

	;ready to conduct usb mouse interrupt IN transactions
	;see /usb/interrupt.s



	;"zero" out our mousereportbuf to something which the mouse
	;can not possibly give as a valid report
	cld
	mov al,0x09
	mov ecx,5
	mov edi,mousereportbuf
	rep stosb


	;queue up our first mouse request
	call usbmouserequest


.done:
	ret



