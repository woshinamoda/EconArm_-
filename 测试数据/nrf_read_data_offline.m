%���ߣ���ͨ����
%�����ʣ�500Hz
%���ݸ�ʽ����ͷ + EEG���� +У�� + �����
%BBAA + 24x9 + У��λ + ����� = 220�ֽ�
%EEG����ԭʼ����
%EMG_Sequence�������

clear;clc;
filename = '����ۻ���������ֻ�����17.txt';
% data=textread(filename,'%2c','delimiter','-');%%%�ֻ�App����
data=textread(filename,'%2c');%%%UartAssist.exe����
buff=hex2dec(data(:,:));
TT = reshape(buff,220,length(buff)/220);
EMG_CHANNEL=8;
emg_cnt_max=EMG_CHANNEL*3*9;%%%9����һ�����ݰ�

EMG_bytes=zeros(1,emg_cnt_max);%%%��¼һ֡���ֽ�����
emg_cnt_state=0;%%%��¼switch������״̬
emg_cnt_count=0;%%%ÿ�μ�����emg_cnt_maxΪֹ
emg_idx=1;


for index=1:length(buff)
        %-------EEG-----%
        switch(emg_cnt_state)
            case 0
                if(buff(index)==187) %0xBB
                    emg_cnt_state=1;
                else 
                    emg_cnt_state=0;
                end
            case 1
                if(buff(index)==170) %0xAA
                    emg_cnt_state=2;
                    emg_cnt_count=1;
                    emg_sumchkm = 0;
                elseif(buff(index)==187)%�ų�0xBB BB AA�����
                    emg_cnt_state=1;
                else
                    emg_cnt_state=0;
                end 
            case 2
                EMG_bytes(1,emg_cnt_count) = buff(index);
                emg_cnt_count = emg_cnt_count + 1;
                emg_sumchkm = emg_sumchkm + buff(index);
                if(emg_cnt_count == emg_cnt_max+1)%%�ж����ݽ����Ƿ����
                    emg_cnt_state=3;
                else
                    emg_cnt_state=2;
                end 
                
            case 3
                if(buff(index) == 0)%%���У��λ
                    emg_cnt_state=4;
                else
                    emg_cnt_state=0;
                end
            case 4
                EMG_Sequence(emg_idx,1) = buff(index);%%%��¼�����

                % ԭʼ���ݽ���%

                for i=1:9
                    for j=1:8
                       if(EMG_bytes(1,j*3-2+24*(i-1)) > 127)%%%��8λ�Ƿ�Ϊ1
                           EEG(j,(emg_idx-1)*9+i) = swapbytes(typecast(uint8([255 EMG_bytes((j*3-2+24*(i-1)):j*3+24*(i-1))]),'int32'));
                       else
                           EEG(j,(emg_idx-1)*9+i) = swapbytes(typecast(uint8([0   EMG_bytes((j*3-2+24*(i-1)):j*3+24*(i-1))]),'int32'));                       
                       end                         
                    end
                end
%                 EMG(emg_idx,1:8)=(EMG_frame-2048)/4096*3300000/2500;%%��ѹת��
                emg_idx = emg_idx + 1;
                emg_cnt_state=0;  % switch״̬�л�%
              

        end  
end

AA=diff(TT(220,:));
BB=find(AA~=1);
CC=diff(BB);
