function code = LNN_analyzer_1(LNN_data_d,LNN_data_a,LNN_taps,LNN_epochs)

% clearvars
data_g = 'C';
data_d = LNN_data_d;
data_a = LNN_data_a;
dataset = append(data_g, data_d, data_a);
dataset_title = append(data_g, '\', data_d, '\', data_a);
% please modify the following path accordingly
data_dir = append(pwd, '\..\dataset\');
joint_path = append(data_dir, dataset);
load(joint_path)
fig_on = false;
pre_norm = false;
taps = LNN_taps;
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

net.trainParam.epochs=LNN_epochs;

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

% if (pos_fact>=neg_fact)
%     Y_tst_r=round(Y_tst*neg_fact);
% else
%     Y_tst_r=round(Y_tst*pos_fact);
% end
% 
% lnn_diff = data_r - Y_tst_r;
% for i=1:taps
%     lnn_diff(i) = data_r(i);
% end

file_int8=quanti(data_d,data_a,taps,net.trainParam.epochs,net.IW,net.b,2,5);
file_int12=quanti(data_d,data_a,taps,net.trainParam.epochs,net.IW,net.b,2,9);
file_int16=quanti(data_d,data_a,taps,net.trainParam.epochs,net.IW,net.b,4,11);
file_int32=quanti(data_d,data_a,taps,net.trainParam.epochs,net.IW,net.b,8,23);
file_original=net_data(data_d,data_a,taps,net.trainParam.epochs,net.IW,net.b);

%code=[net.IW,net.b,file_int8,file_int16,file_int32,file_original];
code=["CNM","RNM",file_int8,file_int16,file_int32,file_original,file_int12];

% figure(1)
% lnn_diff_tab = tabulate(lnn_diff);
% plot(lnn_diff_tab(:,1), lnn_diff_tab(:,3))
% hold on
% lnn_tab_c1=lnn_diff_tab(:,1);
% lnn_tab_c3=lnn_diff_tab(:,3);
% 
% data_diff2=diff(data_r,2);
% data_dpcm2=cat(2, data_r(1), (data_r(2)-data_r(1)), data_diff2);
% dpcm2_tab=tabulate(data_dpcm2);
% plot(dpcm2_tab(:,1), dpcm2_tab(:,3))
% hold on
% dpcm2_tab_c1=dpcm2_tab(:,1);
% dpcm2_tab_c3=dpcm2_tab(:,3);
% 
% data_diff1=diff(data_r,1);
% data_dpcm1=cat(2, data_r(1), data_diff1);
% dpcm1_tab=tabulate(data_dpcm1);
% plot(dpcm1_tab(:,1), dpcm1_tab(:,3))
% hold on
% dpcm1_tab_c1=dpcm1_tab(:,1);
% dpcm1_tab_c3=dpcm1_tab(:,3);
% 
% data_diff3=diff(data_r,3);
% data_dpcm3=cat(2, data_r(1), data_dpcm2(2:3), data_diff3);
% dpcm3_tab=tabulate(data_dpcm3);
% dpcm3_tab_c1=dpcm3_tab(:,1);
% dpcm3_tab_c3=dpcm3_tab(:,3);
% 
% original_tab=tabulate(data_r);
% plot(original_tab(:,1), original_tab(:,3))
% 
% legend('lnn\_diff', 'dpcm2', 'dpcm1', 'original')
% 
% for i=1:length(lnn_diff)
%     if (lnn_diff(i)>=0)
%         lnn_diff_mapped(i) = 2*lnn_diff(i);
%     else
%         lnn_diff_mapped(i) = -2*lnn_diff(i)-1;
%     end
% 
%     if (data_dpcm2(i)>=0)
%         data_dpcm2_mapped(i) = 2*data_dpcm2(i);
%     else
%         data_dpcm2_mapped(i) = -2*data_dpcm2(i) - 1;
%     end
% 
%     if (data_dpcm1(i)>=0)
%         data_dpcm1_mapped(i) = 2*data_dpcm1(i);
%     else
%         data_dpcm1_mapped(i) = -2*data_dpcm1(i) - 1;
%     end
% 
%     if (data_r(i)>=0)
%         data_r_mapped(i) = 2*data_r(i);
%     else
%         data_r_mapped(i) = -2*data_r(i) - 1;
%     end
% end
% 
% figure(2)
% lnn_diff_mapped_tab=tabulate(lnn_diff_mapped);
% plot(lnn_diff_mapped_tab(:,1), lnn_diff_mapped_tab(:,3))
% hold on
% data_dpcm2_mapped_tab=tabulate(data_dpcm2_mapped);
% plot(data_dpcm2_mapped_tab(:,1), data_dpcm2_mapped_tab(:,3))
% hold on
% data_dpcm1_mapped_tab=tabulate(data_dpcm1_mapped);
% plot(data_dpcm1_mapped_tab(:,1), data_dpcm1_mapped_tab(:,3))
% hold on
% data_r_mapped_tab=tabulate(data_r_mapped);
% plot(data_r_mapped_tab(:,1), data_r_mapped_tab(:,3))
% legend('lnn\_diff\_mapped', 'dpcm2\_mapped', 'dpcm1\_mapped', 'original\_mapped')
% 
% title(dataset_title)
% 
% CR_lnn_gcv2=adap_m_CR(lnn_diff_mapped, GC_group_size)
% CR_dpcm2_gcv2=adap_m_CR(data_dpcm2_mapped, GC_group_size)
% CR_dpcm1_gcv2=adap_m_CR(data_dpcm1_mapped, GC_group_size)
% 
% 
% code=[CR_lnn_gcv2,net.IW,net.b,lnn_diff];