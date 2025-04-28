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
              (b)? {{21{ir[31]}}, ir[7], ir[30:25], ir[11:8]}:
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

module m_proc3(w_clk);
  input wire w_clk;
  wire [31:0] w_npc, w_r1, w_r2, w_rt, w_imm, w_ir, w_s2, w_alu, w_ldd;
  wire w_r, w_i, w_s, w_b, w_u, w_j, w_ld;

  // IF
  reg [31:0] m_pc = 0;
  m_am_imem m_if_am(m_pc, w_ir);
  m_add m_if_add(32'h4, m_pc, w_npc);
  always @(posedge w_clk) m_pc <= w_npc;

  // ID
  m_rf m_id_rf(w_clk, w_ir[19:15], w_ir[24:20], w_ir[11:7], !w_s, w_rt, w_r1, w_r2);
  m_gen_imm m_id_gen_imm(w_ir, w_imm, w_r, w_i, w_s, w_b, w_u, w_j, w_ld);
  m_mux m_id_mux(w_r2, w_imm, !w_r, w_s2);

  // EX
  m_add m_ex_add(w_r1, w_s2, w_alu);

  // MA
  m_am_dmem m_ma_am_dem(w_clk, w_alu, w_s, w_r2, w_ldd);

  // WB
  m_mux wb_mux(w_alu, w_ldd, w_ld, w_rt);
endmodule

module m_top();
  reg w_clk = 0;
  initial #150 forever #50 w_clk = ~w_clk;
  m_proc3 m3(w_clk);
  initial begin
    m3.m_if_am.mem[0] = {12'd7, 5'd0, 3'd0, 5'd1, 7'h13};      // addi x1, x0, 7
    m3.m_if_am.mem[1] = {7'd0, 5'd1, 5'd0, 3'h2, 5'd8, 7'h23}; // sw x1, 8(x0)
    m3.m_if_am.mem[2] = {12'd8, 5'd0, 3'b010, 5'd2, 7'h3};     // lw x2, 8(x0)
  end

  // initial #99 forever #100 $display("%3d %d %d %d %d %d", $time, m3.m_ma_am_dem.clk, m3.m_ma_am_dem.wd, m3.m_ma_am_dem.we, m3.m_ma_am_dem.adr[7:2], m3.m_ma_am_dem.mem[2]); // am_dmemの中
  // initial #99 forever #100 $display("%3d %d", $time, m3.m_ma_am_dem.we); // am_dmemの中
  // initial #99 forever #100 $display("%3d %d %d %d", $time, m3.m_ma_am_dem.mem[0], m3.m_ma_am_dem.mem[1], m3.m_ma_am_dem.mem[2]); // am_dmemの中
  // initial #99 forever #100 $display("%3d %d %d", $time, m3.m_id_rf.w_wd, m3.);
  // initial #99 forever #100 $display("%3d %d %d %d", $time, m3.m_ma_am_dem.mem[0], m3.m_ma_am_dem.mem[1], m3.m_ma_am_dem.mem[2] );
  initial #99 forever #100 $display("%3d %d %d %d %d", $time,  m3.w_r1, m3.w_s2, m3.w_rt, m3.w_ldd);
  initial #500 $finish;
endmodule