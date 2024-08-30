// donut ray-marching hit test
module donuthit (
    input clk,
    input start,
    input signed [15:0] pxin,    // origin point
    input signed [15:0] pyin,
    input signed [15:0] pzin,
    input signed [15:0] rxin,    // ray direction
    input signed [15:0] ryin,
    input signed [15:0] rzin,
    input signed [15:0] lxin,    // light direction
    input signed [15:0] lyin,
    input signed [15:0] lzin,
    // these are valid after 8 clocks
    output reg hit,                // hit flag
    output reg signed [15:0] light // light intensity
);

// torus radii
parameter r1 = 1;
parameter r2 = 2;

parameter r1i = r1*256;
parameter r2i = r2*256;

reg signed [15:0] px, py, pz;    // origin point
reg signed [15:0] rx, ry, rz;    // ray direction
wire signed [15:0] lx, ly, lz;    // light direction
reg signed [15:0] t;             // distance along ray

assign lx = lxin;
assign ly = lyin;
assign lz = lzin;

wire signed [15:0] t0;
wire signed [15:0] t1 = t0 - r2i;
wire signed [15:0] t2;
wire signed [15:0] step1_lx, step2_lz;
wire signed [15:0] d = t2 - r1i;

// this multiplier is unfortunate
/*
wire signed [13:0] px_projected = $signed(d[10:5]) * $signed(rx[15:9]);
wire signed [13:0] py_projected = $signed(d[10:5]) * $signed(ry[15:9]);
wire signed [13:0] pz_projected = $signed(d[10:5]) * $signed(rz[15:9]);
*/

wire signed [15:0] px_projected, py_projected, pz_projected;
step3vec step3vec_x (
  .d(d[10:0]),
  .xin_(rx),
  .yin_(ry),
  .zin_(rz),
  .xout(px_projected),
  .yout(py_projected),
  .zout(pz_projected)
);

wire _unused_ok = &{px_projected[5:0], py_projected[5:0], pz_projected[5:0],
  rx[9:0], ry[9:0], rz[9:0]};

cordic2step cordicxy (
  .xin(px),
  .yin(py),
  .x2in(lx),
  .y2in(ly),
  .length(t0),
  .x2out(step1_lx)
);

cordic2step cordicxz (
  .xin(pz),
  .yin(t1),
  .x2in(lz),
  .y2in(step1_lx),
  .length(t2),
  .x2out(step2_lz)
);

// on start, clock in all inputs (can't assume they're valid after start)
always @(posedge clk) begin
  if (start) begin
    // these do not get recomputed every step, so just latch them
    rx <= rxin;
    ry <= ryin;
    rz <= rzin;
    /*
    lx <= lxin;
    ly <= lyin;
    lz <= lzin;
    */
    px <= pxin;
    py <= pyin;
    pz <= pzin;
    t <= 512;
    hit <= 1;
  end else begin
    t <= t + d;
    hit <= hit & ((t+d) < 2048);
    /*
    px <= px + {{2{px_projected[13]}}, px_projected};
    py <= py + {{2{py_projected[13]}}, py_projected};
    pz <= pz + {{2{pz_projected[13]}}, pz_projected};
    */
    px <= px + px_projected;
    py <= py + py_projected;
    pz <= pz + pz_projected;
  end
  light <= step2_lz;
end

endmodule
