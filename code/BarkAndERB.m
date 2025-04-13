% Doc: Xu ly am thanh va nen bang thang Bark va ERB, loai bo tan so khong can thiet

% Doc am thanh
[audio, Fs] = audioread('group_recording.wav');
t = (0:length(audio)-1)/Fs;

% Hien thi waveform
figure; plot(t, audio);
title('Waveform of the Recorded Audio');
xlabel('Time (s)'); ylabel('Amplitude');

% FFT va pho
n = length(audio);
f = (0:n-1)*(Fs/n);
Y = fft(audio);
magY = abs(Y);

figure; plot(f, magY);
title('Frequency Spectrum');
xlabel('Frequency (Hz)'); ylabel('Magnitude');

% Spectrogram
figure; spectrogram(audio, 256, 200, 512, Fs, 'yaxis');
title('Spectrogram');

% Ham chuyen doi tan so sang Bark
freq2bark = @(f) 6 * log10((f / 600) + sqrt(1 + (f / 600).^2));
% Ham chuyen doi tan so sang ERB
freq2erb = @(f) 24.7 * (4.37 * f / 1000 + 1);

bark = freq2bark(f);
erb = freq2erb(f);

%% ===== BARK COMPRESSION =====
numBands = 24;
bandEdges = linspace(0, 24, numBands+1);
bandEnergy = zeros(1, numBands);

for b = 1:numBands
    idx = find(bark >= bandEdges(b) & bark < bandEdges(b+1));
    bandEnergy(b) = sum(magY(idx).^2);
end

% Loai bo cac band co nang luong nho hon nguong
threshold = 0.05 * max(bandEnergy);
bandEnergy(bandEnergy < threshold) = 0;

% Bieu do nang luong Bark
figure;
bar(bandEdges(1:end-1), bandEnergy, 'histc');
title('Energy per Bark Band'); xlabel('Bark Band'); ylabel('Energy');

% Luong tu hoa 8-bit
maxVal = max(bandEnergy);
quantized = round(bandEnergy / maxVal * 255);

save('compressed_bark.mat', 'quantized', 'Fs', 'numBands', 'maxVal');

% Giai nen Bark
load('compressed_bark.mat');
reconstructedY = zeros(size(Y));

for b = 1:numBands
    idx = find(bark >= bandEdges(b) & bark < bandEdges(b+1));
    if quantized(b) > 0
        energy = quantized(b) / 255 * maxVal;
        reconstructedY(idx) = sqrt(energy / length(idx));
    end
end

reconstructedY = reconstructedY .* exp(1i * angle(Y));
reconstructedAudio = real(ifft(reconstructedY));
audiowrite('reconstructed_audio.wav', reconstructedAudio, Fs);

%% ===== ERB COMPRESSION =====
erbBands = 30;
erbEdges = linspace(min(erb), max(erb), erbBands+1);
erbEnergy = zeros(1, erbBands);

for b = 1:erbBands
    idx = find(erb >= erbEdges(b) & erb < erbEdges(b+1));
    erbEnergy(b) = sum(magY(idx).^2);
end

% Loai cac band co nang luong thap
erbThreshold = 0.05 * max(erbEnergy);
erbEnergy(erbEnergy < erbThreshold) = 0;

figure;
bar(erbEdges(1:end-1), erbEnergy, 'histc');
title('Energy per ERB Band'); xlabel('ERB Band'); ylabel('Energy');

erbMaxVal = max(erbEnergy);
erbQuantized = round(erbEnergy / erbMaxVal * 255);
save('compressed_erb.mat', 'erbQuantized', 'Fs', 'erbBands', 'erbMaxVal');

% Giai nen ERB
load('compressed_erb.mat');
erbReconstructedY = zeros(size(Y));

for b = 1:erbBands
    idx = find(erb >= erbEdges(b) & erb < erbEdges(b+1));
    if erbQuantized(b) > 0
        energy = erbQuantized(b) / 255 * erbMaxVal;
        erbReconstructedY(idx) = sqrt(energy / length(idx));
    end
end

erbReconstructedY = erbReconstructedY .* exp(1i * angle(Y));
erbReconstructedAudio = real(ifft(erbReconstructedY));
audiowrite('reconstructed_audio_erb.wav', erbReconstructedAudio, Fs);

%% ===== PSNR EVALUATION =====
[audio_mp3, Fs_mp3] = audioread('group_recording_mp3.mp3');
minLen = min([length(audio), length(reconstructedAudio), length(erbReconstructedAudio), length(audio_mp3)]);
original = audio(1:minLen);
bark_rec = reconstructedAudio(1:minLen);
erb_rec = erbReconstructedAudio(1:minLen);
mp3_rec = audio_mp3(1:minLen);

calc_psnr = @(orig, rec) 10 * log10(max(orig)^2 / mean((orig - rec).^2));
psnr_bark = calc_psnr(original, bark_rec);
psnr_erb  = calc_psnr(original, erb_rec);
psnr_mp3  = calc_psnr(original, mp3_rec);

fprintf('PSNR - Bark: %.2f dB\n', psnr_bark);
fprintf('PSNR - ERB: %.2f dB\n', psnr_erb);
fprintf('PSNR - MP3: %.2f dB\n', psnr_mp3);

psnr_values = [psnr_bark, psnr_erb, psnr_mp3];
methods = {'Bark', 'ERB', 'MP3'};

figure;
bar(psnr_values, 'FaceColor', [0.2 0.6 0.8]);
set(gca, 'XTickLabel', methods, 'FontSize', 12);
ylabel('PSNR (dB)', 'FontSize', 12);
title('So sanh PSNR giua cac phuong phap nen', 'FontSize', 14);
grid on;
text(1:length(psnr_values), psnr_values + 0.5, ...
    string(round(psnr_values, 2)), 'HorizontalAlignment', 'center', 'FontSize', 12);