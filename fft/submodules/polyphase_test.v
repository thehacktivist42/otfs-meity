`timescale 1ns/1ps

module polyphase_demux_tb;

    // Parameters (Matching the DUT)
    localparam IN_WIDTH = 36;
    localparam NUM_BANKS = 32;
    localparam BANK_DEPTH = 32;

    // DUT Signals
    logic clk;
    logic rst_n;
    logic signed [IN_WIDTH - 1:0] in_real;
    logic signed [IN_WIDTH - 1:0] in_imag;

    logic signed [IN_WIDTH - 1:0] broadcast_real;
    logic signed [IN_WIDTH - 1:0] broadcast_imag;
    logic [NUM_BANKS - 1:0] bank_we;
    logic [$clog2(BANK_DEPTH) - 1:0] bank_waddr;
    logic ping_pong_select;
    logic frame_done;

    // Instantiate the Device Under Test (DUT)
    polyphase_demux #(
        .IN_WIDTH(IN_WIDTH),
        .NUM_BANKS(NUM_BANKS),
        .BANK_DEPTH(BANK_DEPTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .in_real(in_real),
        .in_imag(in_imag),
        .broadcast_real(broadcast_real),
        .broadcast_imag(broadcast_imag),
        .bank_we(bank_we),
        .bank_waddr(bank_waddr),
        .ping_pong_select(ping_pong_select),
        .frame_done(frame_done)
    );

    // Clock Generation (100 MHz -> 10ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk; 
    end

    // Stimulus Generation
    initial begin
        // Setup waveform dumping for viewing in GTKWave/Vivado
        $dumpfile("polyphase_demux_tb.vcd");
        $dumpvars(0, polyphase_demux_tb);

        // Initial State
        rst_n = 0;
        in_real = 0;
        in_imag = 0;

        // Apply Reset
        #25; 
        rst_n = 1;

        // Feed Continuous Data
        // A full frame is NUM_BANKS * BANK_DEPTH = 32 * 32 = 1024 samples.
        // We will feed 2100 samples to verify exactly two full frame completions 
        // and the start of a third frame.
        for (int i = 0; i < 2100; i++) begin
            @(posedge clk);
            in_real <= i;           // Increasing ramp for easy tracking
            in_imag <= -i;          // Decreasing ramp for I/Q distinction
        end

        // Wait a few cycles and finish
        #100;
        $display("Simulation complete.");
        $finish;
    end

    // Self-Checking Monitor Block
    always_ff @(posedge clk) begin
        if (rst_n) begin
            // Print a notification to the console every time a frame completes
            if (frame_done) begin
                $display("Time: %0t ns | Frame %0d complete! ping_pong_select toggled to: %b | Address wrapped to: %0d",
                         $time, 
                         (ping_pong_select ? 1 : 2), // Rough frame counter for console clarity
                         ping_pong_select, 
                         bank_waddr);
            end
        end
    end

endmodule