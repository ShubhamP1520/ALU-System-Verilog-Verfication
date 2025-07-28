`include "defines.sv"

class alu_driver;

  mailbox #(alu_transaction) mb_gd; //mailbox between generator and driver
  mailbox #(alu_transaction) mb_dr; //mailbox between driver and reference model

  virtual alu_inf.DRV drv_inf;

  alu_transaction trans = new();

  covergroup drv_cg;
    MODE_CP: coverpoint trans.MODE;
    INP_VALID_CP : coverpoint trans.INP_VALID;
    CMD_CP : coverpoint trans.CMD {
      bins valid_cmd[] = {[0:13]};
      ignore_bins invalid_cmd[] = {14, 15};
    }
    OPA_CP : coverpoint trans.OPA {
      bins all_zeros_a = {0};
      bins opa = {[0:`MAX]};
      bins all_ones_a = {`MAX};
    }
    OPB_CP : coverpoint trans.OPB {
      bins all_zeros_b = {0};
      bins opb = {[0:`MAX]};
      bins all_ones_b = {`MAX};
    }
    CIN_CP : coverpoint trans.CIN;
    CMD_X_IP_V: cross CMD_CP, INP_VALID_CP;
    MODE_X_INP_V: cross MODE_CP, INP_VALID_CP;
    MODE_X_CMD: cross MODE_CP, CMD_CP;
    OPA_X_OPB : cross OPA_CP, OPB_CP;
  endgroup

  function new( mailbox #(alu_transaction) mb_gd,
                mailbox #(alu_transaction) mb_dr,
                virtual alu_inf.DRV drv_inf
  );
    this.mb_gd = mb_gd;
    this.mb_dr = mb_dr;
    this.drv_inf = drv_inf;
    drv_cg = new();
  endfunction

  task drive_inf();
      drv_inf.drv_cb.INP_VALID <= trans.INP_VALID;
      drv_inf.drv_cb.CMD <= trans.CMD;
      drv_inf.drv_cb.MODE <= trans.MODE;
      drv_inf.drv_cb.OPA <= trans.OPA;
      drv_inf.drv_cb.OPB <= trans.OPB;
      drv_inf.drv_cb.CIN <= trans.CIN;
      drv_cg.sample();
  endtask

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

    repeat(3)@(drv_inf.drv_cb);

    for( int j = 0; j < `no_of_transactions; j++) begin

      $display("_______________________________________________________");
      $display("");
      trans = new();
      mb_gd.get(trans);

      trans.MODE.rand_mode(1);
      trans.CMD.rand_mode(1);


      if(single_operand(trans.MODE, trans.CMD)==1) begin

        drive_inf();
        $display("[ %0t ] Driving DUT : MODE = %0b | CMD = %0d | INP_VALID = %0d | OPA = %0d | OPB = %0d | ",$time, trans.MODE, trans.CMD, trans.INP_VALID, trans.OPA, trans.OPB);
        repeat(1)@(drv_inf.drv_cb);
        $display("[ %0t ] Putting REF : MODE = %0b | CMD = %0d | INP_VALID = %0d | OPA = %0d | OPB = %0d | ",$time, trans.MODE, trans.CMD, trans.INP_VALID, trans.OPA, trans.OPB);
        mb_dr.put(trans);

      end

      else begin

        if(trans.INP_VALID == 2'b11 || trans.INP_VALID == 2'b00) begin

          drive_inf();
          $display("[ %0t ] Driving DUT : MODE = %0b | CMD = %0d | INP_VALID = %0d | OPA = %0d | OPB = %0d | ",$time, trans.MODE, trans.CMD, trans.INP_VALID, trans.OPA, trans.OPB);
          if(trans.MODE == 1 && (trans.CMD == 4'd10 || trans.CMD == 4'd9))
            repeat(2)@(drv_inf.drv_cb);
          else
            repeat(1)@(drv_inf.drv_cb);
          $display("[ %0t ] Driving REF : MODE = %0b | CMD = %0d | INP_VALID = %0d | OPA = %0d | OPB = %0d | ",$time, trans.MODE, trans.CMD, trans.INP_VALID, trans.OPA, trans.OPB);
          mb_dr.put(trans);


        end

        else begin
          drive_inf();
          $display("[ %0t ] Driving DUT : MODE = %0b | CMD = %0d | INP_VALID = %0d | OPA = %0d | OPB = %0d | ",$time, trans.MODE, trans.CMD, trans.INP_VALID, trans.OPA, trans.OPB);
          repeat(1)@(drv_inf.drv_cb);
          mb_dr.put(trans);
          $display("[ %0t ] Driving REF : MODE = %0b | CMD = %0d | INP_VALID = %0d | OPA = %0d | OPB = %0d | ",$time, trans.MODE, trans.CMD, trans.INP_VALID, trans.OPA, trans.OPB);
          trans.CMD.rand_mode(0);
          trans.MODE.rand_mode(0);

          for(int i = 0; i < 16; i++) begin

            repeat(1)@(drv_inf.drv_cb);
            void'(trans.randomize());
            drive_inf();
            $display("[ %0t ] Driving DUT : MODE = %0b | CMD = %0d | INP_VALID = %0d | OPA = %0d | OPB = %0d | ",$time, trans.MODE, trans.CMD, trans.INP_VALID, trans.OPA, trans.OPB);
            mb_dr.put(trans);
            $display("[ %0t ] Driving REF : MODE = %0b | CMD = %0d | INP_VALID = %0d | OPA = %0d | OPB = %0d | ",$time, trans.MODE, trans.CMD, trans.INP_VALID, trans.OPA, trans.OPB);
            //$display("[%0t] i = %0d",$time, i);

            if(trans.INP_VALID == 2'b11) begin
              if( trans.MODE == 1 && (trans.CMD == 9 || trans.CMD == 10)) begin
                repeat(1)@(drv_inf.drv_cb);
                break;
              end
                else begin
                  repeat(0)@(drv_inf.drv_cb);
                  break;
                end
            end
          end
        end
      end
      if( trans.MODE == 1 && (trans.CMD == 9 || trans.CMD == 10))
        repeat(1)@(drv_inf.drv_cb);

      repeat(1)@(drv_inf.drv_cb);
      $display("_______________________________________________________");
      $display("");
    end
  endtask
endclass
