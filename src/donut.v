// render a ray-marched donut
// takes 8 clock cycles per pixel, so this will have to be pipelined for
// higher resolution

module donut (
  input clk,
  input rst_n,
  input [10:0] h_count,
  input [9:0] v_count,
  output reg donut_visible,
  output reg [5:0] donut_luma
);

// copied from vgademo.v
parameter H_DISPLAY = 1220;
parameter H_TOTAL = 1525;
parameter V_TOTAL = 525;

// dz is hardcoded as a multiply by 5 down below
// parameter dz = 5;

// I'm sorry, this is totally incomprehensible even to me; I have lost the derivation
// but I promise to come back and explain it

reg signed [15:0] cA, sA, cB, sB;
reg signed [15:0] sAsB, cAsB, sAcB, cAcB;
/*
wire signed [30:0] sAsB = (sA * sB) >>> 14;
wire signed [30:0] cAsB = (cA * sB) >>> 14;
wire signed [30:0] sAcB = (sA * cB) >>> 14;
wire signed [30:0] cAcB = (cA * cB) >>> 14;
*/

// sine/cosine rotations
wire signed [15:0] cA1 = cA - (sA >>> 5);
wire signed [15:0] sA1 = sA + (cA1 >>> 5);
wire signed [15:0] cAsB1 = cAsB - (sAsB >>> 5);
wire signed [15:0] sAsB1 = sAsB + (cAsB1 >>> 5);
wire signed [15:0] cAcB1 = cAcB - (sAcB >>> 5);
wire signed [15:0] sAcB1 = sAcB + (cAcB1 >>> 5);

wire signed [15:0] cB1 = cB - (sB >>> 6);
wire signed [15:0] sB1 = sB + (cB1 >>> 6);
wire signed [15:0] cAcB2 = cAcB1 - (cAsB1 >>> 6);
wire signed [15:0] cAsB2 = cAsB1 + (cAcB2 >>> 6);
wire signed [15:0] sAcB2 = sAcB1 - (sAsB1 >>> 6);
wire signed [15:0] sAsB2 = sAsB1 + (sAcB2 >>> 6);

// these regs have 6 extra bits of precision for accumulation
reg signed [21:0] ycA, ysA;
reg signed [21:0] rx6, ry6, rz6;

/*
wire signed [15:0] p0x = (dz * sB) >>> 6;
wire signed [15:0] p0y = (dz * sAcB) >>> 6;
wire signed [15:0] p0z = -(dz * cAcB) >>> 6;
dz = 5, so just use shifts and adds here
*/
wire signed [15:0] p0x = ((sB>>>2) + sB)>>>4;
wire signed [15:0] p0y = ((sAcB>>>2) + sAcB)>>>4;
wire signed [15:0] p0z = -((cAcB>>>2) + cAcB)>>>4;

// 6 bit precision deltas
wire signed [15:0] yincC6 = cA >>> 2;
wire signed [15:0] yincS6 = sA >>> 2;
wire signed [15:0] xincX6 = cB;
wire signed [15:0] xincY6 = -sAsB;
wire signed [15:0] xincZ6 = cAsB;

/*
wire signed [15:0] xsAsB6 = 76*xincY6;
wire signed [15:0] xcAsB6 = -76*xincZ6;
*/
// 01001100 = 76
wire signed [21:0] xsAsB6 = (xincY6<<6) + (xincY6<<3) + (xincY6<<2);
wire signed [21:0] xcAsB6 = -((xincZ6<<6) + (xincZ6<<3) + (xincZ6<<2));

// pre-step initial ray a bit to reduce iterations
//wire signed [15:0] px = p0x + (rx6>>>11);
//wire signed [15:0] py = p0y + (ry6>>>11);
//wire signed [15:0] pz = p0z + (rz6>>>11);
wire signed [15:0] px = p0x + {{6{rx6[21]}}, rx6[20:11]};
wire signed [15:0] py = p0y + {{6{ry6[21]}}, ry6[20:11]};
wire signed [15:0] pz = p0z + {{6{rz6[21]}}, rz6[20:11]}; 

wire signed [15:0] lx = sB >>> 2;
wire signed [15:0] ly = (sAcB - cA) >>> 2;
wire signed [15:0] lz = (-cAcB - sA) >>> 2;

// fixme: change range from -32..31 to 0..63
wire signed [15:0] luma_unstable;
wire hit_unstable;

donuthit donuthit (
  .clk(clk),
  .start(h_count[3:0] == 0),
  .pxin(px),
  .pyin(py),
  .pzin(pz),
  .rxin(rx6[21:6]),
  .ryin(ry6[21:6]),
  .rzin(rz6[21:6]),
  .lxin(lx),
  .lyin(ly),
  .lzin(lz),
  .hit(hit_unstable),
  .light(luma_unstable)
);

always @(posedge clk) begin
  if (~rst_n) begin
    cA <= 16'h2d3f;
    sA <= 16'h2d3f;
    cB <= 16'h4000;
    sB <= 16'h0000;
    sAsB <= 16'h0000;
    cAsB <= 16'h0000;
    sAcB <= 16'h2d3f;
    cAcB <= 16'h2d3f;

    // the first frame won't actually initialize the donut but that's ok, we
    // just won't show it (most likely the monitor hasn't even synced yet)

  end else begin
    if (h_count == H_TOTAL-15) begin
      if (v_count == V_TOTAL-1) begin
        // ycA/ysA*240; 240 = 256 - 16
        ycA <= -(yincC6<<8) + (yincC6<<4);
        ysA <= -(yincS6<<8) + (yincS6<<4);
        /*
        this will be garbage on the first scanline but i don't care
        rx6 <= -76*xincX6 - sB;
        ry6 <= -yincC6*240 - xsAsB6 - sAcB;
        rz6 <= -yincS6*240 + xcAsB6 + cAcB;
        */
        // also rotate cA, sA, cB, sB, cAsB, sAsB, cAcB, sAcB
        cA <= cA1;
        sA <= sA1;
        cB <= cB1;
        sB <= sB1;
        cAsB <= cAsB2;
        sAsB <= sAsB2;
        cAcB <= cAcB2;
        sAcB <= sAcB2;
      end else begin
        // step y
        ycA <= ycA + yincC6;
        ysA <= ysA + yincS6;
        // 76 = 01001100
        rx6 <= -((xincX6<<6) + (xincX6<<3) + (xincX6<<2)) - (sB<<6);
        ry6 <= ycA - xsAsB6 - (sAcB<<6);
        rz6 <= ysA + xcAsB6 + (cAcB<<6);
      end
    end else if (h_count < H_DISPLAY-8) begin
      if (h_count[3:0] == 0) begin
        // latch output registers
        donut_visible <= hit_unstable;
        // todo: convert from -32..31 to 0..63
        donut_luma <= {!luma_unstable[13], luma_unstable[12:8]};
      end else if (h_count[2:0] == 7) begin
        // step forward one pixel so that next clock donuthit's inputs are stable
        rx6 <= rx6 + xincX6;
        ry6 <= ry6 + xincY6;
        rz6 <= rz6 + xincZ6;
      end
    end
    // if h_count < H_DISPLAY:
    //  - if h_count&7 == 0, load in new donuthit query
    // if h_count == 1220, compute next line constants
    // if v_count == 480, compute next frame constants
    //  - rotate sines, cosines, and combinations thereof

    // if h_count == H_TOTAL-8 && v_count == V_TOTAL-1, kick off the next frame
  end
end


endmodule

