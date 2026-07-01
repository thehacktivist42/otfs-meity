`timescale 1 ns / 1 ps

`include "memory_bank.v"

module memory_bank_array #(
    parameter IN_WIDTH = 36,
    parameter NUM_BANKS = 32, // the M in the M x N representation of the transform (number of banks)
    parameter BANK_DEPTH = 32 // the N in the M x N representation of the transform (depth of each bank)
)(
    // Control signals
    input logic clk,

    // Data inputs
    input logic signed [IN_WIDTH - 1:0] in_real,
    input logic signed [IN_WIDTH - 1:0] in_imag,

    // Write interface
    input logic [NUM_BANKS - 1:0] bank_we, // One-hot write enable (column)
    input logic [$clog2(BANK_DEPTH) - 1:0] bank_waddr, // Shared write address for all banks (row)

    // Read interface
    input logic [$clog2(NUM_BANKS) - 1:0] bank_select, // The selection signal received from the scheduler
    input logic [$clog2(BANK_DEPTH) - 1:0] bank_raddr, // The address to be accessed within the selected bank; received from scheduler
    input logic [NUM_BANKS-1:0] bank_re, // The one-hot read-enable signal received from the scheduler

    // Data outputs
    output logic signed [IN_WIDTH - 1:0] out_real,
    output logic signed [IN_WIDTH - 1:0] out_imag

);
    // Internal arrays to capture outputs from all instantiated memory banks
    logic signed [IN_WIDTH - 1:0] mem_out_real [0:NUM_BANKS - 1];
    logic signed [IN_WIDTH - 1:0] mem_out_imag [0:NUM_BANKS - 1];

    /*
    The memory_bank module has a read latency of 1 clock cycle. 
    Hence, the select signal is pipelined in order to align it with the delayed output data.
    */

    logic [$clog2(NUM_BANKS) - 1:0] bank_select_reg;
    always_ff @(posedge clk) begin
        bank_select_reg <= bank_select;
    end

    // Instantiate NUM_BANKS banks
    genvar i;
    generate
        for (i = 0; i < NUM_BANKS; i++) begin: gen_banks
            memory_bank #(
                .IN_WIDTH(IN_WIDTH),
                .BANK_DEPTH(BANK_DEPTH)
            ) bank_inst (
                .clk(clk),
                .in_real(in_real),
                .in_imag(in_imag),
                .we(bank_we[i]),
                .waddr(bank_waddr),
                .re(bank_re[i]), // Gated read-enable: only active if this specific bank is selected
                .raddr(bank_raddr),
                .out_real(mem_out_real[i]),
                .out_imag(mem_out_imag[i])
            );
        end
    endgenerate

    // Multiplex the final output based on the select signal (which is delayed)
    assign out_real = mem_out_real[bank_select_reg];
    assign out_imag = mem_out_imag[bank_select_reg];

endmodule