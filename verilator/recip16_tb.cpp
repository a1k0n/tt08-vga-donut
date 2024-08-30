#include <stdint.h>
#include "Vrecip16.h"
#include "Vrecip16__Syms.h"
#include "verilated.h"

int main(int argc, char** argv) {
  Verilated::commandArgs(argc, argv);

  Vrecip16* top = new Vrecip16;

  top->clk = 0;
  top->start = 0;
  top->denom = 0;

  top->eval();

  // Test cases
  int test_cases[] = {33, 64, 65, 66, 200, 201, 202, 272, 280};

  for (int denom : test_cases) {
    top->start = 1;
    top->denom = denom;

    // Run for 20 clock cycles (adjust if needed)
    for (int i = 0; i < 18; i++) {
      top->clk = !top->clk;
      top->eval();
      top->clk = !top->clk;
      top->eval();
      top->start = 0;  // Turn off start signal after 1 full clock cycle

      uint32_t runsigned = top->rootp->recip16__DOT__r;
      int32_t r = runsigned;
      // sign extend from 25 bits
      if (r & 0x1000000) {
        r |= 0xFE000000;
      }
      uint32_t d = top->rootp->recip16__DOT__d;
      printf("clk: %d q: %d i: %d r: %x (%d) d: %d\n", i,
             top->rootp->recip16__DOT__q, top->rootp->recip16__DOT__i,
             runsigned, r, d);
    }
    int expected = 65536 / denom;
    int actual = top->recip;

    printf("Denominator: %d\n", denom);
    printf("Expected: %d\n", expected);
    printf("Actual: %d\n", actual);
  }

  delete top;
  return 0;
}
