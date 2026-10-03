initial begin // single channel testing
    input_active = 16'b0000_0000_0000_0011;
    index = 6'b0; // 1 - index

    wb_file = $fopen("/zs/proj/p_eval/s_compress/v0.0.1/workspaces/weimo/units/lnnt_decor/source/tb/Net_data.txt","r");
    if (!wb_file) begin
        $display("Error: Could not open file %s", "Net_data.txt");
        $finish;
    end
    else for (i = 0; i < NUM_CH; i = i + 1) begin
        scan_file = $fscanf(wb_file, "%b %b %b %b %b\n",
            in_wt[i][0], in_wt[i][1], in_wt[i][2], in_wt[i][3], in_bs[i]);
    end
    $fclose(wb_file);

    wb_file = $fopen("/zs/proj/p_eval/s_compress/v0.0.1/workspaces/weimo/units/lnnt_decor/source/tb/Channel_list.txt","r");
    if (!wb_file) begin
        $display("Error: Could not open file %s", "Channel_list.txt");
        $finish;
    end
    else for (i = 0; i < NUM_CH; i = i + 1) begin
        scan_file = $fscanf(wb_file, "%b\n", list_ch[i]);
    end
    $fclose(wb_file);
    

    data_file = $fopen("/zs/proj/p_eval/s_compress/v0.0.1/workspaces/weimo/units/lnnt_decor/source/tb/Data_input.txt","r"); // 2 - data
    if (!data_file) begin
        $display("Error: Could not open file %s", "Data_input.txt");
        $finish;
    end

    ref_file = $fopen("/zs/proj/p_eval/s_compress/v0.0.1/workspaces/weimo/units/lnnt_decor/simulation/ncsim/wei/out_ref_single.txt","r");
    if (!ref_file) begin
        $display("Error: Could not open file %s", "out_ref_single.txt");
        $finish;
    end

    #25 data_valid = 1'b1; // 3 - data_valid

    while (!$feof(data_file)) begin
        read_file = $fscanf(data_file, "%b\n", file_input_data);
        input_data = file_input_data;
        #10;
    end

    $fclose(data_file);
    data_valid = 1'b0;

    #20 index = 6'b000001;
    data_file = $fopen("/zs/proj/p_eval/s_compress/v0.0.1/workspaces/weimo/units/lnnt_decor/source/tb/Data_input.txt","r");
    if (!data_file) begin
        $display("Error: Could not open file %s", "Data_input.txt");
        $finish;
    end

    #20 data_valid = 1'b1;
    while (!$feof(data_file)) begin
        read_file = $fscanf(data_file, "%b\n", file_input_data);
        input_data = file_input_data;
        #10;
    end
    $fclose(data_file);

    #20000 $finish;
end

initial begin
    if (output_valid)
        while (!$feof(data_file)) begin
            ref_scan = $fscanf(data_file, "%b\n", file_ref_data);
            if (file_ref_data != output_result)
            $display("Error: Should output %b instead of %b", file_ref_data, output_result);
            #10;
        end

end