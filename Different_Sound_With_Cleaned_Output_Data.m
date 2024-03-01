% Experiment parameters
n = 420;
Fs = 48000; % Samples per second
testSubject = 'TEST_1';
max_sec = 210; % max seconds in single file < 225s
tmptime = datestr(now, 'yyyymmddTHHMMSS');
mkdir(['C:\Users\Yizhe\Desktop\EEG_All_Data\EEG_Record\', tmptime]);

Path = ['C:\Users\Yizhe\Desktop\EEG_All_Data\EEG_Record\', tmptime, '\'];

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
disp("Time begin at " + time_begin);

pause(5); % Initial pause before starting the experiment
board_shim.insert_marker(500, preset); % Marker start

count_0 = int32(n / 2);
count_1 = int32(n / 2);
binary_vector = [zeros(1, count_0), ones(1, count_1)];
random_binary_vector = binary_vector(randperm(count_0 + count_1));

file_count = 0;
for i = 1:length(random_binary_vector)
    fprintf("Trial %d: Condition %d - ready....\n", i, random_binary_vector(i));

    % Audio playback
    idx = mod(i, length(shuffledFileNames)) + 1; % Ensure cycling through files
    [y, Fs] = audioread(fullfile(audioDir, shuffledFileNames{idx}));
    playerObj = audioplayer(y, Fs);
    playblocking(playerObj);

    % Markers for start and end of playback based on the condition
    if random_binary_vector(i) == 1
        board_shim.insert_marker(600, preset); % Marker for condition 1
    else
        board_shim.insert_marker(300, preset); % Marker for condition 0
    end

    pause(2); % 2-second pause to make total duration 4 seconds

    currentDatetime = datetime('now', 'Format', 'HH:mm:ss');
    time_end = seconds(currentDatetime - dateshift(currentDatetime, 'start', 'day'));
    time_last = time_end - time_begin;
    disp("Time elapsed: " + time_last + "s");

    if time_last > max_sec
        raw_data = board_shim.get_board_data(board_shim.get_board_data_count(preset), preset)';
        cleaned_data = cleanEEGData(raw_data); % Clean the data
        filename_raw = strcat(Path, datestr(now, 'yyyymmddTHHMMSS'), '-', testSubject, '-', num2str(file_count), '-raw-data.csv');
        filename_cleaned = strcat(Path, datestr(now, 'yyyymmddTHHMMSS'), '-', testSubject, '-', num2str(file_count), '-cleaned-data.csv');
        csvwrite(filename_raw, raw_data); % Save raw data
        csvwrite(filename_cleaned, cleaned_data); % Save cleaned data
        file_count = file_count + 1;
        time_begin = seconds(datetime('now', 'Format', 'HH:mm:ss') - dateshift(currentDatetime, 'start', 'day'));
    end
end

% Fetch and clean remaining data at the end
raw_data = board_shim.get_board_data(board_shim.get_board_data_count(preset), preset)';
cleaned_data = cleanEEGData(raw_data); % Clean the data
filename_raw = strcat(Path, datestr(now, 'yyyymmddTHHMMSS'), '-', num2str(Fs), '-', testSubject, '-', num2str(file_count), '-raw-data.csv');
filename_cleaned = strcat(Path, datestr(now, 'yyyymmddTHHMMSS'), '-', num2str(Fs), '-', testSubject, '-', num2str(file_count), '-cleaned-data.csv');
csvwrite(filename_raw, raw_data); % Save raw data
csvwrite(filename_cleaned, cleaned_data); % Save cleaned data

board_shim.stop_stream();
board_shim.release_session();

disp("Finish.");

% Cleaning function
function cleaned_data = cleanEEGData(raw_data)
    % Select only the EEG channels and the marker column
    eeg_data = raw_data(:, 1:4); % Example: assuming channels 1 to 4 are EEG
    markers = raw_data(:, end); % markers are in the last column
    
    % Subtract the mean from each channel
    eeg_data = bsxfun(@minus, eeg_data, mean(eeg_data, 1));
    
    % Concatenate the cleaned EEG data with the markers
    cleaned_data = [eeg_data, markers];
end
