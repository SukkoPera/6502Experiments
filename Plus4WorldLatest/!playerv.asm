!addr {
	; Variables
	
	PCH1		= $12		; channel data pattern pointers
	PCH2		= $14
	PCH3		= $15

	PCH1_LO		= $1A
	PCH2_LO		= $1B
	PCH3_LO		= $1C
	PCH1_HI		= $22
	PCH2_HI		= $23
	PCH3_HI		= $24

	PCH_TEMP	= $25		; 16 bit

	CH1_LO		= $27		; channel data pointers
	CH2_LO		= $28
	CH3_LO		= $29
	CH1_HI		= $57
	CH2_HI		= $58
	CH3_HI		= $59

	CH_TEMP		= $fd		; 16 bit

	NOTE1		= $5B		; note counters
	NOTE2		= $5C
	NOTE3		= $5D
	NOTELEN1	= $5E		; current note lengths
	NOTELEN2	= $5F
	NOTELEN3	= $60

	INS_TYPE1	= $61
	INS_TYPE2	= $62
	INS_TYPE3	= $63
	TONE1		= $64
	TONE2		= $65
	TONE3		= $66
	;
	ARP_CNT		= $67
	ARP_LEN		= $68
	;
	NOISE		= $6B
	VOLUME		= $6C
	VOLTAB_CNT	= $6D
	TMP_Y		= $72
	FRAME_CNT	= $73
}
