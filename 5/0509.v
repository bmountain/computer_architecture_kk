`define FUNCT7 7'd0
`define FUNCT3 3'd0
`define X0 5'd0
`define X1 5'd1
`define OPCODE 7'b0110011

// 32ビット加算器
module m_add(w_in1, w_in2, w_out);
  input wire [31:0] w_in1, w_in2;
  output wire [31:0] w_out;
  assign w_out = w_in1 + w_in2;
endmodule

// 非同期メモリ。32ビットのメモリアドレスに対してストアされた32ビット命令を返す。
module m_am(w_in, w_out);
  input wire [31:0] w_in;
  output wire [31:0] w_out;
  assign w_out = (w_in == 32'h0) ? {`FUNCT7, `X1, `X0, `FUNCT3, `X1, `OPCODE}:
                 (w_in == 32'h4) ? {`FUNCT7, `X0, `X1, `FUNCT3, `X1, `OPCODE}:
                                   {`FUNCT7, `X1, `X1, `FUNCT3, `X1, `OPCODE};
endmodule

module m_cmp(w_in1, w_in2, w_out);
  input wire [4:0] w_in1, w_in2;
  output wire w_out;
  assign  w_out = w_in1 == w_in2;
endmodule

module m_mux(w_in1, w_in2, w_s, w_out);
  input wire [31:0] w_in1, w_in2;
  input wire w_s;
  output wire [31:0] w_out;
  assign w_out = (w_s == 1) ? w_in2 : w_in1;
endmodule

module proc1(w_clk);
  input wire w_clk;

  // x1
  reg [31:0] m6 = 3;

  // IF
  wire [31:0] w_npc, w_ir;
  reg [31:0] m1 = 0;
  always @(posedge w_clk) m1 <= w_npc;
  m_add m2(32'h4, m1, w_npc);
  m_am m3(m1, w_ir);

  // ID
  wire w_cmp1, w_cmp2;
  wire [31:0] w_r1, w_r2;
  m_cmp m4(5'd1, w_ir[19:15], w_cmp1);
  m_cmp m5(5'd1, w_ir[24:20], w_cmp2);
  m_mux m7(32'd0, m6, w_cmp1, w_r1);
  m_mux m8(32'd0, m6, w_cmp2, w_r2);

  // EX
  wire [31:0] w_rt;
  m_add m9(w_r1, w_r2, w_rt);
  
  // WB
  always @(posedge w_clk) m6 <= w_rt;
endmodule

module m_top();
  reg w_clk = 0;
  initial #150 forever #50 w_clk = ~w_clk;
  proc1 p(w_clk);

  initial #99 forever #100 $display("%3d %h %h %h %h", $time,  p.w_r1, p.w_r2, p.w_rt, p.m6);
  initial #500 $finish;
endmodule