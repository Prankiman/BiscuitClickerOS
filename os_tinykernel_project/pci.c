//https://wiki.osdev.org/PCI
#include "types.h"
#include "pci.h"
#include "screen.h"


//_________________________________________________________________________________________
//pdoane's PCI code, https://github.com/pdoane/osdev/tree/master/pci
//_______________________________________________________________________________________

const char *PciDeviceName(u32 vendorId, u32 deviceId)
{
    return "Unknown Device";
}

// ------------------------------------------------------------------------------------------------
const char *PciClassName(u32 classCode, u32 subclass, u32 progIntf)
{
    /*switch ((classCode << 8) | subclass)
    {
    case PCI_VGA_COMPATIBLE:            return "VGA-Compatible Device";
    case PCI_STORAGE_SCSI:              return "SCSI Storage Controller";
    case PCI_STORAGE_IDE:               return "IDE Interface";
    case PCI_STORAGE_FLOPPY:            return "Floppy Disk Controller";
    case PCI_STORAGE_IPI:               return "IPI Bus Controller";
    case PCI_STORAGE_RAID:              return "RAID Bus Controller";
    case PCI_STORAGE_ATA:               return "ATA Controller";
    case PCI_STORAGE_SATA:              return "SATA Controller";
    case PCI_STORAGE_OTHER:             return "Mass Storage Controller";
    case PCI_NETWORK_ETHERNET:          return "Ethernet Controller";
    case PCI_NETWORK_TOKEN_RING:        return "Token Ring Controller";
    case PCI_NETWORK_FDDI:              return "FDDI Controller";
    case PCI_NETWORK_ATM:               return "ATM Controller";
    case PCI_NETWORK_ISDN:              return "ISDN Controller";
    case PCI_NETWORK_WORLDFIP:          return "WorldFip Controller";
    case PCI_NETWORK_PICGMG:            return "PICMG Controller";
    case PCI_NETWORK_OTHER:             return "Network Controller";
    case PCI_DISPLAY_VGA:               return "VGA-Compatible Controller";
    case PCI_DISPLAY_XGA:               return "XGA-Compatible Controller";
    case PCI_DISPLAY_3D:                return "3D Controller";
    case PCI_DISPLAY_OTHER:             return "Display Controller";
    case PCI_MULTIMEDIA_VIDEO:          return "Multimedia Video Controller";
    case PCI_MULTIMEDIA_AUDIO:          return "Multimedia Audio Controller";
    case PCI_MULTIMEDIA_PHONE:          return "Computer Telephony Device";
    case PCI_MULTIMEDIA_AUDIO_DEVICE:   return "Audio Device";
    case PCI_MULTIMEDIA_OTHER:          return "Multimedia Controller";
    case PCI_MEMORY_RAM:                return "RAM Memory";
    case PCI_MEMORY_FLASH:              return "Flash Memory";
    case PCI_MEMORY_OTHER:              return "Memory Controller";
    case PCI_BRIDGE_HOST:               return "Host Bridge";
    case PCI_BRIDGE_ISA:                return "ISA Bridge";
    case PCI_BRIDGE_EISA:               return "EISA Bridge";
    case PCI_BRIDGE_MCA:                return "MicroChannel Bridge";
    case PCI_BRIDGE_PCI:                return "PCI Bridge";
    case PCI_BRIDGE_PCMCIA:             return "PCMCIA Bridge";
    case PCI_BRIDGE_NUBUS:              return "NuBus Bridge";
    case PCI_BRIDGE_CARDBUS:            return "CardBus Bridge";
    case PCI_BRIDGE_RACEWAY:            return "RACEway Bridge";
    case PCI_BRIDGE_OTHER:              return "Bridge Device";
    case PCI_COMM_SERIAL:               return "Serial Controller";
    case PCI_COMM_PARALLEL:             return "Parallel Controller";
    case PCI_COMM_MULTIPORT:            return "Multiport Serial Controller";
    case PCI_COMM_MODEM:                return "Modem";
    case PCI_COMM_OTHER:                return "Communication Controller";
    case PCI_SYSTEM_PIC:                return "PIC";
    case PCI_SYSTEM_DMA:                return "DMA Controller";
    case PCI_SYSTEM_TIMER:              return "Timer";
    case PCI_SYSTEM_RTC:                return "RTC";
    case PCI_SYSTEM_PCI_HOTPLUG:        return "PCI Hot-Plug Controller";
    case PCI_SYSTEM_SD:                 return "SD Host Controller";
    case PCI_SYSTEM_OTHER:              return "System Peripheral";
    case PCI_INPUT_KEYBOARD:            return "Keyboard Controller";
    case PCI_INPUT_PEN:                 return "Pen Controller";
    case PCI_INPUT_MOUSE:               return "Mouse Controller";
    case PCI_INPUT_SCANNER:             return "Scanner Controller";
    case PCI_INPUT_GAMEPORT:            return "Gameport Controller";
    case PCI_INPUT_OTHER:               return "Input Controller";
    case PCI_DOCKING_GENERIC:           return "Generic Docking Station";
    case PCI_DOCKING_OTHER:             return "Docking Station";
    case PCI_PROCESSOR_386:             return "386";
    case PCI_PROCESSOR_486:             return "486";
    case PCI_PROCESSOR_PENTIUM:         return "Pentium";
    case PCI_PROCESSOR_ALPHA:           return "Alpha";
    case PCI_PROCESSOR_MIPS:            return "MIPS";
    case PCI_PROCESSOR_CO:              return "CO-Processor";
    case PCI_SERIAL_FIREWIRE:           return "FireWire (IEEE 1394)";
    case PCI_SERIAL_SSA:                return "SSA";
    case PCI_SERIAL_USB:
        switch (progIntf)
        {
        case PCI_SERIAL_USB_UHCI:       return "USB (UHCI)";
        case PCI_SERIAL_USB_OHCI:       return "USB (OHCI)";
        case PCI_SERIAL_USB_EHCI:       return "USB2";
        case PCI_SERIAL_USB_XHCI:       return "USB3";
        case PCI_SERIAL_USB_OTHER:      return "USB Controller";
        default:                        return "Unknown USB Class";
        }
        break;
    case PCI_SERIAL_FIBER:              return "Fiber Channel";
    case PCI_SERIAL_SMBUS:              return "SMBus";
    case PCI_WIRELESS_IRDA:             return "iRDA Compatible Controller";
    case PCI_WIRLESSS_IR:               return "Consumer IR Controller";
    case PCI_WIRLESSS_RF:               return "RF Controller";
    case PCI_WIRLESSS_BLUETOOTH:        return "Bluetooth";
    case PCI_WIRLESSS_BROADBAND:        return "Broadband";
    case PCI_WIRLESSS_ETHERNET_A:       return "802.1a Controller";
    case PCI_WIRLESSS_ETHERNET_B:       return "802.1b Controller";
    case PCI_WIRELESS_OTHER:            return "Wireless Controller";
    case PCI_INTELLIGENT_I2O:           return "I2O Controller";
    case PCI_SATELLITE_TV:              return "Satellite TV Controller";
    case PCI_SATELLITE_AUDIO:           return "Satellite Audio Controller";
    case PCI_SATELLITE_VOICE:           return "Satellite Voice Controller";
    case PCI_SATELLITE_DATA:            return "Satellite Data Controller";
    case PCI_CRYPT_NETWORK:             return "Network and Computing Encryption Device";
    case PCI_CRYPT_ENTERTAINMENT:       return "Entertainment Encryption Device";
    case PCI_CRYPT_OTHER:               return "Encryption Device";
    case PCI_SP_DPIO:                   return "DPIO Modules";
    case PCI_SP_OTHER:                  return "Signal Processing Controller";
    }

    return "Unknown PCI Class";*/
    return "hihi";
}
/*const PciDriver g_pciDriverTable[] =
{
    { EthIntelInit },
    { UhciInit },
    { EhciInit },
    { GfxInit },
    { 0 },
};
*/
// ------------------------------------------------------------------------------------------------
u8 PciRead8(u32 id, u32 reg)
{
    u32 addr = 0x80000000 | id | (reg & 0xfc);
    outl(PCI_CONFIG_ADDR, addr);
    return inb(PCI_CONFIG_DATA + (reg & 0x03));
}

// ------------------------------------------------------------------------------------------------
u16 PciRead16(u32 id, u32 reg)
{
    u32 addr = 0x80000000 | id | (reg & 0xfc);
    outl(PCI_CONFIG_ADDR, addr);
    return inw(PCI_CONFIG_DATA + (reg & 0x02));
}

// ------------------------------------------------------------------------------------------------
u32 PciRead32(u32 id, u32 reg)
{
    u32 addr = 0x80000000 | id | (reg & 0xfc);
    outl(PCI_CONFIG_ADDR, addr);
    return inl(PCI_CONFIG_DATA);
}

// ------------------------------------------------------------------------------------------------
void PciWrite8(u32 id, u32 reg, u8 data)
{
    u32 address = 0x80000000 | id | (reg & 0xfc);
    outl(PCI_CONFIG_ADDR, address);
    outb(PCI_CONFIG_DATA + (reg & 0x03), data);
}

// ------------------------------------------------------------------------------------------------
void PciWrite16(u32 id, u32 reg, u16 data)
{
    u32 address = 0x80000000 | id | (reg & 0xfc);
    outl(PCI_CONFIG_ADDR, address);
    outw(PCI_CONFIG_DATA + (reg & 0x02), data);
}

// ------------------------------------------------------------------------------------------------
void PciWrite32(u32 id, u32 reg, u32 data)
{
    u32 address = 0x80000000 | id | (reg & 0xfc);
    outl(PCI_CONFIG_ADDR, address);
    outl(PCI_CONFIG_DATA, data);
}

// ------------------------------------------------------------------------------------------------
void PciReadBar(u32 id, u32 index, u32 *address, u32 *mask)
{
    u32 reg = PCI_CONFIG_BAR0 + index * sizeof(u32);

    // Get address
    *address = PciRead32(id, reg);

    // Find out size of the bar
    PciWrite32(id, reg, 0xffffffff);
    *mask = PciRead32(id, reg);

    // Restore adddress
    PciWrite32(id, reg, *address);
}

// ------------------------------------------------------------------------------------------------
void PciGetBar(PciBar *bar, u32 id, u32 index)
{
    // Read pci bar register
    u32 addressLow;
    u32 maskLow;
    PciReadBar(id, index, &addressLow, &maskLow);

    if (addressLow & PCI_BAR_64)
    {
        // 64-bit mmio
        u32 addressHigh;
        u32 maskHigh;
        PciReadBar(id, index + 1, &addressHigh, &maskHigh);

        //bar->u.address = (void *)(((u32ptr_t)addressHigh << 32) | (addressLow & ~0xf));
        //bar->size = ~(((u64)maskHigh << 32) | (maskLow & ~0xf)) + 1;
        //bar->flags = addressLow & 0xf;
    }
    else if (addressLow & PCI_BAR_IO)
    {
        // i/o register
        bar->u.port = (u16)(addressLow & ~0x3);
        bar->size = (u16)(~(maskLow & ~0x3) + 1);
        bar->flags = addressLow & 0x3;
    }
    else
    {
        // 32-bit mmio
        bar->u.address = (void *)(u32)(addressLow & ~0xf);
        bar->size = ~(maskLow & ~0xf) + 1;
        bar->flags = addressLow & 0xf;
    }
}

void PciVisit(u32 bus, u32 dev, u32 func, u8 y)
{
    u32 id = PCI_MAKE_ID(bus, dev, func);

    PciDeviceInfo info;
    info.vendorId = PciRead16(id, PCI_CONFIG_VENDOR_ID);
    if (info.vendorId == 0xffff)
    {
        return;
    }

    info.deviceId = PciRead16(id, PCI_CONFIG_DEVICE_ID);
    info.progIntf = PciRead8(id, PCI_CONFIG_PROG_INTF);
    info.subclass = PciRead8(id, PCI_CONFIG_SUBCLASS);
    info.classCode = PciRead8(id, PCI_CONFIG_CLASS_CODE);

    disp_int(info.vendorId, 1, y*16+40, 0);

   /* const PciDriver *driver = g_pciDriverTable;
    while (driver->init)
    {
        driver->init(id, &info);
        ++driver;
    }*/
}

// ------------------------------------------------------------------------------------------------
void PciInit()
{
    for (u32 bus = 0; bus < 256; ++bus)
    {
        for (u32 dev = 0; dev < 32; ++dev)
        {
            u32 baseId = PCI_MAKE_ID(bus, dev, 0);
            u8 headerType = PciRead8(baseId, PCI_CONFIG_HEADER_TYPE);
            u32 funcCount = headerType & PCI_TYPE_MULTIFUNC ? 8 : 1;

            for (u32 func = 0; func < funcCount; ++func)
            {
                PciVisit(bus, dev, func, (u8)dev);
            }
        }
    }
}
