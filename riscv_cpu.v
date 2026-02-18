module riscv_cpu (
    input         clk,reset,
    output [31:0] PC,
    input  [31:0] Instr, 
    output        MemWrite,
    output [31:0] Mem_WrAddr, Mem_WrData,
    input  [31:0] ReadData, 
    output [31:0]Result,
    output [2:0]funct3
);

wire       ALUSrc, RegWrite, Zero, ALUR31, ALUR0;
wire       PCSrc, Jalr, Jump, Op5;
wire [1:0] ResultSrc, ImmSrc, Store;
wire [3:0] ALUControl;
wire [2:0] Load;

controller  c  (Instr[6:0], Instr[14:12], Instr[30], Zero,ALUR31,
                ResultSrc, MemWrite, PCSrc,ALUSrc, RegWrite,Jump,Jalr,ImmSrc,
                ALUControl,Branch);

datapath    dp (clk, reset, ResultSrc, PCSrc, ALUSrc, RegWrite,
                 ImmSrc,ALUControl,Jalr, Zero,ALUR31, PC,
                Instr,Mem_WrAddr, Mem_WrData, ReadData,Result);

endmodule
