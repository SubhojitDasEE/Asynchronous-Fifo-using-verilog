`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.08.2025 10:43:00
// Design Name: 
// Module Name: asynch_test
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module asynch_test(

    );
    reg rst;
    reg wr_clk, rd_clk;
    reg wr_en, rd_en;
    reg [7:0] data_in;
    wire [7:0] data_out;
    wire full, empty;

    // Instantiate the FIFO
    asynch_fifo uut (
        .rst(rst),
        .wr_clk(wr_clk),
        .rd_clk(rd_clk),
        .rd_en(rd_en),
        .wr_en(wr_en),
        .data_in(data_in),
        .full(full),
        .empty(empty),
        .data_out(data_out)
    );

    // Clock generation
    initial begin
        wr_clk = 0;
        forever #5 wr_clk = ~wr_clk;  // 100 MHz
    end

    initial begin
        rd_clk = 0;
        forever #7 rd_clk = ~rd_clk;  // ~71.4 MHz
    end

    // Task to write one byte
    task write_data(input [7:0] value);
    begin
        @(posedge wr_clk);
        if (!full) begin
            wr_en <= 1;
            data_in <= value;
            $display("[WRITE] Time: %0t | Data: %0d | Full: %b", $time, value, full);
        end else begin
            $display("[WRITE BLOCKED - FULL] Time: %0t | Data: %0d", $time, value);
            wr_en <= 0;
        end
        @(posedge wr_clk);
        wr_en <= 0;
    end
    endtask

    // Task to read one byte
    task read_data;
    begin
        rd_en = 1;
        @(posedge rd_clk);
        #1; // small delay to let 'empty' stabilize
        if (!empty)
            $display("[READ] Time: %t | Data Out: %0d | Empty: %0b", $time, data_out, empty);
        else
            $display("[READ BLOCKED - EMPTY] Time: %t | Empty: %0b", $time, empty);
        rd_en = 0;
    end
    endtask

    // Main stimulus
    integer i;
    initial begin
        // Initial setup
        rst = 1;
        wr_en = 0;
        rd_en = 0;
        data_in = 0;
        #20 rst = 0;

        // Phase 1: Write 10 bytes
        $display("\n--- Phase 1: Writing 10 bytes ---");
        for (i = 0; i < 10; i = i + 1) begin
            write_data(i);
        end

        // Idle gap
        $display("\n--- Idle ---");
        #50;

        // Phase 2: Read 5 bytes
        $display("\n--- Phase 2: Reading 5 bytes ---");
        for (i = 0; i < 5; i = i + 1) begin
            read_data();
        end

        // Phase 3: Simultaneous write and read
        $display("\n--- Phase 3: Simultaneous Write/Read ---");
        for (i = 10; i < 18; i = i + 1) begin
            fork
                write_data(i);
                read_data();
            join
        end

        // Phase 4: Try overfilling FIFO (should hit full condition)
        $display("\n--- Phase 4: Attempting to Fill FIFO Completely ---");
        for (i = 18; i < 30; i = i + 1) begin
            write_data(i);  // FIFO should block some writes here
        end

        // Read remaining until empty
        $display("\n--- Phase 5: Reading Until Empty ---");
        while (!empty) begin
            read_data();
       end
 //         for (i = 0; i < 8; i = i + 1) begin
 //           read_data();  // FIFO should block some writes here
 //         end
        

        // Final idle and finish
        #50;
        $display("\n--- Testbench Complete ---");
        $stop;
    end

endmodule
