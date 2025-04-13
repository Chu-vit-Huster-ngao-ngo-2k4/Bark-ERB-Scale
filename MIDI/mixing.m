[audio1, fs1] = audioread('outjazz.wav');
[audio2, fs2] = audioread('group_recording.wav');
audio1 = resample(audio1,16000, fs1);
fs1 = 16000;
audio2 = resample(audio2,16000,fs2);
fs2 = 16000;

% Cắt cho cùng độ dài
n1 = length(audio1);
n2 = length(audio2);
if n1 > n2
    audio1= audio1(1:n2,:);
elseif n1 < n2
    audio2 = audio2(1:n1,:);
end

% Mix 2 đoạn với hệ số
mixed_audio = 0.1*audio1 + 4*audio2;

% Thiết kế bộ lọc thông thấp
fc = 2000;
[b, a] = butter(6, fc/(fs1/2), 'low');
y_lofi = filter(b, a, mixed_audio);

% CHUẨN HÓA âm thanh để tránh clipping
y_lofi = y_lofi / max(abs(y_lofi));

% Ghi file
audiowrite('mixed_audio.wav', y_lofi, fs1);
