;tatOS/usb/usb.s


;this file is included in tlib.s
;this file includes all the other /usb files

;code to control interaction between a USB mass storage device
;aka "flash drive" or "memory stick" or "pen drive"
;and also the low speed usb mouse
;using a UHCI or EHCI USB Controller

;this file contains the data structures
;and "includes" the supporting functions

;initusbmass prepares a pen drive for read10/write10
;as of Aug 2009 it must be executed from the shell (f12)
;initusbmouse does similar work

;this code was specifically developed on
;Intel 82371 UHCI Universal host controller
;VID=0x8086  DID=0x7112
;and later modified for EHCI usage using a pci addon card by Manhattan
;this card contains a chip with (1) EHCI and (2) UHCI companion controllers 
;this usb 2.0 controller chip is made by VIA VT6212 and it has 4 ports
;VID=0x1106  DID=0x3104

;the UHCI controller was typically found on computers
;circa Windows98 up to WindowsXP
;the UHCI controller supports (2) usb "Full" speed ports
;the ports can also operate on low speed for the usb mouse

;the EHCI controller is found on the newer desktop computers
;the OHCI USB controller is unsupported.
;the xHCI which is the newest usb 3.0 super-dooper-speed is unsupported


bits 32


;storage for function pointers
;pointers are assigned at the beginning of initusbmass and initusbmouse
;depending on which controller is found, ehci or uhci
initcontroller dd 0
portreset      dd 0
portconnect    dd 0
portlowspeed   dd 0
portscan       dd 0
portread       dd 0
portdump       dd 0
status         dd 0
command        dd 0
prepareTDchain dd 0
runTDchain     dd 0
TDstatus       dd 0


;our UHCI usb frame list consits of 1024 pointers 
;the frame list starts at 0x1000000
%define FRAMELIST 0x1000000


;The queue heads are setup in /boot/usbinit.s
;0x1005000 is for mouse interrupt xfers on uhci
;0x1005100 is for mouse control xfers on uhci and for flash control/bulk xfer on uhci
;0x1005300 is for flash bulk xfers for ehci


maxPortNum   dd 0
FlashPortNum dd 0 


;boot2 sets to 0, initusbmass sets to 1 at end if successful
;read10 and write10 check for 1 before proceeding
%define FLASHDRIVEREADY 0x528


;usb mouse uses this memory for its TD for interrupt transactions
;all other control and bulk transaction TD's are written to 0xd60000
;we seperate to prevent interference
align 32
interruptTD times 32 db 0


;speed
%define FULLSPEED 0  ;actually this will work for hi speed also, see prepareTDchain
%define LOWSPEED  1


;packet identification
;we use the same values as for ehci
;the uhci_prepareTDchain will modify accordingly
%define PID_SETUP 2   ;uhci=0x2d
%define PID_IN    1   ;uhci=0x69
%define PID_OUT   0   ;uhci=0xe1
	


;global data toggles
;with ehci you could keep toggles in the QH but we cant with uhci
controltoggle  dd 0
bulktogglein   dd 0
bulktoggleout  dd 0
mousetogglein  dd 0
mousetoggleout dd 0


;endpoint numbers read from endpoint descriptors and saved to global memory
endpoint0          dd 0
%define BULKEPIN   0x532
%define BULKEPOUT  0x533
%define MOUSEPIN   0x534   ;mouse IN endpoint


;usb requires a unique address for each device on the bus (0-127)
;address=0 is reserved for control transactions
%define ADDRESS0     0  
%define BULKADDRESS  2  
%define MOUSEADDRESS 3  


;each transfer descriptor TD chain starts at 0xd60000
;and they are spaced out as follows
;prepareTDchain and runTDchain use these values
%define UHCITDSPACING 32
%define EHCITDSPACING 64


;prepareTDchain fills this value in and runTDchain reads it
chainqtyTDs  dd 0


;fields of the USBMASS Configuration Descriptor
;and Interface Descriptor and Endpoint Descriptors
;see uhci-mount.s
;for the usb flash drive:
%define WTOTALLENGTH        0x5022
%define BNUMINTERFACES      0x5024
%define BCONFIGURATIONVALUE 0x5025
%define BNUMENDPOINTS       0x502d
%define BINTERFACECLASS     0x502e
%define BINTERFACESUBCLASS  0x502f
%define BINTERFACEPROTOCOL  0x5030

;for the low speed usb mouse we store the DeviceDescriptor starting
;at 0x5500 then the Config/Interface/HID and endpoint descriptors
;see /doc/memorymap
%define MOUSEWTOTALLENGTH   0x5522  ;length of all Config/Interf/HID/Endpoint descriptors
%define MOUSEBNUMINTERFACES 0x5524
%define MOUSEBCONFIGVALUE   0x5525
%define MOUSEREPORTLENGTH   0x5539  ;length of ReportDescriptor



align 0x10

;the device will fill in the 0x53425355 signature
;and it will copy the CBWtag
;and it will give you status: pass/fail/phase error
scsiCSW:
times 13 db 0

;the device should return this 
;as the signature and tag of the CSW
expectedCSW:
db 0x55,0x53,0x42,0x53,0xdd,0xcc,0xbb,0xaa,0,0,0,0,0



;USB-SCSI
%include "usb/initusbmass.s"
%include "usb/initusbmouse.s"
%include "usb/devicedesc.s"
%include "usb/configdesc.s"
%include "usb/reportdesc.s"
%include "usb/setprotocol.s"
%include "usb/setidle.s"
%include "usb/interrupt.s"
%include "usb/setaddress.s"
%include "usb/setconfig.s"
%include "usb/capacity.s"
%include "usb/inquiry.s"
%include "usb/testunit.s"
%include "usb/requestsense.s"
%include "usb/read10.s"
%include "usb/write10.s"

;UHCI/EHCI-hdwre
%include "usb/status.s"
%include "usb/port.s"
%include "usb/run.s"
%include "usb/checkcsw.s"
%include "usb/saveEP.s"
%include "usb/prepareTD.s"
%include "usb/controller.s"






