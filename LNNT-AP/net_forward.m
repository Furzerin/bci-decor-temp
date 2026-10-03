function code = net_forward(data,taps,IW,b)
Y=[];
for k=1:taps
    Y=[Y,data(k)];
end
for k=(taps+1):(length(data))
    sum=0.0;
    for j=1:taps
        sum=sum+data(k-taps+j-1)*IW(taps-j+1);
    end
    sum=sum+b;
    %k
    Y=[Y,sum];
    if k==1440000
        break;
    end
end

code = Y;