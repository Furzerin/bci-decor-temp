`timescale 1ns/10ps

module tb_lnnt_decor;
        // parameters
        parameter NUM_CH = 16;
        parameter NUM_TAPS = 4;
        parameter NUM_WIDTH = 12;

        // input
        reg sys_clk;
        reg sys_rst;
        reg data_valid;
        reg [5:0] index;
        reg signed [8:0] input_data;
        reg [NUM_CH-1:0] input_active;

        // output
        wire signed [8:0] output_result;
        wire output_valid;
        wire [$clog2(NUM_CH)-1:0] output_index;

        // clk
        initial begin
                sys_clk = 1'b0;
                sys_rst = 1'b0;

                data_valid = 1'b0;
                input_data = 9'b0;

                index = 6'b0;
        end
        always #5 sys_clk=~sys_clk;

        // configuration
        reg signed [NUM_WIDTH-1:0] in_wt [0:NUM_CH-1][0:NUM_TAPS-1];
        reg signed [NUM_WIDTH-1:0] in_bs [0:NUM_CH-1];
        reg [5:0] list_ch [0:NUM_CH-1];

        integer wb_file, scan_file, i;
        
        // tested module
        lnnt_decor #(.NUM_CH(NUM_CH),.NUM_TAPS(NUM_TAPS),.NUM_WIDTH(NUM_WIDTH)) lnnt_decor_i
        (
                .sys_clk(sys_clk),
                .sys_rst(sys_rst),
                .data_valid(data_valid),
                .index(index),
                .input_data(input_data),
                .input_active(input_active),

                .weights_ch0_taps0(in_wt[0][0]),
                .weights_ch0_taps1(in_wt[0][1]),
                .weights_ch0_taps2(in_wt[0][2]),
                .weights_ch0_taps3(in_wt[0][3]),
                .bias_ch0(in_bs[0]),
                .weights_ch1_taps0(in_wt[1][0]),
                .weights_ch1_taps1(in_wt[1][1]),
                .weights_ch1_taps2(in_wt[1][2]),
                .weights_ch1_taps3(in_wt[1][3]),
                .bias_ch1(in_bs[1]),
                .weights_ch2_taps0(in_wt[2][0]),
                .weights_ch2_taps1(in_wt[2][1]),
                .weights_ch2_taps2(in_wt[2][2]),
                .weights_ch2_taps3(in_wt[2][3]),
                .bias_ch2(in_bs[2]),
                .weights_ch3_taps0(in_wt[3][0]),
                .weights_ch3_taps1(in_wt[3][1]),
                .weights_ch3_taps2(in_wt[3][2]),
                .weights_ch3_taps3(in_wt[3][3]),
                .bias_ch3(in_bs[3]),
                .weights_ch4_taps0(in_wt[4][0]),
                .weights_ch4_taps1(in_wt[4][1]),
                .weights_ch4_taps2(in_wt[4][2]),
                .weights_ch4_taps3(in_wt[4][3]),
                .bias_ch4(in_bs[4]),
                .weights_ch5_taps0(in_wt[5][0]),
                .weights_ch5_taps1(in_wt[5][1]),
                .weights_ch5_taps2(in_wt[5][2]),
                .weights_ch5_taps3(in_wt[5][3]),
                .bias_ch5(in_bs[5]),
                .weights_ch6_taps0(in_wt[6][0]),
                .weights_ch6_taps1(in_wt[6][1]),
                .weights_ch6_taps2(in_wt[6][2]),
                .weights_ch6_taps3(in_wt[6][3]),
                .bias_ch6(in_bs[6]),
                .weights_ch7_taps0(in_wt[7][0]),
                .weights_ch7_taps1(in_wt[7][1]),
                .weights_ch7_taps2(in_wt[7][2]),
                .weights_ch7_taps3(in_wt[7][3]),
                .bias_ch7(in_bs[7]),
                .weights_ch8_taps0(in_wt[8][0]),
                .weights_ch8_taps1(in_wt[8][1]),
                .weights_ch8_taps2(in_wt[8][2]),
                .weights_ch8_taps3(in_wt[8][3]),
                .bias_ch8(in_bs[8]),
                .weights_ch9_taps0(in_wt[9][0]),
                .weights_ch9_taps1(in_wt[9][1]),
                .weights_ch9_taps2(in_wt[9][2]),
                .weights_ch9_taps3(in_wt[9][3]),
                .bias_ch9(in_bs[9]),
                .weights_ch10_taps0(in_wt[10][0]),
                .weights_ch10_taps1(in_wt[10][1]),
                .weights_ch10_taps2(in_wt[10][2]),
                .weights_ch10_taps3(in_wt[10][3]),
                .bias_ch10(in_bs[10]),
                .weights_ch11_taps0(in_wt[11][0]),
                .weights_ch11_taps1(in_wt[11][1]),
                .weights_ch11_taps2(in_wt[11][2]),
                .weights_ch11_taps3(in_wt[11][3]),
                .bias_ch11(in_bs[11]),
                .weights_ch12_taps0(in_wt[12][0]),
                .weights_ch12_taps1(in_wt[12][1]),
                .weights_ch12_taps2(in_wt[12][2]),
                .weights_ch12_taps3(in_wt[12][3]),
                .bias_ch12(in_bs[12]),
                .weights_ch13_taps0(in_wt[13][0]),
                .weights_ch13_taps1(in_wt[13][1]),
                .weights_ch13_taps2(in_wt[13][2]),
                .weights_ch13_taps3(in_wt[13][3]),
                .bias_ch13(in_bs[13]),
                .weights_ch14_taps0(in_wt[14][0]),
                .weights_ch14_taps1(in_wt[14][1]),
                .weights_ch14_taps2(in_wt[14][2]),
                .weights_ch14_taps3(in_wt[14][3]),
                .bias_ch14(in_bs[14]),
                .weights_ch15_taps0(in_wt[15][0]),
                .weights_ch15_taps1(in_wt[15][1]),
                .weights_ch15_taps2(in_wt[15][2]),
                .weights_ch15_taps3(in_wt[15][3]),
                .bias_ch15(in_bs[15]),

                .list_ch_0(list_ch[0]),
                .list_ch_1(list_ch[1]),
                .list_ch_2(list_ch[2]),
                .list_ch_3(list_ch[3]),
                .list_ch_4(list_ch[4]),
                .list_ch_5(list_ch[5]),
                .list_ch_6(list_ch[6]),
                .list_ch_7(list_ch[7]),
                .list_ch_8(list_ch[8]),
                .list_ch_9(list_ch[9]),
                .list_ch_10(list_ch[10]),
                .list_ch_11(list_ch[11]),
                .list_ch_12(list_ch[12]),
                .list_ch_13(list_ch[13]),
                .list_ch_14(list_ch[14]),
                .list_ch_15(list_ch[15]),

                .output_result(output_result),
                .output_valid(output_valid),
                .output_index(output_index)
        );

        // input
        integer data_file, read_file;
        reg signed [8:0] file_input_data; // 9-bit signed fixed-point data
        reg [5:0] file_input_index;

        integer ref_file, ref_scan;
        reg signed [8:0] file_ref_data; // reference
        
        initial begin
                #22 sys_rst = 1'b1;
        end

        `include "testcase.v"
        
        initial begin
                $monitor("Time: %0t | Index: %0d | Input Data (9-bit): %0d | Output Result: %0d | Output Valid: %0b",
                        $time, output_index, input_data, output_result, output_valid);
        end
        
        

endmodule