H_MAXSLOTS = 16

H_MASK = %00110000						; Bits 4 and 5 must always be 1 for compatibility with Csory's expansion

H_TED_USE_BANKS = 0
H_TED_MONO_BANK = (1 << 6)

H_BOUNDARY_1000 = 0
H_BOUNDARY_4000 = (1 << 7)

!addr HANNES_CTL = $fd16

H_LAST_BANK:							; 0 if no expansion was detected, max slot otherwise
	!byte 0

;-----------------------------------------------------------------------------------------------------------------------
hannes_detect:
;-----------------------------------------------------------------------------------------------------------------------
	ldx #(H_MAXSLOTS - 1)
-	txa
	ora #(H_BOUNDARY_4000 | H_TED_MONO_BANK | H_MASK)
	sta HANNES_CTL							; Set bank X
	stx hannes_test_addr
	dex
	bpl -

	lda #((H_MAXSLOTS - 1) | H_BOUNDARY_4000 | H_TED_MONO_BANK | H_MASK)		; Back to default_slot
	sta HANNES_CTL
	;~ inc hannes_test_addr
	lda hannes_test_addr
	sta H_LAST_BANK
	rts

;-----------------------------------------------------------------------------------------------------------------------	
!macro set_ram_bank .n {
;-----------------------------------------------------------------------------------------------------------------------
	lda #H_BOUNDARY_4000 | H_TED_MONO_BANK | H_MASK | (.n & $0f)
	sta HANNES_CTL
}

;-----------------------------------------------------------------------------------------------------------------------
!macro get_ram_bank {
;-----------------------------------------------------------------------------------------------------------------------
	lda HANNES_CTL
	and H_LAST_BANK
}

;-----------------------------------------------------------------------------------------------------------------------
!macro next_ram_bank {
;-----------------------------------------------------------------------------------------------------------------------
; If you are sure you are not in the default/last slot, a simple inc HANNES_CTL will do, but better safe than sorry...
;----------------------------------------------------------------------------------------------------------------------
	lda HANNES_CTL
	and H_LAST_BANK
	clc
	adc #1
	and #$0f
	ora #(H_BOUNDARY_4000 | H_TED_MONO_BANK)
	sta HANNES_CTL
}

;-----------------------------------------------------------------------------------------------------------------------
!macro set_default_ram_bank {
;-----------------------------------------------------------------------------------------------------------------------
	+set_ram_bank @H_MAXSLOTS - 1
}
