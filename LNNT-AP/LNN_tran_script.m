clearvars
data_g = 'C';
data_d = '_Easy1';
data_a = '_noise005.mat';
dataset = append(data_g, data_d, data_a);
dataset_title = append(data_g, '\', data_d, '\', data_a);
% please modify the following path accordingly
data_dir = append(pwd, '\..\dataset\');
joint_path = append(data_dir, dataset);
load(joint_path)

pos_fact=255/max(data);
neg_fact=-256/min(data);
if (pos_fact>=neg_fact)
    data_r=round(data*neg_fact);
else
    data_r=round(data*pos_fact);
end
%data_r=data_r./128;

CR_8=[];
CR_12=[];
CR_16=[];
CR_32=[];
CR_o=[];

%for taps=[1,2,3,4,5,6,7,8,9,10,16,32]
for taps=[4]
    LNN_output=LNN_analyzer_1(data_d,data_a,taps,4000);
    cr_p=LNN_difference(taps,LNN_output,data_r); % difference: data predicted by quanti-w&b from origianl data
    % calculate with quanti-w&b
    cr_int8=cr_p(1)
    cr_int16=cr_p(2)
    cr_int32=cr_p(3)
    cr_origin=cr_p(4)
    cr_int12=cr_p(5)
    
    CR_8=[CR_8,cr_int8/100];
    CR_12=[CR_12,cr_int12/100];
    CR_16=[CR_16,cr_int16/100];
    CR_32=[CR_32,cr_int32/100];
    CR_o=[CR_o,cr_origin/100];
end

beep on;
beep;
beep;
beep;
beep;
beep;