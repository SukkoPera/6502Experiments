;
; LOD Player Version 2
;
; 1Cf2
; 1D8f
;
!addr {
	F1LO	= $FF0E
	F1HI	= $FF12
	F2LO	= $FF0F
	F2HI	= $FF10
}

OFF	= $3F
	
; COMMAND BYTES

END_MARK	= $FE
SET_VOLTAB	= $FF
SET_ARP		= $F0
SET_INS		= $E0
VOFF		= $D0
LEN		= $40

; Constants
base_note = 0 ; shift to C0
C0	= base_note + 0
Ci0	= base_note + 1
D0	= base_note + 2
Di0	= base_note + 3
E0	= base_note + 4
F0	= base_note + 5
Fi0	= base_note + 6
G0	= base_note + 7
Gi0	= base_note + 8
A0	= base_note + 9
Ai0	= base_note + 10
B0	= base_note + 11

C1	= base_note + 12
Ci1	= base_note + 13
D1	= base_note + 14
Di1	= base_note + 15
E1	= base_note + 16
F1	= base_note + 17
Fi1	= base_note + 18
G1	= base_note + 19
Gi1	= base_note + 20
A1	= base_note + 21
Ai1	= base_note + 22
B1	= base_note + 23

C2	= base_note + 24
Ci2	= base_note + 25
D2	= base_note + 26
Di2	= base_note + 27
E2	= base_note + 28
F2	= base_note + 29
Fi2	= base_note + 30
G2	= base_note + 31
Gi2	= base_note + 32
A2	= base_note + 33
Ai2	= base_note + 34
B2	= base_note + 35

C3	= base_note + 36
Ci3	= base_note + 37
D3	= base_note + 38
Di3	= base_note + 39
E3	= base_note + 40
F3	= base_note + 41
Fi3	= base_note + 42
G3	= base_note + 43
Gi3	= base_note + 44
A3	= base_note + 45
Ai3	= base_note + 46
B3	= base_note + 47

C4	= base_note + 48
Ci4	= base_note + 49
D4	= base_note + 50
Di4	= base_note + 51
E4	= base_note + 52
F4	= base_note + 53
Fi4	= base_note + 54
G4	= base_note + 55
Gi4	= base_note + 56
A4	= base_note + 57
Ai4	= base_note + 58
B4	= base_note + 59

C5	= base_note + 60
Ci5	= base_note + 61
D5	= base_note + 62
Di5	= base_note + 63
E5	= base_note + 64
F5	= base_note + 65

;-----
          
PLAYER_INIT
	ldx #(Channel1 - OFS) & 255
	ldy #(Channel1 - OFS) >> 8
	stx PCH1_LO
	sty PCH1_HI
	;
	ldx #(Channel2 - OFS) & 255
	ldy #(Channel2 - OFS) >> 8
	stx PCH2_LO
	sty PCH2_HI
	;
	ldx #$FF
	stx VOLTAB_CNT
	inx       
	stx NOTE1
	stx NOTE2
	stx NOTE3
	stx FRAME_CNT
	jsr res - OFS
	inx
	stx NOTELEN1
	stx NOTELEN2
	stx NOTELEN3
	jsr res - OFS
	;
	lda #9*0
	sta VOLUME
	;
	rts

res	ldy #$00
	!byte $2C
	
advance	ldy PCH1,x
	;      
	lda PCH1_LO,x
	sta PCH_TEMP
	lda PCH1_HI,x
	sta PCH_TEMP+1
	;
	lda (PCH_TEMP),y	; LO byte
	sta CH1_LO,x
	iny
	lda (PCH_TEMP),y	; HI byte
	beq res
	sta CH1_HI,x
	iny
	sty PCH1,x
	;
pl_ret	rts
	
	;
	;##################
	;

PLAYER
	lda $FF07
	and #$40
	beq player_pal
	;
	ldx FRAME_CNT
	inx
	cpx #12				; count to 12 (6 frames * 2 calls)
	bne *+4                	
	ldx #$00
	stx FRAME_CNT
	cpx #10				; on NTSC, the last two calls (1 frame) do nothing
	bcs pl_ret
player_pal
	;
	ldx #$01
	;
channel_loop
	inc NOTE1,x
	;
	lda NOTE1,x
	cmp NOTELEN1,x
	bne channel_loop_end
	;beq next_note
	;jmp channel_loop_end-OFS
	;
next_note 
	lda CH1_LO,x
	sta CH_TEMP
	lda CH1_HI,x
	sta CH_TEMP+1
	;
	ldy #$00
	sty NOTE1,x		; reset note counter
	;   
	lda (CH_TEMP),y		; get byte
	iny
	;
	cmp #END_MARK		; $FF goes to new pattern
	bne pl_10
	;
	jsr advance - OFS
	bne next_note		; should never be zero
	;
pl_10	cmp #SET_VOLTAB
	bne pl_11
	;
	sta VOLTAB_CNT
	;
	lda (CH_TEMP),y		; get lo byte
	iny
	sta VOL_TAB - OFS+1
	;
	lda (CH_TEMP),y		; get byte
	iny
	;
pl_11	cmp #SET_ARP		; instrument change?
	bcc pl_12
	;
	sty TMP_Y
	;
	and #$0F
	tay
	;
	lda arp_lengths,y
	sta ARP_LEN
	lda arp_offsets,y
	sta arp_ptr+1
	;
	lda #$04		; switch to arp
	sta INS_TYPE1,x   	; store instrument type
	lda #$00
	sta ARP_CNT
	;
	ldy TMP_Y
	;
	lda (CH_TEMP),y		; get byte
	iny
	;
pl_12	cmp #SET_INS		; instrument change?
	bcc pl_13
	;
	and #$0F		; keep lower 4 bits
	sta INS_TYPE1,x   	; store instrument type
	;
	lda (CH_TEMP),y		; get byte
	iny
	;
pl_13	cmp #VOFF
	bcc pl_15
	;
	and #$0F
	sta pl_14+1
	;
	lda NOTELEN1,x
	sec
pl_14	sbc #$00
	sta NOTE1,x
	lda #OFF
	bne pl_16
	;
pl_15	cmp #LEN		; set note length?
	bcc pl_16
	;
	sbc #LEN		; we know carry is always set
	sta NOTELEN1,x
	;
	lda (CH_TEMP),y
	iny
	;
pl_16	sta TONE1,x		; - store note!
	;
	; --- advance pointer
	;
	tya
	clc
	adc CH1_LO,x
	sta CH1_LO,x
	bcc noi_1
	inc CH1_HI,x
noi_1	;
	;
	; -----------------------------------------------------------------
	;
channel_loop_end
	dex
	;bpl channel_loop-OFS
	bmi pl_50
	jmp channel_loop-OFS
	;    
pl_50	
	;
	; --- SOUND PROCESSING
	;
PLAYER_SOUND
	lda #$20
	sta NOISE
	;
	ldx #$01		; channel 2
	jsr sound - OFS
	;
	sta F1LO_store - OFS+1
	sty F1HI_x - OFS+1
	;
	lda F1HI
	and #$FC
F1HI_x	ora #$00
	sta F1HI_store - OFS+1
	;
	ldx #$00		; channel 1
	jsr sound - OFS
	sta F2LO
	sty F2HI
	;
F1LO_store
	lda #$00
	sta F1LO
F1HI_store
	lda #$00
	sta F1HI
	;
	; ---
	;
	ldy VOLTAB_CNT
	iny
res_v	
VOL_TAB	lda vol_default - OFS,y
	bpl noi_v		; check for $FF
	ldy #$00		; reached, so warp
	beq res_v
noi_v	sty VOLTAB_CNT
	clc
	adc VOLUME
	tay
	lda volume_map - OFS,y
	ora NOISE
	;
	ldy F1LO
	cpy #$FE
	bne setvol		; not silent
	ldy F2LO
	cpy #$FE
	beq sil			; silent: skip setting $FF11 to avoid clicks
	;
setvol	sta $FF11		; self-mod
	;
sil	rts     
	;
inst_table_lo
	!byte normal & 255
	!byte hihat & 255
	!byte snare & 255
	!byte blipp & 255
	!byte arpeggio & 255
	!byte vibrato & 255
inst_table_hi
	!byte normal >> 8
	!byte hihat >> 8
	!byte snare >> 8
	!byte blipp >> 8
	!byte arpeggio >> 8
	!byte vibrato >> 8
	;
sound	lda TONE1,x
	cmp #OFF
	beq lookup
	;
	lda INS_TYPE1,x
	tay
	lda inst_table_lo - OFS,y
	sta inst_jump - OFS+1
	lda inst_table_hi - OFS,y
	sta inst_jump - OFS+2
	;
inst_jump
	jmp $0000
	
normal	lda TONE1,x		; normal note
lookup	tax
	lda freqs_lo,x
	ldy freqs_hi,x
	rts
	
;blipp2	lda TONE1,x
;	ldy NOTE1,x
;	beq lookup
;	lda #OFF
;	bne lookup
	
blipp	lda TONE1,x
	ldy NOTE1,x
	cpy #$02
	bcc lookup
	;	
	cpy #$04
	bcc blipp_octave
	;
	lda #OFF
	bne lookup
	;
blipp_octave
	clc
	adc #$0C
	bne lookup
	
arpeggio
	lda ARP_CNT		; load current arp counter
	clc
	adc #$01
	cmp ARP_LEN
	bne *+4
	lda #$00
	sta ARP_CNT
	lsr
	tay
arp_ptr
	lda arpeggio_data,y		; for channel 2 (self-mod)
	clc
	adc TONE1,x
	bne lookup

vibrato	lda TONE1,x
	cmp #$10
	bcc vib1
	;
	lda NOTE1,x
	and #$0F
	tay
	lda vibrato_data_2,y
	bmi vib_sub1
	bpl vib_add
	;
vib1	lda NOTE1,x
	and #$0F
	tay
	lda vibrato_data_1,y
	bmi vib_sub1
	;
vib_add
	sta vib2+1
	;
	lda TONE1,x
	tax
	ldy freqs_hi,x
	lda freqs_lo,x
	clc
vib2	adc #$01
	bcc *+3
	iny
	rts
	;
vib_sub1
	and #$7F
	;      
	sta vib4+1
	;
	lda TONE1,x
	tax
	ldy freqs_hi,x
	lda freqs_lo,x
	sec
vib4	sbc #$01
	bcs *+3
	dey
	rts
	
hihat	lda #$40
	sta NOISE
	;
	bne normal

snare	lda NOTE1,x
	asl
	tax
	lda snare_data+1,x	; use bits $40 and $20 for noise control
	and #$60
	sta NOISE
	lda snare_data+1,x	; lower 10 bits for freq
	and #$03
	tay
	lda snare_data,x
	rts

vibrato_data_1
	!byte $00,$02,$04,$05,$06,$05,$04,$02
	!byte $00,$82,$84,$85,$86,$85,$84,$82
vibrato_data_2
	!byte $00,$00,$01,$01,$01,$01,$00,$00
	!byte $00,$00,$81,$81,$81,$81,$00,$00

SET_ARP_358	= SET_ARP + 0
SET_ARP_47A	= SET_ARP + 1
SET_ARP_C	= SET_ARP + 2

arp_lengths
	!byte 4*2
	!byte 4*2
	!byte 2*2
arp_offsets
	!byte (arpeggio_data & 255) + 0
	!byte (arpeggio_data & 255) + 4
	!byte (arpeggio_data & 255) + 8
	;~ align 16
!align 15, 0
arpeggio_data
	!byte 0,3,5,8
	!byte 0,4,7,$A
	!byte 0,$C
;[eof]
