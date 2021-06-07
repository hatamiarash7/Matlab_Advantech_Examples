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
%    7. Set 'trigger parameters' to decide trigger property.

function StreamingAI_TDtr()

% Make Automation.BDaq assembly visible to MATLAB.
BDaq = NET.addAssembly('Automation.BDaq');

% Configure the following six parameters before running the demo.
% The default device of project is demo device, users can set other devices 
% according to their needs. 
deviceDescription = 'DemoDevice,BID#0'; 
startChannel = int32(0);
channelCount = int32(4);
% For each channel, to decide the capacity of buffer in kernel.
intervalCount = int32(1024); 
            
% For each channel. Recommend: sampleCount is an integer multiple of 
% intervalCount, and equal to twice or greater.			
sampleCount = int32(2048);   
convertClkRate = int32(1000);

% Set trigger parameters.    
triggerAction = Automation.BDaq.TriggerAction.DelayToStart;
triggerSource = Automation.BDaq.SignalDrop.SigAi0;
triggerEdge = Automation.BDaq.ActiveSignal.RisingEdge;
triggerDelayCount = int32(1000);
triggerLevel = double(5.0);

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
    if 	bufferedAiCtrl.Features.TriggerSupported
    else
        e = MException('DAQError:NotSupport', ...
            'The device do not support trigger function!');
        throw (e);
    end
    
    % Step 4: Set necessary parameters for Asynchronous One Buffered AI 
    % operation.
    % Note:this step is optional(you can do these settings via
    % "Device Configuration" dialog).
    scanChannel = bufferedAiCtrl.ScanChannel;
    scanChannel.ChannelStart = startChannel;
    scanChannel.ChannelCount = channelCount;
    scanChannel.IntervalCount = intervalCount;
    scanChannel.Samples = sampleCount;
    convertClock = bufferedAiCtrl.ConvertClock;
    convertClock.Rate = convertClkRate;

    % Setp 5: Trigger parameters setting.
    trigger = bufferedAiCtrl.Trigger;
    trigger.Action = triggerAction;
    trigger.Source = triggerSource;
    trigger.DelayCount = triggerDelayCount;
    trigger.Edge = triggerEdge;
    trigger.Level = triggerLevel;

    % Step 6: prepare the buffered AI.
    errorCode = bufferedAiCtrl.Prepare();
    if BioFailed(errorCode)
        throw Exception();
    end
    
    % Step 7: Start buffered AI, the method will return immediately after 
    % the operation has been started.We can get samples via event handlers.
    errorCode = bufferedAiCtrl.Start();
    if BioFailed(errorCode)
        throw Exception(); 
    end

    % Step 8: Do anything you are interesting while the device is acquiring 
    % data.
    input('StreamingAI is in progress... Press Enter key to quit !', 's');

    % step 9: Stop the operation if it is running.
    errorCode = bufferedAiCtrl.Stop();
    if BioFailed(errorCode)
        throw Exception();
    end
catch e
    % Something is wrong. 
    if BioFailed(errorCode)    
        errStr = 'Some error occurred. And the last error code is ' ... ;
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

function bufferedAiCtrl_DataReady(sender, e)

persistent handle;
if isempty(handle) || ~ishghandle(handle)
    handle = figure('NumberTitle', 'off', 'Name', 'StreamingAI_TDtr');
end
bufferedAiCtrl = sender;
scanChannel = bufferedAiCtrl.ScanChannel;
% channelCountMax = bufferedAiCtrl.Features.ChannelCountMax;
% startChan = scanChannel.ChannelStart;
channelCount = scanChannel.ChannelCount;
Y = zeros(e.Count / channelCount,channelCount);
% buffer section length, when 'DataReady' event been signaled,
% driver renew data count is e.count. 
if e.Count > channelCount
   sectionBuffer = NET.createArray('System.Double', e.Count);
   bufferedAiCtrl.GetData(e.Count, sectionBuffer);
   for i=1:(e.Count / channelCount)
       for j=1:channelCount
           Y(i,j) = sectionBuffer((i - 1) * channelCount+j);
       end
   end
   plot(Y); 
end

end

function bufferedAiCtrl_Overrun(sender, e)

disp('Streaming AI is Over run !');

end

function result = BioFailed(errorCode)

result =  errorCode < Automation.BDaq.ErrorCode.Success && ...
    errorCode >= Automation.BDaq.ErrorCode.ErrorHandleNotValid;

end

