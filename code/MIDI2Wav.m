midi = readmidi('jazz.mid'); % Đọc file MIDI

[y,Fs] = midi2audio(midi);  % Chuyển đổi MIDI thành sóng âm thanh (mặc định FM synth)
soundsc(y, Fs);             % Nghe thử

% Một vài dạng sóng khác:
y = midi2audio(midi, Fs, 'sine'); soundsc(y,Fs); % Sóng sin
y = midi2audio(midi, Fs, 'saw'); soundsc(y,Fs);  % Sóng răng cưa

% Ghi file WAV
y = .95.*y./max(abs(y));    % Chuẩn hóa âm thanh
audiowrite('outjazz.wav', y, Fs); % Ghi ra file
