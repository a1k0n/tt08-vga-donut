`default_nettype none

// purely combinatorial 2-step vectoring CORDIC
// produces an approximation of the vector length of (x,y)
// while also rotating (x2, y2) along with it and returning x2
// just 2 steps, this gives us a way to render faceted objects while racing the
// beam

module cordic2step (
  input signed [15:0] xin,
  input signed [15:0] yin,
  input signed [15:0] x2in,
  input signed [15:0] y2in,
  output [15:0] length,
  output signed [15:0] x2out
);

// purely combinational logic, no registers!
//wire signed [15:0] xflip = {16{xin[15]}};

// compute these sums as early as possible and mux their results
// propagate the final sign bits separately so the sums don't have to wait
wire signed [15:0] xplusy = xin + yin;
wire signed [15:0] yminusx = yin - xin;
wire signed [15:0] x2plusy2 = x2in + y2in;
wire signed [15:0] y2minusx2 = y2in - x2in;

// four cases:
// x > 0, y > 0
//   x1 = x + y -> xplusy,  x1sign=0
//   y1 = y - x -> yminusx
// x > 0, y < 0
//   x1 = x - y -> yminusx, x1sign=1
//   y1 = y + x -> xplusy
// x < 0, y > 0
//   x1 = -x +  y -> yminusx, x1sign=0
//   y1 =  y - -x -> xplusy
// x < 0, y < 0
//   x1 = -x -  y -> xplusy,  x1sign=1
//   y1 =  y + -x -> yminusx

// so:
// x1sign = y[15]
// if x[15]^y[15] == 0: (same sign)
//   x1 = xplusy, y1 = yminusx
// else: (different sign)
//   x1 = yminusx, y1 = xplusy

// the first step also needs to mirror x into the right half-plane
// it just so happens that if the initial y input is negative, then
// every step of cordic will also invert x
// so we're going to separately track the x mirroring until the end as it
// saves a gate delay at each step
wire xinvert = yin[15];
wire parity_in = xin[15]^yin[15];
wire signed [15:0] step1x  = parity_in ? yminusx   : xplusy;
wire signed [15:0] step1y  = parity_in ? xplusy    : yminusx;
wire signed [15:0] step1x2 = parity_in ? y2minusx2 : x2plusy2;
wire signed [15:0] step1y2 = parity_in ? x2plusy2  : y2minusx2;

wire signed [15:0] step2x  = (xinvert ? ~step1x : step1x) + (step1y[15] ? ~step1y>>>1 : step1y>>>1);
//wire signed [15:0] step2y  = step1y + (step1y[15]^xinvert ? step1x>>>1 : ~step1x>>>1);
wire signed [15:0] step2x2 = (xinvert ? ~step1x2 : step1x2) + (step1y[15] ? ~step1y2>>>1 : step1y2>>>1);
//wire signed [15:0] step2y2 = step1y2 + (step1y[15]^xinvert ? step1x2>>>1 : ~step1x2>>>1);

assign length = (step2x >>> 1) + (step2x >>> 3);
assign x2out = (step2x2 >>> 1) + (step2x2 >>> 3);

endmodule
