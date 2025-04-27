module m_top();
  reg r_clk = 0;
  initial #200 r_clk = 1;
  reg [7:0] r_a = 0;
  always@(posedge r_clk) r_a <= r_a + 1;
  initial #201 $display("%d", r_a);
  initial #199 $display("%d", r_a);
endmodule