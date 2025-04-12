
[audio, Fs] = audioread('group_recording.wav');
t = (0:length(audio)-1)/Fs;

% Hiển thị waveform
figure; plot(t, audio);
title('Waveform of the Recorded Audio');
xlabel('Time (s)'); ylabel('Amplitude');

% Hiển thị FFT
n = length(audio);
f = (0:n-1)*(Fs/n);
Y = abs(fft(audio));

figure; plot(f, Y);
title('Frequency Spectrum of the Audio');
xlabel('Frequency (Hz)'); ylabel('Magnitude');

% Spectrogram
figure; spectrogram(audio, 256, 200, 512, Fs, 'yaxis');
title('Spectrogram'); 


% Hàm tính Bark từ tần số f (Hz)
function bark = freq2bark(f)
    bark = 6 * log10((f / 600) + sqrt(1 + (f / 600)^2));
end

% Hàm tính ERB từ tần số f (Hz)
function erb = freq2erb(f)
    erb = 24.7 * (4.37 * f / 1000 + 1);
end


bark = arrayfun(@(x) freq2bark(x), f);  % Tính Bark cho từng tần số
erb = arrayfun(@(x) freq2erb(x), f);    % Tính ERB cho từng tần số

% Hiển thị kết quả
figure;
subplot(2,1,1);
plot(f, bark);
title('Bark Scale');
xlabel('Frequency (Hz)');
ylabel('Bark');

subplot(2,1,2);
plot(f, erb);
title('ERB Scale');
xlabel('Frequency (Hz)');
ylabel('ERB (Hz)');


numBands = 24;
bandEdges = linspace(0, 24, numBands+1);  % BARK scale
bandEnergy = zeros(1, numBands);

for b = 1:numBands
    idx = find(bark >= bandEdges(b) & bark < bandEdges(b+1));
    bandEnergy(b) = sum(Y(idx).^2);  % Tổng năng lượng trong băng Bark này
end

% Biểu đồ năng lượng theo băng Bark
figure;
bar(bandEdges(1:end-1), bandEnergy, 'histc');
xlabel('Bark Band');
ylabel('Energy');
title('Energy per Bark Band');

maxVal = max(bandEnergy);
quantized = round(bandEnergy / maxVal * 255);  % 8-bit quantization

save('compressed_bark.mat', 'quantized', 'Fs', 'numBands', 'maxVal');

load('compressed_bark.mat');
reconstructedY = zeros(size(Y));

for b = 1:numBands
    idx = find(bark >= bandEdges(b) & bark < bandEdges(b+1));
    energy = quantized(b) / 255 * maxVal;
    reconstructedY(idx) = sqrt(energy / length(idx));  % phân phối lại năng lượng
end

reconstructedY = reconstructedY .* exp(1i * angle(fft(audio)));  % giữ nguyên pha
reconstructedAudio = real(ifft(reconstructedY));

audiowrite('reconstructed_audio.wav', reconstructedAudio, Fs);

%% Nén âm thanh theo ERB Scale

% Chia phổ theo thang ERB
erbBands = 30;  % Tùy chọn: bạn có thể chọn 24, 30 hoặc 40 băng
erbEdges = linspace(min(erb), max(erb), erbBands+1);  % Chia đều theo giá trị ERB
erbEnergy = zeros(1, erbBands);

for b = 1:erbBands
    idx = find(erb >= erbEdges(b) & erb < erbEdges(b+1));
    erbEnergy(b) = sum(Y(idx).^2);  % Tổng năng lượng trong mỗi băng ERB
end

% Biểu đồ năng lượng theo băng ERB
figure;
bar(erbEdges(1:end-1), erbEnergy, 'histc');
xlabel('ERB Band');
ylabel('Energy');
title('Energy per ERB Band');

% Lượng tử hóa (8-bit)
erbMaxVal = max(erbEnergy);
erbQuantized = round(erbEnergy / erbMaxVal * 255);

% Lưu dữ liệu nén
save('compressed_erb.mat', 'erbQuantized', 'Fs', 'erbBands', 'erbMaxVal');

% Giải nén (reconstruct spectrum)
load('compressed_erb.mat');
erbReconstructedY = zeros(size(Y));

for b = 1:erbBands
    idx = find(erb >= erbEdges(b) & erb < erbEdges(b+1));
    energy = erbQuantized(b) / 255 * erbMaxVal;
    erbReconstructedY(idx) = sqrt(energy / length(idx));  % phân phối đều năng lượng
end

% Tái tạo âm thanh
erbReconstructedY = erbReconstructedY .* exp(1i * angle(fft(audio)));
erbReconstructedAudio = real(ifft(erbReconstructedY));

audiowrite('reconstructed_audio_erb.wav', erbReconstructedAudio, Fs);


[audio_mp3, Fs_mp3] = audioread('group_recording_mp3.mp3');

% Đồng bộ độ dài
minLen = min([length(audio), length(reconstructedAudio), length(erbReconstructedAudio), length(audio_mp3)]);
original = audio(1:minLen);
bark_rec = reconstructedAudio(1:minLen);
erb_rec = erbReconstructedAudio(1:minLen);
mp3_rec = audio_mp3(1:minLen);

% Hàm tính PSNR
calc_psnr = @(orig, rec) 10 * log10(max(orig)^2 / mean((orig - rec).^2));

psnr_bark = calc_psnr(original, bark_rec);
psnr_erb  = calc_psnr(original, erb_rec);
psnr_mp3  = calc_psnr(original, mp3_rec);

fprintf('PSNR - Bark: %.2f dB\n', psnr_bark);
fprintf('PSNR - ERB: %.2f dB\n', psnr_erb);
fprintf('PSNR - MP3: %.2f dB\n', psnr_mp3);

% Lưu các giá trị PSNR vào mảng để vẽ biểu đồ
psnr_values = [psnr_bark, psnr_erb, psnr_mp3];
methods = {'Bark', 'ERB', 'MP3'};

% Biểu đồ cột so sánh PSNR
figure;
bar(psnr_values, 'FaceColor', [0.2 0.6 0.8]);
set(gca, 'XTickLabel', methods, 'FontSize', 12);
ylabel('PSNR (dB)', 'FontSize', 12);
title('So sánh chất lượng nén âm thanh theo PSNR', 'FontSize', 14);
grid on;

% Ghi giá trị PSNR lên các cột
text(1:length(psnr_values), psnr_values + 0.5, ...
    string(round(psnr_values, 2)), 'HorizontalAlignment', 'center', 'FontSize', 12);