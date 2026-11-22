; As uncomfortable as it might be, in this file we try to stick to the function names as defined in the KERNAL sources
; for the 264 series, in order to make it easy to cross-reference a call to the actual code.

;-----------------------------------------------------------------------------------------------------------------------
; KERNAL variables
;-----------------------------------------------------------------------------------------------------------------------

!addr {
!ifdef PLUS4 {
    ; 264 series only
    KRN_LONGJMP_DEST = $05f0                ; Long jump address for banking 'long' routine (lngjmp)
    KRN_LONGJMP_A = $05f2                   ; A for/from routing being long-jumped to (fetarg)
    KRN_LONGJMP_X = $05f3                   ; X for/from routing being long-jumped to (fetxrg)
    KRN_LONGJMP_S = $05f4                   ; S(tatus) for/from routing being long-jumped to (fetsrg)
}
}

;-----------------------------------------------------------------------------------------------------------------------
; KERNAL functions
;-----------------------------------------------------------------------------------------------------------------------
; The "KRN_" prefix was added in order to make it clear that a KERNAL functions is being called.
; For these functions to work, the KERNAL ROM must be banked in, and ROMs must be enabled. Use LONGJMP otherwise.
;-----------------------------------------------------------------------------------------------------------------------

!addr {
!ifdef PLUS4 {
	KRN_SCNCLR = $c567					; Clear screen
	
	KRN_TOQM = $dc9b                    ; Turn off Insert/Reverse/Flash
	
	; These are in a jump table, so they might also work on later platforms (C128?)
    KRN_GOBVEC = $fcf1                  ; JMP to IRQ routine for cartridge
    KRN_FETCHL = $fcf7
    KRN_LONGJMP = $fcfa                 ; Call a subroutine in another bank (named just "long" in sources)
    KRN_LNGIRQ = $fcfd
}                

!ifdef PLUS4 {
    KRN_DEFKEY   = $ff49
    KRN_PRINT    = $ff4c
    KRN_PRIMM    = $ff4f
    KRN_MONITOR  = $ff52
}
}

!source "../HwLib/uni_kernal.asm"
