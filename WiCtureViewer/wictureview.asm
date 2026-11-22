; *** WiCtureViewer ***
; Code (C64):              Courage
; Code (C16/+4):           SukkoPera
; Code (Backend):          Schorsch3000
; Idea:                    KiWi
; Charset:                 Retrofan
; Support with pictures:   CapFuture1975
; Pictures:                various artists
; Compiler used:           C64 Studio by Georg Rottensteiner - https://www.georg-rottensteiner.de/
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
;
;
; All rights reserved.
;
; Redistribution and use in source and binary forms, with or without
; modification, are permitted provided that the following conditions are
; met:
;
; 1. Redistributions of source code must retain the above copyright
;    notice, this list of conditions and the following disclaimer.
;
; 2. Redistributions in binary form must reproduce the above copyright
;    notice, this list of conditions and the following disclaimer in the
;    documentation and/or other materials provided with the
;    distribution.
;
; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
; "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
; LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
; A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
; OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
; SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
; LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
; DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
; THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
; (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
; OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
;
; NOTE: This code was modified for the C16/+4 version, which BROKE it on C64. More work is needed to make it work on
;       both platforms!

; Layout of Multi Botticelli-format files:
; Graphic mode: High-Resolution Bitmap Mode (320 x 200 px, PAR 1:1), Multicolor Bitmap Mode (160 x 200 px, PAR 2:1)
; Attribute Cell Size: 8 x 8 px
; Name         |Size (Hex)|Size (Dec)|Offset (Hex)|Offset (Dec)|Description
; LOAD ADDRESS |$02       |2         |$00         |0           |Load address: $00, $78
; LUMINANCE MAP|$03e8     |1000      |$02         |2           |Foreground pen 0 (**) and 1 (*) luminance
; PADDING      |$12       |18        |$03ea       |1002        |Padding to adjust to kB boundary
; SIGNATURE    |$04       |4         |$03fc       |1020        |"MULT": $4d, $55, $4c, $54
; BACKGRND 3   |$01       |1         |$0400       |1024        |Background pen 3 color, value stored to TED + $16
; BACKGRND 0   |$01       |1         |$0401       |1025        |Background pen 0 color, value stored to TED + $15
; COLOR MAP    |$03e8     |1000      |$0402       |1026        |Foreground pen 0 (*) and 1 (**) color
; PADDING      |$18       |24        |$07ea       |2026        |Padding to adjust to kB boundary
; BITMAP       |$1f40     |8000      |$0802       |2050        |Bitmap data
;
; (*) Low nibble, (**) High nibble
;
; Note: The BACKGRND 3 & BACKGRND 0 colors are stored in reverse nibble order, so the lower and upper 4 bits must be 
; swapped before you set the value to the TED.
; Note2: No, I don't think so!
;
; File size: 10050 bytes
;
; Memory layout:
; 1000-2fff Code
; 3400: Charset
; 3800-$5f42: Bitmap 1 data
; 7800-$9f42: Bitmap 2 data


;~ ENABLE_TESTING = 1

!addr {
	NDX = $ef							; Keyboard queue length ($c6 on C64)
	RPTFLAG = $0540						; ($028A on C64)

	PRIMM = $ff4f
	SCNCLR = $c567

	SCREEN_RAM = $0c00
	COLOR_RAM = $0800
}

TIMEOUT = 20							; s

; Buffer swap is triggered at the end of the "useful" screen ($cc, use 250 on C64)
SWAP_BUFFER_LINE = 204

; IRQ is triggered shortly afterwards
IRQ_LINE = 208

; Double buffer for the downloaded images. Data is fetched directly at the BASE address and then the display is pointed
; there. For this reason, there are constraints on the alignment. Images are in Multi Botticelli format, so the
; different data segments will magically end up aligned correctly.
!addr {
	BITMAP1_BASE = BITMAP1_LUM_DATA - 2				; Offset load address so that bitmap data is aligned on $800
	BITMAP1_LUM_DATA = $3800						; Must be aligned on $800
	BITMAP1_SIGNATURE = BITMAP1_BASE + $03fc
	BITMAP1_BG_COLOR3 = BITMAP1_BASE + $0400
	BITMAP1_BG_COLOR0 = BITMAP1_BASE + $0401
	BITMAP1_COLOR_DATA = BITMAP1_BASE + $0402		; Must be aligned on $2000
	BITMAP1_DATA = BITMAP1_BASE + $0802

	BITMAP2_BASE = BITMAP2_LUM_DATA - 2
	BITMAP2_LUM_DATA = $7800
	BITMAP2_SIGNATURE = BITMAP2_BASE + $03fc
	BITMAP2_BG_COLOR3 = BITMAP2_BASE + $0400
	BITMAP2_BG_COLOR0 = BITMAP2_BASE + $0401
	BITMAP2_COLOR_DATA = BITMAP2_BASE + $0402
	BITMAP2_DATA = BITMAP2_BASE + $0802
}

;-----------------------------------------------------------------------------------------------------------------------
; DEFINE-ONLY INCLUDES
;-----------------------------------------------------------------------------------------------------------------------
!source "wic64.h"
!source "ted.asm"


;-----------------------------------------------------------------------------------------------------------------------
; BASIC LAUNCHER (2025 SYS xxxx)
;-----------------------------------------------------------------------------------------------------------------------
	* = $1001

	!word nextln, 2025     		; Second word is line number
	!byte $9e          			; SYS
	!pet "4109"        			; Address (in string format)
	!byte 0           			; End of instruction
nextln:
	!byte 0, 0         			; End of program

;-----------------------------------------------------------------------------------------------------------------------
; PROGRAM START
;-----------------------------------------------------------------------------------------------------------------------
	* = 4109
start:
	lda #$0b
	sta TED_CFG1
	lda #$00
	sta TED_BORDER
	sta TED_BACKGROUND
	;~ sta $0286				; Text color
	;~ jsr $e536
!if PLUS4 {
	jsr SCNCLR
}

	;~ lda #$01
	;~ sta $0289				; Maximum number of Bytes in Keyboard Buffer
	lda #$7f
	sta RPTFLAG					; Flag: Repeat keys

!if PLUS4=0 {
	lda #$37
	sta $01
}

	; Set charset base addr (only 6 high bits, must thus be aligned to 1024 bytes)
	lda TED_CFG4
	and #((1 << 1) | (1 << 0))
	ora #(>charset & 0xFC)
	sta TED_CFG4

	; Enable charset from RAM
	lda TED_CFG3
	and #!(1 << 2)
	sta TED_CFG3

!ifndef ENABLE_TESTING {
	;~ +wic64_dont_disable_irqs
	+wic64_detect
	bcs device_not_present                  ; carry set => wic64 not present or unresponsive
	bne legacy_firmware                     ; zero flag clear => legacy firmware detected
}
	jmp done

device_not_present
legacy_firmware
	ldx #09
	ldy #0
	clc
	jsr $fff0							; PLOT

!if PLUS4 {
	jsr oldfirmware
} else {
	lda #<oldfirmware
	ldy #>oldfirmware
	jsr $ab1e
}

	;~ lda #$13  ;$d018
	;~ ;and #%11110001
	;~ ;ora #%00000010
	;~ sta $d018

	lda #$1b
	sta TED_CFG1

	lda #$00
	sta NDX
-	jsr $ffe4
	beq -
	jmp ($fffc)							; CPU reset vector


oldfirmware
!if PLUS4 {
	lda #$f1
	sta TED_BACKGROUND
	lda #$ee
	sta TED_BORDER
	jsr PRIMM
}
	!text 150, "       wic64 INTERFACE NOT FOUND", 13
	!text "       OR FIRMWARE IS OUTDATED!",13,13,159
	!text "           pLEASE UPDATE AT",13,5
	!text "        www.wic64.com/flasher",0
!if PLUS4 {
	rts
}

done
!if PLUS4=0 {
	dec $01
}
-
	; Fetch number of available images
!ifndef ENABLE_TESTING {
	+wic64_execute command, response, 9

	bcc +
	lda #$02
	sta TED_BORDER
	jmp -

+
	lda #$00
	sta TED_BORDER
	lda #urlsize2
	sta command+2
}
	ldx #$03
-
	lda response,x
	sta lastpicture,x
	dex
	bpl -

	; Show welcome screen
	ldx #$00
-	
	lda infotext,x
	sta SCREEN_RAM,x
	lda infocolor,x
	tay
	lda color_table_plus4, y
	sta COLOR_RAM,x
	lda infotext+$0100,x
	sta SCREEN_RAM + $0100,x
	lda infocolor+$0100,x
	tay
	lda color_table_plus4, y
	sta COLOR_RAM + $0100,x
	lda infotext+$0200,x
	sta SCREEN_RAM + $0200,x
	lda infocolor+$0200,x
	tay
	lda color_table_plus4, y
	sta COLOR_RAM + $0200,x
	lda infotext+$02e8,x
	sta SCREEN_RAM + $02e8,x
	lda infocolor+$02e8,x
	tay
	lda color_table_plus4, y
	sta COLOR_RAM + $02e8,x
	dex
	bne -

	; Restore default screen/char location
	;~ lda #$13 ;$d018
	;and #%11110001
	;ora #%00000010
	;~ sta $d018

	; Turn screen back on
	lda #$1b
	sta TED_CFG1

!ifndef ENABLE_TESTING {
	; Wait for keypress
-	jsr $ffe4							; OK on +4 too
	beq -

	lda $c6								; Most recent keyboard code before the last keyboard scan was performed using the SCNKEY routine
	sta repeatcheck
}

	; Set up interrupts & such
	sei

	;~ lda #$00
	;~ sta $0286
	;~ jsr $e536

	lda TED_CFG1
	and #%11101111						; Screen off
	ora #%01000000						; Enable Extended Color Mode
	sta TED_CFG1

	; Disable C64 KERNAL timer
!if PLUS4=0 {
	lda #$7f
	sta $dc0d
}

	; Setup IRQ
	lda #<irq
	sta $fffe
	lda #>irq
	sta $ffff

!if PLUS4 {
	; Enable raster interrupts
	lda #IRQ_LINE
	sta TED_VRASTER_INT
	lda TED_IRQ_MASK
	ora #((1 << 1))	; Enable raster IRQs + clear rasterline MSB
	sta TED_IRQ_MASK

	; Clear pending interrupts
	lda $ff09
	sta $ff09
} else {
	lda $d01a
	ora #%00000001
	sta $d01a

	lda #IRQ_LINE
	sta $d012

	lda $d011
	and #%01111111
	sta $d011

	lda #<nmi
	sta $0318
	lda #>nmi
	sta $0319

	; Clear pending interrupts
	rol $d019
	lda $dc0d
	lda $dd0d
}
	cli

	; FIXME: What is this?
	;~ ldx #$00
;~ -
	;~ lda $0c00,x
	;~ sta $8c00,x
	;~ lda $0ce0,x
	;~ sta $8ce0,x
	;~ inx
	;~ cpx #$e0
	;~ bne -

	jmp startviewer

;-------------------------------------------------------------------------------------------------------

; Occurs at end of the visible screen
irq
	pha
	txa
	pha
	tya
	pha

	;~ lda TED_BORDER
	;~ pha
	;~ lda #$52
	;~ sta TED_BORDER

	lda TED_IRQ
	;~ and #(1 << 1)
	;~ beq @irqend

	; Acknowledge interrupt
	sta TED_IRQ

	; Note that this will reenable interrupts and ROMs, so it's important that it gets called outside of the visible
	; screen (since buffer 2 sits behind the ROMs)
	jsr keyboardcheck

@irqend:
	;~ pla
	;~ sta TED_BORDER

	pla
	tay
	pla
	tax
	pla
	rti

;-------------------------------------------------------------------------------------------------------

keyboardcheck
	sta TED_ENABLE_ROMS
	php
	cli             					; key scan must be interruptable
	jsr $ff9f							; scnkey
	plp
	sta TED_ENABLE_RAM
	lda $c6								; Key pressed
	cmp repeatcheck
	bne +
	rts

+
	sta repeatcheck

	cmp #$40							; No key pressed
	bne +
	rts

!if PLUS4=0 {
+
	cmp #$39             ; arrow left / portal
	bne +
	sta portalbyte
	rts
}


!if PLUS4=0 {
+
	cmp #$21             ; (i)nformation show/hide
	bne +
	lda spritebyte
	eor #%00011111
	sta spritebyte
	sta $d015
	jsr speedtosprite
	rts
}

+
	cmp #$3c             ; space / pause
	bne +
	lda pausebyte
	eor #%00000001
	sta pausebyte
	rts

+
	;~ cmp #$28             ; + speed
	cmp #$36             ; + speed
	bne ++
	lda speedbyte
	cmp #$09
	beq +
	inc speedbyte
	dec delayvalue
+
	rts

++
	;~ cmp #$2b             ; - speed
	cmp #$2e             ; - speed
	bne ++
	lda speedbyte
	cmp #$01
	beq +
	dec speedbyte
	inc delayvalue
+
	rts

++
	cmp #$04             ; F1 + 10
	bne ++
	lda #$01
	sta addbyte
	rts

++
	cmp #$05             ; F3 + 50
	bne ++
	lda #$05
	sta addbyte
	rts

++
	cmp #$06             ; F5 + 100
	bne ++
	lda #$09
	sta addbyte
	rts

++
	cmp #$03             ; F7 + 500
	bne ++
	lda #$0d
	sta addbyte
++
	rts

;-------------------------------------------------------------------------------------------------------

numberaddition
	ldx addbyte
	beq +
	jmp ++

+
	ldx #$03
-
	lda filename,x
	cmp lastpicture,x
	bne +
	dex
	bpl -

	lda #"0"
	sta filename
	sta filename+1
	sta filename+2
	sta filename+3
	rts

+
	ldx #$03
-
	inc filename,x
	lda filename,x
	cmp #$3a
	beq +
	rts
+
	lda #"0"
	sta filename,x
	dex
	jmp -

++
	ldy #$00
	sty addbyte
-
	lda additionbytes,x
	clc
	adc filename,y
	sta filename,y
	inx
	iny
	cpy #$04
	bne -

	ldx #$03
-
	lda filename,x
	cmp #$3a
	bcc +
	sec
	sbc #10
	sta filename,x
	dex
	bmi ++
	inc filename,x
	inx
+
	dex
	bpl -

	ldx #$00
-
	lda filename,x
	cmp lastpicture,x
	bcc +++
	beq +
	jmp ++
+
	inx
	cpx #$04
	bne -
	rts

++
	ldx #$03
	lda #$30
-
	sta filename,x
	dex
	bpl -
+++
	rts

;-------------------------------------------------------------------------------------------------------

startviewer
	; Screen off
	lda #$40
	sta TED_CFG1

	; Multicolor on
!if PLUS4 {
	lda TED_CFG2
	ora #(1 << 4)
	sta TED_CFG2
} else {
	lda #%00011000
	sta $d016

	; Char memory to $2000 and screen memory to $0400
	lda #%00011000
	sta $d018
}

	; Screen off, bitmap mode on
	lda #%00101011
	sta TED_CFG1

	; Bitmap data is in the RAM behind the ROMs, so we disable ROMs from this point
	sta TED_ENABLE_RAM

loadpicture
	lda pausebyte
	beq +
	lda TED_BORDER
	and #$7f
	bne loadpicture						; If we keep setting the border color, we get a strange "glittering" effect
	lda #$32
	sta TED_BORDER
	jmp loadpicture

+	lda #00
	sta TED_BORDER

	lda pointer
	bmi +

	jsr view_bitmap1
	jmp ++
+
	jsr view_bitmap2

++
	; Screen on
	lda TED_CFG1
	ora #%00010000
	sta TED_CFG1

	; Toggle 1st/2nd buffer for next image fetch
	lda pointer
	eor #%10000000
	sta pointer

	; Increase file name/number
	jsr numberaddition

	; Wait a bit
	lda delayvalue
	beq +
	asl
	asl
	asl
	asl
	tax

--
	;~ lda #$f0
	lda #$c1
-	cmp TED_VRASTER
	bne -

	;~ lda #$f1
	lda #$c2
-	cmp TED_VRASTER
	bne -

	dex
	bne --
+
	jmp loadpicture

;----------------------------------------------------------

BOTTICELLI_SIGNATURE:
	!pet "mult"
BOTTICELLI_SIGNATURE_LEN = * - BOTTICELLI_SIGNATURE

view_bitmap1:
!ifndef ENABLE_TESTING {
	+wic64_execute transtimeoutcom
	+wic64_execute servertimeoutcom		; Note this seems to fail in firmware 2.0.0		
	+wic64_execute command, BITMAP1_BASE, TIMEOUT
	bcc @fetched_ok

@fetch_error:
	; Report error somehow (red border)
	lda #$03
	sta TED_BORDER
	jmp view_bitmap1						; Try again

@fetched_ok:
	; Check signature
	ldy #BOTTICELLI_SIGNATURE_LEN - 1
-	lda BITMAP1_SIGNATURE, y
	cmp BOTTICELLI_SIGNATURE, y
	bne @fetch_error
	dey
	bpl -

	lda wic64_response_size				; Make sure response has a decent size
	cmp #$02
	beq @fetch_error
}
	lda #$00
	sta TED_BORDER

	; Wait for proper moment to swap the buffer
	lda #SWAP_BUFFER_LINE
-	cmp TED_VRASTER
	bne -

!if PLUS4 {
	lda #>BITMAP1_LUM_DATA
	sta TED_VRAM
	lda #((1 << 7) | (1 << 6) | ((BITMAP1_DATA >> 13) << 3))
	sta TED_CFG3

	lda BITMAP1_BG_COLOR0
	;~ jsr swap_nibbles
	sta TED_BACKGROUND
	lda BITMAP1_BG_COLOR3
	;~ jsr swap_nibbles
	sta TED_COLOR_1

	rts
} else {
	; Set VIC-II bank #0, $0000-$3FFF, 0-16383
	lda $dd00
	and #%11111100
	ora #%00000011
	sta $dd00

	; TODO: BG

	jmp picnumbertosprite
}

;--------------------------------------------------------------------

view_bitmap2:
!ifndef ENABLE_TESTING {
	+wic64_execute transtimeoutcom
	+wic64_execute servertimeoutcom
	+wic64_execute command, BITMAP2_BASE, TIMEOUT
	bcc @fetched_ok

@fetch_error:
	; Report error somehow (pink border)
	lda #$02
	sta TED_BORDER
	jmp view_bitmap2						; Try again

@fetched_ok:
	; Check signature
	ldy #BOTTICELLI_SIGNATURE_LEN - 1
-	lda BITMAP2_SIGNATURE, y
	cmp BOTTICELLI_SIGNATURE, y
	bne @fetch_error
	dey
	bpl -

	lda wic64_response_size				; Make sure response has a decent size
	cmp #$02
	beq @fetch_error
}
	lda #$00
	sta TED_BORDER

	; Wait for proper moment to swap the buffer
	lda #SWAP_BUFFER_LINE
-	cmp TED_VRASTER
	bne -

!if PLUS4 {
	lda #>BITMAP2_LUM_DATA
	sta TED_VRAM
	lda #((1 << 7) | (1 << 6) | ((BITMAP2_DATA >> 13) << 3))
	sta TED_CFG3

	lda BITMAP2_BG_COLOR0
	;~ jsr swap_nibbles
	sta TED_BACKGROUND
	lda BITMAP2_BG_COLOR3
	;~ jsr swap_nibbles
	sta TED_COLOR_1
	
	rts
} else {
	; Set VIC-II bank #2, $8000-$BFFF, 32768-49151
	lda $dd00
	ora #%00000001
	and #%11111101
	sta $dd00
}

;~ swap_nibbles:
	;~ asl
	;~ adc #$80
	;~ rol
	;~ asl
	;~ adc #$80
	;~ rol
	;~ rts

;-----------------------------------------------------------------------------------------------------------------------
; INCLUDES
;-----------------------------------------------------------------------------------------------------------------------
!source "wic64.asm"

* = $3400								; Just before the image buffers
charset:
	!bin "portalcharset.bin"


;-----------------------------------------------------------------------------------------------------------------------
; DATA & STRINGS
;-----------------------------------------------------------------------------------------------------------------------
color_table_plus4:
	;~ !byte $00, $71, $32, $63, $44, $55, $36, $77, $48, $29, $4b, $31, $51, $7f, $46, $61		; Sukko V1
	;~ !byte $00, $71, $32, $53, $34, $4f, $2e, $67, $38, $29, $42, $31, $41, $6f, $46, $51		; Csabo
	;~ !byte $00, $71, $32, $53, $34, $5f, $1e, $69, $48, $09, $42, $31, $41, $6f, $46, $51		; TRP
	!byte $00, $71, $32, $63, $34, $4f, $36, $77, $38, $29, $42, $31, $41, $6f, $46, $51		; Sukko V2, mix of the above



transtimeoutcom
	!byte "R", WIC64_SET_TRANSFER_TIMEOUT, $01, $00, TIMEOUT
servertimeoutcom
	!byte "R", WIC64_SET_REMOTE_TIMEOUT, $01, $00, TIMEOUT
command
	!text "R", WIC64_HTTP_GET, <urlsize1, >urlsize1
url
!if PLUS4 {
	!text "http://x.wic64.net/koa/p4/"
} else {
	!text "http://x.wic64.net/koa/"
}
urlsize1 = *-url
filename
!if PLUS4 {
	!text "0000.bot"
} else {
	!text "0000.koa"
}
urlsize2 = *-url

;------------------------------------------------------------------------------

repeatcheck
	!byte $00

pausebyte
	!byte $00

speedbyte
	!byte $09

addbyte
	!byte $00

lastpicture
	!scr "0000"

pointer
	!byte $1f

delayvalue
	!byte $00

picnumbercount
	!byte $04

additionbytes
	!byte $00
	!byte $00,$00,$01,$00
	!byte $00,$00,$05,$00
	!byte $00,$01,$00,$00
	!byte $00,$05,$00,$00

infotext
	!scr $68,$69,$69,$69,$69,$69,$69,$6a,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40
	!pet $60,$61,$62,$63,$64,$65,$66,$67,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,29,31,27,36,37,34,30,28,31,30,38,30,34,$40
	!scr $6b,$6c,$6c,$6c,$6c,$6c,$6c,$6d,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$6f
	!scr "                                        "
	!scr "This is just a small viewer that loads  "
	!scr "and displays uncompressed multicolor    "
	!scr "bitmap images from the web space.       "
	!scr "                                        "
	!scr "     ",91,92," Press any key to start! ",93,94,"      "
	!scr "                                        "
	!scr "                                        "
	!scr "SPACE  Pause/Resume                     "
	!scr "                                        "
	!scr "  +/-  Switch pictures faster/slower    "
	!scr "                                        "
	!scr "F1-F7  Skip 10/50/100/500 pictures      "
	!scr "                                        "
	;~ !scr "    I  Hide/Show information            "
	!scr "                                        "
	!scr "                                        "
	;~ !scr "    ",95,"  Return to WiC64-Portal           "
	!scr "                                        "
	!scr "                                        "
	!scr "                                        "
	!scr "                                        "
	!scr "                                        "
	!scr "   Great pictures by various artists!   "

infocolor
	!scr $0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c
	!scr $0c,$04,$0e,$0e,$0e,$02,$02,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c
	!scr $0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c
	!scr $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
	!scr $07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07
	!scr $07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07
	!scr $07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07
	!scr $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
	!scr $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
	!scr $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
	!scr $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
	!scr $0a,$0a,$0a,$0a,$0a,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
	!scr $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
	!scr $0f,$0f,$0a,$0a,$0a,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
	!scr $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
	!scr $0a,$0a,$0a,$0a,$0a,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
	!scr $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
	!scr $0f,$0f,$0f,$0f,$0a,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
	!scr $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
	!scr $0f,$0f,$0f,$0f,$0a,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
	!scr $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
	!scr $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
	!scr $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
	!scr $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
	!scr $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03

response
!ifdef ENABLE_TESTING {
	!text "1010"

* = BITMAP1_BASE
	!binary "img/m.rockband.prg"

* = BITMAP2_BASE
	!binary "img/m.sc. fiction.prg"
}
