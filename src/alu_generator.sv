`include "defines.sv"

class alu_generator;

  mailbox #(alu_transaction) mb_gd; //mailbox between driver and generator

  alu_transaction blueprint; // blueprint object instance


  function new ( mailbox #(alu_transaction) mb_gd);
    this.mb_gd = mb_gd;
    blueprint = new();
  endfunction

  task start();
    $display("*****************************GENERATED RANDOM VALUES****************************************");
    $display("____________________________________________________________________________________________");
    for(int i = 1; i < `no_of_transactions + 1; i++) begin
      void'(blueprint.randomize()); // Randomize the values
      mb_gd.put(blueprint.copy()); // put the values into the driver-generator mail box
      $display("_________________________________________________________________________________________");
      $display("");
      $display("[TR: %0d] INP_VALID = %b | MODE = %0b | CMD = %d | OPA = %d | OPB = %d | CIN = %0b",i, blueprint.INP_VALID, blueprint.MODE, blueprint.CMD, blueprint.OPA, blueprint.OPB, blueprint.CIN );
    end
  endtask

endclass
