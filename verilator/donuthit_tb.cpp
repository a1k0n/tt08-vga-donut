#include <stdint.h>
#include "Vdonuthit.h"
#include "Vdonuthit__Syms.h"
#include "verilated.h"

/*
  test vector dumped from donut demo

  $pxyz (-111,+563,-531)
  [0] (px py pz)=(-111 563 -531) (lx ly lz)=(127 355 -5780) (rx ry rz)=(-4790 -12629 10144) -> t0=562 (lx', ly') = (292, 355) (*) t1=50 (lz', lx') = (5510, 292) t2=513 d=257 t=769
  [1] (px py pz)=(-187 364 -372) (lx ly lz)=(127 355 -5780) (rx ry rz)=(-4790 -12629 10144) -> t0=398 (lx', ly') = (292, 355) (*) t1=-114 (lz', lx') = (5327, 292) t2=383 d=127 t=896
  [2] (px py pz)=(-225 266 -294) (lx ly lz)=(127 355 -5780) (rx ry rz)=(-4790 -12629 10144) -> t0=318 (lx', ly') = (292, 355) (*) t1=-194 (lz', lx') = (5327, 292) t2=336 d=80 t=976
  [3] (px py pz)=(-249 204 -245) (lx ly lz)=(127 355 -5780) (rx ry rz)=(-4790 -12629 10144) -> t0=297 (lx', ly') = (-9, 355) (*) t1=-215 (lz', lx') = (5421, -9) t2=296 d=40 t=1016
  [4] (px py pz)=(-261 173 -221) (lx ly lz)=(127 355 -5780) (rx ry rz)=(-4790 -12629 10144) -> t0=298 (lx', ly') = (-9, 355) (*) t1=-214 (lz', lx') = (5421, -9) t2=273 d=17 t=1033
  [5] (px py pz)=(-266 159 -211) (lx ly lz)=(127 355 -5780) (rx ry rz)=(-4790 -12629 10144) -> t0=298 (lx', ly') = (-9, 355) (*) t1=-214 (lz', lx') = (1815, -9) t2=266 d=10 t=1043
  [6] (px py pz)=(-269 151 -205) (lx ly lz)=(127 355 -5780) (rx ry rz)=(-4790 -12629 10144) -> t0=298 (lx', ly') = (-9, 355) (*) t1=-214 (lz', lx') = (1815, -9) t2=265 d=9 t=1052
  [7] (px py pz)=(-272 144 -200) (lx ly lz)=(127 355 -5780) (rx ry rz)=(-4790 -12629 10144) -> t0=300 (lx', ly') = (-9, 355) (*) t1=-212 (lz', lx') = (1815, -9) t2=261 d=5 t=1057

*/

int main(int argc, char** argv) {
  Verilated::commandArgs(argc, argv);

  Vdonuthit * top = new Vdonuthit;
  top->start = 1;
  top->pxin = -111;
  top->pyin = 563;
  top->pzin = -531;
  top->lxin = 127;
  top->lyin = 355;
  top->lzin = -5780;
  top->rxin = -4790;
  top->ryin = -12629;
  top->rzin = 10144;
  
  for (int i = 0; i < 8; i++) {
    top->clk = 0; top->eval(); top->clk = 1; top->eval();
    // pull out updated internal registers
    printf("[%d] t=%d, t0=%d t1=%d t2=%d; pxyz (%d,%d,%d) lx1 %d\n", i, 
      (int16_t)(top->rootp->donuthit__DOT__t),
      (int16_t)(top->rootp->donuthit__DOT__t0),
      (int16_t)(top->rootp->donuthit__DOT__t0) - 512,
      (int16_t)(top->rootp->donuthit__DOT__t2),
      (int16_t)(top->rootp->donuthit__DOT__px),
      (int16_t)(top->rootp->donuthit__DOT__py),
      (int16_t)(top->rootp->donuthit__DOT__pz),
      (int16_t)(top->rootp->donuthit__DOT__step1_lx));
    // pull out the hit and light signals
    printf("[%d] hit: %d light: %d\n", i, top->hit, top->light);

    top->start = 0;
  }
}
