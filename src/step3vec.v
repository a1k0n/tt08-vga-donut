// approximate step a 3-vector direction a given distance
// only uses the msb of the distance to avoid a full multiply
// we're going to iterate this a few times, so we can afford to be a bit sloppy
// and save a ton of gate area

// the operation performed here is approximately:
//   xyzout = d*xyzin >> 14

module step3vec (
  input signed [10:0] d,
  input signed [15:0] xin_,
  input signed [15:0] yin_,
  input signed [15:0] zin_,
  output reg signed [15:0] xout,
  output reg signed [15:0] yout,
  output reg signed [15:0] zout
);

wire sd = d[10];
wire [9:0] dabs = sd ? ~d[9:0] : d[9:0];

wire [15:0] xin = sd ? ~xin_ : xin_;
wire [15:0] yin = sd ? ~yin_ : yin_;
wire [15:0] zin = sd ? ~zin_ : zin_;

wire _unused_ok = &{xin_[4:0], yin_[4:0], zin_[4:0], xin[4:0], yin[4:0], zin[4:0]};

wire sx = xin[15];
wire sy = yin[15];
wire sz = zin[15];

always @* begin
  casez (dabs)
    10'b1?????????:  // (xin << 9) >> 14 = xin >> 5
      begin
        xout = {{6{sx}}, xin[14:5]};
        yout = {{6{sy}}, yin[14:5]};
        zout = {{6{sz}}, zin[14:5]};
      end
    10'b01????????:  // (xin << 8) >> 14 = xin >> 6
      begin
        xout = {{7{sx}}, xin[14:6]};
        yout = {{7{sy}}, yin[14:6]};
        zout = {{7{sz}}, zin[14:6]};
      end
    10'b001???????:  // (xin << 7) >> 14 = xin >> 7
      begin
        xout = {{8{sx}}, xin[14:7]};
        yout = {{8{sy}}, yin[14:7]};
        zout = {{8{sz}}, zin[14:7]};
      end
    10'b0001??????:  // (xin << 6) >> 14 = xin >> 8
      begin
        xout = {{9{sx}}, xin[14:8]};
        yout = {{9{sy}}, yin[14:8]};
        zout = {{9{sz}}, zin[14:8]};
      end
    10'b00001?????:  // (xin << 5) >> 14 = xin >> 9
      begin
        xout = {{10{sx}}, xin[14:9]};
        yout = {{10{sy}}, yin[14:9]};
        zout = {{10{sz}}, zin[14:9]};
      end
    10'b000001????:  // (xin << 4) >> 14 = xin >> 10
      begin
        xout = {{11{sx}}, xin[14:10]};
        yout = {{11{sy}}, yin[14:10]};
        zout = {{11{sz}}, zin[14:10]};
      end
    10'b0000001???:  // (xin << 3) >> 14 = xin >> 11
      begin
        xout = {{12{sx}}, xin[14:11]};
        yout = {{12{sy}}, yin[14:11]};
        zout = {{12{sz}}, zin[14:11]};
      end
    10'b00000001??:  // (xin << 2) >> 14 = xin >> 12
      begin
        xout = {{13{sx}}, xin[14:12]};
        yout = {{13{sy}}, yin[14:12]};
        zout = {{13{sz}}, zin[14:12]};
      end
    10'b000000001?:  // (xin << 1) >> 14 = xin >> 13
      begin
        xout = {{14{sx}}, xin[14:13]};
        yout = {{14{sy}}, yin[14:13]};
        zout = {{14{sz}}, zin[14:13]};
      end
    10'b0000000001:  // (xin << 0) >> 14 = xin >> 14
      begin
        xout = {{15{sx}}, xin[14]};
        yout = {{15{sy}}, yin[14]};
        zout = {{15{sz}}, zin[14]};
      end
    default:
      begin
        xout = 16'b0;
        yout = 16'b0;
        zout = 16'b0;
      end
  endcase
end

endmodule
