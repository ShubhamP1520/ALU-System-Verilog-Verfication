
`include "defines.sv"

class alu_reference_model;

  alu_transaction trans;

  mailbox #(alu_transaction) mb_dr;
  mailbox #(alu_transaction) mb_sr;

  virtual alu_inf.REF rf_inf;
  int count;

  logic [`SHIFT_W -1 :0] shift_a;
  function new(mailbox #(alu_transaction) mb_dr,
               mailbox #(alu_transaction) mb_sr,
               virtual alu_inf.REF rf_inf
              );
    this.mb_dr = mb_dr;
    this.mb_sr = mb_sr;
    this.rf_inf = rf_inf;
  endfunction


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
    repeat(3)@(rf_inf.ref_cb);

    for(int j = 0; j < `no_of_transactions; j++) begin

      trans = new();
      mb_dr.get(trans);

      //If single operand operations drive directly.
      if(single_operand(trans.MODE, trans.CMD)) begin

        repeat(1) @(rf_inf.ref_cb);
        perform_operations();
        //mb_sr.put(trans);

      end
      else begin

        //If two operand operation
        if(trans.INP_VALID == 2'b11 || trans.INP_VALID == 2'b00) begin
          if(trans.MODE == 1 && (trans.CMD == 9 || trans.CMD == 10)) begin
            repeat(1) @(rf_inf.ref_cb);
            perform_operations();
          end
          else begin
            repeat(1) @(rf_inf.ref_cb);
            perform_operations();
          end
        end


        else begin
          count = 0;
          for(count = 1; count < 17; count++) begin

            @(rf_inf.ref_cb);
            mb_dr.get(trans);
            //perform_operations();
            //$display("@[%0t] Ref : I got RES = %0d | ERR = %0d  ", $time, trans.RES, trans.ERR);
            //$display("@ [%0t] Putting into the Scoreboard mailbox", $time);
            //mb_sr.put(trans);

            if(trans.INP_VALID == 2'b11)begin
              trans.ERR = 1'b0;
              if(trans.MODE == 1 && (trans.CMD == 9 || trans.CMD == 10)) begin
                repeat(1)@(rf_inf.ref_cb);
                perform_operations();
              end
              else begin
                perform_operations();
                $display("REF : RES = %0d", trans.RES);
              end
              break;
            end
          end
          $display("Count = %d", count);
          repeat(1) @(rf_inf.ref_cb);
          if(count == 17)
            trans.ERR = 1;
           // trans.RES = 0;
        end
      end
      //repeat(1) @(rf_inf.ref_cb);
      mb_sr.put(trans);
    end
  endtask

  task perform_operations();
    if(rf_inf.ref_cb.RST) begin
      trans.RES = 9'dz;
      trans.COUT = 1'bz;
      trans.OFLOW = 1'bz;
      trans.ERR = 1'bz;
      trans.G = 1'bz;
      trans.L = 1'bz;
      trans.E = 1'bz;
    end
    else if(rf_inf.ref_cb.CE) begin
      trans.RES = 9'bzzzzzzzzz;
      trans.COUT = 1'bz;
      trans.OFLOW = 1'bz;
      trans.ERR = 1'bz;
      trans.G = 1'bz;
      trans.L = 1'bz;
      trans.E = 1'bz;
      if(trans.MODE) begin

        case(trans.INP_VALID)
          2'b01:begin
            case(trans.CMD)
              4: begin
                trans.RES = trans.OPA + 1;
                trans.COUT = trans.RES[`OP_WIDTH];
              end
              5: begin
                trans.RES = trans.OPA - 1;
                trans.OFLOW = trans.RES[`OP_WIDTH];
                $display(" RES = %0d", trans.RES);
              end
              default: trans.ERR = 1'b1;
            endcase
          end

          2'b10:begin
            case(trans.CMD)
              6: begin
                trans.RES = trans.OPB + 1;
                trans.COUT = trans.RES[`OP_WIDTH];
              end
              7: begin
                trans.RES = trans.OPB - 1;
                trans.OFLOW = trans.RES[`OP_WIDTH];
              end
              default: trans.ERR = 1'b1;
            endcase
          end
          2'b11: begin
            case(trans.CMD)
              0: begin
                trans.RES = trans.OPA + trans.OPB;
                trans.COUT = trans.RES[`OP_WIDTH];
              end
              1: begin
                trans.RES = trans.OPA - trans.OPB;
                trans.OFLOW = (trans.OPA < trans.OPB);
              end
              2: begin
                trans.RES =trans.OPA + trans.OPB + trans.CIN;
                trans.COUT = trans.RES[`OP_WIDTH];
              end
              3: begin
                trans.RES =trans.OPA - trans.OPB - trans.CIN;
                trans.OFLOW = (trans.OPA < (trans.OPB + trans.CIN));

              end
              4: begin
                trans.RES = trans.OPA + 1;
                //trans.COUT = trans.RES[`OP_WIDTH];
              end
              5: begin
                trans.RES = trans.OPA - 1;
               // trans.OFLOW = trans.RES[`OP_WIDTH];
                $display(" RES = %0d", trans.RES);
             end
              6: begin
                trans.RES = trans.OPB + 1;
                trans.COUT = trans.RES[`OP_WIDTH];
              end
              7: begin
                trans.RES = trans.OPB - 1;
                trans.OFLOW = trans.RES[`OP_WIDTH];
              end
              8: begin
                if(trans.OPA == trans.OPB) begin
                  trans.E = 1;
                  trans.G = 1'bz;
                  trans.L = 1'bz;
                end
                else if(trans.OPA > trans.OPB) begin
                   trans.E = 1'bz;
                   trans.G = 1;
                   trans.L = 1'bz;
                end
                else begin
                  trans.E = 1'bz;
                  trans.G = 1'bz;
                  trans.L = 1;
                end
              end
              9: begin
                trans.RES = (trans.OPA + 1) * (trans.OPB + 1);
              end
              10: begin
                trans.RES = (trans.OPA << 1) * (trans.OPB);
              end
              default : trans.ERR = 1'b1;
            endcase
          end
          default: trans.ERR = 1'b1;
        endcase
      end
      else begin
        trans.RES = 9'bzzzzzzzzz;
        trans.COUT = 1'bz;
        trans.OFLOW = 1'bz;
        trans.ERR = 1'bz;
        trans.G = 1'bz;
        trans.L = 1'bz;
        trans.E = 1'bz;

        case(trans.INP_VALID)
          2'b01:begin
            case(trans.CMD)
              6 : trans.RES = {1'b0, ~(trans.OPA)};
              8 : trans.RES = trans.OPA >> 1;
              9 : trans.RES = trans.OPA << 1;
              default: trans.ERR = 1'b1;
            endcase
          end

          2'b10:begin
            case(trans.CMD)
              7 : trans.RES = {1'b0, ~(trans.OPB)};
              10 : trans.RES = trans.OPB >> 1;
              11 : trans.RES = trans.OPB << 1;
              default: trans.ERR = 1'b1;
            endcase
          end
          2'b11: begin
            case(trans.CMD)
              0 : trans.RES = trans.OPA & trans.OPB;
              1 : trans.RES = {1'b0, ~(trans.OPA & trans.OPB)};
              2 : trans.RES = trans.OPA | trans.OPB;
              3 : trans.RES = {1'b0, ~(trans.OPA | trans.OPB)};
              4 : trans.RES = trans.OPA ^ trans.OPB;
              5 : trans.RES = {1'b0, ~(trans.OPA ^ trans.OPB)};
              6 : trans.RES = {1'b0,~(trans.OPA)};
              7 : trans.RES = {1'b0,~(trans.OPB)};
              8 : trans.RES = trans.OPA >> 1;
              9 : trans.RES = trans.OPA << 1;
              10 : trans.RES = trans.OPB >> 1;
              11 : trans.RES = trans.OPB << 1;
              12: begin
                if(|trans.OPB[`OP_WIDTH-1: `SHIFT_W+1])
                  trans.ERR = 1;
                else begin
                  shift_a = trans.OPB[`SHIFT_W-1:0];
                  trans.RES = {1'b0, (trans.OPA << shift_a)|(trans.OPA >> (`OP_WIDTH - shift_a))};
                end
              end
              13: begin
                if(|trans.OPB[`OP_WIDTH-1: `SHIFT_W+1])
                  trans.ERR = 1;
                else begin
                  shift_a = trans.OPB[`SHIFT_W-1:0];
                  trans.RES = {1'b0, (trans.OPA >> shift_a)|(trans.OPA << (`OP_WIDTH - shift_a))};
                end
              end

              default : trans.ERR = 1'b1;
            endcase
          end
          default: trans.ERR = 1'b1;
        endcase
      end
    end
  endtask

endclass
