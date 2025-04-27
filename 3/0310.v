module m_top();
  initial #200 $display("hello, world");
  initial begin
    #100 $display("In Verilog HDL");
    #150 $display("When am I displayed?");
  end
endmodule