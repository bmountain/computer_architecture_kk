module m_OR_gate(w_a, w_b, w_c);
  input wire w_a, w_b;
  output wire w_c;
  assign w_c = w_a | w_b;
endmodule

module m_top();
  reg r_in1, r_in2;
  wire w_out;
  initial r_in1 <= 0;
  initial r_in2 <= 0;
  initial #100 r_in1 <= 0;
  initial #100 r_in2 <= 1;
  initial #200 r_in1 <= 1;
  initial #200 r_in2 <= 0;
  initial #300 r_in1 <= 1;
  initial #300 r_in2 <= 1;
  m_OR_gate m(r_in1, r_in2, w_out);
  always@(*) #1 $display("%d %d %d", r_in1, r_in2, w_out);
endmodule
