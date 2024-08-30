`default_nettype none

module tt_um_a1k0n_vgadonut(
  input  wire [7:0] ui_in,    // Dedicated inputs
  output wire [7:0] uo_out,   // Dedicated outputs
  input  wire [7:0] uio_in,   // IOs: Input path
  output wire [7:0] uio_out,  // IOs: Output path
  output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
  input  wire       ena,      // always 1 when the design is powered, so you can ignore it
  input  wire       clk,      // clock
  input  wire       rst_n     // reset_n - low to reset
);

  // VGA signals
  wire hsync;
  wire vsync;
  wire audio;
  wire [1:0] R;
  wire [1:0] G;
  wire [1:0] B;

  vgadonut vgadonut(
    .clk48(clk),
    .vsync(vsync),
    .hsync(hsync),
    .r_out(R),
    .g_out(G),
    .b_out(B),
    .rst_n(rst_n)
  );

  // TinyVGA PMOD
  assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};

  // Unused outputs assigned to 0.
  assign uio_out = 8'b0;
  assign uio_oe  = 8'b0;

  // Suppress unused signals warning
  wire _unused_ok = &{ena, ui_in, uio_in};

endmodule
