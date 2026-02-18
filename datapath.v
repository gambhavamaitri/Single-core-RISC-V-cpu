// datapath.v - Corrected with x0 Write Prevention
module datapath (
    input clk, reset,
    input [1:0] ResultSrc,
    input PCSrc, ALUSrc,
    input RegWrite,
    input [1:0] ImmSrc,
    input [3:0] ALUControl,
    input Jalr,
    output Zero, ALUR31,
    output [31:0] PC,
    input [31:0] Instr,
    output [31:0] Mem_WrAddr, Mem_WrData,
    input [31:0] ReadData,
    output [31:0] Result
);

wire [31:0] PCNext, PCJalr, PCPlus4, PCTarget, AuiPC, lAuiPC;
wire [31:0] ImmExt, SrcA, SrcB, WriteData, ALUResult;
// NEW WIRE: The JALR target address must have its LSB cleared (bit 0)
wire [31:0] ALUResult_Jalr; 

wire FinalRegWrite = RegWrite & (Instr[11:7] != 5'b00000); 

// next PC logic
mux2 #(32) pcmux(PCPlus4, PCTarget, PCSrc, PCNext);
// Use ALUResult_Jalr for the JALR target
mux2 #(32) jalrmux(PCNext, ALUResult_Jalr, Jalr, PCJalr); 
reset_ff #(32) pcreg(clk, reset, PCJalr, PC);

adder pcadd4(PC, 32'd4, PCPlus4);
adder pcaddbranch(PC, ImmExt, PCTarget);

// register file logic
reg_file rf (clk, FinalRegWrite, Instr[19:15], Instr[24:20], Instr[11:7], Result, SrcA, WriteData); 
imm_extend ext (Instr[31:7], ImmSrc, ImmExt);

// ALU logic
mux2 #(32) srcbmux(WriteData, ImmExt, ALUSrc, SrcB);
alu alu (SrcA, SrcB, ALUControl, ALUResult, Zero);

// JALR TARGET ALIGNMENT FIX: Clear the LSB of ALUResult (This line was already correct in your code)
assign ALUResult_Jalr = {ALUResult[31:1], 1'b0};

// AUIPC/LUI logic
adder #(32) auipcadder({Instr[31:12],12'b0},PC,AuiPC);
mux2 #(32) lauipcmux(AuiPC,{Instr[31:12],12'b0}, Instr[5],lAuiPC);

// Result Mux (ALUResult, ReadData, PCPlus4, lAuiPC)
mux4 #(32) resultmux(ALUResult, ReadData, PCPlus4, lAuiPC, ResultSrc, Result);

assign Mem_WrData = WriteData;
assign Mem_WrAddr = ALUResult;
assign ALUR31 = ($signed(SrcA) < $signed(SrcB));

endmodule
