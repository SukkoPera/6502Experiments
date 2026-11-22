; As uncomfortable as it might be, in this file we try to stick to the function names as defined in the BASIC sources
; for the 264 series, in order to make it easy to cross-reference a call to the actual code.

;-----------------------------------------------------------------------------------------------------------------------
; KERNAL variables
;-----------------------------------------------------------------------------------------------------------------------
!addr {
    BAS_PROGRAM_START = $2b           ; TXTTAB
    BAS_VARIABLES_START = $2d         ; VARTAB
    BAS_ARRAYS_START = $2f            ; ARYTAB
    BAS_ARRAYS_END = $31              ; STREND
    SAVE_ADDRESS_END = $9d            ; EAL/EAH
}

;-----------------------------------------------------------------------------------------------------------------------
; BASIC functions
;-----------------------------------------------------------------------------------------------------------------------
; The "BAS_" prefix was added in order to make it clear that a BASIC functions is being called.
; For these functions to work, the BASIC ROM must be banked in, and ROMs must be enabled. Use LONGJMP otherwise.
;-----------------------------------------------------------------------------------------------------------------------
!addr {
    BAS_INITCZ = $802e                ; Init BASIC
    BAS_INITV = $8117                 ; Init BASIC vectors
    BAS_LNKPRG = $8818
       
	BAS_RUN = $8bbe                   ; Should actually be $8bbc...
    BAS_NEWSTT = $8bdc
}
