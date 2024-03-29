;tatOS/usb/checkCSW.s

;a CSW CommandStatusWrapper is what is returned in the status phase
;of a scsi bulk transfer


;********************************************
;CheckCSWstatus
;check last byte of the CSW (bCSWStatus)
;00=command passed 
;01=failed 
;02=phase error
;03,04=Reserved (Obsolete)
;05-ff=Reserved
;input:none
;return:
;sets CF if command passed else clears CF
cswstr1 db 'CSW bCSWStatus = FAIL',0
cswstr2 db 'CSW bCSWStatus = FAIL-PHASE ERROR',0
cswstr3 db 'CSW bCSWStatus = FAIL-Reserved',0
;********************************************

checkc:
CheckCSWstatus:

	mov al, [scsiCSW+12]  ;bCSWStatus

	cmp al,0
	jz .commandpassed
	cmp al,1
	jz .commandfailed
	cmp al,2
	jz .phaseerror


	;al>2 : failed reserved
	;STDCALL cswstr3,dumpstr
	clc
	jmp .done

.commandpassed:
	stc
	jmp .done

.commandfailed:
	;STDCALL cswstr1,dumpstr
	clc
	jmp .done

.phaseerror:
	;STDCALL cswstr2,dumpstr
	clc
	jmp .done


.done:
	ret



;this function is currently not used
;****************************************************
;CheckCSWSignatureTag
;check the CSW signature and tag
;the device should return this 
;as the signature and tag of the CSW
;expectedCSW (defined in uhci.s)
;db 0x55,0x53,0x42,0x53,0xdd,0xcc,0xbb,0xaa
;input
;none
;return
;sets CF on success,  clears CF on invalid Signature/Tag
checkcsw db 'USB Status Transport invalid CSW Signature&Tag',0
;****************************************************
CheckCSWSignatureTag:

	mov esi,scsiCSW
	mov edi,expectedCSW
	mov ecx,8
	cld
	repe cmpsb
	je .done
	;STDCALL checkcsw,dumpstr

.done:
	ret


