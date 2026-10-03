function NR = normalization(data,num)
    pos_fact=255/max(data);
    neg_fact=-256/min(data);
    if (pos_fact >= neg_fact)
        data_r = round(data*neg_fact);
    else
        data_r = round(data*pos_fact);
    end
    NR = data_r(1:num);
end