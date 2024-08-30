module demo_orangecrab (
    input clk48,
    output gpio_0,  // vsync
    output gpio_1,  // hsync
    output gpio_a0, // BlueH
    output gpio_a1, // GreenH
    output gpio_a2, // RedH
    output gpio_a3, // BlueL
    output gpio_a4, // GreenL
    output gpio_a5 // RedL
);

reg [1:0] poweron_reset = 3;
wire [1:0] R, G, B;
vgadonut vgadonut(
  .vsync(gpio_0),
  .hsync(gpio_1),
  .b_out(B),
  .g_out(G),
  .r_out(R),
  .clk48(clk48),
  .rst_n(poweron_reset == 0)
);

always @(posedge clk48) begin
  if (poweron_reset != 0)
    poweron_reset <= poweron_reset - 1;
end

assign gpio_a0 = B[1];
assign gpio_a1 = G[1];
assign gpio_a2 = R[1];
assign gpio_a3 = B[0];
assign gpio_a4 = G[0];
assign gpio_a5 = R[0];

endmodule
