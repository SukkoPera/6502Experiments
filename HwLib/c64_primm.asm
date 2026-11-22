; Implementation of the TED "primm" function to be used on the C64
; Taken from the TED KERNAL sources

!zone primm {

; Change this if necessary
!addr .imparm = $40

;-----------------------------------------------------------------------------------------------------------------------
KRN_PRIMM:
;-----------------------------------------------------------------------------------------------------------------------
; PRINT IMMEDIATE: A jsr to this routine is followed by a immediate ascii string, terminated by a $00. The immediate
; string must not be longer than 255 characters including the terminator.
;-----------------------------------------------------------------------------------------------------------------------
       pha             	;protect a,x,y
       tya
       pha
       txa
       pha
       tsx             	;get sp
       inx             	;make it point to return addr low
       inx
       inx
       inx

       lda $0100,x     	;get it
       sta .imparm     	;in base ptr.
       inx             	;point to hi
       lda $0100,x     	;get it
       sta .imparm+1   	;in base ptr.
       inc .imparm     	;this was actually a return addr minus 1
       bne @ipskip     	;...note that a string of only a $0 will work
       inc .imparm+1
@ipskip:
       ldy #0          	;we're pointing to 1st byte of string
-      lda (.imparm),y  ;loop to output string
       beq @priend
       jsr KRN_BSOUT
       iny
       bne -

@priend: 				;shove true return addr in the stack
       tya             	;y has offset to add onto .imparmbase
       tsx
       inx             	;x points to ret adr lo
       inx
       inx
       inx

       clc
       adc .imparm
       sta $0100,x     	;new lo ret adr
       lda #0
       adc .imparm+1
       inx
       sta $0100,x     	;new hi ret adr

       pla
       tax
       pla
       tay
       pla
       rts
}
