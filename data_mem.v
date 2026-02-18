module data_mem #(parameter DATA_WIDTH = 32, ADDR_WIDTH = 32, MEM_SIZE = 64) (
    input clk,
    input wr_en,
    input [2:0] funct3,
    input [ADDR_WIDTH-1:0] wr_addr,
    input [DATA_WIDTH-1:0] wr_data,
    output reg [DATA_WIDTH-1:0] rd_data_mem
);

    // memory
    reg [DATA_WIDTH-1:0] data_ram [0:MEM_SIZE-1];

    // compute word index (MEM_SIZE assumed power-of-two or ok with modulus)
    localparam WA = $clog2(MEM_SIZE);
    wire [ADDR_WIDTH-1:0] addr_word = wr_addr[ADDR_WIDTH-1:2];
    wire [WA-1:0] word_addr = addr_word % MEM_SIZE;
    wire [1:0] byte_offset = wr_addr[1:0];

    // synchronous writes - use non-blocking
    always @(posedge clk) begin
        if (wr_en) begin
            case (funct3)
                3'b000: begin // SB: store byte (low 8 bits)
                    case (byte_offset)
                        2'b00: data_ram[word_addr][7:0]   <= wr_data[7:0];
                        2'b01: data_ram[word_addr][15:8]  <= wr_data[7:0];
                        2'b10: data_ram[word_addr][23:16] <= wr_data[7:0];
                        2'b11: data_ram[word_addr][31:24] <= wr_data[7:0];
                    endcase
                end

                3'b001: begin // SH: store halfword (low 16 bits)
                    if (byte_offset[1] == 1'b0)
                        data_ram[word_addr][15:0]  <= wr_data[15:0];
                    else
                        data_ram[word_addr][31:16] <= wr_data[15:0];
                end

                3'b010: begin // SW: store word
                    data_ram[word_addr] <= wr_data;
                end

                default: ; // no write for load opcodes
            endcase
        end
    end

    // combinational read
    always @(*) begin
        rd_data_mem = 32'b0;
        // Typically read behavior is independent of wr_en; testbenches expect rd when not writing.
        // If you want write-first semantics you'd need to handle wr_en case explicitly.
        case (funct3)
            3'b000: begin // LB (signed byte)
                case (byte_offset)
                    2'b00: rd_data_mem = {{24{data_ram[word_addr][7]}},  data_ram[word_addr][7:0]};
                    2'b01: rd_data_mem = {{24{data_ram[word_addr][15]}}, data_ram[word_addr][15:8]};
                    2'b10: rd_data_mem = {{24{data_ram[word_addr][23]}}, data_ram[word_addr][23:16]};
                    2'b11: rd_data_mem = {{24{data_ram[word_addr][31]}}, data_ram[word_addr][31:24]};
                endcase
            end

            3'b001: begin // LH (signed half)
                if (byte_offset[1] == 1'b0)
                    rd_data_mem = {{16{data_ram[word_addr][15]}}, data_ram[word_addr][15:0]};
                else
                    rd_data_mem = {{16{data_ram[word_addr][31]}}, data_ram[word_addr][31:16]};
            end

            3'b010: begin // LW
                rd_data_mem = data_ram[word_addr];
            end

            3'b100: begin // LBU (unsigned byte)
                case (byte_offset)
                    2'b00: rd_data_mem = {24'b0, data_ram[word_addr][7:0]};
                    2'b01: rd_data_mem = {24'b0, data_ram[word_addr][15:8]};
                    2'b10: rd_data_mem = {24'b0, data_ram[word_addr][23:16]};
                    2'b11: rd_data_mem = {24'b0, data_ram[word_addr][31:24]};
                endcase
            end

            3'b101: begin // LHU (unsigned half)
                if (byte_offset[1] == 1'b0)
                    rd_data_mem = {16'b0, data_ram[word_addr][15:0]};
                else
                    rd_data_mem = {16'b0, data_ram[word_addr][31:16]};
            end

            default: rd_data_mem = 32'b0;
        endcase
    end

endmodule
