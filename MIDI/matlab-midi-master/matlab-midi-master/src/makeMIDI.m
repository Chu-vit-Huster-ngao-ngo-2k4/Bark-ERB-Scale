% === CẤU HÌNH CƠ BẢN ===
duration_seconds = 120;
tempo_bpm = 120;
ticks_per_quarter_note = 480;
microseconds_per_quarter = round(60e6 / tempo_bpm);
beats_total = floor(duration_seconds * tempo_bpm / 60);  % = 240

% === TRACK 1: PIANO MELODY ===
melody_notes = [60, 62, 64, 65, 67, 69, 71, 72];  % C major
melody = [];
time = 0;
note_duration = 1;  % 1 beat
i = 1;
while time + note_duration <= beats_total
    pitch = melody_notes(mod(i-1, numel(melody_notes)) + 1);
    melody = [melody; 1, 1, pitch, 100, time, time + note_duration];
    time = time + 2;  % note every 2 beats
    i = i + 1;
end

% === TRACK 2: WALKING BASS ===
bass_notes = [36, 38, 40, 41];
bass = [];
time = 0;
i = 1;
while time + 1 <= beats_total
    pitch = bass_notes(mod(i-1, numel(bass_notes)) + 1);
    bass = [bass; 2, 2, pitch, 90, time, time + 1];
    time = time + 1;
    i = i + 1;
end

% === TRACK 3: DRUMS ===
drum = [];
for b = 0:(beats_total - 1)
    if mod(b, 4) == 0
        drum = [drum; 3, 10, 36, 100, b, b + 0.1];  % Kick
    end
    if mod(b, 4) == 2
        drum = [drum; 3, 10, 38, 100, b, b + 0.1];  % Snare
    end
    drum = [drum; 3, 10, 42, 60, b, b + 0.1];       % Hi-hat
end

% === TRACK 4: HORN (SAX/TRUMPET) ===
horn_notes = [67, 69, 71, 72, 74, 76, 77, 79];
horn = [];
time = 1;  % Start offset from melody
i = 1;
while time + 1 <= beats_total
    pitch = horn_notes(mod(i-1, numel(horn_notes)) + 1);
    horn = [horn; 4, 3, pitch, 110, time, time + 1];
    time = time + 2;
    i = i + 1;
end

% === GỘP TOÀN BỘ TRACK ===
M = [melody; bass; drum; horn];

% === TẠO MIDI FILE ===
midi = matrix2midi(M);
midi.ticks_per_quarter_note = ticks_per_quarter_note;
midi.metaMessages = struct( ...
    'type', {'set_tempo'}, ...
    'time', 0, ...
    'tempo', microseconds_per_quarter ...
);

% === GHI FILE MIDI ===
writemidi(midi, 'jazz.mid');
