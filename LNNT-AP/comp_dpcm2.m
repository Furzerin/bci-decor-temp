function code = comp_dpcm2(data_r)

data_diff2=diff(data_r,2);
data_dpcm2=cat(2, data_r(1), (data_r(2)-data_r(1)), data_diff2);
dpcm2_tab=tabulate(round(data_dpcm2));

code = dpcm2_tab;
