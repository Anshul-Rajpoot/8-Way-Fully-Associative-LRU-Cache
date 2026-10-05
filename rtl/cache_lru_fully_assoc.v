`timescale 1ns/1ps

// 8-entry, fully associative cache with a 4-byte block size.
// The cache stores one byte per block in this educational example.
module cache_lru_fully_assoc (
    input        clk,
    input        reset,
    input  [7:0] addr,
    input  [7:0] data_in,
    input        we,
    input        re,

    output reg [7:0] data_out,
    output reg       hit
);

    wire [5:0] tag = addr[7:2];

    reg [7:0] data_array  [0:7];
    reg [5:0] tag_array   [0:7];
    reg       valid_array [0:7];
    reg [2:0] lru         [0:7];

    reg [2:0] hit_way;
    reg [2:0] replace_way;
    reg [2:0] old_lru;
    reg       hit_found;

    integer i;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 8; i = i + 1) begin
                data_array[i]  <= 8'd0;
                tag_array[i]   <= 6'd0;
                valid_array[i] <= 1'b0;
                lru[i]         <= 3'd0;
            end

            hit      <= 1'b0;
            data_out <= 8'd0;
        end else begin
            hit      <= 1'b0;
            data_out <= 8'hxx;

            hit_found   = 1'b0;
            hit_way     = 3'd0;
            replace_way = 3'd0;

            // Search the whole cache because it is fully associative.
            for (i = 0; i < 8; i = i + 1) begin
                if (valid_array[i] && tag_array[i] == tag) begin
                    hit_found = 1'b1;
                    hit_way   = i[2:0];
                end
            end

            if ((re || we) && hit_found) begin
                hit <= 1'b1;

                if (re)
                    data_out <= data_array[hit_way];

                if (we)
                    data_array[hit_way] <= data_in;

                old_lru = lru[hit_way];

                for (i = 0; i < 8; i = i + 1) begin
                    if (valid_array[i] && lru[i] < old_lru)
                        lru[i] <= lru[i] + 3'd1;
                end

                lru[hit_way] <= 3'd0;
            end else if (we) begin
                // Use an invalid entry first. The last invalid entry wins.
                for (i = 0; i < 8; i = i + 1) begin
                    if (!valid_array[i])
                        replace_way = i[2:0];
                end

                // If the cache is full, replace the least-recently-used entry.
                if (valid_array[replace_way]) begin
                    for (i = 0; i < 8; i = i + 1) begin
                        if (lru[i] == 3'd7)
                            replace_way = i[2:0];
                    end
                end

                old_lru = valid_array[replace_way] ? lru[replace_way] : 3'd7;

                for (i = 0; i < 8; i = i + 1) begin
                    if (valid_array[i] && lru[i] < old_lru)
                        lru[i] <= lru[i] + 3'd1;
                end

                data_array[replace_way]  <= data_in;
                tag_array[replace_way]   <= tag;
                valid_array[replace_way] <= 1'b1;
                lru[replace_way]         <= 3'd0;
            end
        end
    end

endmodule
