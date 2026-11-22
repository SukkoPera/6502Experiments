    ; 264 series and C64 (probably VIC-20 and other platforms too)
!addr {
    KRN_CINT     = $ff81				; Initialize screen editor
    KRN_IOINIT   = $ff84				; Initialize I/O devices
    KRN_RAMTAS   = $ff87				; RAM Test
    KRN_RESTOR   = $ff8a				; Restore IRQ vectors to initial values
    KRN_VECTOR   = $ff8d
    KRN_SETMSG   = $ff90
    KRN_SECOND   = $ff93
    KRN_TKSA     = $ff96
    KRN_MEMTOP   = $ff99
    KRN_MEMBOT   = $ff9c
    KRN_SCNKEY   = $ff9f
    KRN_SETTMO   = $ffa2
    KRN_IECIN    = $ffa5
    KRN_IECOUT   = $ffa8
    KRN_UNTALK   = $ffab
    KRN_UNLISTEN = $ffae
    KRN_LISTEN   = $ffb1
    KRN_TALK     = $ffb4
    KRN_READST   = $ffb7
    KRN_SETLFS   = $ffba    ; Set file parameters. Input: A = Logical number; X = Device number; Y = Secondary address
    KRN_SETNAM   = $ffbd
    KRN_OPEN     = $ffc0
    KRN_CLOSE    = $ffc3
    KRN_CHKIN    = $ffc6
    KRN_CHKOUT   = $ffc9
    KRN_CLRCHANS = $ffcc
    KRN_CHRIN    = $ffcf
    KRN_BSOUT    = $ffd2				; Send a byte to output channel (or print char)
    KRN_LOAD     = $ffd5
    KRN_SAVE     = $ffd8    ; Save file. (Must call SETLFS and SETNAM beforehands.) Input: A = Address of zero page register holding start address of memory area to save; X/Y = End address of memory area plus 1
    KRN_SETTIME  = $ffdb
    KRN_READTIM  = $ffde
    KRN_STOP     = $ffe1
    KRN_GETCHAR  = $ffe4
    KRN_CLOSEALL = $ffe7
    KRN_UDTIME   = $ffea
    KRN_SCRNSIZE = $ffed
    KRN_PLOT     = $fff0
    KRN_IOBASE   = $fff3
    KRN_RESET    = $fff6
}
