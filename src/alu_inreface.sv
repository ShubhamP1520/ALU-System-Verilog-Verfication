`include "defines.sv"

interface alu_inf (input bit clk, RST, CE);
  // Input port declaration
  logic[1:0] INP_VALID;
  logic MODE;
  logic [`CMD_WIDTH-1:0] CMD;
  logic [`OP_WIDTH-1:0] OPA;
  logic [`OP_WIDTH-1:0] OPB;
  logic CIN;

  // Output port declaration
  logic ERR;
  logic [`OP_WIDTH:0] RES;
  logic OFLOW;
  logic COUT;
  logic G;
  logic L;
  logic E;

  // Clocking block for driver
  clocking drv_cb @(posedge clk);
    default input #0 output #1;
    output INP_VALID, MODE, CMD, OPA, OPB, CIN;
  endclocking

  // Clocking block for monitor
  clocking mon_cb @(posedge clk);
    default input #0 output #1;
    input ERR, RES, OFLOW, COUT, G, L, E, RST, CIN, INP_VALID, MODE, CMD, OPA, OPB;
  endclocking

  // Clocking block for reference model
  clocking ref_cb @(posedge clk);
    default input #0 output #1;
    input CE, RST;
  endclocking

  //modports
  modport DRV ( clocking drv_cb );
  modport MON ( clocking mon_cb );
  modport REF ( clocking ref_cb );

  //Assertions
  //1. RESET assertion
  property ppt_reset;
    @(posedge clk) RST |=> (RES === 9'bzzzzzzzz && ERR === 1'bz && E === 1'bz && G === 1'bz && L === 1'bz && COUT === 1'bz && OFLOW === 1'bz)
  endproperty
  assert property(ppt_reset)
    $display("RST assertion PASSED at time %0t", $time);
  else
    $info("RST assertion FAILED @ time %0t", $time);

  //2. 16- cycle TIMEOUT assertion
 property ppt_timeout;
   @(posedge clk) disable iff(RST)(CE && (INP_VALID == 2'b01 ||  INP_VALID == 2'b10)) |-> !(INP_VALID == 2'b11) [*16] |-> ##1 error;  
  endproperty
    
  assert property (ppt_timeout)  $info("passed");
    else $info("failed");

  //3. ROR/ROL error
    assert property (@(posedge clk) disable iff(RST) (CE && MODE && (CMD == 12 || CMD == 13) && $countones(OPB) > `SHIFT_W + 1) |=> ERR )
  else $info("NO ERROR FLAG RAISED");

  //4. CMD out of range
  assert property (@(posedge clk) (MODE && CMD > 10) |=> ERR)
    else $info("CMD INVALID ERR NOT RAISED");

  //5. CMD out of range logical
  assert property (@(posedge clk) (!MODE && CMD > 13) |=> ERR)
  else $info("CMD INVALID ERR NOT RAISED");

  //6.INP_VALID  assertion
  property ppt_valid_inp_valid;
   @(posedge clk) disable iff(RST) INP_VALID inside {2'b00, 2'b01, 2'b10, 2'b11};
  endproperty
  assert property(ppt_valid_inp_valid)
  else $info("Invalid INP_VALID value: %b at time %0t", INP_VALID, $time);

  // 7. INP_VALID 00 case
  assert property (@(posedge clk) (INP_VALID == 2'b00) |=> ERR )
  else $info("ERROR NOT raised");

  //8. CE assertion
  property ppt_clock_enable;
     @(posedge clk) disable iff(RST) !CE |-> ##1 ($stable(RES) && $stable(COUT) && $stable(OFLOW) && $stable(G) && $stable(L) && $stable(E) && $stable(ERR));
  endproperty
  assert property(ppt_clock_enable)
  else $info("Clock enable assertion failed at time %0t", $time);

endinterface
