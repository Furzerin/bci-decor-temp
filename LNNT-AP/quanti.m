function code = quanti(d_data,n_data,taps,epochs,wts,bs,x,y)
% a: mapped data
% x digits for dig, y digits for dec

file_name=append(d_data(2:end),n_data(1:end-4),"_taps",num2str(taps),"_epoch",num2str(epochs),"_int",num2str(x+y+1),".txt");
data_dir = append(pwd, '\..\data_output\',file_name);
fid=fopen(data_dir,'wt');

wts_n=cell2mat(wts);
bs_n=cell2mat(bs);

for i=1:length(wts_n)
    a=wts_n(i);
    if a<0
        a_sgn='1';
        a=a*(-1);
    else
        a_sgn='0';
    end
    a_d=round((2^y)*a);
    a_dec=(2^(x+y))-(-1*a_d);
    a_bin=dec2bin(a_dec,x+y);
    fprintf(fid,'%s%s\n',a_sgn,a_bin);
end

a=bs_n(1);
if a<0
    a_sgn='1';
    a=a*(-1);
else
    a_sgn='0';
end
a_d=(2^y)*a;
a_dec=(2^(x+y))-(-1*a_d);
a_bin=dec2bin(a_dec,x+y);
fprintf(fid,'%s%s\n',a_sgn,a_bin);

sta=fclose(fid);
code = file_name;