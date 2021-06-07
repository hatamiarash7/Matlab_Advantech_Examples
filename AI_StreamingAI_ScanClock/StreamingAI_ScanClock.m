%    1. Set the 'deviceDescription' which can get from system device 
%       manager for opening the device. 
%    2. Set the 'startChannel' as the first channel for scan analog 
%       samples.  
%    3. Set the 'channelCount' to decide how many sequential channels to 
%       scan analog samples.
%    4. Set the 'intervalCount'to decide what occasion to signal event; 
%       when one section it is capacity decided by 
%       'intervalCount*channelCount' in kernel buffer(the capacity decided
%       by 'sampleCount*channelCount' )is filled,driver signal a 
%       'DataReady' event to notify APP.
%       ( ***Notes: the buffer is divided up with many sections begin with 
%                   buffer's head, the last section may not be equal to 
%                   'intervalCount*channelCount' if the 'sampleCount' is 
%                   not an integer multiple of 'intervalCount',but the last 
%                   section is filled , driver signal 'DataReady' event 
%                   too. ***)
%    5. Set the 'sampleCount' to decide the capacity of buffer in kernel. 
%    6. Set the 'convertClkRate' to to tell driver sample data rate for 
%       each channel.  
%    7. Set 'scan clock parameters' to decide scan clock property.

function StreamingAI_ScanClock()
% Make Automation.BDaq assembly visible to MATLAB.
BDaq = NET.addAssembly('Automation.BDaq');

% Configure the following six parameters before running the demo.
% The default device of project is demo device, users can set other devices 
% according to their needs. 
deviceDescription = 'DemoDevice,BID#0'; 
startChannel = int32(0);
channelCount = int32(1);
% For each channel, to decide the capacity of buffer in kernel.
intervalCount = int32(1024); 
                    
% For each channel. Recommend: sampleCount is an integer multiple of 
% intervalCount, and equal to twice or greater.					
sampleCount = int32(2048);  
convertClkRate = int32(1000);

% Set scan clock parameters.    
scanClockSource = Automation.BDaq.SignalDrop.SigInternalClock;
scanClockRate = int32(1000);
scanCount = int32(10);

errorCode = Automation.BDaq.ErrorCode.Success;

% Step 1: Create a 'BufferedAiCtrl' for buffered AI function.
bufferedAiCtrl = Automation.BDaq.BufferedAiCtrl();

% Step 2: Set the notification event Handler by which we can known the 
% state of operation effectively. 
addlistener(bufferedAiCtrl, 'DataReady', @bufferedAiCtrl_DataReady);
addlistener(bufferedAiCtrl, 'Overrun', @bufferedAiCtrl_Overrun);

try
    % Step 3: Select a device by device number or device description and 
    % specify the access mode. In this example we use 
    % AccessWriteWithReset(default) mode so that we can fully control the 
    % device, including configuring, sampling, etc.
    bufferedAiCtrl.SelectedDevice = Automation.BDaq.DeviceInformation(...
        deviceDescription);
    % Specify the running mode: streaming buffered.
    bufferedAiCtrl.Streaming = true; 

    % Step 4: Set necessary parameters for Asynchronous One Buffered AI 
    % operation.
    scanChannel = bufferedAiCtrl.ScanChannel;
    scanChannel.ChannelStart = startChannel;
    scanChannel.ChannelCount = channelCount;
    scanChannel.IntervalCount = intervalCount;
    scanChannel.Samples = sampleCount;
    convertClock = bufferedAiCtrl.ConvertClock;
    convertClock.Rate = convertClkRate;
    
    % Step 5: Scan Clock parameters setting.
    if bufferedAiCtrl.Features.BurstScanSupported
        scanClock = bufferedAiCtrl.ScanClock;
        scanClock.Source = scanClockSource;
        scanClock.Rate = scanClockRate;
        scanClock.ScanCount = scanCount;
    else
        e = MException('DAQError:NotSupport', ...
            'The device do not support scan clock function!');
        throw (e);
    end

    % Step 6: Prepare the buffered AI. 
    errorCode = bufferedAiCtrl.Prepare();
    if BioFailed(errorCode)
        throw Exception();
    end

    % Step 7: Start buffered AI, the method will return immediately after 
    % the operation has been started in streaming buffered mode.
    errorCode = bufferedAiCtrl.Start();
    if BioFailed(errorCode)
        throw Exception();
    end

    % Step 8: Do anything you are interesting while the device is acquiring 
    % data.
    input('StreamingAI is in progress... Press Enter key to quit!', 's');
    
    % Step 9: Stop the operation if it is running.
    errorCode = bufferedAiCtrl.Stop();
    if BioFailed(errorCode)
        throw Exception();
    end
catch e
    % Something is wrong.
    if BioFailed(errorCode)    
        errStr = 'Some error occurred. And the last error code is ' ... 
            + errorCode.ToString();
    else
        errStr = e.message;
    end
    disp(errStr);
end

% Step 10: Close device and release any allocated resource.
clear functions
bufferedAiCtrl.Dispose();

end

function result = BioFailed(errorCode)

result =  errorCode < Automation.BDaq.ErrorCode.Success && ...
    errorCode >= Automation.BDaq.ErrorCode.ErrorHandleNotValid;

end

function bufferedAiCtrl_DataReady(sender, e)

persistent handle;
if isempty(handle) || ~ishghandle(handle)
    handle = figure('NumberTitle', 'off', 'Name', 'StreamingAI_ScanClock');
end
bufferedAiCtrl = sender;
scanChannel = bufferedAiCtrl.ScanChannel;
%channelCountMax = bufferedAiCtrl.Features.ChannelCountMax;
%startChan = scanChannel.ChannelStart;
channelCount = scanChannel.ChannelCount;

if e.Count > channelCount
   sectionBuffer = NET.createArray('System.Double', e.Count);
   bufferedAiCtrl.GetData(e.Count, sectionBuffer);
   plot(sectionBuffer); 
end

end

function bufferedAiCtrl_Overrun(sender, e)

disp('Streaming AI is Over run ! ');

end
