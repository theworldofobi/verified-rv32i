package rv32i_pkg;

  // --- OPCODES: inst[6:0]
  localparam logic [6:0] OP_LUI    = 7'b011_0111;
  localparam logic [6:0] OP_AUIPC  = 7'b001_0111;
  localparam logic [6:0] OP_JAL    = 7'b110_1111;
  localparam logic [6:0] OP_JALR   = 7'b110_0111;
  localparam logic [6:0] OP_BRANCH = 7'b110_0011;
  localparam logic [6:0] OP_LOAD   = 7'b000_0011;
  localparam logic [6:0] OP_STORE  = 7'b010_0011;
  localparam logic [6:0] OP_IMM    = 7'b001_0011;
  localparam logic [6:0] OP_REG    = 7'b011_0011;
  localparam logic [6:0] OP_FENCE  = 7'b000_1111;
  localparam logic [6:0] OP_SYSTEM = 7'b111_0011;

  // --- no op instruction
  localparam logic [31:0] NOP_INST = 32'h0000_0013;

  // --- func3 encoding
  // branches
  localparam logic [2:0] F3_BEQ  = 3'b000;
  localparam logic [2:0] F3_BNE  = 3'b001;
  localparam logic [2:0] F3_BLT  = 3'b100;
  localparam logic [2:0] F3_BGE  = 3'b101;
  localparam logic [2:0] F3_BLTU = 3'b110;
  localparam logic [2:0] F3_BGEU = 3'b111;
  // loads / stores
  localparam logic [2:0] F3_B    = 3'b000;
  localparam logic [2:0] F3_H    = 3'b001;
  localparam logic [2:0] F3_W    = 3'b010;
  localparam logic [2:0] F3_BU   = 3'b100;
  localparam logic [2:0] F3_HU   = 3'b101;

  // --- CONTROL ENCODINGS
  typedef enum logic [3:0] {
    ALU_ADD, ALU_SUB, ALU_SLL, ALU_SLT, ALU_SLTU,
    ALU_XOR, ALU_SRL, ALU_SRA, ALU_OR,  ALU_AND
  } alu_op_e;

  typedef enum logic [1:0] { SRCA_RS1, SRCA_PC, SRCA_ZERO }      src_a_e;
  typedef enum logic       { SRCB_RS2, SRCB_IMM }                src_b_e;
  typedef enum logic [2:0] { IMM_I, IMM_S, IMM_B, IMM_U, IMM_J } imm_sel_e;
  typedef enum logic [1:0] { WB_ALU, WB_MEM, WB_PC4 }            wb_sel_e;

  typedef struct packed {
    logic     reg_write;  // writes rd
    logic     mem_read;   // load
    logic     mem_write;  // store
    logic     branch;     // conditional branch
    logic     jal;
    logic     jalr;
    logic     uses_rs1;   // reads rs1 (for hazard detection)
    logic     uses_rs2;   // reads rs2 (for hazard detection)
    alu_op_e  alu_op;
    src_a_e   src_a;
    src_b_e   src_b;
    imm_sel_e imm_sel;
    wb_sel_e  wb_sel;
    logic     halt;       // ecall / ebreak: stop simulation when retired
    logic     illegal;    // for invalid RV32I encoding
  } ctrl_t;

  localparam ctrl_t CTRL_NOP = '{
    reg_write: 1'b0, 
    mem_read: 1'b0, 
    mem_write: 1'b0, 
    branch: 1'b0,
    jal: 1'b0, 
    jalr: 1'b0, 
    uses_rs1: 1'b0, 
    uses_rs2: 1'b0,
    alu_op: ALU_ADD, 
    src_a: SRCA_RS1, 
    src_b: SRCB_IMM, 
    imm_sel: IMM_I,
    wb_sel: WB_ALU, 
    halt: 1'b0, 
    illegal: 1'b0
  };

  typedef struct packed {
    logic        valid;
    logic [31:0] pc;
    logic [31:0] insn;
    logic [31:0] pc_next;    // architectural next PC
    logic [4:0]  rd;         // 0 if the instruction writes no register
    logic [31:0] rd_wdata;   // 0 if rd == 0
    logic        mem_we;
    logic [31:0] mem_addr;   // word-aligned byte address
    logic [3:0]  mem_wstrb;
    logic [31:0] mem_wdata;  // lanes outside wstrb are zeroed
    logic        halt;       // ecall / ebreak
    logic        trap;       // illegal instruction
  } retire_t;


endpackage : rv32i_pkg
