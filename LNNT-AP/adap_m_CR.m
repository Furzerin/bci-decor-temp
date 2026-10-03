%get adaptive parameter m for golomb code and calculate CR
%input:
%   data:one channel data in this paper is the root reference channel and
%   other ec hat
%   delta: groupsize to update m
%output: compression ratio
function CR = adap_m_CR(data,delta)
      L = 0;
     
    for group=1:delta:((length(data)-delta)+1)
        data_dpcm_group=data(1,group:(group+delta-1));
        tab_data=tabulate(data_dpcm_group);
        [row_0,col_0]=find(tab_data==0.000);
        percent = tab_data(row_0,3);
         
        if percent<5.1
            m=9;
        elseif percent<7.4
            m=8;
        elseif percent<8.26
            m=7;
        elseif percent<9.15
            m=6;
        elseif percent<9.66
            m=5;
        elseif percent<10.52
            m=7;
        elseif percent<12.28
            m=8;
        elseif percent<12.69
            m=7;
        elseif percent<13.05
            m=6;
        elseif percent<13.86
            m=5;
        elseif percent<16.51
            m=4;  
        else
            m=3;
        end
    j=1;
    for j=1:length(data_dpcm_group)
        code = golomb_enco(data_dpcm_group(j),m);
        L = L+length(code);   
    end  
    end
    CR=(1-L/(length(data)*9))*100; 
end