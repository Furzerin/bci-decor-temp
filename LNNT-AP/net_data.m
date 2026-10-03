function code = net_data(d_data,n_data,taps,epochs,wts,bs)
% export the data net.IW & net.b

file_name=append(d_data(2:end),n_data(1:end-4),"_taps",num2str(taps),"_epoch",num2str(epochs),"_original",".txt");
data_dir = append(pwd, '\..\data_output\',file_name);
fid=fopen(data_dir,'wt');

wts_n=cell2mat(wts);
bs_n=cell2mat(bs);

for i=1:length(wts_n)
    fprintf(fid,'%8.15f\n',wts_n(i));
end

fprintf(fid,'%8.15f\n',bs_n);

sta=fclose(fid);
code=file_name;