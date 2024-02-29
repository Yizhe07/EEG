%RUN BY ADMINISTRATOR
n =420;
Fs = 48000;% Samples per second. 48000 is also a good choice
toneFreq = 500; % Tone frequency, in Hertz. must be less than .5 * Fs
toneDuration = 2;
testDuration = 4;
testSubject = 'TEST_1';
max_sec=210; % max seconds in single file < 225s
tmptime=datestr(now, 'yyyymmddTHHMMSS');
mkdir('D:\0 Research\0 EEG\EEG_Record', tmptime);

Path=strcat('D:\0 Research\0 EEG\EEG_Record\', tmptime,'\');



a = sin(linspace(0, toneDuration*toneFreq*2*pi, round(toneDuration*Fs)));
b = sin(linspace(0, 0, round(toneDuration*Fs)));
playerObj_1=audioplayer(a,Fs);
playerObj_0=audioplayer(b,Fs);

BoardShim.set_log_file(strcat( Path ,'brainflow.log'));
BoardShim.enable_dev_board_logger();

params = BrainFlowInputParams();
params.serial_port='COM3';
board_shim = BoardShim(int32(BoardIds.GANGLION_BOARD), params);
preset = int32(BrainFlowPresets.DEFAULT_PRESET);  %https://brainflow.readthedocs.io/en/stable/DataFormatDesc.html  : BrainFlow Presets
board_shim.prepare_session();
board_shim.add_streamer('file://data_default.csv:w', preset);
board_shim.start_stream(45000, '');
% freq different???????????

currentDatetime = datetime('now', 'Format', 'HH:mm:ss');
time_begin = seconds(currentDatetime - dateshift(currentDatetime, 'start', 'day'));
disp("Time begin at "+ time_begin);

 pause(5);
 board_shim.insert_marker(500, preset); %marker start
 
count_0=int32(n/2);
count_1=int32(n/2);
binary_vector=[zeros(1,count_0),ones(1,count_1)];
random_binary_vector=binary_vector(randperm(count_0+count_1));
disp(binary_vector);
disp(random_binary_vector);

file_count=0;
for i = 1:length(random_binary_vector)
    
    disp(i+"-"+random_binary_vector(i));
    fprintf("	ready....");
    pause((testDuration-toneDuration)/2);

   
    fprintf("beeping....");
    if random_binary_vector(i)==1
        board_shim.insert_marker(600, preset); %marker
        playblocking(playerObj_1);
        board_shim.insert_marker(-600, preset); %marker
    else
         board_shim.insert_marker(300, preset); %marker
        playblocking(playerObj_0);
         board_shim.insert_marker(-300, preset); %marker
    end

    pause((testDuration-toneDuration)/2);
    fprintf("end.\n");
    
    currentDatetime = datetime('now', 'Format', 'HH:mm:ss');
    time_end = seconds(currentDatetime - dateshift(currentDatetime, 'start', 'day'));
    %disp("Time end at "+time_end);
    time_last= time_end-time_begin;
    disp("time_last = "+time_last);
    
    if time_last> max_sec
        data = board_shim.get_board_data(board_shim.get_board_data_count(preset),preset)';
        filename = strcat( Path ,datestr (now, 'yyyymmddTHHMMSS'),'-',num2str(toneFreq),'-',num2str(toneDuration),'-',num2str(testDuration),'-',num2str(n),'-',testSubject,'-',num2str(file_count),'-data.csv');
        csvwrite (filename,data);
        file_count=file_count+1;
        currentDatetime = datetime('now', 'Format', 'HH:mm:ss');
        time_begin = seconds(currentDatetime - dateshift(currentDatetime, 'start', 'day'));
        disp("Time begin at "+time_begin);
    end

    sleeptime=5*rand(1);
    disp("	Sleep "+sleeptime+" s");
    pause(sleeptime);
    
    
end

endwaittime=20;
for i = 1:endwaittime/10
    pause(10);
    disp("Has slept "+ i*10 +" s, totally "+endwaittime+" s");
end
 

    data = board_shim.get_board_data(board_shim.get_board_data_count(preset),preset)';
    filename = strcat( Path ,datestr (now, 'yyyymmddTHHMMSS'),'-',num2str(toneFreq),'-',num2str(toneDuration),'-',num2str(testDuration),'-',num2str(n),'-',testSubject,'-',num2str(file_count),'-data.csv');
    csvwrite (filename,data);
    
      
   
%     filename_mat = fullfile(Path, 'mydata.mat');
%     labels = {'Time', 'Ch1', 'Ch2', 'Ch3', 'Ch4','6','7','8','9','10','11','12','13','14','15','Mark'};  % Example cell array of labels
%     % Use the save function to save the variables to the .mat file
%     save(filename_mat, 'data', 'labels');


board_shim.stop_stream();
board_shim.release_session();

disp("Finish.");



%no sound may have noise sometime

%Matlab Signal Filtering 
%Matlab Denoising 


