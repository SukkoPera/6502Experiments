WICP4_OPTS = -I ../wic64-library -DPLUS4=1 -DPLUSVIA=1
OPTS = -v --color -f cbm -l $(@:prg=lst) --vicelabels $(@:prg=vice) # -Wtype-mismatch 
X64SC_OPTS =
XPLUS4_OPTS =

.PHONY: all

all: p4wlatest.prx p4wlatest-debug.prx

#~ %.prg: %.asm
#~ 	acme $(OPTS) -I ../HwLib -o $@ $<

p4wlatest.prg: p4wlatest.asm !player.asm !player_data.asm !playerv.asm music.asm portalcharset.bin data.bin
	acme $(OPTS) -I ../HwLib $(WICP4_OPTS) -o $@ $<

p4wlatest-debug.prg: p4wlatest.asm !player.asm !player_data.asm !playerv.asm music.asm portalcharset.bin data.bin
	acme $(OPTS) -I ../HwLib $(WICP4_OPTS) -DDEBUG=1 -o $@ $<
	
%.prx: %.prg
	exomizer sfx sys -t4 -n -o $@ $<

data.bin:
	curl https://plus4world.powweb.com/latest.php?limit=100 --output $@

clean:
	rm -f *.prg *.prx *.lst *.vice *.mon

debug: p4wlatest-debug.prx
	echo "ll \"$(<:prx=vice)\"" > xplus4.mon
	echo "break .breakhere" >> xplus4.mon
	xplus4 -moncommands xplus4.mon $(XPLUS4_OPTS) $^
