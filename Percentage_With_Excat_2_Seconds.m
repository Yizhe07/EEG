% Initialization and Setup
n = 420;
Fs = 48000; % Samples per second
testSubject = 'TEST_1';
tmptime = datestr(now, 'yyyymmddTHHMMSS');
mkdir(['H:\我的云端硬盘\EEG_Record\', tmptime]);

Path = ['H:\我的云端硬盘\EEG_Record\', tmptime, '\'];

% Audio Files Setup for WAV format
audioDir = 'C:\Users\Yizhe\Desktop\EEG_All_Data\Audio';
audioFiles = dir(fullfile(audioDir, '*.wav'));
fileNames = {audioFiles.name};
shuffledIndices = randperm(length(fileNames));
shuffledFileNames = fileNames(shuffledIndices);

BoardShim.set_log_file(strcat(Path, 'brainflow.log'));
BoardShim.enable_dev_board_logger();

params = BrainFlowInputParams();
params.serial_port = 'COM3';
board_shim = BoardShim(int32(BoardIds.GANGLION_BOARD), params);
preset = int32(BrainFlowPresets.DEFAULT_PRESET);
board_shim.prepare_session();
board_shim.add_streamer('file://data_default.csv:w', preset);
board_shim.start_stream(45000, '');

currentDatetime = datetime('now', 'Format', 'HH:mm:ss');
time_begin = seconds(currentDatetime - dateshift(currentDatetime, 'start', 'day'));

pause(5); % Initial pause before starting the experiment

epoch_duration = 2; % Duration in seconds to save data
last_save_time = time_begin;
sound_time = 0; % To calculate the percentage of sound in each epoch
silence_time = 0; % To calculate the percentage of silence in each epoch
headers = {'chn_1', 'chn_2', 'chn_3', 'chn_4', 'marker'}; % Define your headers here

for i = 1:n
    fprintf("Trial %d - ready....\n", i);
    
    % Random delay before playing sound (no-sound period)
    random_delay = rand() * 10; % Random delay between 0 and 10 seconds
    pause(random_delay); % Introduce a random silence period before the sound
    silence_time = silence_time + random_delay; % Track silence time

    % Insert marker for no-sound period start
    if i > 1  % To avoid placing a marker before any sound has ever been played
        board_shim.insert_marker(300, preset);
    end

    idx = mod(i, length(shuffledFileNames)) + 1;
    [y, Fs] = audioread(fullfile(audioDir, shuffledFileNames{idx}));
    playerObj = audioplayer(y, Fs);

    % Insert marker for sound start
    board_shim.insert_marker(600, preset);
    playblocking(playerObj);

    % Insert marker for sound end
    board_shim.insert_marker(-600, preset);

    % Mark the end of the no-sound period before the next sound
    if i < n  % Ensuring we don't place an end marker after the last sound
        board_shim.insert_marker(-300, preset);
    end

    sound_time = sound_time + length(y) / Fs; % Update sound time

    currentDatetime = datetime('now', 'Format', 'HH:mm:ss');
    current_time = seconds(currentDatetime - dateshift(currentDatetime, 'start', 'day'));

    if (current_time - last_save_time >= epoch_duration)
        epoch_data = board_shim.get_board_data(board_shim.get_board_data_count(preset), preset)';
        cleaned_data = cleanEEGData(epoch_data);
        cleaned_data_table = array2table(cleaned_data, 'VariableNames', headers);
        percentage_sound = (sound_time / (sound_time + silence_time)) * 100;
        filename_epoch = strcat(Path, 'epoch_', num2str(i), '_', num2str(round(percentage_sound)), 'pct_sound.csv');
        writetable(cleaned_data_table, filename_epoch);

        % Log message to confirm file saving
        fprintf('Saved %s with %0.2f%% sound.\n', filename_epoch, percentage_sound);

        % Reset sound and silence times for the next epoch
        sound_time = 0;
        silence_time = 0;
        last_save_time = current_time; % Update last save time to current time
    end
end

board_shim.stop_stream();
board_shim.release_session();

disp("Finish.");

% Function to clean EEG data
function cleaned_data = cleanEEGData(raw_data)
    eeg_data = raw_data(:, 1:4); % Assume channels 1 to 4 are EEG
    markers = raw_data(:, end); % Assuming markers are in the last column
    eeg_data = bsxfun(@minus, eeg_data, mean(eeg_data, 1)); % Subtract the mean
    cleaned_data = [eeg_data, markers]; % Concatenate cleaned EEG data with markers
end
