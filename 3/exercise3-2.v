module m_AND_gate(w_a, w_b, w_c);
  input wire w_a, w_b;
  output wire w_c;
  assign w_c = w_a & w_b;
endmodule

module m_top();
  reg r_in1, r_in2, r_in3;
  wire w_t, w_c;
  initial r_in1 <= 1;
  initial r_in2 <= 1;
  initial r_in3 <= 0;
  m_AND_gate m1(r_in1, r_in2, w_t);
  m_AND_gate m2(w_t, r_in3, w_c);
  initial #1 $display("%d %d %d %d", r_in1, r_in2, r_in3, w_c);
endmodule
