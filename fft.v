`timescale 1 ns / 1 ps

`define WIDTH 1024
`define SIZE 10
`define HALF_WIDTH (`WIDTH / 2)

`define DATA_WIDTH 32
`define TWIDDLE_WIDTH 16

`define OUT_WIDTH (`DATA_WIDTH + `TWIDDLE_WIDTH - 1 + `SIZE)


module twiddle_factors(output logic signed[15:0]twiddle_real[`HALF_WIDTH-1:0], 
                        output logic signed[15:0]twiddle_imag[`HALF_WIDTH-1:0]);
    initial begin
        $readmemh("data/fft/twiddles_real.hex", twiddle_real);
        $readmemh("data/fft/twiddles_imag.hex", twiddle_imag); 
    end

endmodule

module bit_reversal(
    input [`DATA_WIDTH-1:0] in[`WIDTH-1:0],
    output reg [`DATA_WIDTH-1:0] out[`WIDTH-1:0]
);
    integer i, j;
    reg [`SIZE-1:0] reversed_bits;
    always_comb begin
        for (i = 0; i < `WIDTH; i = i + 1) begin
            for (j = 0; j < `SIZE; j = j + 1)
                reversed_bits[j] = i[`SIZE-1-j];
            out[i] = in[reversed_bits];
        end
    end
endmodule

module add_sub(
    input signed [`OUT_WIDTH-1:0] in_real[`WIDTH-1:0],
    input signed [`OUT_WIDTH-1:0] in_imag[`WIDTH-1:0],
    output reg signed [`OUT_WIDTH-1:0] out_real[`WIDTH-1:0],
    output reg signed [`OUT_WIDTH-1:0] out_imag[`WIDTH-1:0],
    output reg done
);
    logic signed[`TWIDDLE_WIDTH - 1:0] twiddle_real[`HALF_WIDTH-1:0];
    logic signed[`TWIDDLE_WIDTH - 1:0] twiddle_imag[`HALF_WIDTH-1:0];

    twiddle_factors uut(twiddle_real, twiddle_imag);

    integer i, j, k, jump, num;

    reg signed [`OUT_WIDTH-1:0] inter1_real[`WIDTH-1:0];
    reg signed [`OUT_WIDTH-1:0] inter1_imag[`WIDTH-1:0];
    reg signed [`OUT_WIDTH-1:0] inter2_real[`WIDTH-1:0];
    reg signed [`OUT_WIDTH-1:0] inter2_imag[`WIDTH-1:0];

    task complex_multiply;

        input logic signed [`TWIDDLE_WIDTH - 1:0] mul1_real;
        input logic signed [`TWIDDLE_WIDTH - 1:0] mul1_imag;
        input logic signed [`OUT_WIDTH - 1:0] mul2_real;
        input logic signed [`OUT_WIDTH - 1:0] mul2_imag;
        output reg signed [`OUT_WIDTH - 1:0] out_real;
        output reg signed [`OUT_WIDTH - 1:0] out_imag;

        logic signed [`OUT_WIDTH + `TWIDDLE_WIDTH:0] prod_rr, prod_ii, prod_ri, prod_ir;
        logic signed [`OUT_WIDTH + `TWIDDLE_WIDTH:0] temp_real;
        logic signed [`OUT_WIDTH + `TWIDDLE_WIDTH:0] temp_imag;
        logic signed [`OUT_WIDTH + `TWIDDLE_WIDTH:0] round_val;

        begin

            round_val = 1 << (`TWIDDLE_WIDTH - 2);

            prod_rr = $signed(mul1_real) * $signed(mul2_real);
            prod_ii = $signed(mul1_imag) * $signed(mul2_imag);
            prod_ri = $signed(mul1_real) * $signed(mul2_imag);
            prod_ir = $signed(mul1_imag) * $signed(mul2_real);

            temp_real = prod_rr - prod_ii;
            temp_imag = prod_ri + prod_ir;

            out_real = (temp_real + round_val) >>> (`TWIDDLE_WIDTH - 1);
            out_imag = (temp_imag + round_val) >>> (`TWIDDLE_WIDTH - 1);

        end
    endtask

    always_comb begin
        done = 1'b0;
        for (i = 0; i < `SIZE; i = i + 1) begin
            num = 1 << i;
            k = 0;
            jump = `HALF_WIDTH/num;

            for (j = 0; j < `WIDTH; j = j + 1) begin
                if (i != 0) begin 
                    if ((j & num) != 0) begin
                        k = (j % num) * jump;
                        if (i % 2 != 0) begin
                            complex_multiply(twiddle_real[k], twiddle_imag[k], inter1_real[j], inter1_imag[j], inter1_real[j], inter1_imag[j]);
                        end 
                        else begin
                            complex_multiply(twiddle_real[k], twiddle_imag[k], inter2_real[j], inter2_imag[j], inter2_real[j], inter2_imag[j]);
                        end
                    end
                end
            end

            for (j = 0; j < `WIDTH; j = j + 1) begin
                if (i == 0) begin
                    if ((j & num) == 0) begin
                        inter1_real[j] = in_real[j] + in_real[j + 1];
                        inter1_imag[j] = in_imag[j] + in_imag[j + 1];
                    end
                    else begin
                        inter1_real[j] = in_real[j - 1] - in_real[j];
                        inter1_imag[j] = in_imag[j - 1] - in_imag[j];
                    end
                end
                else begin
                    if (i % 2 != 0) begin
                        if ((j & num) == 0) begin
                            inter2_real[j] = inter1_real[j] + inter1_real[j + num];
                            inter2_imag[j] = inter1_imag[j] + inter1_imag[j + num];
                        end
                        else begin
                            inter2_real[j] = inter1_real[j - num] - inter1_real[j];
                            inter2_imag[j] = inter1_imag[j - num] - inter1_imag[j];
                        end
                    end
                    else
                        if ((j & num) == 0) begin
                            inter1_real[j] = inter2_real[j] + inter2_real[j + num];
                            inter1_imag[j] = inter2_imag[j] + inter2_imag[j + num];
                        end
                        else begin
                            inter1_real[j] = inter2_real[j - num] - inter2_real[j];
                            inter1_imag[j] = inter2_imag[j - num] - inter2_imag[j];
                        end
                end
            end
        end
        for (i = 0; i < `WIDTH; i = i + 1) begin
            if (`SIZE % 2 == 0) begin
                out_real[i] = inter2_real[i];
                out_imag[i] = inter2_imag[i];
            end else begin
                out_real[i] = inter1_real[i];
                out_imag[i] = inter1_imag[i];
            end
        end
        done = 1'b1;
    end
endmodule