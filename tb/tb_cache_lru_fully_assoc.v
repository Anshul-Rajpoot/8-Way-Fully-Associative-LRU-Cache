`timescale 1ns/1ps

// Self-checking testbench for cache_lru_fully_assoc.
//
// The testbench verifies:
//   - reset behavior
//   - write allocation
//   - read hits
//   - read misses
//   - LRU updates
//   - LRU replacement
//   - write hits
//
// Run with:
//   make
//
// Generate waveform:
//   make wave

module tb_cache_lru_fully_assoc;

    reg clk;
    reg reset;
    reg [7:0] addr;
    reg [7:0] data_in;
    reg we;
    reg re;

    wire [7:0] data_out;
    wire hit;

    integer i;
    integer errors;

    cache_lru_fully_assoc dut (
        .clk      (clk),
        .reset    (reset),
        .addr     (addr),
        .data_in  (data_in),
        .we       (we),
        .re       (re),
        .data_out (data_out),
        .hit      (hit)
    );

    always #5 clk = ~clk;

    task automatic check;
        input condition;
        input [8*120-1:0] message;
        begin
            if (!condition) begin
                $display("FAIL: %0s", message);
                errors = errors + 1;
            end else begin
                $display("PASS: %0s", message);
            end
        end
    endtask

    task automatic write_cache;
        input [7:0] a;
        input [7:0] d;
        begin
            @(negedge clk);
            addr    = a;
            data_in = d;
            we      = 1'b1;
            re      = 1'b0;

            @(posedge clk);
            #1;
            we = 1'b0;

            // A write miss allocates but is not considered a hit.
            check(hit === 1'b0, "write miss has hit=0");
        end
    endtask

    task automatic write_hit_cache;
        input [7:0] a;
        input [7:0] d;
        begin
            @(negedge clk);
            addr    = a;
            data_in = d;
            we      = 1'b1;
            re      = 1'b0;

            @(posedge clk);
            #1;
            we = 1'b0;

            check(hit === 1'b1, "write hit has hit=1");
        end
    endtask

    task automatic read_cache;
        input [7:0] a;
        input expected_hit;
        input [7:0] expected_data;
        begin
            @(negedge clk);
            addr = a;
            we   = 1'b0;
            re   = 1'b1;

            @(posedge clk);
            #1;
            re = 1'b0;

            check(hit === expected_hit, "read hit status is correct");

            if (expected_hit)
                check(data_out === expected_data, "read data is correct");
            else
                check(data_out === 8'hxx, "read miss returns unknown data");
        end
    endtask

    task automatic check_entry;
        input integer index;
        input expected_valid;
        input [5:0] expected_tag;
        input [7:0] expected_data;
        begin
            check(
                dut.valid_array[index] === expected_valid,
                "cache valid bit is correct"
            );

            if (expected_valid) begin
                check(
                    dut.tag_array[index] === expected_tag,
                    "cache tag is correct"
                );
                check(
                    dut.data_array[index] === expected_data,
                    "cache data is correct"
                );
            end
        end
    endtask

    task automatic show_cache;
        begin
            $display("");
            $display("Cache state:");
            $display("Way | Valid | Tag | Data | LRU");
            $display("--------------------------------");
            for (i = 0; i < 8; i = i + 1) begin
                $display(
                    " %0d  |   %b   |  %02h |  %02h  |  %0d",
                    i,
                    dut.valid_array[i],
                    dut.tag_array[i],
                    dut.data_array[i],
                    dut.lru[i]
                );
            end
            $display("--------------------------------");
        end
    endtask

    initial begin
        errors  = 0;
        clk     = 1'b0;
        reset   = 1'b1;
        addr    = 8'h00;
        data_in = 8'h00;
        we      = 1'b0;
        re      = 1'b0;

        $display("");
        $display("========================================");
        $display(" Fully Associative LRU Cache Testbench");
        $display("========================================");

        // Generate waveform only when requested:
        // make wave -> passes +WAVE to vvp.
        if ($test$plusargs("WAVE"))
            $dumpfile("build/cache_lru.vcd");

        if ($test$plusargs("WAVE"))
            $dumpvars(0, tb_cache_lru_fully_assoc);

        // -------------------------
        // Reset verification
        // -------------------------
        #2;
        for (i = 0; i < 8; i = i + 1) begin
            check(dut.valid_array[i] === 1'b0, "reset clears valid bit");
            check(dut.lru[i] === 3'd0, "reset clears LRU metadata");
        end

        #10;
        reset = 1'b0;

        // -------------------------
        // Fill cache
        // -------------------------
        $display("");
        $display("[1] Filling cache");

        write_cache(8'h00, 8'hA0);
        write_cache(8'h04, 8'hA1);
        write_cache(8'h08, 8'hA2);
        write_cache(8'h0C, 8'hA3);
        write_cache(8'h10, 8'hA4);
        write_cache(8'h14, 8'hA5);
        write_cache(8'h18, 8'hA6);
        write_cache(8'h1C, 8'hA7);

        // All eight entries must now be valid.
        for (i = 0; i < 8; i = i + 1)
            check(dut.valid_array[i] === 1'b1, "cache entry allocated");

        // -------------------------
        // Read hit + LRU update
        // -------------------------
        $display("");
        $display("[2] Testing read hit and LRU update");

        read_cache(8'h00, 1'b1, 8'hA0);
        check(dut.lru[7] === 3'd0, "most recently used entry has LRU rank 0");

        // -------------------------
        // LRU replacement
        // -------------------------
        $display("");
        $display("[3] Testing LRU replacement");

        write_cache(8'h20, 8'hB0);

        // Address 04 is expected to be the LRU entry and therefore evicted.
        read_cache(8'h04, 1'b0, 8'h00);
        read_cache(8'h20, 1'b1, 8'hB0);
        read_cache(8'h00, 1'b1, 8'hA0);

        // -------------------------
        // Write hit
        // -------------------------
        $display("");
        $display("[4] Testing write hit");

        write_hit_cache(8'h20, 8'hB1);
        read_cache(8'h20, 1'b1, 8'hB1);

        // -------------------------
        // Read miss
        // -------------------------
        $display("");
        $display("[5] Testing read miss");

        read_cache(8'hFC, 1'b0, 8'h00);

        show_cache();

        // -------------------------
        // Final result
        // -------------------------
        $display("");
        $display("========================================");

        if (errors == 0) begin
            $display("ALL TESTS PASSED");
            $display("========================================");
        end else begin
            $display("TEST FAILED: %0d error(s)", errors);
            $display("========================================");
            $finish(1);
        end

        $finish;
    end

endmodule
