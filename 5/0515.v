`define FUNCT7 7'd0
`define FUNCT3 3'd0
`define X0 5'd0
`define X1 5'd1
`define X2 5'd2
`define X3 5'd3
`define X4 5'd4
`define X5 5'd5
`define X6 5'd6
`define X7 5'd7
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
  assign w_out = (w_in == 32'h0) ? {`FUNCT7, `X2, `X1, `FUNCT3, `X5, `OPCODE}: // add x5, x1, x2
                 (w_in == 32'h4) ? {`FUNCT7, `X4, `X3, `FUNCT3, `X6, `OPCODE}: // add x6, x3, x4
                                   {`FUNCT7, `X6, `X5, `FUNCT3, `X7, `OPCODE}; // add x7, x5, x6
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

module m_rf(w_clk, w_ra1, w_ra2, w_wa, w_we, w_wd, w_rd1, w_rd2);
  input wire [4:0] w_ra1, w_ra2, w_wa;
  input wire w_we, w_clk;
  input wire [31:0] w_wd;
  output wire [31:0] w_rd1, w_rd2;
  reg [31:0] mem [31:0];
  assign w_rd1 = (w_ra1 == 5'd0) ? 32'd0 : mem[w_ra1];
  assign w_rd2 = (w_ra2 == 5'd0) ? 32'd0 : mem[w_ra2];
  always @(posedge w_clk) if (w_we == 1) mem[w_wa] <= w_wd;
  always @(posedge w_clk) if (w_we & w_wa == 5'd30) $finish;
  integer i; initial for (i = 0; i < 32; i = i+1) mem[i] = 32'd0;
endmodule

module m_proc2(w_clk);
  input wire w_clk;
  wire [31:0] w_npc, w_ir, w_r1, w_r2, w_rt;

  // IF
  reg [31:0] r_pc = 32'd0;
  always @(posedge w_clk) r_pc <= w_npc;
  m_add m_if_adder(32'h4, r_pc, w_npc);
  m_am m_if_am(r_pc, w_ir);
  
  // ID
  m_rf m_id_rf(w_clk, w_ir[19:15], w_ir[24:20], w_ir[11:7], 1'b1, w_rt, w_r1, w_r2);

  // EX
  m_add m_ex_adder(w_r1, w_r2, w_rt);
endmodule

module m_top();
  reg w_clk = 0;
  initial #150 forever #50 w_clk = ~w_clk;
  m_proc2 m2(w_clk);
  initial m2.m_id_rf.mem[1] = 5;
  initial m2.m_id_rf.mem[2] = 6;
  initial m2.m_id_rf.mem[3] = 7;
  initial m2.m_id_rf.mem[4] = 8;

  initial #99 forever #100 $display("%3d %d %d %d", $time,  m2.w_r1, m2.w_r2, m2.w_rt);
  initial #500 $finish;
endmodule