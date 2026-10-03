function code = LNN_analyzer(LNN_data_d,LNN_data_a,LNN_taps,LNN_epochs)

%clearvars
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
data_r = data_r/128;

format long

% normalize
if pre_norm == true
    data_n=normalize(data, 'range', [-1 255/256]);
else
    data_n=data;
end

data_to_LNN=data_r(1:2000);
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

% net.IW
% net.b

file_int8=quanti(data_d,data_a,taps,net.trainParam.epochs,net.IW,net.b,2,5);
file_int12=quanti(data_d,data_a,taps,net.trainParam.epochs,net.IW,net.b,2,9);
file_int16=quanti(data_d,data_a,taps,net.trainParam.epochs,net.IW,net.b,4,11);
file_int32=quanti(data_d,data_a,taps,net.trainParam.epochs,net.IW,net.b,8,23);
file_original=net_data(data_d,data_a,taps,net.trainParam.epochs,net.IW,net.b);

%code=[net.IW,net.b,file_int8,file_int16,file_int32,file_original];
code=["CNM","RNM",file_int8,file_int16,file_int32,file_original,file_int12];