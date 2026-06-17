module testbench_tb;
    reg [2:0] A[7:0];
    wire [2:0] B[7:0];
    wire [23:0] out_real[7:0];
    wire [23:0] out_imag[7:0];
    reg [7:0] B_new_real[7:0];
    reg [7:0] B_new_imag[7:0];
    integer i;
    bit_reversal uut1(.in(A), .out(B));
    add_sub uut2(.in_real(B_new_real), .in_imag(B_new_imag), .out_real(out_real), .out_imag(out_imag));
    always @(*) begin
        for (i = 0; i < 8; i = i + 1) begin
            B_new_real[i] = {5'b0, B[i]};
            B_new_imag[i] = {8'd0};
        end
    end
    initial begin
        $dumpfile("test.vcd");
        $dumpvars(0, testbench_tb);
        $display("Test testbench");
        A[0] = 3'd0;
        A[1] = 3'd1;
        A[2] = 3'd2;
        A[3] = 3'd3;
        A[4] = 3'd4;
        A[5] = 3'd5;
        A[6] = 3'd6;
        A[7] = 3'd7;
        #10;
        $display("Bit reversal module");
        for (i = 0; i < 8; i = i + 1) begin
            $display("%b %b", A[i], B[i]);
        end
        $display("Add-Sub");
        for (i = 0; i < 8; i = i + 1) begin
            $display("%b + %b j : %b + %b j", B_new_real[i], B_new_imag[i], out_real[i], out_imag[i]);
        end
    end
    
endmodule
