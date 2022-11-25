clear
clc

delete(instrfindall);
scom = 'COM5';                 %定义串口名称
Baudrate = 921600;              %串口波特率
b = serial(scom);
b.InputBufferSize=2500;

set(b,'BaudRate',Baudrate);     %%%设置串口波特率
fopen(b);                       %%%打开serial串口
pause(1)


EMG_CHANNEL=8;                      %%定义8个通道
emg_cnt_max=EMG_CHANNEL*3*9;        %%定义一包最大点数，4ch x 3 x 18 = 216

EMG_bytes=zeros(1,emg_cnt_max);     %%定义一个1行.4chn * 3bytes * 18pot列的.阵列
                                    
emg_cnt_state=0;                    %%读取到当前状态值
emg_cnt_count=0;                    %%读取到的数据count值
emg_idx=1;                          %%emg的自动+1

EMG_frame=zeros(EMG_CHANNEL,9);     %%生成一个8行(chn)，9列的.阵列

result_emg=zeros(EMG_CHANNEL,2502); %%生成一个8行(chn)，2502列点的.阵列

result_emg_idx=1;                   %%
% fs=1000;
% fn = 50;
% Q = 5;
% Wo = fn/(fs/2);
% BW = Wo/Q;
% [NT_b, NT_a] = iirnotch(Wo, BW);





fig=figure();
hold on;
for k=1:8                                                         %%%for循环 k 从 .1.循环到.8.
    subplot(4,2,k);                                               %%%将图形分割为4行2列的区间，每个对应的k指定位置创建坐标区
    
        
    line_EMG{k}=plot((1:size(result_emg,2))/500,result_emg(k,:)); %%%定义一个cell数组line_EMG,用来保存每个窗口的横纵坐标
    %%%横坐标：size(result_emg,2) 取阵列result_emg的列数,除以500。相当于横坐标点数，从1循环绘制
    %%%纵坐标：result_emg所在行的所有元素。                                                                  

%      ylim([-3300000/2/2500,3300000/2/2500])                      %%% y轴限制，暂时无限制
% 
%     ylim([-70,70])
    ylabel('输出电压(uV)');
    xlim([0,size(result_emg,2)/500])                               %%% x轴限制，0 ->到 矩阵result_emg列 除以 500
    xlabel('时间(s)');                                             %%% 计算 500HZ采样率下，对应5sec
end
drawnow();                                                         %%%至此，上面代码作用创建一个2x4的图形界面



while true%%while（1）                                             %%% 循环绘图
    [buff,count]=fread(b,1000,'uint8');                            %%% fread(fileID, sizeA, precision)
                                                                   %%% 数据存于buff，字符数量count    
                                                                   
% emg_cnt_state（读取数组状态）  0：开始找BB  1：开始找AA   2：开始保存数据  3：查看校验位     4：
% emg_cnt_count（读取数组数量）
% emg_sumchkm  （EMG数据总和）



    for index=1:length(buff)                                       %%% 循环从1 -> 1000                                        
        switch(emg_cnt_state)                                      %%% 判断字节识别状态
            case 0                                                 %%% 0代表寻找头第一个字
                if(buff(index)==187) %0xBB                        
                    emg_cnt_state=1;                              
                else 
                    emg_cnt_state=0;
                end
            case 1                                                  %%% 找到头第一个字后， 1代表寻找头第二个字
                if(buff(index)==170) %0xAA
                    emg_cnt_state=2;                                %%% 找到后状态改为开始读取数据
                    emg_cnt_count=1;                                %%% emg输出数量旗标 = 1
                    emg_sumchkm = 0;                                %%% emg_sumchkm清0
                elseif(buff(index)==187)                            %%% 如果BB后面又读到BB，重新恢复到找AA的状态
                    emg_cnt_state=1;                                
                else
                    emg_cnt_state=0;                                
                end               
            case 2                                                  %%% 开始保存数据
                EMG_bytes(1,emg_cnt_count) = buff(index);           %%% 数据存放到EMG_bytes中
                emg_cnt_count = emg_cnt_count + 1;                  %%% count位++
                emg_sumchkm = emg_sumchkm + buff(index);            %%% 记录读取到的EMG数量
                if(emg_cnt_count == emg_cnt_max+1)                  %%% 如果读取到足够数量
                    emg_cnt_state=3;                                %%% 转到state=3，看下校验位是否为0
                else
                    emg_cnt_state=2;                                %%% 没有读够就继续读取数据
                 end    
            case 3
                if(buff(index) == 0)                                %%% 读取到校验位是0
                    emg_cnt_state=4;
                else
                    emg_cnt_state=0;
                end
            case 4
                EMG_Sequence(emg_idx,1) = buff(index);              %%% 自动+1数据传递到矩阵EMG_Sequence当中
             

% % %      下面这一部分进行拼接          
%%%        C语言代码如下
%%%        判断boardChannelDataInt[i] == 0x00800000
%%%        YES : boardChannelDataInt[i] |= 0xFF000000
%%%        NO  ：boardChannelDataInt[i] &= 0x00FFFFFF

                for i=1:9
                    for j=1:8
                        if(EMG_bytes(1,j*3-2+24*(i-1)) > 127)       %%% 216个字节，每3个字节一个j，对应8个通道的转换
                           EMG_frame(j,i) = swapbytes(typecast(uint8([255 EMG_bytes((j*3-2+24*(i-1)):j*3+24*(i-1))]),'int32'));
                       else
                           EMG_frame(j,i) = swapbytes(typecast(uint8([0   EMG_bytes((j*3-2+24*(i-1)):j*3+24*(i-1))]),'int32'));                 
                       end                         
                    end
                end

                
                EMG(1:8,(emg_idx-1)*9+1:emg_idx*9) = EMG_frame;
                emg_idx = emg_idx + 1;
                emg_cnt_state=0;  % switch鐘舵?佸垏鎹?%

    
                % 转换uV
                result_emg(:,(result_emg_idx-1)*9+1:result_emg_idx*9)=EMG_frame*0.02235174;
%                 if result_emg_idx == 278  %%%278*9=2502
%                     result_emg=zeros(EMG_CHANNEL,2502);
%                 end
                result_emg_idx=mod(result_emg_idx,278)+1;  
        end
    end
    %%更新绘图
    for k=1:8
%         result_emg(k,:) = filtfilt(NT_b, NT_a, result_emg(k,:));
        set(line_EMG{k},'YData',result_emg(k,:));
    end
    drawnow();   

end

AA = diff(EMG_Sequence);            %%%AA自动+1前后递减
BB=find(AA~=1);                     %%%看看前后递减有没有不等于1的
CC=diff(BB);                        

%%/***************测试示值准确度的代码******************************/
Test_Data = EMG(8,:);                %%%第8列单独摘出来
Test_Data = Test_Data(:);            %%%在单独转换行列,至此得到完整的一列测试数据波形
Test_Data = Test_Data * 0.02235174;  %%%转换成幅值
Time_min = size(Test_Data,1)*2/1000/60;
Time_sec = size(Test_Data,1)*2/1000;
%%%save('10uv测试数据')



%%%*************************************************************
%%% 绘制带有打标的数据图
c = findpeaks(Test_Data(:,1));
IndMin = find(diff(sign(diff(Test_Data(:,1))))>0)+1;
IndMax = find(diff(sign(diff(Test_Data(:,1))))<0)+1;
figure; hold on; box on;
plot(1:length(Test_Data(:,1)),Test_Data(:,1));
plot(IndMin,Test_Data(IndMin),'r^')
plot(IndMax,Test_Data(IndMax),'k*')
legend('曲线','波谷点','波峰点')
title('计算离散节点的波峰波谷信息','FontWeight','Bold');

%%% 给波谷数据点打标
for k=1:length(IndMin) 
text(IndMin(k),Test_Data(IndMin(k)),num2str(Test_Data(IndMin(k))),'color','r')
end

%%%给波峰数据点打标
for k=1:length(IndMax) 
text(IndMax(k),Test_Data(IndMax(k)),num2str(Test_Data(IndMax(k))),'color','b')
end

AVE_Max = 0;
AVE_Min = 0;
for k = 100:149
   AVE_Max = AVE_Max + Test_Data(IndMax(k))
   AVE_Min = AVE_Min + Test_Data(IndMin(k))
end
AVE_Max = AVE_Max/50;
AVE_Min = AVE_Min/50;
AVE_voltage = AVE_Max - AVE_Min;








%%%%**********************徐瑶做的频域频率测试*******************************
fs = 1000;
frequencyBand = [0.1, 200];%带通滤波参数
order = 4;
Wn = [frequencyBand(1), frequencyBand(2)]/(fs/2);
[BP_b, BP_a] = butter(order, Wn);
% notch filter
fn = 50;
Q = 5;
Wo = fn/(fs/2);
BW = Wo/Q;
[NT_b, NT_a] = iirnotch(Wo, BW);

bandpassedData = filtfilt(BP_b, BP_a, double(Test_Data'));
filteredData = filtfilt(NT_b, NT_a, bandpassedData); 

Signal1 = filteredData;%eeg noise test
N =length(Signal1);
t =(0:N-1)/fs;
FFT_Signal1 = fft(Signal1);
f = fs/N*(0:round(N/2)-1);
figure(1)
plot(t,Signal1);%绘制时域波形

grid;
figure(2)
plot(f,abs(FFT_Signal1(1:round(N/2)))/4096);%绘制频域波形





