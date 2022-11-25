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
result_emg_idx=1;                   

%%%%%===================================================IMU设置声明=============================================================
IMU_CHANNEL = 6;                        %%% 加速度通道数
IMU_frame = zeros(IMU_CHANNEL,1);         %%% 6个通道1个点

result_imu=zeros(IMU_CHANNEL,500);
imu_idx=1;
result_imu_idx=1; 

imu_cnt_max = IMU_CHANNEL*2*1;      %%%6chn x  2bytes  x 1
IMU_bytes=zeros(1,imu_cnt_max); 

imu_cnt_count = 0;








fig=figure();
hold on;
for k=1:8                                                         %%%for循环 k 从 .1.循环到.8.
    subplot(6,2,k);                                               %%%将图形分割为4行2列的区间，每个对应的k指定位置创建坐标区
    
        
    line_EMG{k}=plot((1:size(result_emg,2))/500,result_emg(k,:)); %%%定义一个cell数组line_EMG,用来保存每个窗口的横纵坐标
    %%%横坐标：size(result_emg,2) 取阵列result_emg的列数,除以500。相当于横坐标点数，从1循环绘制
    %%%纵坐标：result_emg所在行的所有元素。                                                                  

%      ylim([-3300000/2/2500,3300000/2/2500])                      %%% y轴限制，暂时无限制
    ylabel('输出电压(uV)');
    xlim([0,size(result_emg,2)/500])                               %%% x轴限制，0 ->到 矩阵result_emg列 除以 500
    xlabel('时间(s)');                                             %%% 计算 500HZ采样率下，对应5sec
end

subplot(6,2,[9,10]);
line_ACC{1}=plot((1:size(result_imu,2))/100,result_imu(1,:),'b');
hold on;
line_ACC{2}=plot((1:size(result_imu,2))/100,result_imu(2,:),'g');
hold on;
line_ACC{3}=plot((1:size(result_imu,2))/100,result_imu(3,:),'r');
% ylim([-2000,2000])
ylabel('加速度(mg)');
% xlim([0,size(result_acc,1)/100])                           
xlabel('时间(s)'); 


subplot(6,2,[11,12]);
line_GRY{1}=plot((1:size(result_imu,2))/100,result_imu(4,:),'b');
hold on;
line_GRY{2}=plot((1:size(result_imu,2))/100,result_imu(5,:),'g');
hold on;
line_GRY{3}=plot((1:size(result_imu,2))/100,result_imu(6,:),'r');
% ylim([-2000,2000])
ylabel('角速度(mdps)');
% xlim([0,size(result_acc,1)/100])                           
xlabel('时间(s)'); 

drawnow();                                                         %%%至此，上面代码作用创建一个2x6的图形界面

while true%%while（1）                                             %%% 循环绘图
    [buff,count]=fread(b,1000,'uint8');                            %%% fread(fileID, sizeA, precision)
                                                                   %%% 数据存于buff，字符数量count    
                                                                   
% emg_cnt_state（读取数组状态）  0：开始找BB  1：开始找AA   2：开始保存数据  3：查看校验位     4：
% emg_cnt_count（读取数组数量）
% emg_sumchkm  （EMG数据总和）



    for index=1:length(buff)                                       %%% 循环从1 -> 1000                                        
        switch(emg_cnt_state)                                      %%% 判断字节识别状态
            case 0 %%% 0代表寻找头第一个字
                if(buff(index)==187) %0xBB                        
                    emg_cnt_state=1;                              
                else 
                    emg_cnt_state=0;
                end
            case 1 %%% 找到头第一个字后， 1代表寻找头第二个字
                if(buff(index)==170) %0xAA
                    emg_cnt_state=2;                                %%% 找到后状态改为开始读取数据
                elseif(buff(index)==187)                            %%% 如果BB后面又读到BB，重新恢复到找AA的状态
                    emg_cnt_state=1;                                
                else
                    emg_cnt_state=0;                                
                end   
            case 2 %%%判断长度
                if(buff(index)==233) %0xE9 带IMU
                    emg_cnt_state = 3;
                    emg_cnt_count=1;                                %%% emg输出数量旗标 = 1
                    emg_sumchkm = 0;                                %%% emg_sumchkm清0      
                elseif(buff(index)==221)%0xDD 只有EMG，不带IMU
                    emg_cnt_state = 0;
                else
                    emg_cnt_state = 0;
                end
            case 3 %%% 一直读，读完EMG数据 216个
                EMG_bytes(1,emg_cnt_count) = buff(index);           %%% 数据存放到EMG_bytes中
                emg_cnt_count = emg_cnt_count + 1;                  %%% count位++
                emg_sumchkm = emg_sumchkm + buff(index);            %%% 记录读取到的EMG数量
                if(emg_cnt_count == emg_cnt_max+1)                  %%% 如果读取到足够数量
                    emg_cnt_state=4;           %%% 转到state=4,开始读取IMU数据
                    imu_cnt_count = 1;
                    imu_sumchkm = 0;
                else
                    emg_cnt_state=3;                                %%% 没有读够就继续读取EMG信号
                end    
            case 4 %%% 一直读，读完IMU数据12个
                IMU_bytes(1,imu_cnt_count) = buff(index); 
                imu_cnt_count = imu_cnt_count + 1;
                imu_sumchkm = imu_sumchkm + buff(index); 
                if(imu_cnt_count == imu_cnt_max+1)
                    emg_cnt_state = 5;         %%%读取完数据，准备开始识别校验位
                else
                    emg_cnt_state = 4;
                end
            case 5
                if(buff(index) == 0)                                %%% 读取到校验位是0
                    emg_cnt_state=6;
                else
                    emg_cnt_state=0;
                end
            case 6
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
                 emg_cnt_state=0;  % switch结束
                % 转换uV
                result_emg(:,(result_emg_idx-1)*9+1:result_emg_idx*9)=EMG_frame*0.02235174;
%                 if result_emg_idx == 278  %%%278*9=2502
%                     result_emg=zeros(EMG_CHANNEL,2502);
%                 end
                result_emg_idx=mod(result_emg_idx,278)+1;  
                
                
                 for j = 1:6
                    IMU_frame(j,1) = typecast(uint8(IMU_bytes(j*2-1:j*2)),'int16');
                 end
                 IMU(1:6,imu_idx) = IMU_frame;
                 imu_idx = imu_idx + 1;
                   %数据存入result_imu
                  result_imu(:,result_imu_idx) = IMU_frame;
                  if(result_imu_idx == 500)
                      result_imu = ones(IMU_CHANNEL,500);
                  end
                  result_imu_idx = mod(result_imu_idx,500)+1;
                  
                  
                 
                 

        end
    end
    %%更新绘图
    for k=1:8
%         result_emg(k,:) = filtfilt(NT_b, NT_a, result_emg(k,:));
        set(line_EMG{k},'YData',result_emg(k,:));
    end
    
    set(line_ACC{1},'YData',result_imu(1,:));
    set(line_ACC{2},'YData',result_imu(2,:));
    set(line_ACC{3},'YData',result_imu(3,:));    
    
    set(line_GRY{1},'YData',result_imu(4,:));
    set(line_GRY{2},'YData',result_imu(5,:));
    set(line_GRY{3},'YData',result_imu(6,:));      
%     
    
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





