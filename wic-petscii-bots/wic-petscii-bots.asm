; *** WIC64 PETSCIIBOTS Viewer ***
;
; Code (C64):              Schorsch3000
; Code (Backend):          Schorsch3000
; Code (C16/Plus4):        SukkoPera
; Charset:                 Retrofan
; Compiler used:           Acme Assembler
;
;
;                   WiC64 Hardware & Software:
;
;               Thomas "GMP" Müller <gmp@wic64.de>
;             Sven Oliver "KiWi" Arke <kiwi@wic64.de>
;        Hardy "Lazy Jones" Ullendahl <lazyjones@wic64.de>
;             Henning "Yps" Harperath <yps@wic64.de>
;         Markus "Courage" Spiering <courage-c64@gmx.de>
;       Dirk "Schorsch3000" Heilig <schorsch3000@shnbk.de>

;~ ENABLE_TESTING = 1

ENABLE_MUSIC = 1

VERSION_STR = "0.2.0"

!if PLUS4 {
	!source "../HwLib/ted.asm"
	!source "../HwLib/ted_kernal.asm"
	!source "../HwLib/ted_keys.asm"

    !addr screen_ram_1 = $0800
	!addr screen_ram_2 = $4800
	!addr screenRamAddressChange = TED_VRAM
	!addr borderColor = TED_BORDER
	!addr backgroundColor = TED_BACKGROUND
	
	; On +4 color RAM moves with screen RAM and actually precedes it
	!addr color_dest_1 = screen_ram_1
	!addr char_dest_1 = screen_ram_1 + 1024
	!addr color_dest_2 = screen_ram_2
	!addr char_dest_2 = screen_ram_2 + 1024
	
	!addr IRQ_VECTOR = $312				; Use configurable VBlank interrupt
	!addr KERNAL_IRQ = $ce42			; Default VBlank IRQ handler
	
	!addr SID_BASE = $fd40
	!addr SID_BASE_C64 = $d400
	
	DEFAULT_BORDER_COLOR = $ee
	DEFAULT_BACKGROUND_COLOR = $f1
	
	!macro set_screen_ram .addr {
		!if .addr % $0800 != 0 {
			!error "Screen RAM must be aligned on $800: ", .addr
		}
		
		lda #>(.addr)
		sta screenRamAddressChange
	}
	
	!macro set_charset .addr {
		; Why doesn't this work???
		;~ !if .addr % $0400 != 0 {
			;~ !error "Charset must be aligned on $0400 (1kB): ", .addr
		;~ }
		
		; Set charset base addr (only 6 high bits, must thus be aligned to 1024 bytes)
		lda TED_CFG4
		and #((1 << 1) | (1 << 0))
		ora #(>.addr & $fc)
		sta TED_CFG4
		
		; Enable charset from RAM
		lda TED_CFG3
		and #!(1 << 2)
		sta TED_CFG3
	}
	
	!macro set_default_charset {
		!addr BUILTIN_CHARSET = $d000
		
		; Set charset base addr (only 6 high bits, must thus be aligned to 1024 bytes)
		lda TED_CFG4
		and #((1 << 1) | (1 << 0))
		ora #(>BUILTIN_CHARSET & $fc)
		sta TED_CFG4
		
		; Enable charset from ROM
		lda TED_CFG3
		ora #(1 << 2)
		sta TED_CFG3
	}
} else {
	!source "../HwLib/c64_kernal.asm"
	!source "../HwLib/c64_keys.asm"
	
	!addr screen_ram_1 = $0400
	!addr screen_ram_2 = $3c00
	
	; When in text screen mode, the VIC-II looks at $d018 for information on where the character set and text screen
	; character RAM is located:
    ; - The four most significant bits form a 4-bit number in the range 0 thru 15: Multiplied with 1024 this gives the
    ;   start address for the screen character RAM.
    ; - Bits 1 thru 3 (weights 2 thru 8) form a 3-bit number in the range 0 thru 7: Multiplied with 2048 this gives the
    ;   start address for the character set.
	!addr screenRamAddressChange = $d018
	!addr color_ram = $d800				;  1000 positions (25*40), $d800 to $dbe7
	!addr borderColor = 53280
	!addr backgroundColor = 53281
	
	; On C64 color RAM is fixed at $d800 and only screen RAM moves
	!addr color_dest_1 = color_ram
	!addr char_dest_1 = screen_ram_1
	!addr color_dest_2 = color_ram
	!addr char_dest_2 = screen_ram_2
	
	!addr IRQ_VECTOR = $314				; Use configurable VBlank interrupt
	!addr KERNAL_IRQ = $ea31
	
	!addr SID_BASE = $d400
	
	!addr TED_VRASTER = $d012
	
	DEFAULT_BORDER_COLOR = $0e
	DEFAULT_BACKGROUND_COLOR = $06 
	
	!macro set_screen_ram .addr {
		!if .addr % $0400 != 0 {
			!error "Screen RAM must be aligned on $0400: ", .addr
		}
		!if .addr / $0400 > 15 {
			!error "Screen RAM address too large (max is $3c00): ", .addr
		}
		
		lda screenRamAddressChange
		and #%00001111
		ora #((.addr / $0400) << 4)
		sta screenRamAddressChange
	}
	
	!macro set_charset .addr {
		; Why doesn't this work???
		;~ !if .addr % $0800 != 0 {
			;~ !error "Charset must be aligned on $0800 (2kB): ", .addr
		;~ }
		
		; Also charset cannot be at 4096/$1000, 6144/$1800, 36864/$9000, or 38912/$9800
		; TBD
		
		; The VIC-II can only see 16 KB of memory at a time, so we have to choose one of 4 banks:
		; %11 = bank 0 ($0000-$3FFF)
		; %10 = bank 1 ($4000-$7FFF)
		; %01 = bank 2 ($8000-$BFFF)
		; %00 = bank 3 ($C000-$FFFF)
		lda $dd00
		and #%11111100
		ora #%00000011
		sta $dd00

		; $D018 only handles character set, screen and bitmap pointing for a 16K
		; bank and is split into two nybbles, the upper four bits tell the VIC-II
		; where the screen starts (simply multiply by 1K and that's where it
		; starts) and the lower four control where the charset is coming from (it
		; ignores the lowest bit, the bank is skipped through in steps of 2K since
		; that's how long charsets are).
		lda $d018
		and #$f0
		ora #(.addr / $0400)				; Charset must be aligned on 2k but address is in 1k-slices, crazy...
		sta $d018
	}
	
	!macro set_default_charset {
		!addr BUILTIN_CHARSET = $1000
		
		lda $dd00
		and #%11111100
		ora #%00000011
		sta $dd00

		lda $d018
		and #$f0
		ora #(BUILTIN_CHARSET / $0400)
		sta $d018
	}
}

!macro copy1000 .src, .dst {
	ldx #250

-	lda .src - 1, x
	sta .dst  - 1, x
	lda .src + 250 - 1, x
	sta .dst  + 250 - 1, x
	lda .src + 500 - 1, x
	sta .dst  + 500 - 1, x
	lda .src + 750 - 1, x
	sta .dst  + 750 - 1, x
	dex
	bne -
}

!if PLUS4 {
	!macro copy1000_color .src, .dst {
		ldx #250

-		ldy .src - 1, x
		lda color_table_plus4, y
		sta .dst  - 1, x
		ldy .src + 250 - 1, x
		lda color_table_plus4, y
		sta .dst  + 250 - 1, x
		ldy .src + 500 - 1, x
		lda color_table_plus4, y
		sta .dst  + 500 - 1, x
		ldy .src + 750 - 1, x
		lda color_table_plus4, y
		sta .dst  + 750 - 1, x
		dex
		bne -
	}
} else {
	!macro copy1000_color .src, .dst {
		+copy1000 .src, .dst
	}
}


; Used as a temporary pointer
!addr PTR = $45

;-----------------------------------------------------------------------------------------------------------------------
; BASIC launcher (2026 SYS xxxx)
;-----------------------------------------------------------------------------------------------------------------------
!if PLUS4 {
    * = $1001

    !word nextln, 2026     		; Second word is line number
    !byte $9e          			; SYS
    !pet "4109"        			; Address (in string format)
    !byte 0           			; End of instruction
nextln:                                 
    !byte 0, 0         			; End of program
					
    * = 4109                            
} else {                                
    * = $0801                           
					
    !word nextln, 2026     		; Second word is line number
    !byte $9e          			; SYS
    !pet "2064"        			; Address (in string format)
    !byte 0           			; End of instruction
nextln:                                 
    !byte 0, 0         			; End of program

    * = 2064
}


;-----------------------------------------------------------------------------------------------------------------------
; INCLUDES
;-----------------------------------------------------------------------------------------------------------------------
	jmp start
	
!source "wic64.h"
!source "wic64.asm"

!ifdef ENABLE_MUSIC {
	!source "tune.asm"  ; load autogenerated tune info
}


;-----------------------------------------------------------------------------------------------------------------------
; PROGRAM START
;-----------------------------------------------------------------------------------------------------------------------
start:
	lda #0
	sta borderColor
	sta backgroundColor

	jsr KRN_SCNCLR
	
	lda #08   							; Disable C= + shift to switch charset
	jsr KRN_BSOUT

	+set_charset portal_charset

!if 0 {
	lda $02			; Just an unused zero-page byte (on C64)
	cmp #42
	beq bc
}

	; Display splash screen data
	+copy1000 infotext, char_dest_1
	+copy1000_color infocolor, color_dest_1
	;~ +set_screen_ram screen_ram_1
	
@wicinit:
	+wic64_dont_disable_irqs
	+wic64_detect                       ; detect wic64 device and firmware
	bcs @no_wifi             			; carry set => wic64 not present or unresponsive
	bne @legacy_firmware                ; zero flag clear => legacy firmware detected

@musicinit:
!ifdef ENABLE_MUSIC {
!if PLUS4 {
	jsr detect_sid
	bcc @proceed

	lda #<@no_sid_msg
	sta PTR
	lda #>@no_sid_msg
	sta PTR + 1
	jsr @show_error
	jmp @proceed
	
@no_sid_msg:
	!scr " No SIDcard detected, music will be off ", $00
}
}

	; All good, proceed!
@proceed:
	jmp @wait_for_key

@no_wifi:
	lda #<@no_wifi_msg
	sta PTR
	lda #>@no_wifi_msg
	sta PTR + 1
	jsr @show_error
	jmp @quit
	
@no_wifi_msg:
	!scr "           WiC64 not detected           ", $00

@legacy_firmware:
	lda #<@legacy_firmware_sg
	sta PTR
	lda #>@legacy_firmware_sg
	sta PTR + 1
	jsr @show_error
	jmp @quit
	
@legacy_firmware_sg:
	!scr "         WiC64 firmware too old         ", $00

@show_error:
	; Print error message
	@err_pos = 22 * 40
	ldy #0
-	lda (PTR), y
	beq +
	sta char_dest_1 + @err_pos, y
	lda #$c2							; Flashing light red
	sta color_dest_1 + @err_pos, y
	iny
	jmp -
+	rts

	; Patch "Press a key" message
@quit:
!ct scr {
	@pos = 24 * 40 + 25
	lda #'a'
	sta char_dest_1 + @pos
	lda #'b'
	sta char_dest_1 + @pos + 1
	lda #'o'
	sta char_dest_1 + @pos + 2
}

	; Wait for keypress
-	jsr KRN_GETCHAR
	beq -
		
	; Back to default charset (in ROMs)
	+set_default_charset
	jmp quit
	
	
	; Wait for a key to be pressed or about 25 seconds
@wait_for_key:
	;~ lda #1
	;~ sta $0289			; Maximum length of keyboard buffer. 
	;~ lda #127
	;~ sta $028a			; Keyboard repeat switch.
	jsr KRN_GETCHAR
	bne @go

	inc intro_timeout_counter
	bne @wait_for_key
	inc intro_timeout_counter + 1
	bne @wait_for_key
	inc intro_timeout_counter + 2
	bne @wait_for_key

@go:
	jsr KRN_SCNCLR

	; Back to default charset (in ROMs)
	+set_default_charset

	lda #'1'   								; enforce blank canvas on re-run
	sta urlInitParam

	; Setup interrupts
	sei
	
	lda #<irq           
	ldx #>irq
	sta IRQ_VECTOR
	stx IRQ_VECTOR + 1

!if PLUS4=0 {
	; Enable raster interrupt signals from VIC
	lda #$01
	sta $d01a

	; set rasterline where interrupt shall occur
	lda #$00
	sta $d012
	lda $d011					; MSB
	ora #%10000000
	sta $d011

	; Disable KERNAL timer
	lda #$7f
	sta $dc0d
	lda $dc0d

	; Clear pending interrupts
	lda #$ff
	sta $d019
}

!ifdef ENABLE_MUSIC {
	; Set up the tune
	lda #$00            				; clear a x and y to initialize tune
	tax
	tay
	jsr sid_initAddress 				; initialize the SID tune by calling the init routine
	
!if PLUS4 {
	; The SID song uses some locations in the zero page that mess with the KERNAL IRQ handler, save those values
	lda BNKSEL
	sta sidtmp_bnksel
	lda CURBNK
	sta sidtmp_curbnk
}
}

	cli                 				; enable interrupts

loop:
!ifndef ENABLE_TESTING {
	+wic64_execute url, data, 8
	lda #'0'							; Will not clear previous bots
	sta urlInitParam
}
	jsr copy
	jsr delay
	bcs quit
	jmp loop

quit:
	; Restore default IRQ handler
	sei
	
	lda #<KERNAL_IRQ           
	ldx #>KERNAL_IRQ
	sta IRQ_VECTOR
	stx IRQ_VECTOR + 1

!if PLUS4=0 {
	lda #$00            				; Disable all VIC-II interrupts (raster, sprite, etc.)
	sta $d01a
	lda $d019           				; Acknowledge any pending VIC-II interrupt flags
	sta $d019
}

	+set_screen_ram screen_ram_1
	jsr KRN_SCNCLR
	jsr KRN_IOINIT
	jsr KRN_RESTOR
	jsr KRN_CINT

	cli

	; Restore default screen colors
	lda #DEFAULT_BACKGROUND_COLOR
	sta backgroundColor
	lda #DEFAULT_BORDER_COLOR
	sta borderColor
	
	lda #09   							; Re-enable C= + shift to switch charset
	jsr KRN_BSOUT
	
	rts

;-----------------------------------------------------------------------------------------------------------------------
delay:
;-----------------------------------------------------------------------------------------------------------------------
	; Load value
	lda #50
	sta timer

	; Value is decreased at every raster interrupt, i.e. once per frame
-	jsr KRN_GETCHAR
	cmp #KEY_SPACE
	bne +
	sec
	rts
+	lda timer
	bne -
	
	clc
	rts

;-----------------------------------------------------------------------------------------------------------------------
copy:
;-----------------------------------------------------------------------------------------------------------------------
; Copy the fetched screen data to the non-active screen RAM, and make it active at the proper moment
;-----------------------------------------------------------------------------------------------------------------------
	!addr color_data = data + 1000

	lda active_screen_ram
	beq @use_screen_2

@use_screen_1:
	+copy1000 data, char_dest_1
	jsr @rasterWait
	+copy1000_color color_data, color_dest_1
	+set_screen_ram screen_ram_1
	dec active_screen_ram
	rts
	
@use_screen_2:
	+copy1000 data, char_dest_2
	jsr @rasterWait
	+copy1000_color color_data, color_dest_2
	+set_screen_ram screen_ram_2
	inc active_screen_ram
	rts

@rasterWait:
	; Wait for first line of bottom border
!if PLUS4 {
	lda #$cc
} else {
	lda #$fb
}
-	cmp TED_VRASTER
	bne -
	rts
	
;-----------------------------------------------------------------------------------------------------------------------
detect_sid:
;-----------------------------------------------------------------------------------------------------------------------
; Thanks Csabo!
;-----------------------------------------------------------------------------------------------------------------------
	lda #0
	ldy #24
-	ora SID_BASE,y						; The first 25 SID registers always return 0 when read
	dey
	bpl -
	cmp #0								; If any non-zero values are found, there's no SID
	bne @no_sid
	clc
	rts

@no_sid:
	sec
	rts
	
;-----------------------------------------------------------------------------------------------------------------------
irq:
;-----------------------------------------------------------------------------------------------------------------------
!ifdef ENABLE_TESTING {
	inc borderColor
}

!ifdef ENABLE_MUSIC {
!if PLUS4 {
	; Save values of key ZP locations that will be messed up by the SID play routine
	lda CURBNK
	pha
	lda sidtmp_curbnk
	sta CURBNK
	
	lda BNKSEL
	pha
	lda sidtmp_bnksel
	sta BNKSEL
}

	jsr sid_playAddress					; Play the music

!if PLUS4 {
	; Restore values of ZP locations
	lda BNKSEL
	sta sidtmp_bnksel
	pla
	sta BNKSEL
	
	lda CURBNK
	sta sidtmp_curbnk
	pla
	sta CURBNK

	; Copy C64 SID range to +4
	+bank_in_ram						; SID data was written to RAM beyond ROMs
	ldx #25								; Registers after 25 are read-only
-	lda SID_BASE_C64,x
	sta SID_BASE,x
	;~ sta $fe80,x						; Uncomment to support Hungarian SIDcards
	dex
	bpl -
	+bank_in_roms
}
}

!if PLUS4=0 {
	; Clear all interrupt flags
	lda #$ff
	sta $d019
}

	; Tick down timer
	lda timer
	beq @irqend
	dec timer

@irqend:
!ifdef ENABLE_TESTING {
	dec borderColor
}
	jmp KERNAL_IRQ

sidtmp_bnksel:
	!byte 0
sidtmp_curbnk:
	!byte 0


;-----------------------------------------------------------------------------------------------------------------------
; DATA & STRINGS
;-----------------------------------------------------------------------------------------------------------------------
intro_timeout_counter:
	!byte 0, 0, 253						; Results in about 25 secs
timer:
	!byte 0
	
no_wifi:
	!pet "wic64 interface not found", $0d, $00
	
active_screen_ram:
	!byte 0

url:
	!byte "R", WIC64_HTTP_GET, <(urlEnd - url - 4), >(urlEnd - url - 4)		; 4 is size of header
	!text "http://petsciibots.shnbk.de/wic/?mac=%mac&init="
urlInitParam:
	!byte $30
urlEnd:

	; Here the -64 is for switching to the "Uppercase + GFX" set (which actually contains lower and upper case in the
	; WiC64 font), while |128 is for obtaining reverse colors
infotext
	!scr $68,$69,$69,$69,$69,$69,$69,$6a,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40
!if PLUS4 {
	!pet $60,$61,$62,$63,$64,$65,$66,$67,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,'P','E','T','S','C','I','I','B','O','T','S',$40,'V',('i' - 64) | 128,('e' - 64) | 128,('w' - 64) | 128,('e' - 64) | 128,('r' - 64) | 128,$40
} else {
	!pet $60,$61,$62,$63,$64,$65,$66,$67,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,27,28,29,30,31,34,34,35,36,37,38,$40,39,40,41,42,41,43,$40
}
	!scr $6b,$6c,$6c,$6c,$6c,$6c,$6c,$6d,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$6f
	!scr "                                        "
	!scr "This is just a small viewer that loads  "
	!scr "and displays PETSCIIBOTS from the       "
	!scr "Internet. It will also play music, in   "
	!scr "order to show that network transfers do "
	!scr "not interfere with interrupts.          "
	!scr "                                        "
	!scr " Version:                               "
	!scr "  " + VERSION_STR + "                                 "
	!scr "                                        "
	!scr " Graphics:                              "
	!scr "  Fantastic Italian Research Enterprise "
	!scr "  http://plus4world.com/sd.php?pid=24036"
	!scr "  http://csdb.dk/release/?id=231072     "
	!scr "                                        "
	!scr " Code:                                  "
	!scr "  2023 Schorsch3000                     "
	!scr "  2025-2026 SukkoPera                   "
	!scr "                                        "
	!scr "                                        "
	!scr "                                        "
	!scr "     ",91,92," Press any key to start! ",93,94,"      "

infocolor
	!scr $0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c
	!scr $0c,$04,$0e,$0e,$0e,$02,$02,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c
	!scr $0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c
	!scr $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
	!scr $07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07
	!scr $07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07
	!scr $07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07
	!scr $07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07
	!scr $07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07
	!scr $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
	!scr $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
	!scr $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
	!scr $0f,$0f,$0f,$0f,$0a,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
	!scr $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
	!scr $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
	!scr $06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06
	!scr $06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06
	!scr $0a,$0a,$0a,$0a,$0a,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
	!scr $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
	!scr $0f,$0f,$0a,$0a,$0a,$0a,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
	!scr $0f,$0f,$0a,$0a,$0a,$0a,$0a,$0a,$0a,$0a,$0a,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
	!scr $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
	!scr $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
	!scr $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
	!scr $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03

!if PLUS4 {
color_table_plus4:
	;~ !byte $00, $71, $32, $63, $44, $55, $36, $77, $48, $29, $4b, $31, $51, $7f, $46, $61		; Sukko V1
	;~ !byte $00, $71, $32, $53, $34, $4f, $2e, $67, $38, $29, $42, $31, $41, $6f, $46, $51		; Csabo
	;~ !byte $00, $71, $32, $53, $34, $5f, $1e, $69, $48, $09, $42, $31, $41, $6f, $46, $51		; TRP
	!byte $00, $71, $32, $63, $34, $4f, $36, $77, $38, $29, $42, $31, $41, $6f, $46, $51		; Sukko V2, mix of the above
}

!if PLUS4 {
	!align 1023, 0, $ea
} else {
	; Charset must be aligned on 2k on C64, but $1000 and $1800 are not usable, so make sure we go beyond that
	!align 2047, 0, $ea
	!if (* <= $1800) {
		* = * + 1
		!align 2047, 0, $ea
	}
}
portal_charset:
	!bin "portalcharset.bin"

data:
!ifdef ENABLE_TESTING {
	!binary "robot_data.bin"
}

!ifdef ENABLE_MUSIC {
	* = sid_loadAddress
	!bin "tune.sid", sid_dataSize, sid_offset
}
