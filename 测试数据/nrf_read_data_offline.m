%作者：念通智能
%采样率：500Hz
%数据格式：包头 + EEG数据 +校验 + 包序号
%BBAA + 24x9 + 校验位 + 包序号 = 220字节
%EEG：存原始数据
%EMG_Sequence：包序号

clear;clc;
filename = '朝旭臂环检测间测试手机测试17.txt';
% data=textread(filename,'%2c','delimiter','-');%%%手机App接收
data=textread(filename,'%2c');%%%UartAssist.exe接收
buff=hex2dec(data(:,:));
TT = reshape(buff,220,length(buff)/220);
EMG_CHANNEL=8;
emg_cnt_max=EMG_CHANNEL*3*9;%%%9个点一个数据包

EMG_bytes=zeros(1,emg_cnt_max);%%%记录一帧的字节数据
emg_cnt_state=0;%%%记录switch函数的状态
emg_cnt_count=0;%%%每次计数到emg_cnt_max为止
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
                elseif(buff(index)==187)%排除0xBB BB AA的情况
                    emg_cnt_state=1;
                else
                    emg_cnt_state=0;
                end 
            case 2
                EMG_bytes(1,emg_cnt_count) = buff(index);
                emg_cnt_count = emg_cnt_count + 1;
                emg_sumchkm = emg_sumchkm + buff(index);
                if(emg_cnt_count == emg_cnt_max+1)%%判断数据接收是否结束
                    emg_cnt_state=3;
                else
                    emg_cnt_state=2;
                end 
                
            case 3
                if(buff(index) == 0)%%检查校验位
                    emg_cnt_state=4;
                else
                    emg_cnt_state=0;
                end
            case 4
                EMG_Sequence(emg_idx,1) = buff(index);%%%记录包序号

                % 原始数据解析%

                for i=1:9
                    for j=1:8
                       if(EMG_bytes(1,j*3-2+24*(i-1)) > 127)%%%第8位是否为1
                           EEG(j,(emg_idx-1)*9+i) = swapbytes(typecast(uint8([255 EMG_bytes((j*3-2+24*(i-1)):j*3+24*(i-1))]),'int32'));
                       else
                           EEG(j,(emg_idx-1)*9+i) = swapbytes(typecast(uint8([0   EMG_bytes((j*3-2+24*(i-1)):j*3+24*(i-1))]),'int32'));                       
                       end                         
                    end
                end
%                 EMG(emg_idx,1:8)=(EMG_frame-2048)/4096*3300000/2500;%%电压转换
                emg_idx = emg_idx + 1;
                emg_cnt_state=0;  % switch状态切换%
              

        end  
end

AA=diff(TT(220,:));
BB=find(AA~=1);
CC=diff(BB);
