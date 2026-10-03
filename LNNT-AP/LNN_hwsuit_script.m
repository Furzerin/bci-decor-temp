for i=[4]
    LNN_output=LNN_hwsuit('_Easy1','_noise005.mat',i,10);
    cr=cell2mat(LNN_output(1))/100;
    GC_result=[GC_result_E102, cr];
    net_ori=LNN_output(2);
end

Y_tst=cell2mat(net(num2cell(data)));
Y_tst=Y_tst-data;

for i=1:taps
    Y_tst(i) = data(i);
end
lnn_diff_tab = tabulate(lnn_diff);

net.IW=round(num2cell(cell2num(net.IW)*2^9))./2^9;
net.b=round(num2cell(cell2num(net.b))*2^9)./2^9;