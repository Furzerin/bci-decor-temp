module lnnt_decor
#(
        parameter NUM_CH = 16,
        parameter NUM_TAPS = 4,
        parameter NUM_WIDTH = 12
)
(
        input sys_clk,
        input sys_rst,
        input data_valid,

        input [5:0] index,
        input signed [8:0] input_data,
        input [NUM_CH-1:0] input_active,

        input signed [NUM_WIDTH-1:0] weights_ch0_taps0,
        input signed [NUM_WIDTH-1:0] weights_ch0_taps1,
        input signed [NUM_WIDTH-1:0] weights_ch0_taps2,
        input signed [NUM_WIDTH-1:0] weights_ch0_taps3,
        input signed [NUM_WIDTH-1:0] bias_ch0,
        input signed [NUM_WIDTH-1:0] weights_ch1_taps0,
        input signed [NUM_WIDTH-1:0] weights_ch1_taps1,
        input signed [NUM_WIDTH-1:0] weights_ch1_taps2,
        input signed [NUM_WIDTH-1:0] weights_ch1_taps3,
        input signed [NUM_WIDTH-1:0] bias_ch1,
        input signed [NUM_WIDTH-1:0] weights_ch2_taps0,
        input signed [NUM_WIDTH-1:0] weights_ch2_taps1,
        input signed [NUM_WIDTH-1:0] weights_ch2_taps2,
        input signed [NUM_WIDTH-1:0] weights_ch2_taps3,
        input signed [NUM_WIDTH-1:0] bias_ch2,
        input signed [NUM_WIDTH-1:0] weights_ch3_taps0,
        input signed [NUM_WIDTH-1:0] weights_ch3_taps1,
        input signed [NUM_WIDTH-1:0] weights_ch3_taps2,
        input signed [NUM_WIDTH-1:0] weights_ch3_taps3,
        input signed [NUM_WIDTH-1:0] bias_ch3,
        input signed [NUM_WIDTH-1:0] weights_ch4_taps0,
        input signed [NUM_WIDTH-1:0] weights_ch4_taps1,
        input signed [NUM_WIDTH-1:0] weights_ch4_taps2,
        input signed [NUM_WIDTH-1:0] weights_ch4_taps3,
        input signed [NUM_WIDTH-1:0] bias_ch4,
        input signed [NUM_WIDTH-1:0] weights_ch5_taps0,
        input signed [NUM_WIDTH-1:0] weights_ch5_taps1,
        input signed [NUM_WIDTH-1:0] weights_ch5_taps2,
        input signed [NUM_WIDTH-1:0] weights_ch5_taps3,
        input signed [NUM_WIDTH-1:0] bias_ch5,
        input signed [NUM_WIDTH-1:0] weights_ch6_taps0,
        input signed [NUM_WIDTH-1:0] weights_ch6_taps1,
        input signed [NUM_WIDTH-1:0] weights_ch6_taps2,
        input signed [NUM_WIDTH-1:0] weights_ch6_taps3,
        input signed [NUM_WIDTH-1:0] bias_ch6,
        input signed [NUM_WIDTH-1:0] weights_ch7_taps0,
        input signed [NUM_WIDTH-1:0] weights_ch7_taps1,
        input signed [NUM_WIDTH-1:0] weights_ch7_taps2,
        input signed [NUM_WIDTH-1:0] weights_ch7_taps3,
        input signed [NUM_WIDTH-1:0] bias_ch7,
        input signed [NUM_WIDTH-1:0] weights_ch8_taps0,
        input signed [NUM_WIDTH-1:0] weights_ch8_taps1,
        input signed [NUM_WIDTH-1:0] weights_ch8_taps2,
        input signed [NUM_WIDTH-1:0] weights_ch8_taps3,
        input signed [NUM_WIDTH-1:0] bias_ch8,
        input signed [NUM_WIDTH-1:0] weights_ch9_taps0,
        input signed [NUM_WIDTH-1:0] weights_ch9_taps1,
        input signed [NUM_WIDTH-1:0] weights_ch9_taps2,
        input signed [NUM_WIDTH-1:0] weights_ch9_taps3,
        input signed [NUM_WIDTH-1:0] bias_ch9,
        input signed [NUM_WIDTH-1:0] weights_ch10_taps0,
        input signed [NUM_WIDTH-1:0] weights_ch10_taps1,
        input signed [NUM_WIDTH-1:0] weights_ch10_taps2,
        input signed [NUM_WIDTH-1:0] weights_ch10_taps3,
        input signed [NUM_WIDTH-1:0] bias_ch10,
        input signed [NUM_WIDTH-1:0] weights_ch11_taps0,
        input signed [NUM_WIDTH-1:0] weights_ch11_taps1,
        input signed [NUM_WIDTH-1:0] weights_ch11_taps2,
        input signed [NUM_WIDTH-1:0] weights_ch11_taps3,
        input signed [NUM_WIDTH-1:0] bias_ch11,
        input signed [NUM_WIDTH-1:0] weights_ch12_taps0,
        input signed [NUM_WIDTH-1:0] weights_ch12_taps1,
        input signed [NUM_WIDTH-1:0] weights_ch12_taps2,
        input signed [NUM_WIDTH-1:0] weights_ch12_taps3,
        input signed [NUM_WIDTH-1:0] bias_ch12,
        input signed [NUM_WIDTH-1:0] weights_ch13_taps0,
        input signed [NUM_WIDTH-1:0] weights_ch13_taps1,
        input signed [NUM_WIDTH-1:0] weights_ch13_taps2,
        input signed [NUM_WIDTH-1:0] weights_ch13_taps3,
        input signed [NUM_WIDTH-1:0] bias_ch13,
        input signed [NUM_WIDTH-1:0] weights_ch14_taps0,
        input signed [NUM_WIDTH-1:0] weights_ch14_taps1,
        input signed [NUM_WIDTH-1:0] weights_ch14_taps2,
        input signed [NUM_WIDTH-1:0] weights_ch14_taps3,
        input signed [NUM_WIDTH-1:0] bias_ch14,
        input signed [NUM_WIDTH-1:0] weights_ch15_taps0,
        input signed [NUM_WIDTH-1:0] weights_ch15_taps1,
        input signed [NUM_WIDTH-1:0] weights_ch15_taps2,
        input signed [NUM_WIDTH-1:0] weights_ch15_taps3,
        input signed [NUM_WIDTH-1:0] bias_ch15,

        input [5:0] list_ch_0,
        input [5:0] list_ch_1,
        input [5:0] list_ch_2,
        input [5:0] list_ch_3,
        input [5:0] list_ch_4,
        input [5:0] list_ch_5,
        input [5:0] list_ch_6,
        input [5:0] list_ch_7,
        input [5:0] list_ch_8,
        input [5:0] list_ch_9,
        input [5:0] list_ch_10,
        input [5:0] list_ch_11,
        input [5:0] list_ch_12,
        input [5:0] list_ch_13,
        input [5:0] list_ch_14,
        input [5:0] list_ch_15,

        output reg signed [8:0] output_result,
        output reg output_valid,
        output reg [$clog2(NUM_CH)-1:0] output_index
);

// input transform
reg signed [NUM_WIDTH-1:0] in_wt [0:NUM_CH-1][0:NUM_TAPS-1];
reg signed [NUM_WIDTH-1:0] in_bs [0:NUM_CH-1];
reg [5:0] list_ch [0:NUM_CH-1];
integer ch, tap;
always @(posedge sys_clk or negedge sys_rst) begin
        if (sys_rst==0) begin
                for (ch=0;ch<NUM_CH;ch=ch+1) begin
                        for (tap=0;tap<NUM_TAPS;tap=tap+1)
                                in_wt[ch][tap] <= 12'b0;
                        in_bs[ch] <= 12'b0;
                end
        end
        else begin
                for (ch=0;ch<NUM_CH;ch=ch+1) begin
                        for (tap=0;tap<NUM_TAPS;tap=tap+1) begin
                                case(ch)
                                        0: begin 
                                                in_wt[ch][tap] <= (tap==0) ? weights_ch0_taps0 :
                                                                  (tap==1) ? weights_ch0_taps1 :
                                                                  (tap==2) ? weights_ch0_taps2 :
                                                                  (tap==3) ? weights_ch0_taps3 : 12'b0;
                                                in_bs[ch] <= bias_ch0;
                                                list_ch[ch] <= list_ch_0;
                                        end
                                        1: begin 
                                                in_wt[ch][tap] <= (tap==0) ? weights_ch1_taps0 :
                                                                  (tap==1) ? weights_ch1_taps1 :
                                                                  (tap==2) ? weights_ch1_taps2 :
                                                                  (tap==3) ? weights_ch1_taps3 : 12'b0;
                                                in_bs[ch] <= bias_ch1;
                                                list_ch[ch] <= list_ch_1;
                                        end
                                        2: begin 
                                                in_wt[ch][tap] <= (tap==0) ? weights_ch2_taps0 :
                                                                  (tap==1) ? weights_ch2_taps1 :
                                                                  (tap==2) ? weights_ch2_taps2 :
                                                                  (tap==3) ? weights_ch2_taps3 : 12'b0;
                                                in_bs[ch] <= bias_ch2;
                                                list_ch[ch] <= list_ch_2;
                                        end
                                        3: begin 
                                                in_wt[ch][tap] <= (tap==0) ? weights_ch3_taps0 :
                                                                  (tap==1) ? weights_ch3_taps1 :
                                                                  (tap==2) ? weights_ch3_taps2 :
                                                                  (tap==3) ? weights_ch3_taps3 : 12'b0;
                                                in_bs[ch] <= bias_ch3;
                                                list_ch[ch] <= list_ch_3;
                                        end
                                        4: begin 
                                                in_wt[ch][tap] <= (tap==0) ? weights_ch4_taps0 :
                                                                  (tap==1) ? weights_ch4_taps1 :
                                                                  (tap==2) ? weights_ch4_taps2 :
                                                                  (tap==3) ? weights_ch4_taps3 : 12'b0;
                                                in_bs[ch] <= bias_ch4;
                                                list_ch[ch] <= list_ch_4;
                                        end
                                        5: begin 
                                                in_wt[ch][tap] <= (tap==0) ? weights_ch5_taps0 :
                                                                  (tap==1) ? weights_ch5_taps1 :
                                                                  (tap==2) ? weights_ch5_taps2 :
                                                                  (tap==3) ? weights_ch5_taps3 : 12'b0;
                                                in_bs[ch] <= bias_ch5;
                                                list_ch[ch] <= list_ch_5;
                                        end
                                        6: begin 
                                                in_wt[ch][tap] <= (tap==0) ? weights_ch6_taps0 :
                                                                  (tap==1) ? weights_ch6_taps1 :
                                                                  (tap==2) ? weights_ch6_taps2 :
                                                                  (tap==3) ? weights_ch6_taps3 : 12'b0;
                                                in_bs[ch] <= bias_ch6;
                                                list_ch[ch] <= list_ch_6;
                                        end
                                        7: begin 
                                                in_wt[ch][tap] <= (tap==0) ? weights_ch7_taps0 :
                                                                  (tap==1) ? weights_ch7_taps1 :
                                                                  (tap==2) ? weights_ch7_taps2 :
                                                                  (tap==3) ? weights_ch7_taps3 : 12'b0;
                                                in_bs[ch] <= bias_ch7;
                                                list_ch[ch] <= list_ch_7;
                                        end
                                        8: begin 
                                                in_wt[ch][tap] <= (tap==0) ? weights_ch8_taps0 :
                                                                  (tap==1) ? weights_ch8_taps1 :
                                                                  (tap==2) ? weights_ch8_taps2 :
                                                                  (tap==3) ? weights_ch8_taps3 : 12'b0;
                                                in_bs[ch] <= bias_ch8;
                                                list_ch[ch] <= list_ch_8;
                                        end
                                        9: begin 
                                                in_wt[ch][tap] <= (tap==0) ? weights_ch9_taps0 :
                                                                  (tap==1) ? weights_ch9_taps1 :
                                                                  (tap==2) ? weights_ch9_taps2 :
                                                                  (tap==3) ? weights_ch9_taps3 : 12'b0;
                                                in_bs[ch] <= bias_ch9;
                                                list_ch[ch] <= list_ch_9;
                                        end
                                        10: begin 
                                                in_wt[ch][tap] <= (tap==0) ? weights_ch10_taps0 :
                                                                  (tap==1) ? weights_ch10_taps1 :
                                                                  (tap==2) ? weights_ch10_taps2 :
                                                                  (tap==3) ? weights_ch10_taps3 : 12'b0;
                                                in_bs[ch] <= bias_ch10;
                                                list_ch[ch] <= list_ch_10;
                                        end
                                        11: begin 
                                                in_wt[ch][tap] <= (tap==0) ? weights_ch11_taps0 :
                                                                  (tap==1) ? weights_ch11_taps1 :
                                                                  (tap==2) ? weights_ch11_taps2 :
                                                                  (tap==3) ? weights_ch11_taps3 : 12'b0;
                                                in_bs[ch] <= bias_ch11;
                                                list_ch[ch] <= list_ch_11;
                                        end
                                        12: begin 
                                                in_wt[ch][tap] <= (tap==0) ? weights_ch12_taps0 :
                                                                  (tap==1) ? weights_ch12_taps1 :
                                                                  (tap==2) ? weights_ch12_taps2 :
                                                                  (tap==3) ? weights_ch12_taps3 : 12'b0;
                                                in_bs[ch] <= bias_ch12;
                                                list_ch[ch] <= list_ch_12;
                                        end
                                        13: begin 
                                                in_wt[ch][tap] <= (tap==0) ? weights_ch13_taps0 :
                                                                  (tap==1) ? weights_ch13_taps1 :
                                                                  (tap==2) ? weights_ch13_taps2 :
                                                                  (tap==3) ? weights_ch13_taps3 : 12'b0;
                                                in_bs[ch] <= bias_ch13;
                                                list_ch[ch] <= list_ch_13;
                                        end
                                        14: begin 
                                                in_wt[ch][tap] <= (tap==0) ? weights_ch14_taps0 :
                                                                  (tap==1) ? weights_ch14_taps1 :
                                                                  (tap==2) ? weights_ch14_taps2 :
                                                                  (tap==3) ? weights_ch14_taps3 : 12'b0;
                                                in_bs[ch] <= bias_ch14;
                                                list_ch[ch] <= list_ch_14;
                                        end
                                        15: begin 
                                                in_wt[ch][tap] <= (tap==0) ? weights_ch15_taps0 :
                                                                  (tap==1) ? weights_ch15_taps1 :
                                                                  (tap==2) ? weights_ch15_taps2 :
                                                                  (tap==3) ? weights_ch15_taps3 : 12'b0;
                                                in_bs[ch] <= bias_ch15;
                                                list_ch[ch] <= list_ch_15;
                                        end
                                endcase
                        end
                end
        end
end

reg [NUM_CH-1:0] ch_sel;
reg [$clog2(NUM_CH)-1:0] selected;
//reg [$clog2(NUM_CH)-1:0] selected_prev;
integer j;

always @(*) begin
        selected = 'b0;
        for (j = 0; j < NUM_CH; j = j + 1)
                if (index == list_ch[j]) begin
                        ch_sel[j] = 1'b1;
                        //selected_prev <= selected;
                        selected = j[3:0];
                end
                else begin
                        ch_sel[j] = 1'b0;
                        // selected = ; // todo
                end
end

//always @(posedge sys_clk or negedge sys_rst) begin
//        if (sys_rst==0) begin
//                ch_sel <= 'b0;
//                selected <= 'b0;
//                selected_prev <= 'b0;
//        end
//        else begin
//                for (j = 0; j < NUM_CH; j = j + 1)
//                        if (index == list_ch[j]) begin
//                                ch_sel[j] <= 1'b1;
//                                selected_prev <= selected;
//                                selected <= j[3:0];
//                        end
//                        else
//                                ch_sel[j] <= 1'b0;
//        end
//end

reg signed [8:0] input_data_i;
always @(posedge sys_clk or negedge sys_rst) begin
        if (sys_rst == 0) begin
                input_data_i <= 9'b0;
        end
        else
                input_data_i <= input_data;
end

wire signed [8:0] output_result_temp [0:NUM_CH-1];
wire [NUM_CH-1:0] output_index_temp;

genvar k;
generate
        for (k = 0; k < NUM_CH; k = k + 1)
                lnnt #(.CH_NUM(NUM_CH), .CH_TAPS(NUM_TAPS), .WB_WIDTH(NUM_WIDTH)) lnnt_i
                (
                        .in_active(input_active[k]),
                        .in_valid(data_valid),
                        .in_data(input_data_i),
                        .sel(ch_sel[k]),
                        .in_wt_0(in_wt[k][0]),
                        .in_wt_1(in_wt[k][1]),
                        .in_wt_2(in_wt[k][2]),
                        .in_wt_3(in_wt[k][3]),
                        .in_bs(in_bs[k]),
                        .sys_clk(sys_clk),
                        .sys_rst(sys_rst),
                        .out_lnn_valid(output_index_temp[k]),
                        .out_lnn_data(output_result_temp[k])
                );
endgenerate

// reg [$clog2(NUM_CH)-1:0] selected_buf0;
// reg [$clog2(NUM_CH)-1:0] selected_buf1;

always @(*) begin
        output_valid = 'b0;
        if (data_valid != 0 && sys_rst != 0)
                output_valid = |output_index_temp;
        // else
        //         output_valid = 1'b0;
end

always @(posedge sys_clk or negedge sys_rst) begin
        if (sys_rst == 0) begin
                // selected <= 'b0;
                output_result <= 9'b0;
                output_index <= 4'b0;
                // output_valid <= 1'b0;
        end
        else begin
                if (data_valid != 0) begin
                        output_result <= output_result_temp[selected];
                        //output_index <= selected_buf1;
                        //selected_buf1 <= selected_buf0;
                        //selected_buf0 <= selected;
                        output_index <= selected;
                        // output_valid <= |output_index_temp;
                end
                else begin
                        output_result <= 9'b0;
                        output_index <= 4'b0;
                        // output_valid <= 1'b0;
                end
        end
end

endmodule