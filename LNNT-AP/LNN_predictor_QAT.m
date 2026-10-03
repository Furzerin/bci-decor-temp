function code = LNN_predictor_QAT(LNN_data_d, LNN_data_a, LNN_taps, LNN_epochs)
% LNN_predictor_QAT: 使用trainNetwork + QAT进行线性预测
% 输入参数：
% - LNN_data_d: 数据集主目录名
% - LNN_data_a: 数据文件名
% - LNN_taps: 滑动窗口长度
% - LNN_epochs: 训练轮数

data_g = 'C';
data_d = LNN_data_d;
data_a = LNN_data_a;
dataset = append(data_g, data_d, data_a);
data_dir = fullfile(pwd, '\..\dataset\');
joint_path = append(data_dir, dataset);
load(joint_path); % 加载变量 data

% 构造训练样本（滑动窗口方式）
data_to_LNN = data(1:2000)';
XTrain = [];
YTrain = [];
for i = 1:(length(data_to_LNN) - LNN_taps)
    XTrain(end+1,:) = data_to_LNN(i:i+LNN_taps-1);
    YTrain(end+1,:) = data_to_LNN(i+LNN_taps);
end

% 构建训练数据集
dsX = arrayDatastore(XTrain, 'IterationDimension', 1);
dsY = arrayDatastore(YTrain, 'IterationDimension', 1);
ds = combine(dsX, dsY);

% 转换为列向量并打包为 {input, label}
ds = transform(ds, @(data) {data{1}.', data{2}});

% 构建网络结构
layers = [
    featureInputLayer(LNN_taps, 'Normalization','none', 'Name', 'input')
    fullyConnectedLayer(1, 'Name', 'fc')
    regressionLayer('Name', 'output')];


lgraph = layerGraph(layers);

% 设置训练参数，关闭正则化
options = trainingOptions('adam', ...
    'MaxEpochs', LNN_epochs, ...
    'MiniBatchSize', 32, ...
    'Shuffle', 'every-epoch', ...
    'L2Regularization', 0, ...
    'Verbose', false);

% 初步训练网络
net = trainNetwork(ds, lgraph, options);

% QAT 量化准备
calData = arrayDatastore(XTrain(1:500,:), 'IterationDimension', 1);
% qOpts = quantizationOptions('QuantizationMethod', 'qat', ...
%                             'BitPrecision', struct('Weights',8,'Bias',8,'Activations',8));
qNet = quantizeNetwork(net, calData, ...
    'ExecutionEnvironment', 'cpu', ...
    'QuantizationMethod', 'qat');

% 可选：继续训练 QAT 网络
qNet = trainNetwork(ds, qNet, options);

% 推理
YPred = predict(qNet, XTrain);

% 可视化
figure;
plot(YTrain, 'b'); hold on;
plot(YPred, 'r--');
legend('Ground Truth', 'QAT Prediction');
title('QAT Output vs True');

for i=1:length(lnn_diff)
    if (lnn_diff(i)>=0)
        YPred_mapped(i) = 2*YPred(i);
    else
        YPred_mapped(i) = -2*YPred(i)-1;
    end
end
CR_lnn_gcv2=adap_m_CR(lnn_diff_mapped, 50000)


% 返回模型与预测结果
code = {qNet, YPred_mapped};

end
