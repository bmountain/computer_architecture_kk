module m_get_type(opcode5, r, i, s, b, u, j);
  input wire [4:0] opcode5;
  output wire r, i, s, b, u, j;
  assign r = (opcode5 == 5'b01100);
  assign s = (opcode5 == 5'b01000);
  assign b = (opcode5 == 5'b11000);
  assign u = (opcode5 == 5'b00101 | opcode5 == 5'b01101);
  assign j = (opcode5 == 5'b11011);
  assign i = ~(r | s | b | u | j);
endmodule

module m_top();
  reg [4:0] opcode5 = 5'b00110;
  wire r, i, s, b, u, j;
  m_get_type m(opcode5, r, i, s, b, u, j);
  initial #1 $display("%5b %1b %1b %1b %1b %1b %1b", opcode5, r, i, s, b, u, j);
endmodule