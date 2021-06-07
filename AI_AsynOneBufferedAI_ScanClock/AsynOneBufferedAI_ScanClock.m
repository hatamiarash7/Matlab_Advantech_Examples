%    1. Set the 'deviceDescription' for opening the device. 
%    2. Set the 'startChannel' as the first channel for scan analog samples  
%    3. Set the 'channelCount' to decide how many sequential channels to 
%       scan analog samples.
%    4. Set the 'sampleCount' to decide the capacity of buffer in kernel 
%       and how many samples you want to get for each channel.
%    5. Set the 'convertClkRate' to tell driver sample data rate for each 
%       channel.    
%    6. Set 'scan clock parameters' to decide scan clock property.

function AsynOneBufferedAI_ScanClock()

% Make Automation.BDaq assembly visible to MATLAB.
BDaq = NET.addAssembly('Automation.BDaq');

% Configure the following five parameters before running the demo.
% The default device of project is demo device, users can choose other 
% devices according to their needs. 
deviceDescription = 'DemoDevice,BID#0'; 
startChannel = int32(0);
channelCount = int32(1);
sampleCount = int32(1024);
intevalCount = int32(1024);
% Recommend: sampleCount is equal to intevalCount here.
convertClkRate = int32(1000);

% Set scan clock parameters.
scanClockSource = Automation.BDaq.SignalDrop.SigInternalClock;
% For each channel
scanClockRate = int32(1000); 
scanCount = int32(10);

errorCode = Automation.BDaq.ErrorCode.Success;
% Step 1: Create a 'BufferedAiCtrl' for buffered AI function.
bufferedAiCtrl = Automation.BDaq.BufferedAiCtrl();

% Step 2: Set the notification event Handler by which we can known the 
% state of operation effectively.
addlistener(bufferedAiCtrl, 'Stopped', @bufferedAiCtrl_Stopped);

try
    % Step 3: Select a device by device number or device description and 
    % specify the access mode. In this example we use 
    % AccessWriteWithReset(default) mode so that we can fully control the 
    % device, including configuring, sampling, etc.
    bufferedAiCtrl.SelectedDevice = Automation.BDaq.DeviceInformation(...
        deviceDescription);
    % Specify the running mode: one-buffered.
    bufferedAiCtrl.Streaming = false; 

    % Step 4: Set necessary parameters for Asynchronous One Buffered AI
    % operation.
    scanChannel = bufferedAiCtrl.ScanChannel;
    scanChannel.ChannelStart = startChannel;
    scanChannel.ChannelCount = channelCount;
    scanChannel.Samples = sampleCount;
    scanChannel.IntervalCount = intevalCount;
    convertClock = bufferedAiCtrl.ConvertClock;
    convertClock.Rate = convertClkRate;
    
    % Step 5: Scan Clock parameters setting
    if bufferedAiCtrl.Features.BurstScanSupported
        scanClock = bufferedAiCtrl.ScanClock;
        scanClock.Source = scanClockSource;
        scanClock.Rate = scanClockRate;
        scanClock.ScanCount = scanCount;
    else
        e = MException('DAQError:NotSupport',...
            'The device do not support scan clock function!');
        throw (e);
    end

    % Step 6: prepare the buffered AI.   
    errorCode = bufferedAiCtrl.Prepare();
    if BioFailed(errorCode)
        throw Exception();
    end
    
    % Step 7: start Asynchronous Buffered AI, 'Asynchronous' means the
    % method returns immediately after the acquisition has been started. 
    % The 'bufferedAiCtrl_Stopped' method will be called after the 
    % acquisition is completed.
    errorCode = bufferedAiCtrl.Start();
    if BioFailed(errorCode)
        throw Exception();
    end
    
    % Step 8: Do anything you are interesting while the device is acquiring
    % data.
    fprintf('AsynchronousOneBufferedAI is in progress...');
    input('Press Enter key to quit!', 's');
    
    % step 9: Stop the operation if it is running.
    bufferedAiCtrl.Stop();
    pause(1);
catch e
    % Something is wrong.
    if BioFailed(errorCode)    
        errStr = 'Some error occurred. And the last error code is ' + ...
            errorCode.ToString();
    else
        errStr = e.message;
    end
    disp(errStr); 
end

% Step 10: close device, release any allocated resource before quit.
bufferedAiCtrl.Dispose();

end

function result = BioFailed(errorCode)

result =  errorCode < Automation.BDaq.ErrorCode.Success && ...
    errorCode >= Automation.BDaq.ErrorCode.ErrorHandleNotValid;

end

function bufferedAiCtrl_Stopped(sender, e)

bufferedAiCtrl = sender;

% e.Count notifys that how many samples had been gathered in the 'Stopped'
% event. 
allChanData = NET.createArray('System.Double', e.Count);
bufferedAiCtrl.GetData(e.Count, allChanData);
figure('NumberTitle', 'off', 'Name', 'AsyOneBufferedAI_ScanClock');
plot(allChanData);

end
