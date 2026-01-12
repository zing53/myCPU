`include "mycpu.h"
`default_nettype wire
// 根据mycpu_top.v得知mem输入输出定义                
module mem_stage(
    input clk,
    input reset,
    //allowin
    input ws_allowin,
    output ms_allowin,
    //from es
    input es_to_ms_valid,
    input [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus,
    //to ws
    output ms_to_ws_valid,
    output [`MS_TO_WS_BUS_WD -1:0] ms_to_ws_bus,
    //from data-sram 读出内存中的数据
    input [31:0] data_sram_rdata
);

// 对于数据有效性，是否允许读入的一些设计
reg ms_valid;
wire ms_ready_go;
reg  [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus_r;
wire [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus;
assign ms_ready_go    = 1'b1;
assign ms_allowin     = !ms_valid || ms_ready_go && ws_allowin;
assign ms_to_ws_valid = ms_valid && ms_ready_go;

// 当允许读入时，读入es到ms的总线
always @(posedge clk) begin
    if (reset) begin     
        ms_valid <= 1'b0;
    end
    else if (ms_allowin) begin 
        ms_valid <= es_to_ms_valid;

    end 
    if (es_to_ms_valid && ms_allowin) begin
        es_to_ms_bus_r <= es_to_ms_bus;
    end
end

// 读es到ms的总线缓冲
wire        gr_we;
wire        load_op;
wire [31:0] alu_result ;
wire [31:0] ds_pc;
wire [4: 0] dest;
assign {gr_we,
load_op,
alu_result,
ds_pc,
dest
} = es_to_ms_bus_r;

// 设置mem到ws的总线
wire [31:0] mem_result;
wire [31:0] final_result;
assign mem_result   = data_sram_rdata;
// 判断是否是内存中的数据
assign final_result = load_op ? mem_result : alu_result;
assign ms_to_ws_bus = { gr_we,  //69:69
        dest,  //68:64
        final_result,  //63:32
        ds_pc             //31:0
       };

endmodule