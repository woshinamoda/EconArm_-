clear
clc

delete(instrfindall);
scom = 'COM5';                 %���崮������
Baudrate = 921600;              %���ڲ�����
b = serial(scom);
b.InputBufferSize=2500;

set(b,'BaudRate',Baudrate);     %%%���ô��ڲ�����
fopen(b);                       %%%��serial����
pause(1)


EMG_CHANNEL=8;                      %%����8��ͨ��
emg_cnt_max=EMG_CHANNEL*3*9;        %%����һ����������4ch x 3 x 18 = 216

EMG_bytes=zeros(1,emg_cnt_max);     %%����һ��1��.4chn * 3bytes * 18pot�е�.����
                                    
emg_cnt_state=0;                    %%��ȡ����ǰ״ֵ̬
emg_cnt_count=0;                    %%��ȡ��������countֵ
emg_idx=1;                          %%emg���Զ�+1

EMG_frame=zeros(EMG_CHANNEL,9);     %%����һ��8��(chn)��9�е�.����

result_emg=zeros(EMG_CHANNEL,2502); %%����һ��8��(chn)��2502�е��.����

result_emg_idx=1;                   %%
% fs=1000;
% fn = 50;
% Q = 5;
% Wo = fn/(fs/2);
% BW = Wo/Q;
% [NT_b, NT_a] = iirnotch(Wo, BW);





fig=figure();
hold on;
for k=1:8                                                         %%%forѭ�� k �� .1.ѭ����.8.
    subplot(4,2,k);                                               %%%��ͼ�ηָ�Ϊ4��2�е����䣬ÿ����Ӧ��kָ��λ�ô���������
    
        
    line_EMG{k}=plot((1:size(result_emg,2))/500,result_emg(k,:)); %%%����һ��cell����line_EMG,��������ÿ�����ڵĺ�������
    %%%�����꣺size(result_emg,2) ȡ����result_emg������,����500���൱�ں������������1ѭ������
    %%%�����꣺result_emg�����е�����Ԫ�ء�                                                                  

%      ylim([-3300000/2/2500,3300000/2/2500])                      %%% y�����ƣ���ʱ������
% 
%     ylim([-70,70])
    ylabel('�����ѹ(uV)');
    xlim([0,size(result_emg,2)/500])                               %%% x�����ƣ�0 ->�� ����result_emg�� ���� 500
    xlabel('ʱ��(s)');                                             %%% ���� 500HZ�������£���Ӧ5sec
end
drawnow();                                                         %%%���ˣ�����������ô���һ��2x4��ͼ�ν���



while true%%while��1��                                             %%% ѭ����ͼ
    [buff,count]=fread(b,1000,'uint8');                            %%% fread(fileID, sizeA, precision)
                                                                   %%% ���ݴ���buff���ַ�����count    
                                                                   
% emg_cnt_state����ȡ����״̬��  0����ʼ��BB  1����ʼ��AA   2����ʼ��������  3���鿴У��λ     4��
% emg_cnt_count����ȡ����������
% emg_sumchkm  ��EMG�����ܺͣ�



    for index=1:length(buff)                                       %%% ѭ����1 -> 1000                                        
        switch(emg_cnt_state)                                      %%% �ж��ֽ�ʶ��״̬
            case 0                                                 %%% 0����Ѱ��ͷ��һ����
                if(buff(index)==187) %0xBB                        
                    emg_cnt_state=1;                              
                else 
                    emg_cnt_state=0;
                end
            case 1                                                  %%% �ҵ�ͷ��һ���ֺ� 1����Ѱ��ͷ�ڶ�����
                if(buff(index)==170) %0xAA
                    emg_cnt_state=2;                                %%% �ҵ���״̬��Ϊ��ʼ��ȡ����
                    emg_cnt_count=1;                                %%% emg���������� = 1
                    emg_sumchkm = 0;                                %%% emg_sumchkm��0
                elseif(buff(index)==187)                            %%% ���BB�����ֶ���BB�����»ָ�����AA��״̬
                    emg_cnt_state=1;                                
                else
                    emg_cnt_state=0;                                
                end               
            case 2                                                  %%% ��ʼ��������
                EMG_bytes(1,emg_cnt_count) = buff(index);           %%% ���ݴ�ŵ�EMG_bytes��
                emg_cnt_count = emg_cnt_count + 1;                  %%% countλ++
                emg_sumchkm = emg_sumchkm + buff(index);            %%% ��¼��ȡ����EMG����
                if(emg_cnt_count == emg_cnt_max+1)                  %%% �����ȡ���㹻����
                    emg_cnt_state=3;                                %%% ת��state=3������У��λ�Ƿ�Ϊ0
                else
                    emg_cnt_state=2;                                %%% û�ж����ͼ�����ȡ����
                 end    
            case 3
                if(buff(index) == 0)                                %%% ��ȡ��У��λ��0
                    emg_cnt_state=4;
                else
                    emg_cnt_state=0;
                end
            case 4
                EMG_Sequence(emg_idx,1) = buff(index);              %%% �Զ�+1���ݴ��ݵ�����EMG_Sequence����
             

% % %      ������һ���ֽ���ƴ��          
%%%        C���Դ�������
%%%        �ж�boardChannelDataInt[i] == 0x00800000
%%%        YES : boardChannelDataInt[i] |= 0xFF000000
%%%        NO  ��boardChannelDataInt[i] &= 0x00FFFFFF

                for i=1:9
                    for j=1:8
                        if(EMG_bytes(1,j*3-2+24*(i-1)) > 127)       %%% 216���ֽڣ�ÿ3���ֽ�һ��j����Ӧ8��ͨ����ת��
                           EMG_frame(j,i) = swapbytes(typecast(uint8([255 EMG_bytes((j*3-2+24*(i-1)):j*3+24*(i-1))]),'int32'));
                       else
                           EMG_frame(j,i) = swapbytes(typecast(uint8([0   EMG_bytes((j*3-2+24*(i-1)):j*3+24*(i-1))]),'int32'));                 
                       end                         
                    end
                end

                
                EMG(1:8,(emg_idx-1)*9+1:emg_idx*9) = EMG_frame;
                emg_idx = emg_idx + 1;
                emg_cnt_state=0;  % switch状�?�切�?%

    
                % ת��uV
                result_emg(:,(result_emg_idx-1)*9+1:result_emg_idx*9)=EMG_frame*0.02235174;
%                 if result_emg_idx == 278  %%%278*9=2502
%                     result_emg=zeros(EMG_CHANNEL,2502);
%                 end
                result_emg_idx=mod(result_emg_idx,278)+1;  
        end
    end
    %%���»�ͼ
    for k=1:8
%         result_emg(k,:) = filtfilt(NT_b, NT_a, result_emg(k,:));
        set(line_EMG{k},'YData',result_emg(k,:));
    end
    drawnow();   

end

AA = diff(EMG_Sequence);            %%%AA�Զ�+1ǰ��ݼ�
BB=find(AA~=1);                     %%%����ǰ��ݼ���û�в�����1��
CC=diff(BB);                        

%%/***************����ʾֵ׼ȷ�ȵĴ���******************************/
Test_Data = EMG(8,:);                %%%��8�е���ժ����
Test_Data = Test_Data(:);            %%%�ڵ���ת������,���˵õ�������һ�в������ݲ���
Test_Data = Test_Data * 0.02235174;  %%%ת���ɷ�ֵ
Time_min = size(Test_Data,1)*2/1000/60;
Time_sec = size(Test_Data,1)*2/1000;
%%%save('10uv��������')



%%%*************************************************************
%%% ���ƴ��д�������ͼ
c = findpeaks(Test_Data(:,1));
IndMin = find(diff(sign(diff(Test_Data(:,1))))>0)+1;
IndMax = find(diff(sign(diff(Test_Data(:,1))))<0)+1;
figure; hold on; box on;
plot(1:length(Test_Data(:,1)),Test_Data(:,1));
plot(IndMin,Test_Data(IndMin),'r^')
plot(IndMax,Test_Data(IndMax),'k*')
legend('����','���ȵ�','�����')
title('������ɢ�ڵ�Ĳ��岨����Ϣ','FontWeight','Bold');

%%% ���������ݵ���
for k=1:length(IndMin) 
text(IndMin(k),Test_Data(IndMin(k)),num2str(Test_Data(IndMin(k))),'color','r')
end

%%%���������ݵ���
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








%%%%**********************��������Ƶ��Ƶ�ʲ���*******************************
fs = 1000;
frequencyBand = [0.1, 200];%��ͨ�˲�����
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
plot(t,Signal1);%����ʱ����

grid;
figure(2)
plot(f,abs(FFT_Signal1(1:round(N/2)))/4096);%����Ƶ����





