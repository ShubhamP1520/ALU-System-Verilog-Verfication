
`include "defines.sv"

class alu_monitor;
  alu_transaction trans;

  mailbox #(alu_transaction) mb_ms; // mailbox to scoreboard

  virtual alu_inf mon_inf;

  covergroup mon_cg;
      RES_CP : coverpoint trans.RES {
        bins all_zero = {0};
        bins all_ones = {9'b111111111};
        bins others = default;
      }
      ERR_CP : coverpoint trans.ERR;
      E_CP : coverpoint trans.E { bins one_e = {1};
      }
      G_CP : coverpoint trans.G { bins one_g = {1};
      }
      L_CP : coverpoint trans.L { bins one_l = {1};
      }
      OV_CP: coverpoint trans.OFLOW;
      COUT_CP: coverpoint trans.COUT;
  endgroup

  function new(mailbox #(alu_transaction) mb_ms,
               virtual alu_inf mon_inf
              );
    this.mb_ms = mb_ms;
    this.mon_inf = mon_inf;
    mon_cg = new();
  endfunction

  // Function to check if operation needs single operand
  function int single_operand(input logic MODE, input logic [`CMD_WIDTH-1:0] CMD);
    if(MODE) begin
      case(CMD)
        0,1,2,3,8,9,10,11: return 0;
        default: return 1;
      endcase
    end
    else begin
      case(CMD)
        0,1,2,3,4,5,12,13: return 0;
        default: return 1;
      endcase
    end
  endfunction

   task start();
    repeat(4)@(mon_inf.mon_cb);

    for(int j = 0; j < `no_of_transactions; j++) begin
      trans = new();
      sample_outputs();
      $display("MODE = %0d and CMD = %0d", trans.MODE, trans.CMD);
      if(single_operand(trans.MODE, trans.CMD)==1) begin

        repeat(1) @(mon_inf.mon_cb);
        sample_outputs();
        $display("[ %0t ] MONITOR RES| RES =%0d | ERR = %0d | COUT = %0d | OFLOW = %0d | E = %0b | G = %0b| L = %0b|", $time, trans.RES, trans.ERR, trans.COUT, trans.OFLOW, trans.E, trans.G, trans.L);
      end
      else begin
        if(trans.INP_VALID == 2'b11 || trans.INP_VALID == 2'b00) begin
          sample_outputs();
          if(trans.MODE == 1 && (trans.CMD == 9 || trans.CMD == 10)) begin
            repeat(2)@(mon_inf.mon_cb);
            sample_outputs();
            $display("[ %0t ] MONITOR RES| RES =%0d | ERR = %0d | COUT = %0d | OFLOW = %0d | E = %0b | G = %0b| L = %0b|", $time, trans.RES, trans.ERR, trans.COUT, trans.OFLOW, trans.E, trans.G, trans.L);
          end
          else begin
            repeat(1)@(mon_inf.mon_cb);
            sample_outputs();
            $display("[ %0t ] MONITOR RES| RES =%0d | ERR = %0d | COUT = %0d | OFLOW = %0d | E = %0b | G = %0b| L = %0b|", $time, trans.RES, trans.ERR, trans.COUT, trans.OFLOW, trans.E, trans.G, trans.L);
          end
        end

        else begin
          sample_outputs();
          for(int i = 0; i < 16; i++) begin

            @(mon_inf.mon_cb);
            sample_outputs();
            // Check if valid inputs have changed

            $display("[ %0t ] MONITOR RES| RES =%0d | ERR = %0d | COUT = %0d | OFLOW = %0d | E = %0b | G = %0b| L = %0b|", $time, trans.RES, trans.ERR, trans.COUT, trans.OFLOW, trans.E, trans.G, trans.L);
            if(mon_inf.mon_cb.INP_VALID == 2'b11) begin
              if(trans.MODE == 1 && (trans.CMD == 9 || trans.CMD == 10)) begin
                repeat(1)@(mon_inf.mon_cb);
                break;
              end
              else begin
                repeat(0)@(mon_inf.mon_cb);
                break;
              end
            end
          end
        end
      end
      sample_outputs(); // This should have ERR = 1
      if(trans.MODE == 1 && (trans.CMD == 9 || trans.CMD == 10))
        repeat(1)@(mon_inf.mon_cb);
      repeat(1)@(mon_inf.mon_cb);
      sample_outputs();
      $display("[ %0t ] MONITOR RES| RES =%0d | ERR = %0d | COUT = %0d | OFLOW = %0d | E = %0b | G = %0b| L = %0b|", $time, trans.RES, trans.ERR, trans.COUT, trans.OFLOW, trans.E, trans.G, trans.L);
      mb_ms.put(trans);
    end
  endtask

  task sample_outputs();
    trans.RES = mon_inf.mon_cb.RES;
    trans.COUT = mon_inf.mon_cb.COUT;
    trans.OFLOW = mon_inf.mon_cb.OFLOW;
    trans.ERR = mon_inf.mon_cb.ERR;
    trans.G = mon_inf.mon_cb.G;
    trans.E = mon_inf.mon_cb.E;
    trans.L = mon_inf.mon_cb.L;

    // Also capture the input conditions for debugging
    trans.MODE = mon_inf.mon_cb.MODE;
    trans.CMD = mon_inf.mon_cb.CMD;
    trans.INP_VALID = mon_inf.mon_cb.INP_VALID;
    trans.OPA = mon_inf.mon_cb.OPA;
    trans.OPB = mon_inf.mon_cb.OPB;
    trans.CIN = mon_inf.mon_cb.CIN;

    mon_cg.sample();
    
  endtask

endclass
