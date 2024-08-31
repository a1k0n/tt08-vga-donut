`default_nettype none

// purely combinatorial 3-step vectoring CORDIC
// produces an approximation of the vector length of (x,y)

module cordic3step (
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

// four cases again:
// x1 noninverted, y1 > 0 (_parity_in=0)
//   x2 = x1 + (y1>>1) -> _xplusy
//   y2 = y1 - (x1>>1) -> _yminusx
// x1 noninverted, y1 < 0 (_parity_in=1)
//   x2 = x1 - (y1>>1) -> _xminusy
//   y2 = y1 + (x1>>1) -> _yplusx
// x1 inverted, y1 > 0    (_parity_in=1)
//   x2 = -(x1 - (y1>>1)) -> _xminusy, x2sign=1   (x2sign is preserved from x1!)
//   y2 =  y1 + (x1>>1)   -> _yplusx
// x1 inverted, y1 < 0    (_parity_in=0)
//   x2 = -(x1 + (y1>>1)) -> _xplusy, x2sign=1
//   y2 =  y1 - (x1>>1)   -> _yminusx

/*
wire signed [15:0] _xplusy    = step1x  + (step1y>>>1);
wire signed [15:0] _x2plusy2  = step1x2 + (step1y2>>>1);
wire signed [15:0] _yplusx    = step1y  + (step1x>>>1);
wire signed [15:0] _yminusx   = step1y  - (step1x>>>1);
wire signed [15:0] _xminusy   = step1x  - (step1y>>>1);
wire signed [15:0] _y2plusx2  = step1y2 + (step1x2>>>1);
wire signed [15:0] _y2minusx2 = step1y2 - (step1x2>>>1);
wire signed [15:0] _x2minusy2 = step1x2 - (step1y2>>>1);
wire _parity_in = xinvert^step1y[15];

wire signed [15:0] step2x  = _parity_in ? _xminusy   : _xplusy;
wire signed [15:0] step2y  = _parity_in ? _yplusx    : _yminusx;
wire signed [15:0] step2x2 = _parity_in ? _x2minusy2 : _x2plusy2;
wire signed [15:0] step2y2 = _parity_in ? _y2plusx2  : _y2minusx2;
*/

wire signed [15:0] step2x  = (xinvert ? ~step1x : step1x) + (step1y[15] ? ~step1y>>>1 : step1y>>>1);
wire signed [15:0] step2y  = step1y + (step1y[15]^xinvert ? step1x>>>1 : ~step1x>>>1);
wire signed [15:0] step2x2 = (xinvert ? ~step1x2 : step1x2) + (step1y[15] ? ~step1y2>>>1 : step1y2>>>1);
wire signed [15:0] step2y2 = step1y2 + (step1y[15]^xinvert ? step1x2>>>1 : ~step1x2>>>1);

//wire signed [15:0] __xplusy    = step2x  + (step2y>>>2);
//wire signed [15:0] __x2plusy2  = step2x2 + (step2y2>>>2);
//wire signed [15:0] __yplusx    = step2y  + (step2x>>>2);
//wire signed [15:0] __yminusx   = step2y  - (step2x>>>2);
//wire signed [15:0] __xminusy   = step2x  - (step2y>>>2);
//wire signed [15:0] __y2plusx2  = step2y2 + (step2x2>>>2);
//wire signed [15:0] __y2minusx2 = step2y2 - (step2x2>>>2);
//wire signed [15:0] __x2minusy2 = step2x2 - (step2y2>>>2);

wire signed [15:0] step3x  = step2x  + (step2y[15] ? ~step2y>>>2  : step2y>>>2);
//wire signed [15:0] step3y  = _parity_in ? _yplusx    : _yminusx;
wire signed [15:0] step3x2 = step2x2 + (step2y[15] ? ~step2y2>>>2 : step2y2>>>2);
//wire signed [15:0] step3y2 = _parity_in ? _y2plusx2  : _y2minusx2;


//wire signed [15:0] step2x  = step1y[15]^xinvert ? step1x - (step1y>>>1) : step1x + (step1y>>>1);
//wire signed [15:0] step2x2 = step1y2[15]^xinvert ? step1x2 - (step1y2>>>1) : step1x2 + (step1y2>>>1);


/*
wire signed [15:0] x = xin ^ xflip;
wire signed [15:0] y = yin;
wire signed [15:0] x2 = x2in ^ xflip;
wire signed [15:0] y2 = y2in;

wire signed [15:0] yflip   = {16{y[15]}};
wire signed [15:0] yflipn  = {16{~y[15]}};
wire signed [15:0] step1x  = x + (yflip ^ y);
wire signed [15:0] step1y  = y + (yflipn ^ x);
wire signed [15:0] step1x2 = x2 + (yflip ^ y2); // (y[15] ? ~y2 : y2);
wire signed [15:0] step1y2 = y2 + (yflipn ^ x2); // (y[15] ? x2 : ~x2);

wire signed [15:0] yflip2 = {16{step1y[15]}};
wire signed [15:0] step2x  = step1x  + (yflip2 ^ (step1y>>>1));
wire signed [15:0] step2x2 = step1x2 + (yflip2 ^ (step1y2>>>1));
wire signed [15:0] yflip2n = {16{~step1y[15]}};
wire signed [15:0] step2y  = step1y  + (yflip2n ^ (step1x>>>1));
wire signed [15:0] step2y2 = step1y2 + (yflip2n ^ (step1x2>>>1));

wire signed [15:0] yflip3 = {16{step2y[15]}};
wire signed [15:0] step3x  = step2x + (yflip3 ^ (step2y>>>2));
wire signed [15:0] step3x2 = step2x2 + (yflip3 ^ (step2y2>>>2));
*/

/*
wire signed [15:0] step3x  = step2y[15] ? step2x - (step2y>>>2) : step2x + (step2y>>>2);
wire signed [15:0] step3x2 = step2y[15] ? step2x2 - (step2y2>>>2) : step2x2 + (step2y2>>>2);
*/

//assign length = (step2x >>> 1) + (step2x >>> 3);
//assign x2out = (step2x2 >>> 1) + (step2x2 >>> 3);
assign length = (step3x >>> 1) + (step3x >>> 3);
assign x2out = (step3x2 >>> 1) + (step3x2 >>> 3);

endmodule
