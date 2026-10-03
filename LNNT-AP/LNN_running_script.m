clearvars

load('../dataset/C_Easy1_noise005.mat');
%pos_fact=255/max(data);
%neg_fact=-256/min(data);
%if (pos_fact>=neg_fact)
%    data_r=round(data*neg_fact);
%else
%    data_r=round(data*pos_fact);
%end


GC_result_E102=[];
IW_i=[];
b_i=[];

for i=[4]
    LNN_output=LNN_predictor_1('_Easy1','_noise005.mat',i,100);
    cr=cell2mat(LNN_output(1))/100;
    IW_i=[IW_i,cell2mat(LNN_output(2))];
    b_i=[b_i,cell2mat(LNN_output(3))];
    GC_result_E102=[GC_result_E102, cr];
    % ans=LNN_output(5);
    
    % net_o=LNN_output(4);

end

% Y=[];
% for k=1:4
%     Y=[Y,data(k)];
% end
% for k=(4+1):(length(data))
%     sum=0.0;
%     for j=1:4
%         sum=sum+data(k-4+j-1)*IW_i(4-j+1);
%     end
%     sum=sum+b_i;
%     %k
%     Y=[Y,sum];
%     if k==1440000
%         break;
%     end
% end
% 
% pos_fact=255/max(data);
% neg_fact=-256/min(data);
% if (pos_fact>=neg_fact)
%    data_r=round(data*neg_fact);
%    b_i(1)=b_i(1)*neg_fact;
%    Y_r=round(Y*neg_fact);
% else
%    data_r=round(data*pos_fact);
%    b_i(1)=b_i(1)*pos_fact;
%    Y_r=round(Y*pos_fact);
% end
% 
% Y_diff=Y_r-data_r;
% 
% for j=1:length(Y_diff)
%    if (Y_diff(j)>=0)
%        data_mapped(j) = 2*Y_diff(j);
%    else
%        data_mapped(j) = -2*Y_diff(j)-1;
%    end
% end
% CR_lnn_gc=adap_m_CR(data_mapped, 50000)

pos_fact=255/max(data);
neg_fact=-256/min(data);
if (pos_fact>=neg_fact)
   data_r=round(data*neg_fact);
   b_i(1)=b_i(1)*neg_fact;
else
   data_r=round(data*pos_fact);
   b_i(1)=b_i(1)*pos_fact;
end

data_p=zeros(1,length(data_r));
for j=5:length(data_p)
   data_p(j)=IW_i(1)*data_r(j-4)+IW_i(2)*data_r(j-3)+IW_i(3)*data_r(j-2)+IW_i(4)*data_r(j-1)+b_i(1);
   %data_p(j)=IW_i(4)*data_r(j-4)+IW_i(3)*data_r(j-3)+IW_i(2)*data_r(j-2)+IW_i(1)*data_r(j-1)+b_i(1);
end
data_p(1:length(data_p)-4)=data_p(5:length(data_p));
for j=1:4
   data_p(j)=data_r(j);
end
data_p=round(data_p)-data_r;

for j=1:length(data_p)
   if (data_p(j)>=0)
       data_mapped(j) = 2*data_p(j);
   else
       data_mapped(j) = -2*data_p(j)-1;
   end
end
CR_lnn_gc=adap_m_CR(data_mapped, 50000)