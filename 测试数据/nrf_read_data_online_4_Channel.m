clear
clc

delete(instrfindall);
scom = 'COM39';                 %���崮������
Baudrate = 921600;              %���ڲ�����
b = serial(scom);
b.InputBufferSize=2500;

set(b,'BaudRate',Baudrate);     %%%���ô��ڲ�����
fopen(b);                       %%%��serial����
pause(1)


EMG_CHANNEL=4;                      %%����8��ͨ��
emg_cnt_max=EMG_CHANNEL*3*18;        %%����һ����������4ch x 3 x 18 = 216

EMG_bytes=zeros(1,emg_cnt_max);     %%����һ��1��.4chn * 3bytes * 18pot�е�.����
                                    
emg_cnt_state=0;                    %%��ȡ����ǰ״ֵ̬
emg_cnt_count=0;                    %%��ȡ��������countֵ
emg_idx=1;                          %%emg���Զ�+1

EMG_frame=zeros(EMG_CHANNEL,18);     %%����һ��4��(chn)��18�е�.����

result_emg=zeros(EMG_CHANNEL,5004); %%����һ��4��(chn)��2502�е��.����

result_emg_idx=1;                   %%


fig=figure();
hold on;
for k=1:4                                                         %%%forѭ�� k �� .1.ѭ����.8.
    subplot(4,1,k);                                               %%%��ͼ�ηָ�Ϊ2��2�е����䣬ÿ����Ӧ��kָ��λ�ô���������
    
        
    line_EMG{k}=plot((1:size(result_emg,2))/1000,result_emg(k,:)); %%%����һ��cell����line_EMG,��������ÿ�����ڵĺ�������
                                               

%      ylim([-3300000/2/2500,3300000/2/2500])                       %%% y�����ƣ���ʱ������

%     ylim([-150,-20])
    ylabel('�����ѹ(uV)');
    xlim([0,size(result_emg,2)/1000])                              %%% x�����ƣ�0 ->�� ����result_emg�� ���� 1000
    xlabel('ʱ��(s)');                                             %%% ���� 1000HZ�������£���Ӧ5sec
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

                for i=1:18
                    for j=1:4
                        if(EMG_bytes(1,j*3-2+12*(i-1)) > 127)       %%% 216���ֽڣ�ÿ3���ֽ�һ��j����Ӧ8��ͨ����ת��
                           EMG_frame(j,i) = swapbytes(typecast(uint8([255 EMG_bytes((j*3-2+12*(i-1)):j*3+12*(i-1))]),'int32'));
                       else
                           EMG_frame(j,i) = swapbytes(typecast(uint8([0   EMG_bytes((j*3-2+12*(i-1)):j*3+12*(i-1))]),'int32'));                 
                       end                         
                    end
                end
                
% % %           ��Frame�����˲�     
%                 for i=1:8
%                     EMG_frame(i,:) = filtfilt(NT_b, NT_a, double(EMG_frame(i,:)));
%                 end
                
                
                EMG(1:4,(emg_idx-1)*18+1:emg_idx*18) = EMG_frame;
                emg_idx = emg_idx + 1;
                emg_cnt_state=0;  % switch状�?�切�?%

    
                % ת��uV
                result_emg(:,(result_emg_idx-1)*18+1:result_emg_idx*18)=EMG_frame*0.02235174;
%                 if result_emg_idx == 278  %%%278*18=5004
%                     result_emg=zeros(EMG_CHANNEL,5004);
%                 end
                result_emg_idx=mod(result_emg_idx,278)+1;  
        end
    end
    %%���»�ͼ
    for k=1:4
%         result_emg(k,:) = filtfilt(NT_b, NT_a, result_emg(k,:));
        set(line_EMG{k},'YData',result_emg(k,:));
    end
    drawnow();   

end

                       

%%/***************����ʾֵ׼ȷ�ȵĴ���******************************/
Test_Data = EMG(1,:);                %%%��8�е���ժ����
Test_Data = Test_Data(:);            %%%�ڵ���ת������,���˵õ�������һ�в������ݲ���
Test_Data = Test_Data * 0.02235174;  %%%ת���ɷ�ֵ
Time_min = size(Test_Data,1)*1/1000/60;
Time_sec = size(Test_Data,1)*1/1000;
Test_Data = Test_Data(600:end,:);
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





%%%%%%%%******************************************************���������õ�������%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
test_number = 300                    %%%ʵ�ʲ��Ե���
peak_valley=zeros(test_number,1);    %%%���ֵ��Ҳ��Ϊ���εķ�ֵ
Vrms = 0;                            %%%����������ֵ
uVpp = 0;                            %%%��������ֵ
for calcuator=1:test_number
    peak_count = calcuator;
    peak_valley(calcuator,:) = Test_Data(IndMax(peak_count)) - Test_Data(IndMin(peak_count));   %%%����<-->��������
    
    uVpp = uVpp + peak_valley(calcuator,:); 
end

uVpp = uVpp/test_number;        %%%���з�ֵ����ƽ���õ�����Vpp
% Vrms = sqrtm(Vrms);
    
for rms_cout=1:999      %%%
    Vrms = Vrms + (peak_valley(rms_cout+1,:) - peak_valley(rms_cout,:))^2;
end
Vrms = Vrms/999;
Vrms = sqrtm(Vrms);















%%/***************�Զ�+1ǰ��ݼ���������û�ж�����******************************/
AA = diff(EMG_Sequence);            %%%AA�Զ�+1ǰ��ݼ�
BB=find(AA~=1);                     %%%����ǰ��ݼ���û�в�����1��
CC=diff(BB); 







%%%%**********************��������Ƶ��Ƶ�ʲ���*******************************
fs = 1000;
frequencyBand = [5, 400];                           %%��ͨ�˲�����
order = 4;                                          %%��ͨ�˲������������ƽ�ֹƵ�ʵ��½��ٶȣ���б�ȣ�
Wn = [frequencyBand(1), frequencyBand(2)]/(fs/2);   %%��ֹƵ��
[BP_b, BP_a] = butter(order, Wn);                   %%
% notch filter
fn = 50;
Q = 5;
Wo = fn/(fs/2);
BW = Wo/Q;
[NT_b, NT_a] = iirnotch(Wo, BW);

bandpassedData = filtfilt(BP_b, BP_a, Test_Data);  %%���˲�������1������2�� ��Ҫ�˲����ݣ�Ҫ�����е���ʽ����  ��ͨ�˲�
filteredData = filtfilt(NT_b, NT_a, bandpassedData);        %% ����

Signal1 = filteredData;                                     %% ���겨�Ժ�Ĳ���

%%%-------------------------------��ͼ����1-----------------
N =length(Signal1);
t =(0:N-1)/fs;
FFT_Signal1 = fft(Signal1);
f = fs/N*(0:round(N/2)-1);
figure(1)
plot(t,Signal1);%����ʱ����
%%%-------------------------------��ͼ����2-----------------
grid;
figure(2)
plot(f,abs(FFT_Signal1(1:round(N/2)))/4096);%����Ƶ����





