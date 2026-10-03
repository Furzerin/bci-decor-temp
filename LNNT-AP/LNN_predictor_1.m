% function code = LNN_predictor_1(LNN_data_d,LNN_data_a,LNN_taps,LNN_epochs)

LNN_data_d='_Easy1';
LNN_data_a='_noise005.mat';
LNN_taps=32;
LNN_epochs=20000;

%% training
% clearvars
data_g = 'C';
data_d = LNN_data_d;
data_n = LNN_data_a;
dataset = append(data_g, data_d, data_n);
dataset_title = append(data_g, '\', data_d, '\', data_n);
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

%% inference
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

figure(1)
lnn_diff_tab = tabulate(lnn_diff);
plot(lnn_diff_tab(:,1), lnn_diff_tab(:,3))
hold on
lnn_tab_c1=lnn_diff_tab(:,1);
lnn_tab_c3=lnn_diff_tab(:,3);

data_diff2=diff(data_r,2);
data_dpcm2=cat(2, data_r(1), (data_r(2)-data_r(1)), data_diff2);
dpcm2_tab=tabulate(data_dpcm2);
plot(dpcm2_tab(:,1), dpcm2_tab(:,3))
hold on
dpcm2_tab_c1=dpcm2_tab(:,1);
dpcm2_tab_c3=dpcm2_tab(:,3);

data_diff1=diff(data_r,1);
data_dpcm1=cat(2, data_r(1), data_diff1);
dpcm1_tab=tabulate(data_dpcm1);
plot(dpcm1_tab(:,1), dpcm1_tab(:,3))
hold on
dpcm1_tab_c1=dpcm1_tab(:,1);
dpcm1_tab_c3=dpcm1_tab(:,3);

data_diff3=diff(data_r,3);
data_dpcm3=cat(2, data_r(1), data_dpcm2(2:3), data_diff3);
dpcm3_tab=tabulate(data_dpcm3);
dpcm3_tab_c1=dpcm3_tab(:,1);
dpcm3_tab_c3=dpcm3_tab(:,3);

original_tab=tabulate(data_r);
plot(original_tab(:,1), original_tab(:,3))

legend('lnn\_diff', 'dpcm2', 'dpcm1', 'original')

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

    if (data_dpcm1(i)>=0)
        data_dpcm1_mapped(i) = 2*data_dpcm1(i);
    else
        data_dpcm1_mapped(i) = -2*data_dpcm1(i) - 1;
    end

    if (data_r(i)>=0)
        data_r_mapped(i) = 2*data_r(i);
    else
        data_r_mapped(i) = -2*data_r(i) - 1;
    end
end

figure(2)
lnn_diff_mapped_tab=tabulate(lnn_diff_mapped);
plot(lnn_diff_mapped_tab(:,1), lnn_diff_mapped_tab(:,3))
hold on
data_dpcm2_mapped_tab=tabulate(data_dpcm2_mapped);
plot(data_dpcm2_mapped_tab(:,1), data_dpcm2_mapped_tab(:,3))
hold on
data_dpcm1_mapped_tab=tabulate(data_dpcm1_mapped);
plot(data_dpcm1_mapped_tab(:,1), data_dpcm1_mapped_tab(:,3))
hold on
data_r_mapped_tab=tabulate(data_r_mapped);
plot(data_r_mapped_tab(:,1), data_r_mapped_tab(:,3))
legend('lnn\_diff\_mapped', 'dpcm2\_mapped', 'dpcm1\_mapped', 'original\_mapped')

title(dataset_title)

CR_lnn_gcv2=adap_m_CR(lnn_diff_mapped, GC_group_size)
CR_dpcm2_gcv2=adap_m_CR(data_dpcm2_mapped, GC_group_size)
CR_dpcm1_gcv2=adap_m_CR(data_dpcm1_mapped, GC_group_size)

%% inference manual

iw=cell2mat(net.IW);
b=cell2mat(net.b);

% for i=1:LNN_taps
%     Y_pred(i)=data(i);
% end
% for i=LNN_taps+1:length(data)
%     Y_pred(i)=data(i-LNN_taps)*iw(4)+data(i-LNN_taps+1)*iw(3)+data(i-LNN_taps+2)*iw(2)+data(i-LNN_taps+3)*iw(1)+b(1);
% end

%% quantization

iw4=round(iw*power(2,1))/power(2,1); % 1,2,1
iw8=round(iw*power(2,5))/power(2,5); % 1,2,5
iw12=round(iw*power(2,9))/power(2,9); % 1,2,9
iw16=round(iw*power(2,11))/power(2,11); % 1,4,11
iw32=round(iw*power(2,23))/power(2,23); % 1,8,23

b4=round(b*power(2,1))/power(2,1);
b8=round(b*power(2,5))/power(2,5);
b12=round(b*power(2,9))/power(2,9);
b16=round(b*power(2,11))/power(2,11);
b32=round(b*power(2,23))/power(2,23);

for i=1:LNN_taps
    Y_pred4(i)=data(i);
    Y_pred8(i)=data(i);
    Y_pred12(i)=data(i);
    Y_pred16(i)=data(i);
    Y_pred32(i)=data(i);
end
for i=LNN_taps+1:length(data)
    Y_pred4(i)=0;
    Y_pred8(i)=0;
    Y_pred12(i)=0;
    Y_pred16(i)=0;
    Y_pred32(i)=0;
    for j=1:LNN_taps
        Y_pred4(i)=Y_pred4(i)+data(i-LNN_taps+j-1)*iw4(LNN_taps-j+1);
        Y_pred8(i)=Y_pred8(i)+data(i-LNN_taps+j-1)*iw8(LNN_taps-j+1);
        Y_pred12(i)=Y_pred12(i)+data(i-LNN_taps+j-1)*iw12(LNN_taps-j+1);
        Y_pred16(i)=Y_pred16(i)+data(i-LNN_taps+j-1)*iw16(LNN_taps-j+1);
        Y_pred32(i)=Y_pred32(i)+data(i-LNN_taps+j-1)*iw32(LNN_taps-j+1);
    end
    Y_pred4(i)=Y_pred4(i)+b4;
    Y_pred8(i)=Y_pred8(i)+b8;
    Y_pred12(i)=Y_pred12(i)+b12;
    Y_pred16(i)=Y_pred16(i)+b16;
    Y_pred32(i)=Y_pred32(i)+b32;
end

if (pos_fact>=neg_fact)
    Y_pred4_r=round(Y_pred4*neg_fact);
    Y_pred8_r=round(Y_pred8*neg_fact);
    Y_pred12_r=round(Y_pred12*neg_fact);
    Y_pred16_r=round(Y_pred16*neg_fact);
    Y_pred32_r=round(Y_pred32*neg_fact);
else
    Y_pred4_r=round(Y_pred4*pos_fact);
    Y_pred8_r=round(Y_pred8*pos_fact);
    Y_pred12_r=round(Y_pred12*pos_fact);
    Y_pred16_r=round(Y_pred16*pos_fact);
    Y_pred32_r=round(Y_pred32*pos_fact);
end
lnn_diff4 = data_r - Y_pred4_r;
lnn_diff8 = data_r - Y_pred8_r;
lnn_diff12 = data_r - Y_pred12_r;
lnn_diff16 = data_r - Y_pred16_r;
lnn_diff32 = data_r - Y_pred32_r;

%% hybrid
lnn_diff4(1) = 0;
lnn_diff8(1) = 0;
lnn_diff12(1) = 0;
lnn_diff16(1) = 0;
lnn_diff32(1) = 0;

lnn_diff4(2) = data_dpcm1(2);
lnn_diff8(2) = data_dpcm1(2);
lnn_diff12(2) = data_dpcm1(2);
lnn_diff16(2) = data_dpcm1(2);
lnn_diff32(2) = data_dpcm1(2);

for i=3:taps
    lnn_diff4(i) = data_dpcm2(i);
    lnn_diff8(i) = data_dpcm2(i);
    lnn_diff12(i) = data_dpcm2(i);
    lnn_diff16(i) = data_dpcm2(i);
    lnn_diff32(i) = data_dpcm2(i);
end

%% output
for i=1:length(lnn_diff)
    if (lnn_diff4(i)>=0)
        lnn_diff4_mapped(i) = 2*lnn_diff4(i);
    else
        lnn_diff4_mapped(i) = -2*lnn_diff4(i)-1;
    end

    if (lnn_diff8(i)>=0)
        lnn_diff8_mapped(i) = 2*lnn_diff8(i);
    else
        lnn_diff8_mapped(i) = -2*lnn_diff8(i)-1;
    end

    if (lnn_diff12(i)>=0)
        lnn_diff12_mapped(i) = 2*lnn_diff12(i);
    else
        lnn_diff12_mapped(i) = -2*lnn_diff12(i)-1;
    end

    if (lnn_diff16(i)>=0)
        lnn_diff16_mapped(i) = 2*lnn_diff16(i);
    else
        lnn_diff16_mapped(i) = -2*lnn_diff16(i)-1;
    end

    if (lnn_diff32(i)>=0)
        lnn_diff32_mapped(i) = 2*lnn_diff32(i);
    else
        lnn_diff32_mapped(i) = -2*lnn_diff32(i)-1;
    end
end

%CR_lnn_quan4=adap_m_CR(lnn_diff4_mapped, GC_group_size)
%CR_lnn_quan8=adap_m_CR(lnn_diff8_mapped, GC_group_size)
CR_lnn_quan12=adap_m_CR(lnn_diff12_mapped, GC_group_size)
%CR_lnn_quan16=adap_m_CR(lnn_diff16_mapped, GC_group_size)
%CR_lnn_quan32=adap_m_CR(lnn_diff32_mapped, GC_group_size)

% code=[CR_lnn_gcv2, net.IW, net.b, Y_tst, lnn_diff];