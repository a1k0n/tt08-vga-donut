`default_nettype none

module vgadonut (
    input clk48,
    input rst_n,
    output reg vsync,  // vsync
    output reg hsync,  // hsync
    output reg [1:0] b_out, // Blue
    output reg [1:0] g_out, // Green
    output reg [1:0] r_out // Red
);

// VGA timing parameters for 640x480 @ 60Hz
parameter H_DISPLAY = 1220;
parameter H_FRONT_PORCH = 31;
parameter H_SYNC_PULSE = 183;
parameter H_BACK_PORCH = 92;
parameter H_TOTAL = 1525;  // ideally 1525.322; run clock at 47.989844 MHz for better VGA timing :)

parameter V_DISPLAY = 480;
parameter V_FRONT_PORCH = 10;
parameter V_SYNC_PULSE = 2;
parameter V_BACK_PORCH = 33;
parameter V_TOTAL = 525;

reg [7:0] frame;
reg [10:0] h_count;
reg [9:0] v_count;

wire display_active = (h_count < H_DISPLAY) && (v_count < V_DISPLAY);

task new_frame;
    begin
        frame <= frame + 1;
    end
endtask

// runs during hblank
task start_of_next_line;
    begin
    end
endtask

// Horizontal and vertical counters
always @(posedge clk48 or negedge rst_n) begin
    if (~rst_n) begin
        h_count <= 0;
        v_count <= 0;
    end else begin
        if (h_count == H_TOTAL - 1) begin
            h_count <= 0;
            if (v_count == V_TOTAL - 1) begin
                v_count <= 0;
                new_frame;
            end else
                v_count <= v_count + 1;
        end else begin
            h_count <= h_count + 1;
        end

        // Start of next line, plus clock cycles to account for divider to finish
        if (h_count == H_DISPLAY)
            start_of_next_line;
    end
end


// --- donut
wire donut_visible;
wire [5:0] donut_luma;
donut donut(
    .clk(clk48),
    .rst_n(rst_n),
    .h_count(h_count),
    .v_count(v_count),
    .donut_luma(donut_luma),
    .donut_visible(donut_visible),
    .frame(frame[0:0])
);

reg [5:0] palette_r [0:63];
reg [5:0] palette_g [0:63];
reg [5:0] palette_b [0:63];

initial begin
    $readmemh("../data/palette_r.hex", palette_r);
    $readmemh("../data/palette_g.hex", palette_g);
    $readmemh("../data/palette_b.hex", palette_b);
end

wire [6:0] scrollh = h_count[6:0] + frame[6:0];
wire [5:0] scrollv = v_count[5:0] + frame[7:2];
wire chq = scrollh[6] ^ scrollv[5];

wire [5:0] checker_r = chq ? 0  : 42;
wire [5:0] checker_g = chq ? 21 : 42;
wire [5:0] checker_b = chq ? 63 : 42;

wire [5:0] r = donut_visible ? palette_r[donut_luma] : checker_r;
wire [5:0] g = donut_visible ? palette_g[donut_luma] : checker_g;
wire [5:0] b = donut_visible ? palette_b[donut_luma] : checker_b;

// Bayer dithering
// this is a 8x4 Bayer matrix which gets toggled every frame (so the other 8x4 elements are actually on odd frames)
wire [2:0] bayer_i = h_count[2:0] ^ {3{frame[0]}};
wire [1:0] bayer_j = v_count[1:0];
wire [2:0] bayer_x = {bayer_i[2], bayer_i[1]^bayer_j[1], bayer_i[0]^bayer_j[0]};
wire [4:0] bayer = {bayer_x[0], bayer_i[0], bayer_x[1], bayer_i[1], bayer_x[2]};

// output dithered 2 bit color from 6 bit color and 5 bit Bayer matrix
function [1:0] dither2;
    input [5:0] color6;
    input [4:0] bayer5;
    begin
        dither2 = ({1'b0, color6} + {2'b0, bayer5} + color6[0] + color6[5] + color6[5:1]) >> 5;
    end
endfunction

wire [1:0] rdither = dither2(r, bayer);
wire [1:0] gdither = dither2(g, bayer);
wire [1:0] bdither = dither2(b, bayer);

always @(posedge clk48) begin
    // Generate sync signals
    hsync <= ~((h_count >= (H_DISPLAY + H_FRONT_PORCH)) && (h_count < (H_DISPLAY + H_FRONT_PORCH + H_SYNC_PULSE)));
    vsync <= ~((v_count >= (V_DISPLAY + V_FRONT_PORCH)) && (v_count < (V_DISPLAY + V_FRONT_PORCH + V_SYNC_PULSE)));
    // Assign color outputs
    r_out <= display_active ? rdither : 0; // Red
    g_out <= display_active ? gdither : 0; // Green
    b_out <= display_active ? bdither : 0; // Blue
end

endmodule
