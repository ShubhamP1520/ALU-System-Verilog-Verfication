module top;
  import alu_pkg::*;

  bit clk;
  bit RST;
  bit CE;

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  alu_inf inf(clk, RST, CE);

  ALU_DESIGN  DUT(.CLK(clk),
                 .RST(RST),
                 .CE(CE),
                 .INP_VALID(inf.INP_VALID),
                 .MODE(inf.MODE),
                 .CMD(inf.CMD),
                 .CIN(inf.CIN),
                 .ERR(inf.ERR),
                 .RES(inf.RES),
                 .OPA(inf.OPA),
                 .OPB(inf.OPB),
                 .OFLOW(inf.OFLOW),
                 .COUT(inf.COUT),
                 .G(inf.G),
                 .L(inf.L),
                 .E(inf.E));

                 alu_test test = new(inf.DRV, inf.MON, inf.REF);
                 alu_test_single_a test1 = new(inf.DRV, inf.MON, inf.REF);
                 alu_test_two_a test2 = new(inf.DRV, inf.MON, inf.REF);
                 alu_test_two_l test3 = new(inf.DRV, inf.MON, inf.REF);
                 alu_test_single_l test4 = new(inf.DRV, inf.MON, inf.REF);
                 alu_regression_test tr = new(inf.DRV, inf.MON, inf.REF);
  initial begin
    CE = 1'b1;
    RST = 1'b1;
    repeat(3) @(posedge clk);
    RST = 1'b0;
  end

  initial begin
    //test.run();
    //test1.run(); //single operand arithmetic
    test2.run(); //two operand arithmetic
    //test3.run(); //two operand logical
    //test4.run(); //single operand logical
//    tr.run();
   
    $finish();
  end


endmodule
