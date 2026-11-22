;-----------------------------------------------------------------------------------------------------------------------
; System definitions
;-----------------------------------------------------------------------------------------------------------------------
; Here we use more generic names so that (in theory) we could make similar files for different systems (C64, C128,
; etc.). We still try to add the corresponding source symbol whenever possible. Everything shall be prefixed with "SYS".
;-----------------------------------------------------------------------------------------------------------------------
!addr {
	;~ SYS_SCREEN_MEM_BASE = $0400		; C64
    SYS_SCREEN_MEM_BASE = $0c00     	; Ends at $0fe7
    SYS_COLOR_MEM_BASE = $0800      	; Ends at $0be7
    
    SYS_ACIA_BASE = $fd00
    SYS_ACIA_TX = SYS_ACIA_BASE         ; Write only
    SYS_ACIA_RX = SYS_ACIA_BASE         ; Read only
    SYS_ACIA_RESET = SYS_ACIA_BASE + 1  ; Write only
    SYS_ACIA_STATUS = SYS_ACIA_BASE + 1 ; Read only
    SYS_ACIA_CMD = SYS_ACIA_BASE + 2
    SYS_ACIA_CTL = SYS_ACIA_BASE + 3

	; Userport base address, always use this for compatibility with the Hannes RAM expansion
    SYS_USERPORT = $fd10
    
    SYS_KEYBOARD_BUFFER = $0527			; keyd
    SYS_KEYBOARD_BUFFER_SIZE = 10
    SYS_KEYBOARD_BUFFER_INDEX = $ef     ; ndx - Number of jeys currently in the buffer
    
    ; Note the tape buffer officially starts at $333, but the preceding byte is unused
    SYS_TAPE_BUFFER = $0332				; tapbuf
	SYS_TAPE_BUFFER_SIZE = 193
	
	; This is used by the KERNAL serial receive function, but it can be used freely if that is not needed
	SYS_ACIA_BUFFER = $03f7			; inpque
	SYS_ACIA_BUFFER_COUNT = $07d3	; inqcnt - Not an index, use agetch to retrieve next char
	SYS_ACIA_BUFFER_SIZE = 64		; inpqlen
}

; ACIA Status Register bits
SYS_ACIA_STBIT_ERR_PARITY      = 1 << 0
SYS_ACIA_STBIT_ERR_FRAMING     = 1 << 1
SYS_ACIA_STBIT_ERR_OVERRUN     = 1 << 2
SYS_ACIA_STBIT_ERR_RXREG_FULL  = 1 << 3
SYS_ACIA_STBIT_ERR_TXREG_EMPTY = 1 << 4
SYS_ACIA_STBIT_DCD             = 1 << 5
SYS_ACIA_STBIT_DSR             = 1 << 6
SYS_ACIA_STBIT_IRQ             = 1 << 7
