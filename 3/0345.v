module m_top();
  initial forever #100 $display("%3d a", $time);
  initial #550 $finish;
  initial #350 $display("%3d b", $time);
  initial begin
    #260 $display("%3d c", $time);
    #260 $display("%3d d", $time);
  end
endmodule