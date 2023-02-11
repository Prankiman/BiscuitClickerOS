;tatOS/usb/interrupt.s


;code to conduct mouse interrupt transactions
;and get the 4 or 5 or whatever byte report from the mouse interrupt IN endpoint
;for uhci controller only

;the interrupt transaction is nothing but data transport on the IN pipe
;no command transport and no status transport

;you have to constantly queue up a request
;then poll the device for a response 
;NAK=0x048807ff indicates the user has not clicked a button or moved the mouse
;since the request was queued up
;the way we check for mouse activity is to set the mousereport buffer to
;something the mouse can not possibly give (09090909) 

;the mouse report is written to "mousereportbuf"
;after a report is given you have to queue up a new request
;and "zero" out the mousereport buffer

;the mouse report bytes are similar for both ps2 and usb mice 
;the only differance is the deltaY is in the opposite direction
;note also that the Manhattan mouse gives a 5 byte report with leading 01 byte 
;the microsoft and Logitech mouse give a traditional 4 byte report
;also the bytes given depend on protocol boot or report (we use report protocol)
;for this reason and because we do not have any code to parse the messy mouse
;report descriptor, you have to run usbShowMouseReport and "calibrate" the usb mouse driver
;by entering the index of your button click byte. For Logitech and Microsoft
;the button click byte is the first byte of the mouse report so you enter 00.
;For my odd Manhattan mouse the second byte is the button click byte so you enter 01.

;mouse report:
;bb dx dy dz
;the first byte is a bitmask of button clicks
;bit0=left button  (bit set=down, clear=up)
;bit1=right button
;bit2=middle button
;the next byte is delta X movement  (+X right)
;the next byte is delta Y movement  (+Y down)
;the next byte is delta Z movement  (wheel either 1 or 0xff)



;Manhattan Mouse with SetProtocol=boot 
;****************************************
;this mouse is giving 3 bytes (TD = 0x04000002 or NAK=0x048807ff)
;01 11 22
;the 01 byte never changes
;the 11 byte indicates button up/down events 
;the 22 byte indicates movement 2=right, fe=left, ff=up, 1=dn (x & y in 1 byte ??)
;cant seem to get any wheel rotation indicator



;Manhattan Mouse with SetProtocol=report 
;****************************************
;Manhattan mouse is giving 6 bytes  (TD = 0x04000005 or NAK)
;01 11 22 33 44 55 
;the 01 byte never changes - whats the point of this byte ???
;the 11 byte is button clicks same as above
;the 22 byte gives 1,2,3,4... for +delta_X and fe,fd,fc... for -delta_X
;the 33 byte gives same for delta_Y movement
;the 44 byte gives 1 to roll wheel forward and ff to roll backward
;the 55 byte is 00 always
;the coordinate system for mouse movement follows vga graphics
;+x to right and +y down



;Logitech & Microsoft Mouse w/ SetProtocol=report
;***************************************************
;the byte order is as above except no leading 01 byte 
;11 22 33 44
;11 = mouse clicks same as above
;22 = X movement
;33 = Y movement
;44 = wheel movement


align 0x10

;the mouse writes its 4 or 5 or 6 byte report to this buf
mousereportbuf:
times 10 db 0



;***************************************************************************
;usbShowMouseReport
;this is a demo and driver calibration program 
;it is executed from the shell
;I wrote this to see what the mouse is doing/what bytes its giving
;just move the mouse, click buttons and scroll the wheel 
;the current mouse report is displayed on the screen 
;and all mouse reports may be written to the dump.
;I did not want to write a lot of code to parse the messy report descriptor
;use this to customize your mouse driver

;SetIdleDuration must be set to 00 for normal mouse reporting

;this program requires the user examine the mouse report and enter a value
;to indicate the 0 based index of the button click byte in the mouse report
;if the button click byte is the first byte enter 0
;if the button click byte is the 2nd   byte enter 1
;this button click index is stored as a global dword at 0x520

;we initialize dword 0x520 to a value of 01 for my Manhattan mouse in boot2.s 
;usbcheckmouse uses the dword at 0x520 to process the mouse report
;so if you have a microsoft of logitech mouse then just edit boot2.s
;to assign 0x520 the value of 0 then you dont have to run this all the time

;sample mouse reports for Microsoft/Logitech:
;LeftButtonDown   01 00 00 00
;AnyButtonUp      00 00 00 00
;RightButtonDown  02 00 00 00
;MiddleButtonDown 04 00 00 00
;HorizontalMovementRight 00 02 00 00
;HorizontalMovementLeft  00 FE 00 00
;VerticalMovementDown    00 00 02 00
;VerticalMovementUP      00 00 FE 00
;WheelAway               00 00 00 01
;WheelTowards            00 00 00 FF
;Consecutive reports may duplicate each other for mouse move
;and wheel events

;input:none
;return: none
showmousereportstr4:
db 'USB Show Mouse Report',NL 
db 'Move the mouse, click buttons, scroll, observe the report',NL
db 'Observe which byte identifies the button click',NL
db 'Press spacebar to set button click byte index',0
showmousereportstr5:
db  'Enter Button Click Byte Index (0 for first byte, 1 for second...)',0  
;*********************************************************************

usbShowMouseReport:

	call backbufclear
	STDCALL 100,50,showmousereportstr4,0xefff,putsml 
	call swapbuf

.queueUpInterruptRequest:

	call usbmouserequest
	
.stillActive:
	test dword [interruptTD+4],0x800000  
	;zf is set if we have a mouse report
	jz .ShowMouseReport
	;no mouse activity so check keyboard
	call checkc
	jnz .assignButtonClickByteIndex
	;if we got here we have no mouse and no key activity
	jmp .stillActive
	

.ShowMouseReport:
	STDCALL 100,200,0xfeef,mousereportbuf,5,putmem
	call swapbuf
	jmp .queueUpInterruptRequest

.assignButtonClickByteIndex:
	mov byte [CLIPBOARD],0
	push showmousereportstr5
	push CLIPBOARD
	call comprompt
	jnz .done
	mov eax,CLIPBOARD
	call str2eax
	;save the index of the button click byte
	;usbcheckmouse needs this value
	;for Logitech and Microsoft the button click is the first byte so eax=00
	;for Manhattan the button click is the 2nd byte so eax=01
	mov [0x520],eax  

.done:
	ret


	



	
	



;***********************************************************************
;usbcheckmouse
;this function will queue up a usbmouse request and 
;check for mouse activity
;use this function at the top of app_main_loop  
;updates global MOUSEX and MOUSEY used to draw cursor
;note we dont actually keep tract of button up events
;the mouse will give 00 on button up which could also mean
;no activity

;input:none

;return:
;al=Button Activity
;   1=Left click
;   2=Right click
;   4=Middle click
;   0=no button activity or button up
;bl=Wheel Activity
;   01=away
;   ff=towards
;   00=no wheel activity


;note:
;most Microsoft or Logitech mice only give a 4 button report bb dx dy dz
;because of the peculiar report of my Manhattan mouse 
;with the leading 01 byte there is a %define which must be customized 
;for your particular mouse. see tatos.config
;***********************************************************************

usbcheckmouse:


	;copy the 4 byte mouse report to eax 
	;skip leading 01 byte if Manhattan	
	mov esi,mousereportbuf
	;520 should contain 00 for Logitech/Microsoft and 01 for Manhattan
	;run usbShowMouseReport to set this value
	;its set to 01 by default in boot2.s 
	add esi,[0x520]  
	;esi contains the starting address of the valid 4 byte mouse report
	mov eax,[esi]  
	;eax contains the 4 byte mouse report in reverse


	;did we get a report ?
	;we use 09090909 to indicate no report given yet
	;since the mouse can not possibly give such a report
	cmp eax,0x09090909
	jz .done


	;Process the mouse report 
	;in eax the bytes are reversed because of Intels little endian
	;so we have dz dx dy bb in eax

	;inc MOUSEX byte amount of delta X movement
	mov ebx,eax  
	shr ebx,8
	movsx ecx,bl  ;must sign extend because the dx may be negative
	add dword [MOUSEX], ecx

	;inc MOUSEY by amount of delta Y movement
	mov ebx,eax
	shr ebx,16
	movsx ecx,bl
	add dword [MOUSEY], ecx


	;"zero" out our mousereportbuf to something which the mouse
	;can not possibly give as a valid report
	mov dword [esi],0x09090909

	;queue up a new request
	call usbmouserequest   ;registers are preserved

.done:

	;return button click in al and wheel activity in bl
	mov ebx,eax
	shr ebx,24
	and eax,0xff

	ret




;*********************************************************
;usbmouserequest
;prepares a mouse interrupt TD and attaches to QH to start
;*********************************************************
usbmouserequest:

	;build a new TD
	call uhci_prepareInterruptTD   ;registers are preserved

	;attach TD to second dword of queue head to begin usb transaction
	mov dword [0x1005000+4],interruptTD  

	ret





