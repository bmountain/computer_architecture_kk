`define EDGE 200

module m_top();
  reg r_clk = 0;
  initial #`EDGE r_clk = 1;
  reg [7:0] r_a = 0;
  always@(posedge r_clk) r_a <= r_a + 1;
  initial #(`EDGE + 1) $display("%d", r_a);
  initial #(`EDGE - 1) $display("%d", r_a);
endmodule