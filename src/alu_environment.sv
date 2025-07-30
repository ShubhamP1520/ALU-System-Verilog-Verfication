
class alu_environment;

  mailbox #(alu_transaction) mb_ms; // mailbox between scoreboard and monitor
  mailbox #(alu_transaction) mb_gd; // mailbox between generator and driver
  mailbox #(alu_transaction) mb_dr; // mailbox between driver and reference model
  mailbox #(alu_transaction) mb_sr; // mailbox between reference and scoreboard

  virtual alu_inf drv_inf;
  virtual alu_inf mon_inf;
  virtual alu_inf ref_inf;

  alu_generator gen;
  alu_driver drv;
  alu_monitor mon;
  alu_reference_model ref_m;
  alu_scoreboard scb;

  function new(virtual alu_inf drv_inf,
               virtual alu_inf mon_inf,
               virtual alu_inf ref_inf
  );
    this.drv_inf = drv_inf;
    this.mon_inf = mon_inf;
    this.ref_inf = ref_inf;
  endfunction

  task build();
    //assigning mem to mailboxes
    mb_ms = new();
    mb_gd = new();
    mb_dr = new();
    mb_sr = new();

    //instances of all the env component
    gen = new(mb_gd);
    drv = new(mb_gd, mb_dr, drv_inf);
    mon = new(mb_ms, mon_inf);
    ref_m = new(mb_dr, mb_sr, ref_inf);
    scb = new(mb_sr, mb_ms);
  endtask

  task start();
    fork
      gen.start();
      drv.start();
      mon.start();
      ref_m.start();
    join
    scb.start();
  endtask
endclass
