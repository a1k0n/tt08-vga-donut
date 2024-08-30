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
wire signed [15:0] xflip = {16{xin[15]}};
wire signed [15:0] x = xin ^ xflip;
wire signed [15:0] y = yin;
wire signed [15:0] x2 = x2in ^ xflip;
wire signed [15:0] y2 = y2in;

wire signed [15:0] step1x, step1y, step1x2, step1y2;
wire signed [15:0] step2x, step2x2;

wire signed [15:0] yflip = {16{y[15]}};
wire signed [15:0] yflipn = {16{~y[15]}};
assign step1x  = x + (yflip ^ y);
assign step1y  = y + (yflipn ^ x);
assign step1x2 = x2 + (yflip ^ y2); // (y[15] ? ~y2 : y2);
assign step1y2 = y2 + (yflipn ^ x2); // (y[15] ? x2 : ~x2);

wire signed [15:0] yflip2 = {16{step1y[15]}};
//wire signed [15:0] yflipn2 = {16{~step1y[15]}};
//assign step2x  = step1x + (step1y[15] ? ~(step1y>>>1)  : (step1y>>>1));
//assign step2x2 = step1x2 + (step1y[15] ? ~(step1y2>>>1) : (step1y2>>>1));
assign step2x  = step1x + (yflip2 ^ (step1y>>>1));
assign step2x2 = step1x2 + (yflip2 ^ (step1y2>>>1));

//assign step2y  = step1y[15] ? step1y + (step1x>>1) : step1y - (step1x>>1);
//assign step2y2 = step1y[15] ? step1y2 + (step1x2>>1) : step1y2 - (step1x2>>1);

//assign length = (step2x >>> 1) + (step2x >>> 3);
//assign x2out = (step2x2 >>> 1) + (step2x2 >>> 3);
assign length = (step2x >>> 1) + (step2x >>> 3);
assign x2out = (step2x2 >>> 1) + (step2x2 >>> 3);

endmodule
