module m_top();
  reg [3:0] r_a=4'b1010, r_b=4'b1100;
  wire [3:0] w_c = r_a ^ r_b;
  initial #1 $display("%b %b %b", r_a, r_b, w_c);
endmodule