function code = comp_dpcm1(data_r)

data_dpcm1=diff(data_r);
dpcm1_tab=tabulate(round(data_dpcm1));

code = dpcm1_tab;