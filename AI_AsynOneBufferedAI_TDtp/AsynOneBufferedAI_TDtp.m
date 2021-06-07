%    1. Set the 'deviceDescription' for opening the device. 
%    2. Set the 'startChannel' as the first channel for scan analog samples  
%    3. Set the 'channelCount' to decide how many sequential channels to 
%       scan analog samples.
%    4. Set the 'sampleCount' to decide the capacity of buffer in kernel 
%       and how many samples you want to get for each channel.
%    5. Set the 'convertClkRate' to tell driver sample data rate for each 
%       channel.    
%    6. Set 'trigger parameters' to decide trigger property.

function AsynOneBufferedAI_TDtp()

% Make Automation.BDaq assembly visible to MATLAB.
BDaq = NET.addAssembly('Automation.BDaq');

% Configure the following four parameters before running the demo.
% The default device of project is demo device, users can choose other 
% devices according to their needs. 
deviceDescription = 'DemoDevice,BID#0'; 
startChannel = int32(0);
channelCount = int32(1);
% For each channel. Recommend: sampleCount is an integer multiple of
% intervalCount, and equal to twice or greater.
sampleCount = int32(2048);  
% For each channel.
convertClkRate = int32(1000);

% Set trigger parameters.
triggerAction = Automation.BDaq.TriggerAction.DelayToStop;
triggerSource = Automation.BDaq.SignalDrop.SigExtDigClock;
triggerEdge = Automation.BDaq.ActiveSignal.RisingEdge;
triggerDelayCount = int32(1000);
triggerLevel = 3.0;

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
    convertClock = bufferedAiCtrl.ConvertClock;
    convertClock.Rate = convertClkRate;
    
    % Step 5: Trigger parameters setting.
    trigger = bufferedAiCtrl.Trigger;
    if ~isempty(trigger)
        trigger.Action = triggerAction;
        trigger.Source = triggerSource;
        trigger.DelayCount = triggerDelayCount;
        trigger.Edge = triggerEdge;
        trigger.Level = triggerLevel;
    else
        e = MException('DAQError:NotSupport',...
            'The device do not support trigger function!');
        throw (e);
    end

    % Step 6: Prepare the buffered AI.   
    errorCode =  bufferedAiCtrl.Prepare();
    if BioFailed(errorCode)
        throw Exception();
    end
    
    % Step 7: Start Asynchronous Buffered AI, 'Asynchronous' means the
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
    input('Press Enter key to quit!','s');
    
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

% Step 10: Close device, release any allocated resource before quit.
bufferedAiCtrl.Dispose();

end

function result = BioFailed(errorCode)

result =  errorCode < Automation.BDaq.ErrorCode.Success && ...
    errorCode >= Automation.BDaq.ErrorCode.ErrorHandleNotValid;

end

function bufferedAiCtrl_Stopped(sender, e)

fprintf('Acquisition has completed, all channel sample count is %d.\n', ...
    e.Count);
bufferedAiCtrl = sender;

% e.Count notifys that how many samples had been gathered in the 'Stopped'
% event. 
if e.Count <= 0
else
allChanData = NET.createArray('System.Double', e.Count);
bufferedAiCtrl.GetData(e.Count, allChanData);
figure('NumberTitle', 'off', 'Name', 'AsynOneBufferedAI_TDtp');
plot(allChanData);
end

end
