TARGETS = cordic2step vgadonut donuthit
VERILATOR = verilator
VERILATOR_FLAGS = -Wall --trace -cc --exe -I../src
CPP = g++
CPP_FLAGS = -std=c++11 -Wall

all: $(TARGETS)

vgadonut: ../src/vgadonut.v ../src/donuthit.v ../src/donut.v ../src/cordic2step.v ../src/cordic3step.v ../src/step3vec.v vgadonut_tb.cpp
	$(VERILATOR) -Wno-widthexpand -Wno-widthtrunc --trace -cc --exe $^ -CFLAGS "-g -O3" --LDFLAGS "-lSDL2 -lSDL2_image" --top-module vgadonut
	$(MAKE) -C obj_dir -f V$@.mk
	cp obj_dir/V$@ $@

%: ../src/%.v %_tb.cpp
	$(VERILATOR) $(VERILATOR_FLAGS) $< $*_tb.cpp
	$(MAKE) -C obj_dir -f V$@.mk
	cp obj_dir/V$@ $@

clean:
	rm -rf obj_dir
	rm -f $(TARGETS)
	rm -f *.vcd

.PHONY: all clean
