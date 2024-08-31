PROJ=demo_orangecrab

# `r0.1` or `r0.2` or `r0.2.1`
VERSION:=r0.2
# `25F` or `85F`
DENSITY=25F

ifneq (,$(findstring 85,$(DENSITY)))
	NEXTPNR_DENSITY:=--85k
else
	NEXTPNR_DENSITY:=--25k
endif

# Add Windows and Unix support
RM         = rm -rf
COPY       = cp -a
PATH_SEP   = /
ifeq ($(OS),Windows_NT)
# When SHELL=sh.exe and this actually exists, make will silently
# switch to using that instead of cmd.exe.  Unfortunately, there's
# no way to tell which environment we're running under without either
# (1) printing out an error message, or (2) finding something that
# works everywhere.
# As a result, we force the shell to be cmd.exe, so it works both
# under cygwin and normal Windows.
SHELL      = cmd.exe
COPY       = copy
RM         = del
PATH_SEP   = \\
endif


all: ${PROJ}.dfu

dfu: ${PROJ}.dfu
	dfu-util --alt 0 -D $<


%.json: %.v
	yosys -p "read_verilog $<; synth_ecp5 -json $@"

demo_orangecrab.json: demo_orangecrab.v ../src/vgadonut.v ../src/donuthit.v ../src/cordic2step.v ../src/cordic3step.v ../src/donut.v ../src/step3vec.v
	yosys -p "read_verilog $^; synth_ecp5 -abc2 -json $@ -top demo_orangecrab; ltp"

%_out.config: %.json
	nextpnr-ecp5 --json $< --textcfg $@ $(NEXTPNR_DENSITY) --package CSFBGA285 --lpf orangecrab_${VERSION}.pcf --lpf-allow-unconstrained

%.bit: %_out.config
	ecppack --compress --freq 38.8 --input $< --bit $@

%.dfu : %.bit
	$(COPY) $< $@
	dfu-suffix -v 1209 -p 5af0 -a $@

clean:
	$(RM) -f ${PROJ}.bit ${PROJ}_out.config ${PROJ}.json ${PROJ}.dfu

.PHONY: prog clean
