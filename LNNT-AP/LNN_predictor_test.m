clearvars
data_g = 'C';
data_d = '_Easy1';
data_n = '_noise005.mat';
dataset = append(data_g, data_d, data_n);
dataset_title = append(data_g, '\', data_d, '\', data_n);
% please modify the following path accordingly
data_dir = append(pwd, '\..\dataset\');
joint_path = append(data_dir, dataset);
load(joint_path)
fig_on = false;
pre_norm = false;
taps = 4;
GC_group_size = 50000;

pos_fact=255/max(data);
neg_fact=-256/min(data);

if (pos_fact>=neg_fact)
    data_r=round(data*neg_fact);
else
    data_r=round(data*pos_fact);
end

% data_diff2=diff(data_r,2);
% data_dpcm2=cat(2, data_r(1), (data_r(2)-data_r(1)), data_diff2);
% 
% data_diff1=diff(data_r,1);
% data_dpcm1=cat(2, data_r(1), data_diff1);
format long

% normalize
if pre_norm == true
    data_n=normalize(data, 'range', [-1 255/256]);
else
    data_n=data;
end

data_to_LNN=data_n(1:2000);
%data_to_LNN2=data_r(1:2000);
x = num2cell(data_to_LNN);
t = num2cell(data_to_LNN);
% length 1000: lr => 0.002/0.0018
% length 100000: lr => 0.000011/0.00001
net = linearlayer(1:taps,0.0010); % last argument: learning rate

net.trainFcn = 'trains';
net.inputWeights{1}.learnFcn = 'learnwh';
net.layerWeights{1}.learnFcn = 'learnwh';
net.biases{1}.learnFcn = 'learnwh';
p=rand(2,1);
e=rand(3,1);
lp.lr=0.0005;
dW=learnwh([],p,[],[],[],[],e,[],[],[],lp,[]);

net.trainParam.epochs=4000;

[Xs, Xi, Ai, Ts] = preparets(net, x, t);
net = train(net, Xs, Ts, Xi, Ai);
% view(net)
% Y = net(Xs,Xi);
% Ym = cell2mat(Y);
% Ys = round(Ym*256);
% perf = perform(net, Ts, Y)
% the following 2 lines shows the weights in net
% net.IW
% net.b
Y_tst=cell2mat(net(num2cell(data)));
if fig_on == true
    plot(Y_tst(taps+1:end))
    hold on
    plot(data(taps+1:end))
end
perf = perform(net, data(taps+1:end), Y_tst(taps+1:end))

if (pos_fact>=neg_fact)
    Y_tst_r=round(Y_tst*neg_fact);
else
    Y_tst_r=round(Y_tst*pos_fact);
end

lnn_diff = data_r - Y_tst_r;
for i=1:taps
    lnn_diff(i) = data_r(i);
end

lnn_diff_tab = tabulate(lnn_diff);
figure
plot(lnn_diff_tab(:,1), lnn_diff_tab(:,3))

lnn_tab_c1=lnn_diff_tab(:,1);
lnn_tab_c3=lnn_diff_tab(:,3);

data_diff2=diff(data_r,2);
data_dpcm2=cat(2, data_r(1), (data_r(2)-data_r(1)), data_diff2);
dpcm2_tab=tabulate(data_dpcm2);
hold on
plot(dpcm2_tab(:,1), dpcm2_tab(:,3))
dpcm2_tab_c1=dpcm2_tab(:,1);
dpcm2_tab_c3=dpcm2_tab(:,3);

data_diff1=diff(data_r,1);
data_dpcm1=cat(2, data_r(1), data_diff1);
dpcm1_tab=tabulate(data_dpcm1);
dpcm1_tab_c1=dpcm1_tab(:,1);
dpcm1_tab_c3=dpcm1_tab(:,3);

data_diff3=diff(data_r,3);
data_dpcm3=cat(2, data_r(1), data_dpcm2(2:3), data_diff3);
dpcm3_tab=tabulate(data_dpcm3);
dpcm3_tab_c1=dpcm3_tab(:,1);
dpcm3_tab_c3=dpcm3_tab(:,3);


for i=1:length(lnn_diff)
    if (lnn_diff(i)>=0)
        lnn_diff_mapped(i) = 2*lnn_diff(i);
    else
        lnn_diff_mapped(i) = -2*lnn_diff(i)-1;
    end

    if (data_dpcm2(i)>=0)
        data_dpcm2_mapped(i) = 2*data_dpcm2(i);
    else
        data_dpcm2_mapped(i) = -2*data_dpcm2(i) - 1;
    end
end

lnn_diff_mapped_tab=tabulate(lnn_diff_mapped);
plot(lnn_diff_mapped_tab(:,1), lnn_diff_mapped_tab(:,3))
data_dpcm2_mapped_tab=tabulate(data_dpcm2_mapped);
plot(data_dpcm2_mapped_tab(:,1), data_dpcm2_mapped_tab(:,3))

legend('lnn\_diff', 'dpcm2', 'lnn\_diff\_mapped', 'dpcm2\_mapped')
title(dataset_title)

CR_lnn_gcv2=adap_m_CR(lnn_diff_mapped, GC_group_size);
CR_dpcm2_gcv2=adap_m_CR(data_dpcm2_mapped, GC_group_size);


%%%%%%%%%%%%%%%%%%%%%%%%%
%% goladap
%%%%%%%%%%%%%%%%%%%%%%%%%

%data_mapped_bit_total=[];

%clear goladap_encode_for_v4

%startpoint=1;
%endpoint=300000;
%length_i=endpoint-startpoint+1;

%for i=startpoint:endpoint
%    data_mapped_bit=exhausting_one_code(lnn_diff(i));
%    data_mapped_bit_total=[data_mapped_bit_total data_mapped_bit];
%end

%compressed_data=goladap_encode_for_v4(data_mapped_bit_total);
%L=length(compressed_data);
%CR_lnn_goladap=(1 - L/(length_i*9))*100;

