module m_top();
  reg w_clk = 0;
  initial
    begin
      #150 forever begin
        #50 w_clk = ~w_clk;
      end
    end
  m_proc3 m3(w_clk);
  initial begin
    m3.m_if_am.mem[0] = {12'd7, 5'd0, 3'd0, 5'd1, 7'h13};      // addi x1, x0, 7
    m3.m_if_am.mem[1] = {7'd0, 5'd1, 5'd0, 3'h2, 5'd8, 7'h23}; // sw x1, 8(x0)
    m3.m_if_am.mem[2] = {12'd8, 5'd0, 3'b010, 5'd2, 7'h3};     // lw x2, 8(x0)
  end

  initial begin
    #99 forever 
    #100 $display("%3d %d %d %d", $time, m3.m_ma_am_dem.mem[0], m3.m_ma_am_dem.mem[1], m3.m_ma_am_dem.mem[2] );
  end
  // initial #99 forever #100 $display("%3d %d %d %d %d", $time,  m3.w_r1, m3.w_s2, m3.w_rt, m3.w_ldd);
  initial #500 $finish;
endmodule

