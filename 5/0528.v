`timescale 1ns/100ps
`default_nettype none

// opcode5から命令タイプを取得
module m_get_type(opcode5, r, i, s, b, u, j);
  input wire [4:0] opcode5;
  output wire r, i, s, b, u, j;
  assign r = (opcode5 == 5'b01100);
  assign s = (opcode5 == 5'b01000);
  assign b = (opcode5 == 5'b11000);
  assign u = (opcode5 == 5'b00101 || opcode5 == 5'b01101);
  assign j = (opcode5 == 5'b11011);
  assign i = ~(r | s | b | u | j);
endmodule

// 命令から即値を取得
module m_get_imm(ir, i, s, b, u, j, imm);
  input wire [31:0] ir;
  input wire i, s, b, u, j;
  output wire [31:0] imm;
  assign imm =(i)? {{21{ir[31]}}, ir[30:20]}:
              (s)? {{21{ir[31]}}, ir[30:25], ir[11:7]}:
              (b)? {{20{ir[31]}}, ir[7], ir[30:25], ir[11:8], 1'b0}:
              (u)? {{ir[31:12]}, {12{1'b0}}}:
              (j)? {{12{ir[31]}}, ir[19:12], ir[20], ir[30:21], 1'b0}: 0;
endmodule

// 命令から命令タイプと即値を取得
module m_gen_imm(w_ir, w_imm, w_r, w_i, w_s, w_b, w_u, w_j, w_ld);
  input wire [31:0] w_ir;
  output wire [31:0] w_imm;
  output wire w_r, w_i, w_s, w_b, w_u, w_j, w_ld;
  m_get_imm m_imm(w_ir, w_i, w_s, w_b, w_u, w_j, w_imm);
  m_get_type m_type(w_ir[6:2], w_r, w_i, w_s, w_b, w_u, w_j);
  assign w_ld = (w_ir[6:2] == 0);
endmodule

// 32ビット加算器
module m_add(w_in1, w_in2, w_out);
  input wire [31:0] w_in1, w_in2;
  output wire [31:0] w_out;
  assign w_out = w_in1 + w_in2;
endmodule

// ALU
module m_alu(w_in1, w_in2, w_out, w_tkn);
  input wire [31:0] w_in1, w_in2;
  output wire w_tkn;
  output wire [31:0] w_out;
  assign w_out = w_in1 + w_in2;
  assign w_tkn = w_in1 != w_in2;
endmodule

// 32ビット64ワードの非同期メモリ
module m_am_imem(w_pc, w_insn);
  input wire [31:0] w_pc;
  output wire [31:0] w_insn;
  reg [31:0] mem [0:63];
  assign w_insn = mem[w_pc[7:2]];
  integer i; initial for(i = 0; i< 64; i = i+1) mem[i] = 32'd0;
endmodule

// データメモリ
module m_am_dmem(clk, adr, we, wd, rd);
  input wire we, clk;
  input wire [31:0] adr, wd;
  output wire [31:0] rd;
  reg [31:0] mem [0:63];
  assign rd = mem[adr[7:2]];
  always @(posedge clk) if(we) mem[adr[7:2]] <= wd;  
  integer i; initial for(i = 0; i < 64; i = i+1) mem[i] = 32'd0;
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
  reg [31:0] mem [0:31];
  assign w_rd1 = (w_ra1 == 5'd0) ? 32'd0 : mem[w_ra1];
  assign w_rd2 = (w_ra2 == 5'd0) ? 32'd0 : mem[w_ra2];
  always @(posedge w_clk) if (w_we == 1) mem[w_wa] <= w_wd;
  always @(posedge w_clk) if (w_we & w_wa == 5'd30) $finish;
  integer i; initial for (i = 0; i < 32; i = i+1) mem[i] = 32'd0;
endmodule

module m_proc5(w_clk);
  input wire w_clk;
  wire [31:0] w_pcin, w_npc, w_ir, w_r1, w_r2, w_alu, w_rt, w_imm, w_tpc, w_ldd, w_s2;
  wire r, i, s, b, u, j, ld, w_tkn;
  // IF
  reg [31:0] r_pc = 0;
  always @(posedge w_clk) r_pc <= w_pcin;
  m_am_imem m_if_mem(r_pc, w_ir);
  m_add m_if_add(32'h4, r_pc, w_npc);

  // ID
  m_rf m_id_rf(w_clk, w_ir[19:15], w_ir[24:20], w_ir[11:7], !s & !b, w_rt, w_r1, w_r2);
  m_gen_imm m_id_gen_imm(w_ir, w_imm, r, i, s, b, u, j, ld);
  m_mux m_id_mux(w_r2, w_imm, !r & !b, w_s2);
  m_add m_id_add(w_imm, r_pc,  w_tpc);
  m_mux m_id_mux2(w_npc, w_tpc, b & w_tkn, w_pcin);
  
  // EX
  m_alu m_ex_alu(w_r1, w_s2, w_alu, w_tkn);

  // MA
  m_am_dmem ma_dmem(w_clk, w_alu, s, w_r2, w_ldd);
  
  // WB
  m_mux wb_mux(w_alu, w_ldd, ld, w_rt);
endmodule

module m_sim(w_clk, w_cc);
  input wire w_clk; input wire[31:0] w_cc;
  m_proc5 m(w_clk);
  initial begin
    `define MM m.m_if_mem.mem
    `include "asm.txt"
  end
  // initial #99 forever #100 $display("CC%02d %h %d %d %d",
  //   w_cc, m.r_pc, m.w_r1, m.w_s2, m.w_rt);
  initial #99 forever #100 $display("CC%02d %d %d %d",
    w_cc, m.m_id_rf.mem[1], m.m_id_rf.mem[2], m.m_id_rf.mem[3]);
endmodule

module m_top_wrapper();
  reg r_clk = 0;
  initial #150 forever #50 r_clk = ~r_clk;
  reg [31:0] r_cc = 1; always @(posedge r_clk) r_cc <= r_cc + 1;
  initial #1000000 begin $display("time out") ; $finish; end
  m_sim m (r_clk, r_cc);
  // initial $dumpvars(0,m);
endmodule