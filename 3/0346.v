module m_top();
  initial forever #100 $write("%3d a", $time);
  initial #550 $finish;
  initial #350 $write("%3d b", $time);
  initial begin
    #260 $write("%3d c", $time);
    #260 $write("%3d d", $time);
  end
endmodule