% Initialization
n = 420;
Fs = 48000; % Sample rate
toneFreq = 500; % Tone frequency (Hz)
toneDuration = 2; % Duration of the tone (seconds)
testDuration = 4; % Duration of each test (seconds)
testSubject = 'TEST_1';
max_sec = 210; % Maximum duration for a single data file

% Create directory for saving data
tmptime = datetime('now','Format','yyyyMMdd''T''HHmmss');
dataPath = fullfile('D:\EEG_Record', string(tmptime));
if ~exist(dataPath, 'dir')
    mkdir(dataPath);
end

% Create the log file path
logFilePath = fullfile(dataPath, 'brainflow.log');

try
    % Open the log file for writing (create if it doesn't exist)
    logFile = fopen(logFilePath, 'w');

    if logFile == -1
        error('Failed to open log file for writing.');
    end

    % Write an initial message to the log file
    fprintf(logFile, 'Log file created at %s\n', datetime("now"));

% Sound Stimuli Generation
a = sin(linspace(0, toneDuration * toneFreq * 2 * pi, round(toneDuration * Fs)));
b = zeros(1, round(toneDuration * Fs)); % Generate silence with zeros instead of sinPmatlab
playerObj_1 = audioplayer(a, Fs);
playerObj_0 = audioplayer(b, Fs);

% EEG Board Setup
BoardShim.set_log_file(strcat(dataPath,'brainflow.log'));
BoardShim.enable_dev_board_logger();
params = BrainFlowInputParams();
params.serial_port='COM3';
board_shim = BoardShim(int32(BoardIds.GANGLION_BOARD), params);
preset = int32(BrainFlowPresets.DEFAULT_PRESET);  %https://brainflow.readthedocs.io/en/stable/DataFormatDesc.html  : BrainFlow Presets
board_shim.prepare_session();
board_shim.add_streamer('file://data_default.csv:w', preset);
board_shim.start_stream(45000, '');


% Close the log file when done
    fclose(logFile);
    disp('Log file created successfully.');
    
catch exception
    % Handle any errors
    fclose(logFile);
    disp(['Error: ', exception.message]);
    error('Error while creating or writing to the log file.');
end

% Time Tracking
time_begin = seconds(datetime('now') - dateshift(datetime('now'), 'start', 'day'));
disp(['Time begin at ', num2str(time_begin)]);

pause(5);
board_shim.insert_marker(500, preset); % Marker start

% GUI for Mouse Clicks
hFig = figure('Name', 'Click when you hear the sound', 'NumberTitle', 'off');
set(hFig, 'WindowButtonDownFcn', @mouseClickCallback);
clickTimes = []; % Array to store click times

% Experiment Execution
binary_vector = [zeros(1, n/2), ones(1, n/2)];
random_binary_vector = binary_vector(randperm(n));
file_count = 0; % Initialize file_count

for i = 1:length(random_binary_vector)
    % ... [Rest of the code remains the same]

% Helper Functions (put these functions outside of the main script)
% ... [Rest of the helper functions code remains the same]
end