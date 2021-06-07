%    1. Set the 'deviceDescription' for opening the device. 
%    2. Set the 'startChannel' as the first channel for scan analog 
%       samples.  
%    3. Set the 'channelCount' to decide how many sequential channels to 
%       scan analog samples.
%    4. Set the 'convertClkRate' to to tell driver sample data rate for 
%       each channel.  
%    4. Set the 'sampleCount' to tell driver how many samples you want to 
%       get for all channels.

function SynchronousOneBufferedAI()
% Make Automation.BDaq assembly visible to MATLAB.
BDaq = NET.addAssembly('Automation.BDaq');

% Configure the following four parameters before running the demo.
% The default device of project is demo device, users can choose other 
% devices according to their needs. 
deviceDescription = 'DemoDevice,BID#0'; 
startChannel = int32(0);
channelCount = int32(1);
convertClkRate = int32(1000);
sampleCount = int32(1024);

errorCode = Automation.BDaq.ErrorCode.Success;

% Step 1: Create a 'BufferedAiCtrl' for buffered AI function.
bufferedAiCtrl = Automation.BDaq.BufferedAiCtrl();

try
    % Step 2: Select a device by device number or device description and
    % specify the access mode. in this example we use 
    % AccessWriteWithReset(default) mode so that we can 
    % fully control the device, including configuring, sampling, etc.
    bufferedAiCtrl.SelectedDevice = Automation.BDaq.DeviceInformation(...
        deviceDescription);

    % Step 3: Set necessary parameters for Asynchronous One Buffered AI
    % operation.
    scanChannel = bufferedAiCtrl.ScanChannel;
    scanChannel.ChannelStart = startChannel;
    scanChannel.ChannelCount = channelCount;
    scanChannel.Samples = sampleCount;
    convertClock = bufferedAiCtrl.ConvertClock;
    convertClock.Rate = convertClkRate;

    % Step 4: Prepare the buffered AI. 
    errorCode =  bufferedAiCtrl.Prepare();
    if BioFailed(errorCode)
        throw Exception();
    end
    
    % Step 5: Start buffered AI, 'RunOnce' indicates using synchronous 
    % mode, which means the method will not return until the acquisition is
    % completed.
    disp('SynchronousOneBufferedAI is in progress.');
    disp('Please wait, until acquisition complete.');
    errorCode = bufferedAiCtrl.RunOnce();
    if BioFailed(errorCode)
        throw Exception();
    end
    
    % Step 6: Read samples and do post-process.
    scaledData = NET.createArray('System.Double', sampleCount);
    errorCode = bufferedAiCtrl.GetData(sampleCount,scaledData);
    
    disp('Acquisition has completed!');
    figure('NumberTitle', 'off', 'Name', 'SynchronousOneBufferedAI');
    plot(scaledData);
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

% Step 7: Close device, release any allocated resource.
bufferedAiCtrl.Dispose();

end

function result = BioFailed(errorCode)

result =  errorCode < Automation.BDaq.ErrorCode.Success && ...
    errorCode >= Automation.BDaq.ErrorCode.ErrorHandleNotValid;

end

