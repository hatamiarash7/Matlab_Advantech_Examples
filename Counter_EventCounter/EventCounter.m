%    1. Set the 'deviceDescription' for opening the device. 
%    2. Set the 'channelStart' as the first channel for Event counting.
%    3. Set the 'channelCount' to decide how many sequential channels to  
%       count event.

function EventCounter()

% Make Automation.BDaq assembly visible to MATLAB.
BDaq = NET.addAssembly('Automation.BDaq');

% Configure the following parameters before running the demo.
% The default device of project is demo device, users can choose other 
% devices according to their needs. 
deviceDescription = 'DemoDevice,BID#0'; 
channel = int32(0);
errorCode = Automation.BDaq.ErrorCode.Success;

% Step 1: Create a 'EventCounterCtrl' for Event Counter function.
eventCounterCtrl = Automation.BDaq.EventCounterCtrl();

try
    % Step 2: Select a device by device number or device description and 
    % specify the access mode. In this example we use 
    % AccessWriteWithReset(default) mode so that we can fully control the 
    % device, including configuring, sampling, etc.
    eventCounterCtrl.SelectedDevice = Automation.BDaq.DeviceInformation(...
        deviceDescription);
    
    % Step 3: Set necessary parameters for counter operation.
    eventCounterCtrl.Channel = channel;
    
    % Step 4: Start EventCounter 
    eventCounterCtrl.Enabled = true;
    
    % Step 5: Read counting value: connect the input signal to channels 
    % you selected to get event counter value.
    fprintf('EventCounter is in progress...\nConnect the input signal');
    fprintf(' to CNT#_CLK pin if you choose external clock!\n');
    t = timer('TimerFcn', {@TimerCallback, eventCounterCtrl, channel}, ...
        'period', 1, 'executionmode', 'fixedrate', 'StartDelay', 1);
    start(t);
    input('Press Enter key to quit!\n','s');
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

% Step 6: stop EventCounter
eventCounterCtrl.Enabled = false;
stop(t);
delete(t);

% Step 7: Close device and release any allocated resource.
eventCounterCtrl.Dispose();

end

function result = BioFailed(errorCode)

result =  errorCode < Automation.BDaq.ErrorCode.Success && ...
    errorCode >= Automation.BDaq.ErrorCode.ErrorHandleNotValid;

end

function TimerCallback(obj, event, eventCounterCtrl, channel)

fprintf('channel %d Current Event counts  :%d\n',channel, ...
    eventCounterCtrl.Value);

end 























