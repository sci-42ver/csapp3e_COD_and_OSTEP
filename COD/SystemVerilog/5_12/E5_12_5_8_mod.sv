// `include "./E5_12_4.sv"
`include "debug_view.sv"

/*cache finite state machine*/
/* verilator lint_off UNOPTFLAT */
/*
cpu_req -> mem_req; ...
*/
module dm_cache_fsm (
    input bit clk,
    input bit rst,
    input cpu_req_type cpu_req,
    //CPU request input (CPU->cache)
    input mem_data_type mem_data,
    //memory response (memory->cache)
    output mem_req_type mem_req,
    //memory request (cache->memory)
    output cpu_result_type cpu_res
    //cache result (cache - >CPU)
);
  timeunit 1ns; timeprecision 1ns;
  /*write clock*/
  typedef enum {
    idle,
    compare_tag,
    allocate,
    write_back
  } cache_state_type;
  /*FSM state register*/
  cache_state_type vstate, rstate;
  /*interface signals to tag memory*/
  cache_tag_type tag_read;
  cache_tag_type tag_write;
  cache_req_type tag_req;
  //tag read result
  //tag write data
  //tag request
  /*interface signals to cache data memory*/
  cache_data_type data_read;
  //cache line read data
  cache_data_type data_write;
  //cache line write data
  cache_req_type data_req;
  //data req
  /*temporary variable for cache controller result*/
  cpu_result_type v_cpu_res;
  /*temporary variable for memory controller request*/
  mem_req_type v_mem_req;
  assign mem_req = v_mem_req;
  assign cpu_res = v_cpu_res;
  //connect to output ports

  initial begin
    // not put in always_comb to avoid duplicate write.
    v_mem_req.rw = '0;
  end

  /*
FIGURE E5.12.6 begin
*/

  always_comb begin
    /*
    comb will run multiple times each clock by its self inherent syntax definition (whenever one of the inner variables change).
    */
    // $display("begin comb:%0t",$time);
    /*-------------------------default values for all signals------------*/
    /*no state change by default*/
    vstate = rstate;
    // $display("rstate: %0d tag_read.tag: %0d",rstate,tag_read.tag);
    v_cpu_res = '{data: 0, ready: 0};
    // v_cpu_res.data = '0;
    // v_cpu_res = {'0, '0};
    tag_write = '{valid: 0, dirty: 0, tag: 0};
    // tag_write = {'0, '0, '0};
    /*read tag by default*/
    tag_req.we = '0;
    /*direct map index for tag */
    tag_req.index = cpu_req.addr[13 : 4];
    /*read current cache line by default*/
    data_req.we = '0;
    /*direct map index for cache data*/
    data_req.index = cpu_req.addr[13 : 4];
    /*modify correct word (32 -bit) based on address*/
    data_write = data_read;
    casez (cpu_req.addr[3 : 2])
      2'b00: data_write[31 : 0] = cpu_req.data;
      2'b01: data_write[63 : 32] = cpu_req.data;
      2'b10: data_write[95 : 64] = cpu_req.data;
      2'b11: data_write[127 : 96] = cpu_req.data;
    endcase
    /*read out correct word(32 - bit) from cache (to CP U)*/
    casez (cpu_req.addr[3 : 2])
      2'b00: v_cpu_res.data = data_read[31 : 0];
      2'b01: v_cpu_res.data = data_read[63 : 32];
      2'b10: v_cpu_res.data = data_read[95 : 64];
      2'b11: v_cpu_res.data = data_read[127 : 96];
    endcase
    /*memory request address (sampled from CPU request) */
    /*
    this is to cache.
    */
    v_mem_req.addr = cpu_req.addr;
    /*memory request data (used in write)*/
    v_mem_req.data = data_read;

    /*
FIGURE E5.12.7
*/

    //------------------------------------Cache FSM-------------------------
    casez (rstate)
      /*idle state*/
      idle: begin
        /*If there is a CPU request, then compare cache tag */
        if (cpu_req.valid) vstate = compare_tag;
      end
      /*compare_tag state*/
      compare_tag: begin
        /*cache hit (tag match and cache entry is va l id) */

        /*
        ignore this: TODO how tag_read assigned;this should traverse the whole memory list 
        */
        if (cpu_req.addr[TAGMSB : TAGLSB] == tag_read.tag && tag_read.valid) begin
          $display("tag has been hit");
          v_cpu_res.ready = '1;
          // $display("should return to wait() and fetch new instr; should not show this");
          /*wr i t e hit*/
          if (cpu_req.rw) begin
            /*read/modify cache line*/
            $display("modify cache line");
            tag_req.we = '1;
            data_req.we = '1;
            /*SA(self added)
            write-back so data_write not changed.
            data_write is assigned anytime.
            */
            // data_write = cpu_req.data;

            /*no change in tag*/
            /*
            just change status bit and wirte back.
            */
            tag_write.tag = tag_read.tag;
            tag_write.valid = '1;
            /*cache line is dirty*/
            tag_write.dirty = '1;
          end
          /*xaction is finished*/
          vstate = idle;
        end/*cache miss*/
        else begin
          /*generate new tag*/
          /*
          ignore this line:TODO why directly enable we
          write new tag
          */
          tag_req.we = '1;
          tag_write.valid = '1;
          /*new tag*/
          tag_write.tag = cpu_req.addr[TAGMSB : TAGLSB];
          /*cache line is dirty if wr i te*/
          tag_write.dirty = cpu_req.rw;
          /*generate memory request on miss */
          /*set valid to make request*/
          v_mem_req.valid = '1;
          /*compulsory miss or miss with clean block*/
          /*
          here if not valid, must fetch from mem ( i.e. allocate)
          valid and clean (valid = 1, dirty = 0) is impossible beacuse above tag must match.
          valid and dirty just means that data has been modified, so write back -> go to else ...
          not valid but dirty is obvious impossible.

          so only check `valid` is enough.

          can check with 
          `if (tag_read.valid == 1'b0) begin/*wait till a new block is allocated`
          */

          if (tag_read.valid == 1'b0) begin/*wait till a new block is allocated */
          
          // if (tag_read.valid == 1'b0 || tag_read.dirty == 1'b0) begin/*wait till a new block is allocated*/
            vstate = allocate;
            $display("need init tag");
          end          

/*
FIGURE E5.12.8
*/

          else begin
            /*
            TODO
            */
            /*miss with dirty line*/
            /*write back address*/

            /*
            when r/w, valid always 1, so dirty implies `valid`.

            So valid & dirty.

            TODO can use cpu_req.addr[TAGMSB : TAGLSB]?
            */
            v_mem_req.addr = {tag_read.tag, cpu_req.addr[TAGLSB-1 : 0]};
            v_mem_req.rw   = '1;
            $display("To write back, allow rw, changing v_mem_req.rw");
            /*wait till write is completed*/
            vstate = write_back;
          end
        end
      end

      /*wait for allocating a new cache line*/
      allocate: begin
        /*memory controller has responded*/
        if (mem_data.ready) begin
          $display("To allocate");
          /*re-compare tag for write miss (need modify correct word)*/
          vstate = compare_tag;
          data_write = mem_data.data;
          /*update cache line data*/
          data_req.we = '1;

          // to avoid duplicate write
          // cpu_req.rw = '0;
        end
      end
      /*wait for writing back dirty cache line*/
      write_back: begin
        /*write back is completed*/
        // $display("v_mem_req.rw changed to:%0b; mem_req.rw: %0b",v_mem_req.rw,mem_req.rw);
        if (mem_data.ready) begin
          $display("TO WB, data has been manipulated; v_mem_req.rw changed to:%0b; mem_req.rw: %0b",
                   v_mem_req.rw, mem_req.rw);
          /*issue new memory request (allocating a new line)*/
          v_mem_req.valid = '1;
          v_mem_req.rw = '0;
          vstate = allocate;
        end
      end
    endcase
  end
  always_ff @(posedge (clk)) begin
    if (rst) rstate <= idle;
    //reset to idle state
    else begin
      rstate <= vstate;
      // reset
      // v_mem_req.rw = 0;
    end
  end
  /*connect cache tag/data memory*/
  // dm_cache_tag ctag (.clk(clk),.tag_req(tag_req),.tag_write(tag_write),.tag_read(tag_read));
  // https://stackoverflow.com/questions/58436253/in-systemverilog-what-does-mean
  dm_cache_tag ctag (.*);
  dm_cache_data cdata (.*);

  wire [TAGMSB-TAGLSB:0] cpu_req_tag;
  view_var vars (.*);
endmodule
