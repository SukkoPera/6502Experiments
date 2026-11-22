snare_data
	!word $43A4
	!word $2210
	!word $43C4
	!word $2110
	!word $43B7
	!word $43E6
	!word $43A5
	!word $43E4
	!word $4393
	!word $4252
	!word $4231
	!word $4210

vol_default
	!byte 8,8,8,8, 7,7,7,7, 6,6,6,6, 5,5,5,5, 4,4,4,4, 6,7
	!byte 8,8, 7,7, 6,6, 5,5, 6,7
	;
	!byte $FF
	
Channel1 
	!word pat_bass
	!word pat_drums,pat_drums
	;
	!word pat_bass_drums,pat_bass_drums_1
	!word pat_bass_drums,pat_bass_drums_2
	;
	!word pat_bass_drums,pat_bass_drums_1,pat_bass_drums,pat_bass_drums_1
	!word pat_bass_drums,pat_bass_drums_1,pat_bass_drums,pat_bass_drums_2
	;
	!word pat_bass_drums,pat_bass_drums_1
	!word pat_bass_drums,pat_bass_drums_2
	;
	!word pat_bass_drums,pat_bass_drums_1,pat_bass_drums,pat_bass_drums_1
	!word pat_bass_drums,pat_bass_drums_1,pat_bass_drums,pat_bass_drums_2
	;
	!word pat_bass_drums,pat_bass_drums_1
	!word pat_bass_drums,pat_bass_drums_2
	;
	!word 0
	
Channel2
	!word pat_quiet
	!word pat_bass
	;
	!word pat_chords
	!word pat_chords
	;
	!word pat_lead
	!word pat_lead
	;
	!word pat_chords
	!word pat_chords
	;
	!word pat_lead_2,pat_lead_2
	!word pat_lead_2,pat_lead_2
	;
	!word pat_chords
	!word pat_chords
	;
	!word 0
	;
speed1 = 22
speed2 = 10

def = SET_INS + $0
hht = SET_INS + $1
snr = SET_INS + $2
vib = SET_INS + $5

pat_quiet
	!byte def
	!byte LEN+(speed1+speed2)*4
	!byte OFF,OFF,OFF,OFF
	!byte END_MARK

pat_drums
	!byte SET_VOLTAB, vol_default & 255
	;
	!byte hht, LEN+1,        62,  LEN+speed1-1, OFF
	!byte hht, LEN+1,        62,  LEN+speed2-1, OFF
	!byte hht, LEN+1,        62,  LEN+speed1-1, OFF
	!byte hht, LEN+1,        62,  LEN+speed2-1, OFF
	!byte snr, LEN+12,       0,   LEN+speed1-12, OFF
	!byte hht, LEN+1,        62,  LEN+speed2-1, OFF
	!byte hht, LEN+1,        62,  LEN+speed1-1, OFF
	!byte hht, LEN+1,        62,  LEN+speed2-1, OFF
	;
	!byte hht, LEN+1,        62,  LEN+speed1-1, OFF
	!byte snr, LEN+8,        0,   LEN+speed2-8, OFF
	!byte hht, LEN+1,        62,  LEN+speed1-1, OFF
	!byte hht, LEN+1,        62,  LEN+speed2-1, OFF
	!byte snr, LEN+12,       0,   LEN+speed1-12, OFF
	!byte hht, LEN+1,        62,  LEN+speed2-1, OFF
	!byte hht, LEN+1,        62,  LEN+speed1-1, OFF
	!byte hht, LEN+1,        62,  LEN+speed2-1, OFF
	;
	!byte END_MARK

pat_bass
	!byte vib, LEN+speed1-2, C0,  VOFF+2
	!byte      LEN+speed2-2, OFF, VOFF+2
	!byte      LEN+speed1-2, OFF, VOFF+2
	!byte      LEN+speed2-2, Ai0, VOFF+2
	!byte      LEN+speed1-2, OFF, VOFF+2
	!byte      LEN+speed2-2, OFF, VOFF+2
	!byte      LEN+2,        Ai0
	!byte      LEN+speed1-4, C1,  VOFF+2
	!byte      LEN+speed2-2, OFF, VOFF+2
	;
	!byte      LEN+speed1-2, OFF, VOFF+2
	!byte      LEN+speed2-2, OFF, VOFF+2
	!byte      LEN+speed1-2, C1,  VOFF+2
	!byte      LEN+speed2-2, OFF, VOFF+2
	!byte      LEN+speed1-2, Ai0, VOFF+2
	!byte      LEN+speed2-2, G0,  VOFF+2
	!byte      LEN+speed1-2, Di0, VOFF+2
	!byte      LEN+speed2-2, OFF, VOFF+2
	;
	!byte      LEN+speed1-2, F0,  VOFF+2
	!byte      LEN+speed2-2, OFF, VOFF+2
	!byte      LEN+speed1-2, OFF, VOFF+2
	!byte      LEN+speed2-2, Di1, VOFF+2
	!byte      LEN+speed1-2, OFF, VOFF+2
	!byte      LEN+speed2-2, OFF, VOFF+2
	!byte      LEN+2,        Di1
	!byte      LEN+speed1-4, F1,  VOFF+2
	!byte      LEN+speed2-2, OFF, VOFF+2
	;
	!byte      LEN+speed1-2, OFF, VOFF+2
	!byte      LEN+speed2-2, Di1, VOFF+2
	!byte      LEN+speed1-2, F1,  VOFF+2
	!byte      LEN+speed2-2, Di1, VOFF+2
	!byte      LEN+speed1-2, Gi0, VOFF+2
	!byte      LEN+speed2-2, Ai0, VOFF+2
	!byte      LEN+speed1-2, Di0, VOFF+2
	!byte      LEN+speed2-2, F0,  VOFF+2
	;
	!byte END_MARK

pat_bass_drums
	!byte hht, LEN+1,        62
	!byte vib, LEN+speed1-3, C0,  VOFF+2
	!byte hht, LEN+1,        62,  LEN+speed2-1, OFF
	!byte      LEN+1,        62,  LEN+speed1-1, OFF
	!byte      LEN+1,        62
	!byte vib, LEN+speed2-3, Ai0, VOFF+2
	!byte snr, LEN+12,       0,   LEN+speed1-12,OFF
	!byte hht, LEN+1,        62,  LEN+speed2-1, OFF
	!byte      LEN+1,        62
	!byte vib, LEN+1,        Ai0
	!byte      LEN+speed1-4, C1,  VOFF+2
	!byte hht, LEN+1,        62,  LEN+speed2-1, OFF
	;
	!byte hht, LEN+1,        62,  LEN+speed1-1, OFF
	!byte snr, LEN+8,        0,   LEN+speed2-8, OFF
	!byte hht, LEN+1,        62
	!byte vib, LEN+speed1-3, C1,  VOFF+2
	!byte hht, LEN+1,        62,  LEN+speed2-1, OFF
	!byte snr, LEN+12,       0
	!byte vib, LEN+speed1-14,Ai0, VOFF+2
	!byte hht, LEN+1,        62
	!byte vib, LEN+speed2-3, G0,  VOFF+2
	!byte hht, LEN+1,        62
	!byte vib, LEN+speed1-3, Di0, VOFF+2
	!byte hht, LEN+1,        62,  LEN+speed2-1, OFF
	;
	!byte hht, LEN+1,        62
	!byte vib, LEN+speed1-3, F0,  VOFF+2
	!byte hht, LEN+1,        62,  LEN+speed2-1, OFF
	!byte      LEN+1,        62,  LEN+speed1-1, OFF
	!byte      LEN+1,        62
	!byte vib, LEN+speed2-3, Di1, VOFF+2
	!byte snr, LEN+12,       0,   LEN+speed1-12,OFF
	!byte hht, LEN+1,        62,  LEN+speed2-1, OFF
	!byte      LEN+1,        62
	!byte vib, LEN+1,        Di1
	!byte      LEN+speed1-4, F1,  VOFF+2
	!byte hht, LEN+1,        62,  LEN+speed2-1, OFF
	;
	!byte hht, LEN+1,        62,  LEN+speed1-1, OFF
	!byte snr, LEN+4,        0
	!byte vib, LEN+speed2-6, Di1, VOFF+2
	!byte hht, LEN+1,        62
	!byte vib, LEN+speed1-3, F1,  VOFF+2
	!byte hht, LEN+1,        62
	!byte vib, LEN+speed2-3, Di1, VOFF+2
	!byte snr, LEN+12,       0
	!byte vib, LEN+speed1-14,Gi0, VOFF+2
	!byte hht, LEN+1,        62
	!byte vib, LEN+speed2-3, Ai0, VOFF+2
	;
	!byte END_MARK

pat_bass_drums_1
	!byte hht, LEN+1,        62
	!byte vib, LEN+speed1-3, Di0, VOFF+2
	!byte hht, LEN+1,        62
	!byte vib, LEN+speed2-3, F0,  VOFF+2
	;
	!byte END_MARK

pat_bass_drums_2
	!byte snr, LEN+8,        0
	!byte vib, LEN+speed1-10,Di0, VOFF+2
	!byte snr, LEN+6,        0
	!byte vib, LEN+speed2-8, F0,  VOFF+2
	;
	!byte END_MARK

pat_chords
	!byte SET_ARP_358
	!byte LEN+(speed1+speed2)*4, G1
	!byte LEN+speed1+speed2,     OFF
	!byte LEN+8,                 G1, LEN+speed1-8, OFF
	!byte LEN+speed2+speed1,     OFF
	!byte LEN+8,                 G1, LEN+speed2-8, OFF
	!byte LEN+speed1+speed2,     OFF
	;
	!byte SET_ARP_47A
	!byte LEN+(speed1+speed2)*4, F1
	!byte LEN+speed1+speed2,     OFF
	!byte LEN+8,                 F1, LEN+speed1-8, OFF
	!byte LEN+speed2+speed1,     OFF
	!byte LEN+8,                 F1, LEN+speed2-8, OFF
	!byte LEN+speed1+speed2,     OFF
	!byte END_MARK

pat_lead
	!byte vib, LEN+speed1+speed2-2,   OFF, VOFF+2
	!byte      LEN+speed1-2,          C2,  VOFF+2
	!byte      LEN+speed2,            OFF
	!byte      LEN+speed1+speed2-2,   Di2, VOFF+2
	!byte      LEN+speed1-2,          C2,  VOFF+2
	!byte      LEN+speed1+speed2*2-2, Di2, VOFF+2
	!byte      LEN+speed1+speed2-2,   C2,  VOFF+2
	!byte                             Di2, VOFF+2
	!byte      LEN+speed1-2,          Ai2, VOFF+2
	!byte      LEN+(speed1+speed2)*4-2, A2, VOFF+2
	!byte      LEN+speed2,            OFF
	;
	!byte SET_ARP_C
	!byte      LEN+speed1-2,          Di2, VOFF+2
	!byte      LEN+speed2-2,          F2,  VOFF+2
	!byte      LEN+speed1-2,          G2,  VOFF+2
	!byte      LEN+speed1+speed2-2,   Di2, VOFF+2
	!byte                             C2,  VOFF+2
	!byte      LEN+speed2-2,          OFF, VOFF+2
	;
	!byte vib, LEN+speed1+speed2-2,   OFF, VOFF+2
	!byte      LEN+speed1-2,          C2,  VOFF+2
	!byte      LEN+speed2,            OFF
	!byte      LEN+speed1+speed2-2,   Di2, VOFF+2
	!byte      LEN+speed1-2,          C2,  VOFF+2
	!byte      LEN+speed1+speed2*2-2, Di2, VOFF+2
	!byte      LEN+speed1+speed2-2,   C2,  VOFF+2
	!byte                             Di2, VOFF+2
	!byte      LEN+speed1-2,          Ai1, VOFF+2
	!byte      LEN+(speed1+speed2)*4-2, A1, VOFF+2
	!byte      LEN+speed2,            OFF
	;
	!byte SET_ARP_C
	!byte      LEN+speed1-2,          G2,  VOFF+2
	!byte      LEN+speed2-2,          F2,  VOFF+2
	!byte      LEN+speed1-2,          G2,  VOFF+2
	!byte      LEN+speed2-2,          G2,  VOFF+2
	!byte      LEN+speed1-2,          Di2, VOFF+2
	!byte      LEN+speed2-2,          C2,  VOFF+2
	!byte      LEN+speed1-2,          Ai1, VOFF+2
	!byte      LEN+speed2-2,          C2,  VOFF+2
	!byte END_MARK

pat_lead_2
	!byte vib, LEN+speed1-2,          F2,  VOFF+2
	!byte      LEN+speed2-2,          Fi2, VOFF+2
	!byte      LEN+speed1-2,          G2,  VOFF+2
	!byte      LEN+speed2-2,          OFF, VOFF+2
	!byte      LEN+2,                 D2
	!byte      LEN+speed1-4,          Di2, VOFF+2
	!byte      LEN+speed2-2,          OFF, VOFF+2
	!byte      LEN+speed1-2,          C2,  VOFF+2
	!byte      LEN+speed2*2+speed1-2, Ai1, VOFF+2
	!byte      LEN+speed1-2,          C2,  VOFF+2
	;
	!byte      LEN+speed1*2+speed2*3, OFF
	;
	!byte vib, LEN+speed1-2,          F2,  VOFF+2
	!byte      LEN+speed2-2,          Fi2, VOFF+2
	!byte      LEN+speed1-2,          G2,  VOFF+2
	!byte      LEN+speed2-2,          OFF, VOFF+2
	!byte      LEN+2,                 D2
	!byte      LEN+speed1-4,          Di2, VOFF+2
	!byte      LEN+speed2-2,          OFF, VOFF+2
	!byte      LEN+speed1-2,          C2,  VOFF+2
	!byte      LEN+speed2*2+speed1-2, Ai1, VOFF+2
	!byte      LEN+speed1-2,          C2,  VOFF+2
	!byte      LEN+speed2-2,          OFF, VOFF+2
	;
	!byte      LEN+speed1-2,          Ai1, VOFF+2
	!byte      LEN+speed2-2,          C2,  VOFF+2
	!byte      LEN+speed1-2,          Ai1, VOFF+2
	!byte      LEN+speed2-2,          C2,  VOFF+2
	;
	!byte END_MARK
;[eof]
