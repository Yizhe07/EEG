% Experiment parameters
n = 420;
Fs = 48000; % Samples per second
testSubject = 'TEST_1';
tmptime = datestr(now, 'yyyymmddTHHMMSS');
mkdir(['H:\我的云端硬盘\EEG_Record\', tmptime]);

Path = ['H:\我的云端硬盘\EEG_Record\', tmptime, '\'];

% Audio Files Setup for WAV format
audioDir = 'C:\Users\Yizhe\Desktop\EEG_All_Data\Audio'; % Directory containing audio files
audioFiles = dir(fullfile(audioDir, '*.wav')); % Load WAV files
fileNames = {audioFiles.name};

% Shuffle file names to play them randomly
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
board_shim.insert_marker(500, preset); % Marker start

epoch_duration = 2; % Duration in seconds to save data
last_save_time = time_begin;

epoch_count = 0; % Initialize a counter for the epoch files

headers = {'chn_1', 'chn_2', 'chn_3', 'chn_4', 'marker'}; % Define your headers here

for i = 1:n
    fprintf("Trial %d - ready....\n", i);

    % Audio playback
    idx = mod(i, length(shuffledFileNames)) + 1; % Ensure cycling through files
    [y, Fs] = audioread(fullfile(audioDir, shuffledFileNames{idx}));
    playerObj = audioplayer(y, Fs);
    playblocking(playerObj);

    currentDatetime = datetime('now', 'Format', 'HH:mm:ss');
    current_time = seconds(currentDatetime - dateshift(currentDatetime, 'start', 'day'));

    if (current_time - last_save_time >= epoch_duration)
        epoch_count = epoch_count + 1; % Increment the epoch counter
        epoch_data = board_shim.get_board_data(board_shim.get_board_data_count(preset), preset)';
        cleaned_data = cleanEEGData(epoch_data); % Clean the data

        % Convert array to table with headers and write the table to a CSV file
        cleaned_data_table = array2table(cleaned_data, 'VariableNames', headers);
        filename_epoch = strcat(Path, 'epoch_', num2str(epoch_count), '.csv');
        writetable(cleaned_data_table, filename_epoch); % Write the table to a CSV file with headers

        last_save_time = current_time;
    end
end


board_shim.stop_stream();
board_shim.release_session();

disp("Finish.");

% Cleaning function
function cleaned_data = cleanEEGData(raw_data)
    % Select only the EEG channels (adjust indices based on your EEG device) and the marker column
    eeg_data = raw_data(:, 1:4); % Example: assuming channels 1 to 4 are EEG
    markers = raw_data(:, end); % Assuming markers are in the last column
    
    % Subtract the mean from each channel
    eeg_data = bsxfun(@minus, eeg_data, mean(eeg_data, 1));
    
    % Concatenate the cleaned EEG data with the markers
    cleaned_data = [eeg_data, markers];
end
