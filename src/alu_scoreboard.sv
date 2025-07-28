`include "defines.sv"

class alu_scoreboard;
  mailbox #(alu_transaction) mb_sr; // reference mailbox
  mailbox #(alu_transaction) mb_ms; // monitor mailbox
  alu_transaction trans_ref, trans_mon;

  function new(mailbox #(alu_transaction) mb_sr, mailbox #(alu_transaction) mb_ms);
    this.mb_sr = mb_sr;
    this.mb_ms = mb_ms;
  endfunction
  function int compare();
    return (trans_ref.RES === trans_mon.RES) &&
           (trans_ref.ERR === trans_mon.ERR) &&
           (trans_ref.COUT === trans_mon.COUT) &&
           (trans_ref.G === trans_mon.G) &&
           (trans_ref.L === trans_mon.L) &&
           (trans_ref.E === trans_mon.E) &&
           (trans_ref.OFLOW === trans_mon.OFLOW);
  endfunction

  task start();
    static int fail_count = 0;
    static int pass_count = 0;
    int test_count = 0;
    $display("________________________________________________________________________________");
    $display("********************************SCOREBOARD*************************************");
    $display("________________________________________________________________________________");
    repeat(`no_of_transactions) begin
      trans_ref = new();
      trans_mon = new();
      mb_sr.get(trans_ref);
      mb_ms.get(trans_mon);
      $display("");
      $display("%0d\n",++test_count );
      $display("INP_VALID = %0d| CMD = %0d| OPA = %0d| OPB = %0d", trans_ref.INP_VALID, trans_ref.CMD, trans_ref.OPA, trans_ref.OPB);
      $display("");
      $display("Reference : RES = %0d | ERR = %0d |E = %0d |G = %0d |L = %0d |COUT= %0d | OF = %0d", trans_ref.RES, trans_ref.ERR, trans_ref.E, trans_ref.G, trans_ref.L, trans_ref.COUT, trans_ref.OFLOW);
      $display("Monitor   : RES = %0d | ERR = %0d |E = %0d |G = %0d |L = %0d |COUT= %0d | OF = %0d", trans_mon.RES, trans_mon.ERR, trans_mon.E, trans_mon.G, trans_mon.L, trans_mon.COUT, trans_mon.OFLOW);
      if(compare()) begin
        $display("PASS");
        pass_count ++;
      end
      else begin
        $display("FAIL");
        fail_count++;
      end
      $display("__________________________________________________________________________________");
    end
    $display("");
    $display("TOTAL MATCHES      : %0d", pass_count);
    $display("TOTAL MISSMATCHES  : %0d", fail_count);
    $display("__________________________________________________________________________________");
  endtask
endclass
