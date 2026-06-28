`timescale 1ns/1ps

module fft_top_tb;

    parameter WIDTH = 1024;
    parameter IN_WIDTH = 32;       
    parameter TWIDDLE_WIDTH = 16;
    
    localparam SCALE = 32768.0; 

    logic clk;
    logic rst_n;
    logic signed [IN_WIDTH-1:0] in_real;
    logic signed [IN_WIDTH-1:0] in_imag;
    logic [$clog2(WIDTH)-1:0] sample_count;

    logic signed [IN_WIDTH - 1:0] out_real;
    logic signed [IN_WIDTH - 1:0] out_imag;

    fft_top #(
        .WIDTH(WIDTH),
        .IN_WIDTH(IN_WIDTH),
        .TWIDDLE_WIDTH(TWIDDLE_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .in_real(in_real),
        .in_imag(in_imag),
        .sample_count(sample_count),
        .out_real(out_real),
        .out_imag(out_imag)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk; 
    end

    initial begin
        $dumpfile("fft_top_tb.vcd");
        $dumpvars(0, fft_top_tb);
    end

    always @(posedge clk) begin
        if(rst_n) begin
            $display("Time: %0t | In Count: %2d | In: (%8f, %8f) | Out: (%8f, %8f)",
                     $time, sample_count,
                     real'(in_real) / SCALE, real'(in_imag) / SCALE,
                     real'(out_real) / SCALE, real'(out_imag) / SCALE);
        end
    end

    integer i;
    initial begin
        rst_n = 0;
        in_real = 0;
        in_imag = 0;
        sample_count = 0;

        repeat(5) @(posedge clk);
        #1; 
        
        rst_n = 1;
        
        // Feed 16-point Ramp Data
        for(i = 0; i < WIDTH; i = i + 1) begin
            in_real <= (i << 15); 
            in_imag <= 0;
            sample_count <= i;
            @(posedge clk);
        end

        // Flush pipeline
        repeat(200) begin
            in_real <= 0;
            in_imag <= 0;
            sample_count <= (sample_count + 1) % WIDTH; 
            @(posedge clk);
        end

        $finish;
    end

endmodule