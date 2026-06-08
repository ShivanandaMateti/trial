`timescale 1ns/1ps
`default_nettype none

module fifo_tb;

// ─────────────────────────────────────────────────────────────
//  Parameters – match DUT defaults
// ─────────────────────────────────────────────────────────────
parameter DWIDTH  = 8;
parameter AWIDTH  = 3;          // depth = 2^3 = 8 entries
parameter DEPTH   = 1 << AWIDTH;

// ─────────────────────────────────────────────────────────────
//  DUT signals
// ─────────────────────────────────────────────────────────────
reg  [DWIDTH-1:0] write_data;
reg               write_enable;
reg               write_clk;
reg               write_reset;
reg               read_enable;
reg               read_clk;
reg               read_reset;
wire [DWIDTH-1:0] read_data;
wire              empty;
wire              full;

// ─────────────────────────────────────────────────────────────
//  DUT instantiation
// ─────────────────────────────────────────────────────────────
fifo_top #(
    .Datawidth (DWIDTH),
    .Addresswidth(AWIDTH)
) DUT (
    .write_data   (write_data),
    .write_enable (write_enable),
    .write_clk    (write_clk),
    .write_reset  (write_reset),
    .read_enable  (read_enable),
    .read_clk     (read_clk),
    .read_reset   (read_reset),
    .read_data    (read_data),
    .empty        (empty),
    .full         (full)
);

// ─────────────────────────────────────────────────────────────
//  Asymmetric clocks
//  write_clk : 10 ns period  (100 MHz)
//  read_clk  :  7 ns period  (~143 MHz) – intentionally different
// ─────────────────────────────────────────────────────────────
initial write_clk = 0;
always  #5  write_clk = ~write_clk;

initial read_clk  = 0;
always  #3.5 read_clk  = ~read_clk;

// ─────────────────────────────────────────────────────────────
//  Scoreboard – reference queue
// ─────────────────────────────────────────────────────────────
reg [DWIDTH-1:0] ref_queue [0:255];
integer          q_head = 0;
integer          q_tail = 0;

task push_ref;
    input [DWIDTH-1:0] d;
    begin
        ref_queue[q_tail] = d;
        q_tail = q_tail + 1;
    end
endtask

task check_read;
    input [DWIDTH-1:0] actual;
    input [63:0]       test_id;
    begin
        if (q_head == q_tail) begin
            $display("ERROR [T%0d] Read data 0x%0h but queue is empty!", test_id, actual);
        end else if (actual !== ref_queue[q_head]) begin
            $display("FAIL  [T%0d] Expected 0x%0h  Got 0x%0h",
                     test_id, ref_queue[q_head], actual);
        end else begin
            $display("PASS  [T%0d] Read 0x%0h OK", test_id, actual);
        end
        q_head = q_head + 1;
    end
endtask

// ─────────────────────────────────────────────────────────────
//  Helper tasks
// ─────────────────────────────────────────────────────────────

// Write one word on the next rising write_clk edge
task write_one;
    input [DWIDTH-1:0] d;
    begin
        @(negedge write_clk);
        write_data   = d;
        write_enable = 1;
        @(posedge write_clk); #1;
        write_enable = 0;
    end
endtask

// Read one word on the next rising read_clk edge, return via out
task read_one;
    output [DWIDTH-1:0] out;
    begin
        @(negedge read_clk);
        read_enable = 1;
        @(posedge read_clk); #1;
        out = read_data;
        read_enable = 0;
    end
endtask

// Wait N write-clock cycles
task wclk_delay;
    input integer n;
    integer i;
    begin
        for (i = 0; i < n; i = i+1)
            @(posedge write_clk);
    end
endtask

// Wait N read-clock cycles
task rclk_delay;
    input integer n;
    integer i;
    begin
        for (i = 0; i < n; i = i+1)
            @(posedge read_clk);
    end
endtask

// Assert both resets, release after a few cycles
task apply_reset;
    begin
        write_reset = 1;
        read_reset  = 1;
        repeat(4) @(posedge write_clk);
        repeat(4) @(posedge read_clk);
        @(negedge write_clk); write_reset = 0;
        @(negedge read_clk);  read_reset  = 0;
        // Allow synchronisers to settle
        repeat(6) @(posedge write_clk);
        repeat(6) @(posedge read_clk);
    end
endtask

// ─────────────────────────────────────────────────────────────
//  Pass / fail counter
// ─────────────────────────────────────────────────────────────
integer pass_cnt = 0;
integer fail_cnt = 0;

task assert_eq;
    input [DWIDTH-1:0] got;
    input [DWIDTH-1:0] exp;
    input [127:0]      msg;
    begin
        if (got === exp) begin
            $display("  PASS  %s : 0x%0h", msg, got);
            pass_cnt = pass_cnt + 1;
        end else begin
            $display("  FAIL  %s : expected 0x%0h  got 0x%0h", msg, exp, got);
            fail_cnt = fail_cnt + 1;
        end
    end
endtask

task assert_flag;
    input        got;
    input        exp;
    input [127:0] msg;
    begin
        if (got === exp) begin
            $display("  PASS  %s = %0b", msg, got);
            pass_cnt = pass_cnt + 1;
        end else begin
            $display("  FAIL  %s : expected %0b  got %0b", msg, exp, got);
            fail_cnt = fail_cnt + 1;
        end
    end
endtask

// ─────────────────────────────────────────────────────────────
//  Main test sequence
// ─────────────────────────────────────────────────────────────
integer i;
reg [DWIDTH-1:0] rdata;

initial begin
    // ── Initialise ──────────────────────────────────────────
    write_data   = 0;
    write_enable = 0;
    read_enable  = 0;
    write_reset  = 0;
    read_reset   = 0;

    $dumpfile("fifo_tb.vcd");
    $dumpvars(0, fifo_tb);

    // ════════════════════════════════════════════════════════
    //  TEST 1 : Reset behaviour
    // ════════════════════════════════════════════════════════
    $display("\n═══ TEST 1 : Reset behaviour ═══");
    apply_reset;
    assert_flag(empty, 1, "empty after reset");
    assert_flag(full,  0, "full  after reset");

    // ════════════════════════════════════════════════════════
    //  TEST 2 : Read from empty FIFO (should stay empty)
    // ════════════════════════════════════════════════════════
    $display("\n═══ TEST 2 : Read from empty FIFO ═══");
    @(negedge read_clk);
    read_enable = 1;
    @(posedge read_clk); #1;
    read_enable = 0;
    rclk_delay(4);
    assert_flag(empty, 1, "still empty after spurious read");

    // ════════════════════════════════════════════════════════
    //  TEST 3 : Single write then single read
    // ════════════════════════════════════════════════════════
    $display("\n═══ TEST 3 : Single write / single read ═══");
    write_one(8'hA5);
    push_ref(8'hA5);
    rclk_delay(6);   // let pointer cross clock domain
    assert_flag(empty, 0, "not empty after 1 write");

    read_one(rdata);
    rclk_delay(6);
    check_read(rdata, 3);
    assert_flag(empty, 1, "empty after reading back 1 entry");

    // ════════════════════════════════════════════════════════
    //  TEST 4 : Fill FIFO completely → check full flag
    // ════════════════════════════════════════════════════════
    $display("\n═══ TEST 4 : Fill to full ═══");
    for (i = 0; i < DEPTH; i = i+1) begin
        write_one(i[DWIDTH-1:0]);
        push_ref(i[DWIDTH-1:0]);
    end
    wclk_delay(8);   // wait for full to propagate
    assert_flag(full, 1, "full after writing DEPTH entries");

    // ════════════════════════════════════════════════════════
    //  TEST 5 : Write while full (should be ignored)
    // ════════════════════════════════════════════════════════
    $display("\n═══ TEST 5 : Write while full (no-op) ═══");
    @(negedge write_clk);
    write_data   = 8'hFF;
    write_enable = 1;
    @(posedge write_clk); #1;
    write_enable = 0;
    wclk_delay(4);
    assert_flag(full, 1, "still full after write attempt");

    // ════════════════════════════════════════════════════════
    //  TEST 6 : Drain FIFO completely → check empty flag
    //           Also verifies FIFO order (FIFO not LIFO)
    // ════════════════════════════════════════════════════════
    $display("\n═══ TEST 6 : Drain to empty, verify order ═══");
    for (i = 0; i < DEPTH; i = i+1) begin
        read_one(rdata);
        rclk_delay(4);
        check_read(rdata, 6);
    end
    rclk_delay(8);
    assert_flag(empty, 1, "empty after draining all entries");

    // ════════════════════════════════════════════════════════
    //  TEST 7 : Simultaneous write and read (FIFO non-empty)
    // ════════════════════════════════════════════════════════
    $display("\n═══ TEST 7 : Simultaneous write and read ═══");
    // Pre-fill with 4 entries
    for (i = 0; i < 4; i = i+1) begin
        write_one(8'h10 + i[DWIDTH-1:0]);
        push_ref(8'h10 + i[DWIDTH-1:0]);
    end
    rclk_delay(6);

    // Now toggle write_enable and read_enable concurrently
    fork
        begin
            repeat(4) begin
                @(negedge write_clk);
                write_data   = $random;
                write_enable = 1;
                push_ref(write_data);
                @(posedge write_clk); #1;
                write_enable = 0;
                wclk_delay(1);
            end
        end
        begin
            repeat(4) begin
                read_one(rdata);
                rclk_delay(3);
                check_read(rdata, 7);
            end
        end
    join

    // ════════════════════════════════════════════════════════
    //  TEST 8 : Write-pointer wrap-around
    //           Write DEPTH*2 words in two batches,
    //           draining between them, to exercise
    //           pointer wrap beyond 2^AWIDTH
    // ════════════════════════════════════════════════════════
    $display("\n═══ TEST 8 : Pointer wrap-around ═══");
    apply_reset;
    // Batch 1 – fill and drain
    for (i = 0; i < DEPTH; i = i+1) begin
        write_one(8'hB0 + i[DWIDTH-1:0]);
        push_ref(8'hB0 + i[DWIDTH-1:0]);
    end
    rclk_delay(6);
    for (i = 0; i < DEPTH; i = i+1) begin
        read_one(rdata);
        rclk_delay(4);
        check_read(rdata, 8);
    end
    // Batch 2 – fill and drain again (pointers have wrapped)
    for (i = 0; i < DEPTH; i = i+1) begin
        write_one(8'hC0 + i[DWIDTH-1:0]);
        push_ref(8'hC0 + i[DWIDTH-1:0]);
    end
    rclk_delay(6);
    for (i = 0; i < DEPTH; i = i+1) begin
        read_one(rdata);
        rclk_delay(4);
        check_read(rdata, 8);
    end
    rclk_delay(8);
    assert_flag(empty, 1, "empty after wrap-around drain");

    // ════════════════════════════════════════════════════════
    //  TEST 9 : Reset mid-operation
    //           Write some data, reset without reading,
    //           verify FIFO is empty and pointers are cleared
    // ════════════════════════════════════════════════════════
    $display("\n═══ TEST 9 : Reset mid-operation ═══");
    for (i = 0; i < 3; i = i+1)
        write_one(8'hDE + i[DWIDTH-1:0]);
    wclk_delay(3);
    apply_reset;
    // Reset scoreboard state
    q_head = 0; q_tail = 0;
    assert_flag(empty, 1, "empty after mid-op reset");
    assert_flag(full,  0, "not full after mid-op reset");

    // ════════════════════════════════════════════════════════
    //  TEST 10 : Burst write then burst read (stress)
    // ════════════════════════════════════════════════════════
    $display("\n═══ TEST 10 : Stress – 32 words, back-to-back ═══");
    apply_reset;
    q_head = 0; q_tail = 0;

    // Write DEPTH entries, read them, repeat 4 times
    repeat(4) begin
        for (i = 0; i < DEPTH; i = i+1) begin
            write_one($random & 8'hFF);
            push_ref(write_data);
        end
        wclk_delay(6);
        for (i = 0; i < DEPTH; i = i+1) begin
            read_one(rdata);
            rclk_delay(4);
            check_read(rdata, 10);
        end
        rclk_delay(6);
    end
    assert_flag(empty, 1, "empty after stress test");

    // ════════════════════════════════════════════════════════
    //  TEST 11 : almost-full / almost-empty boundary
    //            Write DEPTH-1 → not full; write 1 more → full
    //            Read 1 → not empty; read rest → empty
    // ════════════════════════════════════════════════════════
    $display("\n═══ TEST 11 : Boundary – almost full / almost empty ═══");
    apply_reset;
    q_head = 0; q_tail = 0;

    for (i = 0; i < DEPTH-1; i = i+1) begin
        write_one(8'hE0 + i[DWIDTH-1:0]);
        push_ref(8'hE0 + i[DWIDTH-1:0]);
    end
    wclk_delay(8);
    assert_flag(full,  0, "not full at DEPTH-1 entries");
    assert_flag(empty, 0, "not empty at DEPTH-1 entries");

    write_one(8'hEF);
    push_ref(8'hEF);
    wclk_delay(8);
    assert_flag(full, 1, "full at DEPTH entries");

    // Read one → no longer full
    read_one(rdata);
    rclk_delay(8);
    check_read(rdata, 11);
    assert_flag(full, 0, "not full after reading 1 from full");

    // Read remaining
    for (i = 0; i < DEPTH-1; i = i+1) begin
        read_one(rdata);
        rclk_delay(4);
        check_read(rdata, 11);
    end
    rclk_delay(8);
    assert_flag(empty, 1, "empty after reading all from almost-full");

    // ════════════════════════════════════════════════════════
    //  TEST 12 : Slow writer, fast reader
    // ════════════════════════════════════════════════════════
    $display("\n═══ TEST 12 : Slow writer fast reader ═══");
    apply_reset;
    q_head = 0; q_tail = 0;

    fork
        begin : slow_writer
            for (i = 0; i < 8; i = i+1) begin
                wclk_delay(4);          // write every 4 cycles
                write_one(8'hF0 + i[DWIDTH-1:0]);
                push_ref(8'hF0 + i[DWIDTH-1:0]);
            end
        end
        begin : fast_reader
            repeat(8) begin
                // Poll until not empty, then read
                while (empty) @(posedge read_clk);
                read_one(rdata);
                rclk_delay(1);
                check_read(rdata, 12);
            end
        end
    join

    // ════════════════════════════════════════════════════════
    //  TEST 13 : Fast writer, slow reader
    // ════════════════════════════════════════════════════════
    $display("\n═══ TEST 13 : Fast writer slow reader ═══");
    apply_reset;
    q_head = 0; q_tail = 0;

    fork
        begin : fast_writer
            for (i = 0; i < DEPTH; i = i+1) begin
                write_one(8'h50 + i[DWIDTH-1:0]);
                push_ref(8'h50 + i[DWIDTH-1:0]);
            end
        end
        begin : slow_reader
            repeat(DEPTH) begin
                rclk_delay(8);          // read every 8 cycles
                while (empty) @(posedge read_clk);
                read_one(rdata);
                rclk_delay(1);
                check_read(rdata, 13);
            end
        end
    join
    rclk_delay(8);
    assert_flag(empty, 1, "empty after slow-reader test");

    // ════════════════════════════════════════════════════════
    //  Summary
    // ════════════════════════════════════════════════════════
    $display("\n═══════════════════════════════════════");
    $display("  Results : %0d PASS   %0d FAIL", pass_cnt, fail_cnt);
    $display("═══════════════════════════════════════\n");

    $finish;
end

// ─────────────────────────────────────────────────────────────
//  Timeout watchdog
// ─────────────────────────────────────────────────────────────
initial begin
    #500000;
    $display("TIMEOUT: simulation exceeded limit");
    $finish;
end

endmodule