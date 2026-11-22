
; For debugging!
;~ DEBUG = 1
;~ SHORTCUT = 1							; Jump straight into menu

ENABLE_MUSIC = 1						; Also enables joystick support

ENABLE_RAMEXP = 1

!addr {
	SCREEN_RAM = $0c00
	COLOR_RAM = $0800
	
	COLOR_TABLE_ROM = $e143
	COLOR_TABLE_RAM = $0113
	
	IRQ = $0314
	
	SCNCLR = $c567
	PRIMM = $ff4f
	SCNKEY = $ff9f
	CHROUT = $ffd2
	GETIN = $ffe4
	PLOT = $fff0

	KEYBUF = $c6						; Most recent keyboard code before the last keyboard scan was performed using the GETIN routine
	NDX = $ef							; Keyboard queue length ($c6 on C64)
	RPTFLAG = $0540						; ($028A on C64)
	
	KERNAL_IRQ = $ce0e					; Default KERNAL IRQ handler
	KERNAL_IRQRET = $fcbe				; KERNAL's irqret
	KERNAL_VBLANK = $ce42				; Default VBlank IRQ handler
	
	ENQUEUE_KEY = $dc1e					; Part of KERNAL's scnkey routine that pushes a pressed key into the keybuffer
}

; ZP variables - Apart from the pointers, these don't actually need to be in ZP
* = $d0
PTR_DATA: * = * + 2
PTR_PAYLOAD: * = * + 2
HAVE_WIFI: * = * + 1
!ifdef ENABLE_RAMEXP {
HAVE_RAMEXP: * = * + 1
}
!ifdef ENABLE_MUSIC {
MUSIC_ON: * = * + 1
}
SELECTED: * = * + 1
FIRST_DISPLAYED: * = * + 1
TEMP1: * = * + 1
TEMP2: * = * + 1
TEMP3: * = * + 1
TEMP4: * = * + 1

PAYLOAD_RECORD_LEN = 6
MAX_PAYLOAD_RECORDS = 70
MENU_START_ROW = 4
ENTRIES_PER_PAGE = 20

IRQ_TOP_LINE = 4
IRQ_BOTTOM_LINE = 204							; Visible screen bottom ($cc)

VOLUME_LEVEL_LOW = 180
VOLUME_LEVEL_HIGH = 0
VOLUME_STEP = 9

;-----------------------------------------------------------------------------------------------------------------------
; MACROS
;-----------------------------------------------------------------------------------------------------------------------
!ifdef ENABLE_RAMEXP {
!macro set_ram_bank .bank {
!if (.bank > 63) {
	!error "Max bank is 63"
}
	ldx #(H_BOUNDARY_4000 | H_TED_MONOBANK | .bank)
	stx HANNES_CTL
}

!macro set_default_ram_bank {
	+set_ram_bank 63					; Works correctly for any expansion size
}
}

;-----------------------------------------------------------------------------------------------------------------------
; DEFINE-ONLY INCLUDES
;-----------------------------------------------------------------------------------------------------------------------
wic64_include_load_and_run = 1
!source "wic64.h"
!source "ted.asm"
!source "!playerv.asm"


; BASIC launcher
* = $1001 ; 2026 SYS 4109 ($100d)
!zone launcher {
	!word .nextline			; Pointer to next BASIC program line
	!word 2026   			; Line number
	!byte $9e          		; SYS
	!pet "4109"        		; Address (in string format)
	!byte 0            		; End of instruction
.nextline:
	!byte 0, 0         		; End of BASIC program
}

* = 4109
start:
	; Restore default colors, overwritten by exomizer (Thanks Csabo!)
	ldx #15
-	lda COLOR_TABLE_ROM, x
	sta COLOR_TABLE_RAM, x
	dex
	bpl -
	
	; Although, let's update the red to the more pastel-like one we use when writing directly to color RAM
	lda #$42
	sta COLOR_TABLE_RAM + 2

	; Also fix this other exomizer artifact which prevents re-running the program, grrrr!
	ldx #$00
	stx $1000

!ifdef ENABLE_MUSIC {
    lda #1
    sta MUSIC_ON
    jsr PLAYER_INIT
}

!ifdef ENABLE_MUSIC {
	; Switch to custom IRQ routing to handle music
	jsr install_irq
}

	jsr init_screen
	
	; Other misc initializations
	lda #$ff
	sta SELECTED

	; Show welcome screen
!ifdef SHORTCUT {
	lda #1
	sta HAVE_WIFI
	;~ jsr fetch						; How come this is not necessary?
	jsr parse
	jmp @show_menu
}
	
	ldx #0
-	lda splash_text,x
	sta SCREEN_RAM,x
	lda splash_color,x
	sta COLOR_RAM,x
	lda splash_text+$0100,x
	sta SCREEN_RAM + $0100,x
	lda splash_color+$0100,x
	sta COLOR_RAM + $0100,x
	lda splash_text+$0200,x
	sta SCREEN_RAM + $0200,x
	lda splash_color+$0200,x
	sta COLOR_RAM + $0200,x
	lda splash_text+$02e8,x
	sta SCREEN_RAM + $02e8,x
	lda splash_color+$02e8,x
	sta COLOR_RAM + $02e8,x
	dex
	bne -
	
!ifdef ENABLE_RAMEXP {
	; Check for RAM expansion
	lda #0
	sta HAVE_RAMEXP
	jsr hannes_detect
	cmp #1
	beq +
	inc HAVE_RAMEXP
!ifdef DEBUG {
	lda #('H' | 128)
	sta SCREEN_RAM + 39
}
+
}

	; Init WiC64 interface
	lda #0
	sta HAVE_WIFI
!ifndef DEBUG {
	+wic64_dont_disable_irqs
	+wic64_detect
	bcs @no_wifi                  		; Carry set => WiC64 not present or unresponsive
	bne @legacy_firmware                ; Zero flag clear => Legacy firmware detected
}
	inc HAVE_WIFI
	jmp @fetch_list

@no_wifi:
	lda #<@no_wifi_msg
	sta PTR_DATA
	lda #>@no_wifi_msg
	sta PTR_DATA + 1
	jmp @show_error
	
@no_wifi_msg:
	!scr "  WiC64 not detected :(", $00

@legacy_firmware:
	lda #<@legacy_firmware_sg
	sta PTR_DATA
	lda #>@legacy_firmware_sg
	sta PTR_DATA + 1
	jmp @show_error
	
@legacy_firmware_sg:
	!scr "WiC64 firmware too old :(", $00

@show_error:
	; Print error message
	@err_pos = 21 * 40 + 7
	ldy #0
-	lda (PTR_DATA), y
	beq @patch_pressakey
	sta SCREEN_RAM + @err_pos, y
	lda #$c2							; Flashing light red
	sta COLOR_RAM + @err_pos, y
	iny
	jmp -

	; Patch "Press a key" message
@patch_pressakey:
!ct scr {
	lda #'a'
	sta @quit
	lda #'b'
	sta @quit + 1
	lda #'o'
	sta @quit + 2
}

	jmp @show_pressakey
	
@msg_fetch:
	!scr "        Fetching release list...        ", $00
	
@msg_parse:
	!scr "           Analyzing list...           ", $00
	
@fetch_list:
!ifdef ENABLE_RAMEXP {
	; We have RAM expansion, cache goes into a dedicated bank
	+set_ram_bank 0						; Switch to the cache bank
}
	jsr cache_check						; Cache available?
	bcc @show_menu						; Yes!

	; No cache available, fetch and apply signature
	; Note this will go into the bank set above, when RAM expansion is present
	lda #<@msg_fetch
	sta PTR_DATA
	lda #>@msg_fetch
	sta PTR_DATA + 1
	jsr .update_status
	jsr fetch
	
	lda #<@msg_parse
	sta PTR_DATA
	lda #>@msg_parse
	sta PTR_DATA + 1
	jsr .update_status
	jsr parse
	
	; Now that data is fetched and parsed, sign it
	jsr cache_sign

+	lda #($63 | $80)					; Blinking cyan
	sta .status_msg_color
	jmp @show_pressakey

	; Print "Press a key" message
@show_pressakey:
	lda #<@presskey_msg
	sta PTR_DATA
	lda #>@presskey_msg
	sta PTR_DATA + 1
	jsr .update_status
	
	jmp @wait_key

@presskey_msg:
	!scr "     ", 91, 92," Press any key to "
@quit:
	!scr "start! ", 93, 94, " ", $00
	
	; Wait for keypress
@wait_key:
-	jsr GETIN
	beq -

@show_menu:
	lda HAVE_WIFI
	beq @pre_end

	lda #0
	sta FIRST_DISPLAYED
	
    jsr menu

@pre_end:
!ifdef ENABLE_MUSIC {
    jsr fade_music_out
	
	; Restore default IRQ handler
	jsr remove_irq
}
	
    lda SELECTED						; Was a payload selected?
    cmp NPAYLOADS
    bcc @start_payload					; Yes!

	; No, leave
	lda #$05							; White
	jsr CHROUT
	jsr SCNCLR
    rts

@start_payload:
    jsr start_payload
    
@handle_failure:
    ; start_payload will not return if it managed to do its job, we only regain control if it failed, in which case it
    ; will have printed a message to press a key, so let's just go back to the menu
!ifdef ENABLE_MUSIC {
	jsr install_irq
	jsr fade_music_in
}
	jsr init_screen

	ldx #MENU_START_ROW					; Row
	ldy #0								; Col
	clc									; Set position
	jsr PLOT
		
	jsr PRIMM
	!pet $1c, "Transfer failed :(", $0d, $00		; $1c => Red

	; Print a nice message using the status function
	; The actual keypress wait will be handled where we return to
	lda #<@backtomenu_msg
	sta PTR_DATA
	lda #>@backtomenu_msg
	sta PTR_DATA + 1
	lda #($63 | $80)					; Blinking cyan
	sta .status_msg_color
	jsr .update_status
    jmp @wait_key
    
@backtomenu_msg:
	!scr "  ", 91, 92," Press any key to return to menu ", 93, 94, $00

	; Print status message
.update_status:
	@line = 24
	
	ldy #0
-	lda (PTR_DATA), y
	beq +
	sta SCREEN_RAM + @line * 40, y
.status_msg_color = * + 1
	lda #$63							; Light blue
	sta COLOR_RAM + @line * 40, y
	iny
	jmp -
	
+	rts


;-----------------------------------------------------------------------------------------------------------------------
init_screen:
;-----------------------------------------------------------------------------------------------------------------------
	lda #$00
	sta TED_BORDER
	sta TED_BACKGROUND

	; Set charset base addr (only 6 high bits, must thus be aligned to 1024 bytes)
	lda TED_CFG4
	and #((1 << 1) | (1 << 0))
	ora #(>charset & $fc)
	sta TED_CFG4

	; Enable charset from RAM
	lda TED_CFG3
	and #!(1 << 2)
	sta TED_CFG3

	; Restore default color for status messages
	lda #$63
	sta .status_msg_color
	
	jsr clear_screen
	
	rts

!ifdef ENABLE_RAMEXP {
;-----------------------------------------------------------------------------------------------------------------------
hannes_detect:
;-----------------------------------------------------------------------------------------------------------------------
	@MAXSLOTS = 64
	
	H_TED_BANKS = 0
	H_TED_MONOBANK = (1 << 6)

	H_BOUNDARY_1000 = 0
	H_BOUNDARY_4000 = (1 << 7)

	!addr HANNES_CTL = $fd16

	ldx #(@MAXSLOTS - 1)
-	txa
	ora #(H_BOUNDARY_4000 | H_TED_MONOBANK)
	sta HANNES_CTL							; Set bank X
	stx hannes_test_addr
	dex
	bpl -

	lda #((@MAXSLOTS - 1) | H_BOUNDARY_4000 | H_TED_MONOBANK)
	sta HANNES_CTL
	inc hannes_test_addr
	lda hannes_test_addr
	rts
}


;-----------------------------------------------------------------------------------------------------------------------
cache_check:
;-----------------------------------------------------------------------------------------------------------------------
	; First of all, check signature
	ldx #SIGNATURE_LEN
-	lda signature - 1, x
	cmp good_signature - 1, x
	bne @cache_invalid
	dex
	bne -

	; Signature is good, evaluate checksum
	lda #<crc_area_start
	sta PTR_DATA
	lda #>crc_area_start
	sta PTR_DATA + 1
	
	clc
	lda #<crc_area_minus_response_size
	adc response_size
	sta TEMP1
	lda #>crc_area_minus_response_size
	adc response_size + 1
	sta TEMP2
	jsr calc_checksum
	cmp checksum
	bne @cache_invalid
	
	; We have a valid signature
@cache_valid:
	clc
	rts
	
	; No RAM expansion available or cache invalid
@cache_invalid:
	sec
	rts
	
;-----------------------------------------------------------------------------------------------------------------------
calc_checksum:
;-----------------------------------------------------------------------------------------------------------------------
; Our bleeding-edge checksum is a simple sum of all bytes with carry never taken into account
;-----------------------------------------------------------------------------------------------------------------------
	@ptr = PTR_DATA
	@len = TEMP1	; + TEMP2
	@crc = TEMP3
	
	ldy #$00
	sty @crc

@next:
	clc
	lda (@ptr),y
	adc @crc
	sta @crc

	inc @ptr
	bne +
	inc @ptr + 1

	; Fast 16-bit decrement from http://6502org.wikidot.com/software-incdec#toc2
+	lda @len
	bne +
	lda @len + 1
	beq @done
	dec @len + 1
+	dec @len
	jmp @next

@done:
	lda @crc
	rts
	
;-----------------------------------------------------------------------------------------------------------------------
cache_sign:
;-----------------------------------------------------------------------------------------------------------------------
	; Calculate checksum
	lda #<crc_area_start
	sta PTR_DATA
	lda #>crc_area_start
	sta PTR_DATA + 1
	
	clc
	lda #<crc_area_minus_response_size
	adc response_size
	sta TEMP1
	lda #>crc_area_minus_response_size
	adc response_size + 1
	sta TEMP2
	jsr calc_checksum
	
	sta checksum

	; Apply signature
	ldx #SIGNATURE_LEN
-	lda good_signature - 1, x
	sta signature - 1, x
	dex
	bne -

	rts


!ifdef ENABLE_MUSIC {
;-----------------------------------------------------------------------------------------------------------------------
install_irq:
;-----------------------------------------------------------------------------------------------------------------------
	; Enable raster interrupts
	sei
	
	lda #IRQ_TOP_LINE
	sta TED_VRASTER_INT
	lda TED_IRQ_MASK
	ora #(1 << 1)						; Enable raster IRQs + clear rasterline MSB
	and #!(1 << 0)
	sta TED_IRQ_MASK
	
	lda #<irq_top
	sta IRQ
	lda #>irq_top
	sta IRQ + 1
	
	; Clear pending interrupts
	lda TED_IRQ
	sta TED_IRQ
	
	cli

	rts

;-----------------------------------------------------------------------------------------------------------------------
remove_irq:
;-----------------------------------------------------------------------------------------------------------------------
    sei
    lda #<KERNAL_IRQ
    sta IRQ
    lda #>KERNAL_IRQ
    sta IRQ + 1
    cli
    rts

;-----------------------------------------------------------------------------------------------------------------------
fade_music_out:
;-----------------------------------------------------------------------------------------------------------------------
	lda VOLUME							; We'll need to alter the volume, so save the current level for later restoring
	pha
	
--  lda VOLUME
    cmp #VOLUME_LEVEL_LOW
    bcs @done
    clc
    adc #VOLUME_STEP					; Yep, increasing the value actually decreases the volume
    sta VOLUME

    ; Wait for next frame so that fade out takes some time
    lda #IRQ_BOTTOM_LINE
-   cmp TED_VRASTER
    bne -
-	cmp TED_VRASTER
	beq -
    
    bne --

@done:
    lda #0
    sta MUSIC_ON
    sta TED_SND_CTRL				    ; Really make sure music has stopped

	pla									; Restore original volume
	sta VOLUME

    rts

;-----------------------------------------------------------------------------------------------------------------------
fade_music_in:
;-----------------------------------------------------------------------------------------------------------------------
    lda VOLUME
	sta @target_volume

	; Start the music from the lowest possible level
	inc MUSIC_ON
	lda #VOLUME_LEVEL_LOW
	sta VOLUME
	
--	lda VOLUME
@target_volume = * + 1
    cmp #00
    beq @done
    sec
    sbc #VOLUME_STEP
    sta VOLUME
    
    lda #IRQ_BOTTOM_LINE
-   cmp TED_VRASTER
    bne -
-	cmp TED_VRASTER
	beq -
	
    bne --

@done:
    rts

;-----------------------------------------------------------------------------------------------------------------------
irq_top:
;-----------------------------------------------------------------------------------------------------------------------
; Occurs at the top of the visible image
;-----------------------------------------------------------------------------------------------------------------------
	lda TED_IRQ
	and #(1 << 1)
	beq @irqend
	
	; Acknowledge interrupt
	sta TED_IRQ
	
	;~ inc TED_BORDER

	; Music!
	lda MUSIC_ON
	beq +
	jsr PLAYER

	; Replace IRQ handler with the one for the screen bottom
+	lda #<irq_bottom
	sta IRQ
	lda #>irq_bottom
	sta IRQ + 1

	lda #IRQ_BOTTOM_LINE
	sta TED_VRASTER_INT

	;~ dec TED_BORDER

@irqend:
	jmp KERNAL_IRQRET


;-----------------------------------------------------------------------------------------------------------------------
irq_bottom:
;-----------------------------------------------------------------------------------------------------------------------
; Occurs at end of the visible image
;-----------------------------------------------------------------------------------------------------------------------
	lda TED_IRQ
	and #(1 << 1)
	beq @irqend
	
	; Acknowledge interrupt
	sta TED_IRQ

	;~ dec TED_BORDER
	
	; Music!
	lda MUSIC_ON
	beq +
	jsr PLAYER

	; Back to screen top IRQ handler
+	lda #<irq_top
	sta IRQ
	lda #>irq_top
	sta IRQ + 1

	lda #IRQ_TOP_LINE
	sta TED_VRASTER_INT
	
	; VBlank activities
	php
	cli             					; key scan must be interruptable
	jsr SCNKEY
	plp
	
	; We play a bit dirty and we emulate cursor+return keypressed through the joystick
	jsr scan_joystick
	beq @irqend
	jsr ENQUEUE_KEY
	
	;~ inc TED_BORDER
	
@irqend:
	jmp KERNAL_IRQRET
	

;-----------------------------------------------------------------------------------------------------------------------
scan_joystick:
;-----------------------------------------------------------------------------------------------------------------------
	lda #$ff
	sta $fd30							; Write $ff to keyboard latch
	lda #($fb & $fd)					; Enable both joystick ports at the same time
	sta TED_KBD_LATCH					; Write to joystick latch
	lda TED_KBD_LATCH					; Read answer (bits are 0 if the coresponding button is pressed)
	
	eor #$ff							; Negate the value and switch to "positive logic" (1 if pressed), this will turn
	bne @button_pressed					; out useful later
	
	; No buttons pressed, return quickly
	sta @last_read
	lda #0
	rts

@button_pressed:
	cmp @last_read
	bne @joy_changed
	
	; No changes from last read, decrement repetition delay
	dec @repeat_delay
	bne @ret
	
	; Repetition delay is over, reload with shorter delay for further repetitions
	ldx #4
	stx @repeat_delay
	jmp @do_joy
	
@joy_changed:
	; Joy changed, load delay counter for initial (longer) repetition
	sta @last_read
	ldx #20
	stx @repeat_delay
	;~ jmp @do_joy
	
@do_joy:
	; Value read is in A but flags have been messed up, so shift out bits one at a time
	lsr
	bcs @up
	lsr
	bcs @down
	lsr
	bcs @left
	lsr
	bcs @right
	
	; At this point the high nibble will be 0 (because of the shifting) and so will be bits 4 and 5 due to negating the
	; read value earlier (they always read as 1), so basically it's only fire button bit controlling whether the
	; accumulator is zero or not (bit 6 for port 1, bit 7 for port 2), which simplifies things
	bne @fire
	
@ret:
	lda #0
	rts

@fire:
	lda #KEY_RETURN
	rts
	
@up:
	lda #KEY_UP
	rts

@down:
	lda #KEY_DOWN
	rts

@right:
	lda #KEY_RIGHT
	rts

@left:
	lda #KEY_LEFT
	rts
	
@last_read:
	!byte $ff
	
@repeat_delay:
	!byte 0
}


;-----------------------------------------------------------------------------------------------------------------------
menu:
;-----------------------------------------------------------------------------------------------------------------------
	@last_displayed = TEMP1
	
	@LINE_COLOR_NORMAL = $77
	@LINE_COLOR_HIGHLIGHT = $63

	; Keycodes returned by GETIN (see kernal/ed7.asm)
	KEY_UP = $91
	KEY_DOWN = $11
	KEY_LEFT = $9d
	KEY_RIGHT = $1d
	KEY_RETURN = $0d
	KEY_ESC = $1b
	KEY_PLUS = $2b
	KEY_MINUS = $2d
	KEY_M = $4d

	ldx #0
	stx SELECTED
	stx NDX								; Clear keyboard buffer
	
	jsr clear_screen
	jsr print_list
	
@menu_loop:
	clc
	lda FIRST_DISPLAYED
	adc #(ENTRIES_PER_PAGE - 1)
	sta @last_displayed
	
	jsr @plot_selector
	lda #@LINE_COLOR_HIGHLIGHT
	jsr @color_selected_line

	; Wait for keypress
-	jsr GETIN
	beq -

@process_key:
	cmp #KEY_UP
	beq @up
	cmp #KEY_DOWN
	beq @down
	cmp #KEY_RIGHT
	beq @right
	cmp #KEY_LEFT
	beq @left
	jmp @keycheck_part2					; We must check for other keys further down because of branch offset limitations

@down:
	clc
	lda SELECTED
	adc #1	
	cmp NPAYLOADS						; Do we have more payloads?
	bcs @menu_loop						; >= No, nothing to do

	lda SELECTED
	cmp @last_displayed					; Is the current selection the last displayed payload?
	bne +								; No, need to touch the list

	; Shift list up
	inc FIRST_DISPLAYED
	jsr print_list

	; Move to next entry
+	jsr @clear_selector
	lda #@LINE_COLOR_NORMAL
	jsr @color_selected_line
	inc SELECTED
	jmp @menu_loop

@up:
	lda SELECTED
	beq @menu_loop

	lda SELECTED
	cmp FIRST_DISPLAYED
	bne +

	dec FIRST_DISPLAYED
	jsr print_list
	
+	jsr @clear_selector
	lda #@LINE_COLOR_NORMAL
	jsr @color_selected_line
	dec SELECTED
	jmp @menu_loop

@right:			; Next page
	jsr @clear_selector					; Do this before we touch FIRST_DISPLAYED or SELECTED!
										; Note there's no need to call @color_selected_line as print_list will
										; de-highlight everything anyway
	
	clc
	lda FIRST_DISPLAYED
	adc #ENTRIES_PER_PAGE
	sta FIRST_DISPLAYED
	cmp NPAYLOADS						; Did we get past the last item?
	bcc +								; No
	lda NPAYLOADS						; Yes, so cap at NPAYLOADS - 1
	sta FIRST_DISPLAYED
	dec FIRST_DISPLAYED
	
+	jsr print_list						; Update screen contents
	
	; Update selected item with the same logic as above, so that is stays in sight
	clc
	lda SELECTED
	adc #ENTRIES_PER_PAGE
	sta SELECTED
	cmp NPAYLOADS
	bcc +
	lda NPAYLOADS
	sta SELECTED
	dec SELECTED
	
+	jmp @menu_loop

@left:			; Previous page
	jsr @clear_selector
	
	sec
	lda FIRST_DISPLAYED
	sbc #ENTRIES_PER_PAGE
	sta FIRST_DISPLAYED
	bcs +								; Did we go negative?
	
	; Yes, so cap at 0
	lda #0
	sta FIRST_DISPLAYED
	
+	jsr print_list
	
	sec
	lda SELECTED
	sbc #ENTRIES_PER_PAGE
	sta SELECTED
	bcs +
	lda #0
	sta SELECTED
	
+	jmp @menu_loop

@keycheck_part2:
	cmp #KEY_RETURN
	beq @return
	cmp #KEY_ESC
	beq @esc
!ifdef ENABLE_MUSIC {
	cmp #KEY_PLUS
	beq @plus
	cmp #KEY_MINUS
	beq @minus
	cmp #KEY_M
	beq @m
}
@menu_loop_trampoline:
	jmp @menu_loop

!ifdef ENABLE_MUSIC {
@plus:
	lda MUSIC_ON
	beq @menu_loop_trampoline
	lda VOLUME
	beq @menu_loop_trampoline
	sec
	sbc #VOLUME_STEP
	sta VOLUME
	jmp @menu_loop_trampoline

@minus:
	lda MUSIC_ON
	beq @menu_loop_trampoline
	lda VOLUME
	cmp #(VOLUME_LEVEL_LOW - VOLUME_STEP)	; Stop before the music gets completely inaudible
	bcs +
	clc
	adc #VOLUME_STEP
	sta VOLUME
+	jmp @menu_loop_trampoline

@m:
	lda MUSIC_ON
	eor #1
	bne +

	; Music going off
	jsr fade_music_out
	jmp @menu_loop_trampoline

	; Music going back on
+	jsr fade_music_in
	jmp @menu_loop_trampoline
}

@esc:
	lda #$ff							; Mark selection invalid
	sta SELECTED
	
@return:
	rts
	
@plot_selector:
	sec
	lda SELECTED
	sbc FIRST_DISPLAYED
	clc
	adc #MENU_START_ROW
	tax									; Row
	ldy #1								; Col
	clc									; Set position
	jsr PLOT

	lda #91 + 32						; Cool arrow char, already used for last line of splash screen (+32 for conversion from screen code)
	jsr CHROUT
	lda #92 + 32
	jsr CHROUT

	ldy #37
	jsr PLOT							; X seems to survive

	lda #93 + 32
	jsr CHROUT
	lda #94 + 32
	jsr CHROUT
	
	rts
	
@clear_selector:
	sec
	lda SELECTED
	sbc FIRST_DISPLAYED
	clc
	adc #MENU_START_ROW
	tax									; Row
	ldy #1								; Col
	clc									; Set position
	jsr PLOT
	lda #' '
	jsr CHROUT
	jsr CHROUT
	ldy #37
	jsr PLOT
	lda #' '
	jsr CHROUT
	jsr CHROUT
	rts

@color_selected_line:					; Enter with desired color in A
	pha
	
	; Init pointer at first row of menu
	lda #<(COLOR_RAM + MENU_START_ROW * 40)
	sta PTR_DATA
	lda #>(COLOR_RAM + MENU_START_ROW * 40)
	sta PTR_DATA + 1

	; Move pointer to the selected row
	sec
	lda SELECTED
	sbc FIRST_DISPLAYED
	tax
-	beq @apply_color
	lda PTR_DATA
	adc #40
	sta PTR_DATA
	lda PTR_DATA + 1
	adc #0
	sta PTR_DATA + 1
	dex
	jmp -
	
@apply_color:
	ldy #40
	pla									; Pull color from stack
-	sta (PTR_DATA), y
	dey
	bpl -

	rts


;-----------------------------------------------------------------------------------------------------------------------
start_payload:
;-----------------------------------------------------------------------------------------------------------------------
	@len = TEMP1
	
	jsr clear_screen

	ldx #MENU_START_ROW					; Row
	ldy #0								; Col
	clc									; Set position
	jsr PLOT
	
	jsr PRIMM
	!pet $9e, "Loading ", $00			; $9e = Yellow		

	lda #<payload_table
	sta PTR_PAYLOAD
	lda #>payload_table
	sta PTR_PAYLOAD + 1

	; Get pointer to selected payload
	ldx SELECTED
-	cpx #0
	beq +
	jsr .increment_payload_ptr
	dex
	jmp -

+	ldy #0
	lda (PTR_PAYLOAD), y				; Double indirection, aaaaargh!
	sta PTR_DATA
	iny
	lda (PTR_PAYLOAD), y
	sta PTR_DATA + 1
	iny
	lda (PTR_PAYLOAD), y
	sta @len
	
	ldy #0
-	lda (PTR_DATA), y
	jsr CHROUT
	iny
	cpy @len
	bne -

	jsr PRIMM
	!pet " from ", $00

+	ldy #5
	lda (PTR_PAYLOAD), y
	sta @len
	sta fetch_command + 2				; Copy the URL length to the WiC command buffer while we're at it
	ldy #3
	lda (PTR_PAYLOAD), y
	sta PTR_DATA
	iny
	lda (PTR_PAYLOAD), y
	sta PTR_DATA + 1
	ldy #0
-	lda (PTR_DATA), y
	sta url,y							; And the URL itself as well!
	jsr CHROUT
	iny
	cpy @len
	bne -

	lda #'.'
	jsr CHROUT
	jsr CHROUT
	jsr CHROUT
	lda #$0d
	jsr CHROUT
	jsr CHROUT

	; Give user some time to read the message
	ldx #30
--	lda #IRQ_BOTTOM_LINE
-	cmp TED_VRASTER
	bne -
-	cmp TED_VRASTER
	beq -
	dex
	bne --

    ; Restore default colors
	lda #$90							; Black
	jsr CHROUT
	lda #$f1
	sta TED_BACKGROUND
	lda #$ee
	sta TED_BORDER

    ; Clear screen
    jsr SCNCLR
    
    ; Switch back to default charset
    lda #%11000100                      ; Power-up value of $ff12
    sta TED_CFG3
    lda #%11010001                      ; Power-up value of $ff13
	sta TED_CFG4

!ifdef ENABLE_RAMEXP {
	lda HAVE_RAMEXP
	beq +
	+set_default_ram_bank
+
}

!ifndef DEBUG {
	+wic64_execute transtimeoutcom
	;~ +wic64_execute servertimeoutcom
	+wic64_load_and_run fetch_command, 10
}

	; Normally this point should never be reached as the loaded code takes over
	rts
		
	
;-----------------------------------------------------------------------------------------------------------------------
print_list:
;-----------------------------------------------------------------------------------------------------------------------
	@len = TEMP1
	@cnt = TEMP2
	@PTR_NAME = TEMP3
	@PTR_SCREEN = PTR_DATA				; Always points to the beginning of the current line
		
	ldx #MENU_START_ROW					; Row
	ldy #1								; Col
	clc									; Set position
	jsr PLOT
	
	lda #0
	sta @cnt
	
	lda #<payload_table
	sta PTR_PAYLOAD
	lda #>payload_table
	sta PTR_PAYLOAD + 1
	
	; Init pointer at first row of menu
	lda #<(SCREEN_RAM + MENU_START_ROW * 40)
	sta @PTR_SCREEN
	lda #>(SCREEN_RAM + MENU_START_ROW * 40)
	sta @PTR_SCREEN + 1
	
	; Get payload corresponding to the first displayed item
	ldx FIRST_DISPLAYED
-	beq @load_entry
	jsr .increment_payload_ptr
	dex
	jmp -

@load_entry:
--	lda @cnt
	cmp #ENTRIES_PER_PAGE				; Did we do one entry per line?
	beq @end							; Yes, done!
	
	; No, load payload data
	clc
	adc FIRST_DISPLAYED
	cmp NPAYLOADS
	ldy #0								; Do this here, since it's essential both if we take the branch or not
	bcs @pad_to_eol						; We have finished iterating on payloads, but we must keep clearing the screen
	
	lda (PTR_PAYLOAD), y				; Double indirection, aaaaargh!
	sta @PTR_NAME
	iny
	lda (PTR_PAYLOAD), y
	sta @PTR_NAME + 1
	iny
	lda (PTR_PAYLOAD), y
	sta @len
	
	jsr .increment_payload_ptr			; We are done with the payload pointer for this iteration, increment it immediately

	; Print enough spaces to center the name
	sec
	lda #40
	sbc @len
	lsr
	pha
	tay
	lda #' '
-	sta (@PTR_SCREEN), y
	dey
	bne -

	; This is tricky: We want to use Y to always contain the "current column" on the line that is being processed, but
	; since we must also use for indexing the name array, we need to make the pointer point a bit back, in order to
	; compensate for the initial spaces.

	; This is one way to do it: since the subtrahend is on the stack and we can onlu subtract an immediate, we invert it
	; using 2's complement and then sum it
	sec									; Prepare +1 for 2'complement
	pla
	pha
	eor #$ff							; 2's complement, now A = -A
	adc @PTR_NAME
	sta @PTR_NAME
	lda @PTR_NAME + 1
	sbc #0
	sta @PTR_NAME + 1 

	; Print name
	ldx @len
	pla
	tay
-	cpx #0
	beq @pad_to_eol
	lda (@PTR_NAME), y
	jsr petscii_to_screen
	sta (@PTR_SCREEN), y
	iny
	dex
	jmp -

	; Pad with spaces until the end of the line
@pad_to_eol:
	lda #' '
-	sta (@PTR_SCREEN), y
	iny
	cpy #40
	bne -

	; Next line
	clc
	lda @PTR_SCREEN
	adc #40
	sta @PTR_SCREEN
	lda @PTR_SCREEN + 1
	adc #0
	sta @PTR_SCREEN + 1

	inc @cnt
	
	jmp --

@end:
@check_pgup:
	lda FIRST_DISPLAYED
	beq +
	lda #30								; Arrow up
	sta SCREEN_RAM + 40 * 3 + 39
	jmp @check_pgdown
+	lda #' '
	sta SCREEN_RAM + 40 * 3 + 39

@check_pgdown:
	clc
	lda FIRST_DISPLAYED
	adc #(ENTRIES_PER_PAGE - 1)
	cmp NPAYLOADS
	bcs +
	lda #95								; Arrow down
	sta SCREEN_RAM + 40 * 24 + 39
	jmp @apply_color
+	lda #' '
	sta SCREEN_RAM + 40 * 24 + 39
	
	; Color all entries in yellow
@apply_color:
	; FIXME
	lda #<COLOR_RAM
	sta PTR_DATA
	lda #>COLOR_RAM
	sta PTR_DATA + 1
	
	lda #$77
	ldy #40 * (MENU_START_ROW - 1)
-	sta (PTR_DATA), y
	iny
	bne -
	inc PTR_DATA + 1
-	sta (PTR_DATA), y
	iny
	bne -
	inc PTR_DATA + 1
-	sta (PTR_DATA), y
	iny
	bne -
	inc PTR_DATA + 1
-	sta (PTR_DATA), y
	iny
	bne -

	rts
	

;-----------------------------------------------------------------------------------------------------------------------
petscii_to_screen:
;-----------------------------------------------------------------------------------------------------------------------
; IN: A=PETSCII character
; OUT: A=Screen code
; See https://sta.c64.org/cbm64pettoscr.html.
;-----------------------------------------------------------------------------------------------------------------------
	cmp #$20
	bcc @control

	cmp #$40
	bcc @range20_3f

	cmp #$60
	bcc @range40_5f

	cmp #$80
	bcc @range60_7f

	cmp #$a0
	bcc @range80_9f
	
	cmp #$c0
	bcc @range_a0_bf
	
	cmp #$ff
	bcc @range_c0_df
	
	lda #$5e						; $ff = Pi

	rts

@control:
	clc
	adc #128
	rts

@range20_3f:
	; $20-$3F -> No change
	rts

@range40_5f:
	; $40-$5F (@ A-Z [\]^_)
	sec
	sbc #64
	rts

@range60_7f:
	; $60-$7F (` a-z {...})
	sec
	sbc #32
	rts
	
@range80_9f:
	clc
	adc #64
	rts
	
@range_a0_bf:
	sec
	sbc #64
	rts
	
@range_c0_df:
	sec
	sbc #128
	rts

	
;-----------------------------------------------------------------------------------------------------------------------
clear_screen:
;-----------------------------------------------------------------------------------------------------------------------
; Clear screen from row 4 on, in order to preserve the WiC64 header
;-----------------------------------------------------------------------------------------------------------------------
	ldx #40 * 3
-	lda splash_text, x
	sta SCREEN_RAM, x
	lda splash_color, x
	sta COLOR_RAM, x
	dex
	bpl -
	
	lda #' '
	ldx #110							; (1000-40*3)/8
-	
	sta SCREEN_RAM + 40 * 3,x
	sta SCREEN_RAM + 40 * 3 + 110,x
	sta SCREEN_RAM + 40 * 3 + 110 * 2,x
	sta SCREEN_RAM + 40 * 3 + 110 * 3,x
	sta SCREEN_RAM + 40 * 3 + 110 * 4,x
	sta SCREEN_RAM + 40 * 3 + 110 * 5,x
	sta SCREEN_RAM + 40 * 3 + 110 * 6,x
	sta SCREEN_RAM + 40 * 3 + 110 * 7,x
	dex
	bpl -
	rts

;-----------------------------------------------------------------------------------------------------------------------
fetch:
;-----------------------------------------------------------------------------------------------------------------------
; Fetch the latest releases CSV file
;-----------------------------------------------------------------------------------------------------------------------
!ifndef DEBUG {
	; Fetch data
	+wic64_execute transtimeoutcom
	;~ +wic64_execute servertimeoutcom
	+wic64_execute fetch_command, response, 10

	bcc +
	lda #$02
	sta TED_BORDER
	jmp *								; FIXME
+
	lda wic64_response_size
	sta response_size
	lda wic64_response_size + 1
	sta response_size + 1
} else {
!ifdef ENABLE_RAMEXP {
	; Quick hack to copy the built-in CSV data to the RAM bank where they would be fetched
	lda HAVE_RAMEXP
	beq @noexp
	
	lda #<response
	sta PTR_DATA
	lda #>response
	sta PTR_DATA + 1

--	ldy #0
-	+set_default_ram_bank
	lda (PTR_DATA), y
	+set_ram_bank 0
	sta (PTR_DATA), y
	lda (PTR_DATA), y
	beq @copy_done
	iny
	bne -
	
	inc PTR_DATA + 1
	jmp --
@copy_done:
	+set_ram_bank 0
	; --- Hack END ---

@noexp:
}
	lda #<debug_response_size
	sta response_size
	sta wic64_response_size
	lda #>debug_response_size
	sta response_size + 1
	sta wic64_response_size + 1

	; Simulate download time with a ~2s pause
	ldx #100
--	lda #IRQ_BOTTOM_LINE				; Wait for next frame
-   cmp TED_VRASTER
	bne -
	dex
	bne --
}

	; Mark end of data
	clc
	lda #<response
	adc wic64_response_size
	sta PTR_DATA
	lda #>response
	adc wic64_response_size + 1
	sta PTR_DATA + 1
	lda #0
	tay
	sta (PTR_DATA), y
	
	rts
	

;-----------------------------------------------------------------------------------------------------------------------
parse:
;-----------------------------------------------------------------------------------------------------------------------
	@len = TEMP1
	@state = TEMP2
	
	@ST_NAME = 0
	@ST_LINK = 1

	lda #<payload_table
	sta PTR_PAYLOAD
	lda #>payload_table
	sta PTR_PAYLOAD + 1

	lda #<response
	sta PTR_DATA
	sta payload_table					; Start of data is also start of name for first payload
	lda #>response
	sta PTR_DATA + 1
	sta payload_table + 1

	lda #@ST_NAME
	sta @state

	ldy #0
	sty NPAYLOADS
	sty @len
	
@loop:
	lda (PTR_DATA), y
	beq @done							; NULL => End of data

	ldx @state
	cpx #@ST_NAME
	beq @st_name
	cpx #@ST_LINK
	beq @st_link
	jmp @done							; Should never happen but better safe than sorry

@st_name:
	cmp #','
	beq @name_complete
	
	; Convert to PETSCII in-place
	tax
	lda ascii_to_petscii_table, x
	sta (PTR_DATA), y
	jmp @next_char

@name_complete:
	; Found separator, save name length
	lda @len
	ldy #2
	sta (PTR_PAYLOAD), y

	; Assume link starts at next byte
	clc
	lda PTR_DATA
	adc #1
	iny
	sta (PTR_PAYLOAD), y
	lda PTR_DATA + 1
	adc #0
	iny
	sta (PTR_PAYLOAD), y

	; Reset counter in order to measure link length
	lda #0
	sta @len

	lda #@ST_LINK
	sta @state

	jmp @next_char_nocnt

@st_link:
	cmp #$0a							; Mmmmh....
	bne @next_char

	; Found end of line, save link length
	lda @len
	ldy #(PAYLOAD_RECORD_LEN - 1)
	sta (PTR_PAYLOAD), y

	; Assume next name starts at next byte
	clc
	lda PTR_DATA
	adc #1
	iny									; Y=6 => First byte of next payload entry
	sta (PTR_PAYLOAD), y
	lda PTR_DATA + 1
	adc #0
	iny									; Y=7
	sta (PTR_PAYLOAD), y

	; Reset counter in order to measure length of next name
	lda #0
	sta @len

	; Prepare for next payload table entry
	jsr .increment_payload_ptr
	inc NPAYLOADS
	lda NPAYLOADS
	cmp #MAX_PAYLOAD_RECORDS
	beq @done

	lda #@ST_NAME
	sta @state

	jmp @next_char_nocnt

@next_char:
	inc @len

@next_char_nocnt:
	clc
	lda PTR_DATA
	adc #1
	sta PTR_DATA
	lda PTR_DATA + 1
	adc #0
	sta PTR_DATA + 1
	
+	ldy #0
	jmp @loop

@done:
	lda #0
	ldy #(PAYLOAD_RECORD_LEN - 1)
-	sta (PTR_PAYLOAD),y					; Mark end of payload table
	dey
	bpl -

	rts


;-----------------------------------------------------------------------------------------------------------------------	
.increment_payload_ptr:
;-----------------------------------------------------------------------------------------------------------------------
	clc
	lda PTR_PAYLOAD
	adc #PAYLOAD_RECORD_LEN
	sta PTR_PAYLOAD
	lda PTR_PAYLOAD + 1
	adc #0
	sta PTR_PAYLOAD + 1
	rts


;-----------------------------------------------------------------------------------------------------------------------
; INCLUDES
;-----------------------------------------------------------------------------------------------------------------------
!source "wic64.asm"

!ifdef ENABLE_MUSIC {
; Music kindly provided by Master Casbo!
muzak:
	OFS = 0
	!src "music.asm"
	!src "!player_data.asm"
	!src "!player.asm"
}


;-----------------------------------------------------------------------------------------------------------------------
; DATA & STRINGS
;-----------------------------------------------------------------------------------------------------------------------
ascii_to_petscii_table:
	!byte $00,$01,$02,$03,$04,$05,$06,$07,$14,$20,$0d,$11,$93,$0a,$0e,$0f
	!byte $10,$0b,$12,$13,$08,$15,$16,$17,$18,$19,$1a,$1b,$1c,$1d,$1e,$1f
	!byte $20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$2a,$2b,$2c,$2d,$2e,$2f
	!byte $30,$31,$32,$33,$34,$35,$36,$37,$38,$39,$3a,$3b,$3c,$3d,$3e,$3f
	!byte $40,$c1,$c2,$c3,$c4,$c5,$c6,$c7,$c8,$c9,$ca,$cb,$cc,$cd,$ce,$cf
	!byte $d0,$d1,$d2,$d3,$d4,$d5,$d6,$d7,$d8,$d9,$da,$5b,$5c,$5d,$5e,$a4
	!byte $c0,$41,$42,$43,$44,$45,$46,$47,$48,$49,$4a,$4b,$4c,$4d,$4e,$4f
	!byte $50,$51,$52,$53,$54,$55,$56,$57,$58,$59,$5a,$db,$dc,$dd,$de,$df
	!byte $80,$81,$82,$83,$84,$85,$86,$87,$88,$89,$8a,$8b,$8c,$8d,$8e,$8f
	!byte $90,$91,$92,$0c,$94,$95,$96,$97,$98,$99,$9a,$9b,$9c,$9d,$9e,$9f
	!byte $a0,$a1,$a2,$a3,$a4,$a5,$a6,$a7,$a8,$a9,$aa,$ab,$ac,$ad,$ae,$af
	!byte $b0,$b1,$b2,$b3,$b4,$b5,$b6,$b7,$b8,$b9,$ba,$bb,$bc,$bd,$be,$bf
	!byte $60,$61,$62,$63,$64,$65,$66,$67,$68,$69,$6a,$6b,$6c,$6d,$6e,$6f
	!byte $70,$71,$72,$73,$74,$75,$76,$77,$78,$79,$7a,$7b,$7c,$7d,$7e,$7f
	!byte $e0,$e1,$e2,$e3,$e4,$e5,$e6,$e7,$e8,$e9,$ea,$eb,$ec,$ed,$ee,$ef
	!byte $f0,$f1,$f2,$f3,$f4,$f5,$f6,$f7,$f8,$f9,$fa,$fb,$fc,$fd,$fe,$ff

; Align to 1 kB
@pre_charset = *
!align $3ff, 0, $ea
!warn "Charset alignment wasted ", * - @pre_charset, " bytes"
charset:
	!bin "portalcharset.bin"

	; Here the -64 is for switching to the "Uppercase + GFX" set (which actually contains lower and upper case in the
	; WiC64 font), while |128 is for obtaining reverse colors
splash_text:
	!scr $68,$69,$69,$69,$69,$69,$69,$6a,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40
	!pet $60,$61,$62,$63,$64,$65,$66,$67,$40,$40,$40,$40,$40,'P',('l' - 64) | 128,('u' - 64) | 128,('s' - 64) | 128,'4' | 128,'W',('o' - 64) | 128,('r' - 64) | 128,('l' - 64) | 128,('d' - 64) | 128,$40,'L',('a' - 64) | 128,('t' - 64) | 128,('e' - 64) | 128,('s' - 64) | 128,('t' - 64) | 128,$40,'R',('e' - 64) | 128,('l' - 64) | 128,('e' - 64) | 128,('a' - 64) | 128,('s' - 64) | 128,('e' - 64) | 128,('s' - 64) | 128,$40
	!scr $6b,$6c,$6c,$6c,$6c,$6c,$6c,$6d,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$6f
	!scr "                                        "
	!scr " This program allows you to browse the  "
	!scr " most recent C16/Plus4 releases on      "
	!scr " Plus4World and to start them directly  "
	!scr " off the network!                       "
	!scr "                                        "
	!scr " Keys:                                  "
	!scr "  ",30,"/",95,"/",31,"/",127," Select Release                "		; 4 arrows
	!scr "  RETURN  Start Selected                "
	!scr "  ESC     Exit                          "
!ifdef ENABLE_MUSIC {
	!scr "  M/+/-   Control Music                 "
} else {
	!scr "                                        "
}
	!scr "                                        "
	!scr " Code:                                  "
	!scr "  2026 SukkoPera                        "
	!scr "                                        "
	!scr " Music, Backend and Help:               "
	!scr "  2025 Csabo                            "
	!scr "                                        "
	!scr "                                        "
	!scr "                                        "
	!scr "                                        "
	!scr "                                        "

splash_color:
	!byte $41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41
	!byte $41,$34,$46,$46,$46,$32,$32,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41
	!byte $41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41
	!byte $51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51
	!byte $77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77
	!byte $77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77
	!byte $77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77
	!byte $77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77,$77
	!byte $51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51
	!byte $71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71
	!byte $42,$42,$42,$42,$42,$42,$42,$42,$42,$42,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51
	!byte $42,$42,$42,$42,$42,$42,$42,$42,$42,$42,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51
	!byte $42,$42,$42,$42,$42,$42,$42,$42,$42,$42,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51
	!byte $42,$42,$42,$42,$42,$42,$42,$42,$42,$42,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51
	!byte $51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51
	!byte $71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71
	!byte $42,$42,$42,$42,$42,$42,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51
	!byte $51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51
	!byte $71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71,$71
	!byte $42,$42,$42,$42,$42,$42,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51
	!byte $51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51
	!byte $51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51
	!byte $51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51,$51
	!byte $63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63
	!byte $63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63

transtimeoutcom
	!byte "R", WIC64_SET_TRANSFER_TIMEOUT, $01, $00, 10
;~ servertimeoutcom
	;~ !byte "R", WIC64_SET_REMOTE_TIMEOUT, $01, $00, $03
fetch_command:
	!byte "R", WIC64_HTTP_GET, <(urlEnd - url), >(urlEnd - url)
url:
good_signature = * + 8					; Just something to be used as a cache validation mechanism
SIGNATURE_LEN = 10
	!text "https://plus4world.powweb.com/latest.php?limit=100"
urlEnd:
	; Leave some space here, as we will need to patch the URL with the payload's
	!fill 64, 0


;-----------------------------------------------------------------------------------------------------------------------
; Hannes-switchable area
;-----------------------------------------------------------------------------------------------------------------------	
; Data here is not covered by the CRC (see below) but it is used to calculate it
;-----------------------------------------------------------------------------------------------------------------------	
	* = $4000
response_size:
	!word 0
checksum:
	!byte $ff

@padding:
	!byte $00, $00						; Reserved for future use

signature:
	!fill SIGNATURE_LEN, $ee

!align 15, 0, $00						; Reserved for future use
!ifdef ENABLE_RAMEXP {
hannes_test_addr = * - 1				; Do NOT put this into CRC!
}

;-----------------------------------------------------------------------------------------------------------------------
; CRC-protected data area
;-----------------------------------------------------------------------------------------------------------------------	
; This is cached into Hannes expansion bank 0 if available
;-----------------------------------------------------------------------------------------------------------------------	
crc_area_start = *

NPAYLOADS:
	!byte 0

!align 15, 0, $bb

payload_table:
	; 0-1 Name start addr
	; 2 Name length
	; 3-4 Link pointer
	; 5 Link length
	!fill PAYLOAD_RECORD_LEN * (MAX_PAYLOAD_RECORDS + 1), $55					; Extra sentinel entry
@payload_table_end = *

payload_table_size = @payload_table_end - payload_table

crc_area_minus_response_size = * - crc_area_start
		
;~ response = * + 64 + PAYLOAD_RECORD_LEN * (MAX_PAYLOAD_RECORDS + 1)
response:
!ifdef DEBUG {
	!bin "data.bin"
response_end = *
debug_response_size = response_end - response
	!byte 00
}

; CRC-protected area ends here, after end of response (keep in mind response size is variable)
