fs = 500;
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