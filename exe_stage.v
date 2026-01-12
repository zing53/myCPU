`include "mycpu.h"
`default_nettype wire
// 根据mycpu_top.v得知exe输入输出定义
module exe_stage(
    input clk,
    input reset,
    // allowin 允许输入
    input ms_allowin,
    output es_allowin,
    // from ds ds 数据的有效性，ds到es的总线
    input ds_to_es_valid,
    input [`DS_TO_ES_BUS_WD -1:0] ds_to_es_bus,
    // to ms es 数据的有效性，es到ms的总线
    output es_to_ms_valid,
    output [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus,
    // data sram interface
    output        data_sram_en,
    output [ 3:0] data_sram_wen,
    output [31:0] data_sram_addr,
    output [31:0] data_sram_wdata
);

// 对于数据有效性，是否允许读入的一些设计
reg es_valid;
wire es_ready_go;
reg  [`DS_TO_ES_BUS_WD -1:0] ds_to_es_bus_r;
wire [`DS_TO_ES_BUS_WD -1:0] ds_to_es_bus;
assign es_ready_go    = 1'b1;
assign es_allowin     = !es_valid || es_ready_go && ms_allowin;
assign es_to_ms_valid = es_valid && es_ready_go;

// 当允许读入时，读入ds到es的总线
always @(posedge clk) begin
    if (reset) begin     
        es_valid <= 1'b0;
    end
    else if (es_allowin) begin 
        es_valid <= ds_to_es_valid;

    end 
    if (ds_to_es_valid && es_allowin) begin
        ds_to_es_bus_r <= ds_to_es_bus;
    end
end

// 定义es到ms的总线，71条线的规定来自mycpu.h，根据es与ms的其他设计反推出这些线是什么
assign es_to_ms_bus = {
gr_we,
load_op,
alu_result,
ds_pc,
dest
};// 71 lines

// 定义好总线传输的相关变量
wire [11:0] alu_op;
wire        load_op;
wire        src1_is_pc;
wire        src2_is_imm;
wire        gr_we;
wire        mem_we;
wire [4: 0] dest;
wire [31:0] rj_value;
wire [31:0] rkd_value;
wire [31:0] ds_imm;
wire [31:0] ds_pc;

// 将ds到es总线上的缓冲数据具体地读出
assign                {alu_op      ,  //149:138
                       load_op     ,  //137:137
                       src1_is_pc  ,  //136:136
                       src2_is_imm ,  //135:135
                       gr_we       ,  //134:134
                       mem_we      ,  //133:133
                       dest        ,  //132:128
                       ds_imm      ,  //127:96
                       rj_value    ,  //95 :64
                       rkd_value   ,  //63 :32
                       ds_pc          //31 :0
                      } = ds_to_es_bus_r;


// 32-bit adder
// 定义好alu相关变量
wire [31:0] adder_a;
wire [31:0] adder_b;
wire        adder_cin;
wire [31:0] adder_result;
wire        adder_cout;

wire [31:0] alu_src1   ;
wire [31:0] alu_src2   ;
wire [31:0] alu_result ;

assign alu_src1 = src1_is_pc  ? ds_pc[31:0] : rj_value;
assign alu_src2 = src2_is_imm ? ds_imm : rkd_value;

// 实例化alu，传入数据和操作进行运算
alu alu(
  .alu_op (alu_op),
  .alu_src1 (alu_src1),
  .alu_src2 (alu_src2),
  .alu_result (alu_result)
);
// 与内存相关的读写
// 这里本来想使用load_op确定读使能，但是因为是单周期的来不及读出数据，所以改为置1
// assign data_sram_en = load_op;
assign data_sram_en = 1;
assign data_sram_wen    = {4{mem_we}};
assign data_sram_addr  = alu_result;
assign data_sram_wdata = rkd_value;

endmodule