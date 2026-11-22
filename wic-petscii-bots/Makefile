WIC64_OPTS = -I ../wic64-library
WICP4_OPTS = -I ../wic64-library -DPLUS4=1
OPTS = -v --color -f cbm -l $(@:prg=lst) --vicelabels $(@:prg=vice) #-Wtype-mismatch
X64SC_OPTS =
XPLUS4_OPTS =

all: wic-petscii-bots.prx

%.prx: %.prg
	exomizer sfx sys -t4 -n -o $@ $<

wic-petscii-bots.prg: wic-petscii-bots.asm portalcharset.bin
	acme $(OPTS) -I ../HwLib $(WICP4_OPTS) -o $@ $<

wic-petscii-bots-64.prg: wic-petscii-bots.asm portalcharset.bin
	acme $(OPTS) $(WIC64_OPTS) -o $@ $<

clean:
	rm -f *.prg *.prx *.lst *.vice *.mon

test: wic-petscii-bots.prx
	echo "ll \"$(<:prx=vice)\"" > xplus4.mon
	echo "break .breakhere" >> xplus4.mon
	xplus4 -moncommands xplus4.mon $(XPLUS4_OPTS) $<

test64: wic-petscii-bots-64.prg
	echo "ll \"$(<:prg=vice)\"" > x64sc.mon
#~ 	echo "break .breakhere" >> x64sc.mon
	x64sc -moncommands x64sc.mon $(X64SC_OPTS) $<
