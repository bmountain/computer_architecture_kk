module m_top();
  reg [7:0] r_a = 0;
  initial begin
    r_a = r_a + 1;
    r_a = r_a + 2;
  end
  initial #1 $display("%1d %b", r_a, r_a);
endmodule