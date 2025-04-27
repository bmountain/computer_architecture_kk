module m_top();
  wire signed[0:7] w_a = -1, w_b = -2;
  initial #1 $display("%d %b %d %b", w_a, w_a, w_b, w_b);
endmodule