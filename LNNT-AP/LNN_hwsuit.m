function code = LNN_hwsuit(LNN_data_d,LNN_data_a,LNN_taps,LNN_epochs)

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

format long

% normalize
if pre_norm == true
    data_n=normalize(data, 'range', [-1 255/256]);
else
    data_n=data;
end

data_to_LNN=data_n(1:2000);
x = num2cell(data_to_LNN);
t = num2cell(data_to_LNN);
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

%%
Y_tst=cell2mat(net(num2cell(data)));
if fig_on == true
    plot(Y_tst(taps+1:end))
    hold on
    plot(data(taps+1:end))
end
%perf = perform(net, data(taps+1:end), Y_tst(taps+1:end))

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

%%


%%
figure(1)
plot(lnn_diff_tab(:,1), lnn_diff_tab(:,3),'LineWidth',1.25)

data_diff2=diff(data_r,2);
data_dpcm2=cat(2, data_r(1), (data_r(2)-data_r(1)), data_diff2);
dpcm2_tab=comp_dpcm2(data_r);
hold on
plot(dpcm2_tab(:,1), dpcm2_tab(:,3),'--','LineWidth',1.25)

data_diff1=diff(data_r,1);
data_dpcm1=cat(2, data_r(1), data_diff1);
dpcm1_tab=comp_dpcm1(data_r);
hold on
plot(dpcm1_tab(:,1),dpcm1_tab(:,3),':','LineWidth',1.25)

data_ori=data_r;
orignal_tab=tabulate(round(data_ori));
hold on
plot(orignal_tab(:,1),orignal_tab(:,3),'-.','LineWidth',1.25)

legend('lnn\_diff', 'dpcm2','dpcm1', 'original')

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

    if (data_ori(i)>=0)
        data_original_mapped(i) = 2*data_ori(i);
    else
        data_original_mapped(i) = -2*data_ori(i) - 1;
    end
end

figure(2)
lnn_diff_mapped_tab=tabulate(lnn_diff_mapped);
plot(lnn_diff_mapped_tab(:,1), lnn_diff_mapped_tab(:,3),'LineWidth',1.25)
hold on
data_dpcm2_mapped_tab=tabulate(data_dpcm2_mapped);
plot(data_dpcm2_mapped_tab(:,1), data_dpcm2_mapped_tab(:,3),'--','LineWidth',1.25)
hold on
data_dpcm1_mapped_tab=tabulate(data_dpcm1_mapped);
plot(data_dpcm1_mapped_tab(:,1), data_dpcm1_mapped_tab(:,3),':','LineWidth',1.25)
hold on
data_original_mapped_tab=tabulate(data_original_mapped);
plot(data_original_mapped_tab(:,1), data_original_mapped_tab(:,3),'-.','LineWidth',1.25)


legend('lnn\_diff\_mapped', 'dpcm2\_mapped','dpcm1\_mapped', 'original\_mapped')
% title(dataset_title)

CR_lnn_gc=adap_m_CR(lnn_diff_mapped, GC_group_size)
CR_dpcm2_gc=adap_m_CR(data_dpcm2_mapped, GC_group_size)
CR_dpcm1_gc=adap_m_CR(data_dpcm1_mapped, GC_group_size)
CR_original_gc=adap_m_CR(data_original_mapped, GC_group_size)

code=[CR_lnn_gc, net];