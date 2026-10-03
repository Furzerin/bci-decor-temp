module lnnt
#(
        parameter CH_NUM = 16,
        parameter CH_TAPS = 4,
        parameter WB_WIDTH = 12
)
(
        input in_active, 
        input in_valid,
        input signed [8:0] in_data,
        input sel,
        input sys_clk,
        input sys_rst,

        input signed [WB_WIDTH-1:0] in_wt_0,
        input signed [WB_WIDTH-1:0] in_wt_1,
        input signed [WB_WIDTH-1:0] in_wt_2,
        input signed [WB_WIDTH-1:0] in_wt_3,
        input signed [WB_WIDTH-1:0] in_bs,

        output reg out_lnn_valid,
        output reg signed [8:0] out_lnn_data
        
);

integer cnt = 0;
reg signed [8:0] buffer_0;
reg signed [8:0] buffer_1;
reg signed [8:0] buffer_2;
reg signed [8:0] buffer_3;

wire signed [20:0] temp_d;
reg signed [8:0] pre_d;
reg valid_temp;

assign temp_d = buffer_0 * in_wt_0 + buffer_1 * in_wt_1 + buffer_2 * in_wt_2 + buffer_3 * in_wt_3 + in_bs;

always @(posedge sys_clk or negedge sys_rst) begin
        if (sys_rst==0) begin
                pre_d <= 9'b0;
                //temp_d <= 21'b0;
                valid_temp <= 1'b0;
                cnt <= 0;
                out_lnn_data <= 9'b0;
                out_lnn_valid <= 1'b0;
                buffer_0 <= 9'b0;
                buffer_1 <= 9'b0;
                buffer_2 <= 9'b0;
                buffer_3 <= 9'b0;
        end
        else begin
                if (in_active && in_valid && sel) begin
                        if (cnt < 1) begin
                                pre_d <= 'b0; // invalid
                                valid_temp <= 1'b0;
                        end
                        else if (cnt < 2) begin
                                pre_d <= buffer_0; // dpcm1
                                valid_temp <= 1'b1;
                        end
                        else if (cnt < 4) begin
                                pre_d <= buffer_0 + (buffer_0 - buffer_1); // dpcm2
                                valid_temp <= 1'b1;
                        end
                        else begin
                                pre_d <= {temp_d[20],temp_d[16:9]};
                                valid_temp <= 1'b1;
                        end
                        out_lnn_data <= pre_d - buffer_0; // a reg here, making the output delay for 1 time cyle
                        out_lnn_valid <= valid_temp; // extra reg to synchronize the data & valid signals
                        buffer_3 <= buffer_2;
                        buffer_2 <= buffer_1;
                        buffer_1 <= buffer_0;
                        buffer_0 <= in_data;
                        cnt <= cnt + 1;
                end
                //else begin
                //        // out_lnn_data <= 9'b0;
                //        valid_temp <= 1'b0;
                //        out_lnn_valid <= valid_temp;
                //end
        end
end

endmodule