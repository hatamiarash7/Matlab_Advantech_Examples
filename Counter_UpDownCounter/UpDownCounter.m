%    1. Set the 'deviceDescription' for opening the device. 
%    2. Set the 'channel' as the work channel for UpDown counter.

function UpDownCounter()

% Make Automation.BDaq assembly visible to MATLAB.
BDaq = NET.addAssembly('Automation.BDaq');

% Configure the following parameters before running the demo.
% The default device of project is demo device, users can choose other 
% devices according to their needs. 
deviceDescription = 'PCI-1784,BID#0'; 
channel = int32(0);

% Step 1: Create a 'UdCounterCtrl' for UpDown Counter function.
udCounterCtrl = Automation.BDaq.UdCounterCtrl();

try
    % Step 2: Select a device by device number or device description and 
    % specify the access mode. In this example we use 
    % AccessWriteWithReset(default) mode so that we can fully control the 
    % device, including configuring, sampling, etc.
    udCounterCtrl.SelectedDevice = Automation.BDaq.DeviceInformation(...
        deviceDescription);
    
    % Step 3: Set necessary parameters for counter operation.
    udCounterCtrl.Channel = channel;
    
    % Step 4: Set counting type for UpDown Counter.
    % counting type : CountingNone,DownCount,UpCount,PulseDirection,
    % TwoPulse,AbPhaseX1,AbPhaseX2,AbPhaseX4.
    signalCountingType = Automation.BDaq.SignalCountingType.AbPhaseX1;
    udCounterCtrl.CountingType = signalCountingType;
    
    % Step 5: Start UpDown Counter. 
    udCounterCtrl.Enabled = true;
    
    % Step 6: Read counting value: connect the input signal to channels
    % you selected to get event counter value.
    fprintf('UpDown Counter is in progress...\n');
    fprintf('Connect the input signal to the connector.\n');
    t = timer('TimerFcn',{@TimerCallback, udCounterCtrl, channel}, ...
        'period', 1, 'executionmode', 'fixedrate', 'StartDelay', 1);
    start(t);
    input('Press Enter key to quit!\n\n','s');
 
    % Step 7: Stop UpDown Counter.
    udCounterCtrl.Enabled = false;
    stop(t);
    delete(t);
catch e
    % Something is wrong. 
    errStr = e.message;
    disp(errStr);
end   

% Step 8: Close device and release any allocated resource.
udCounterCtrl.Dispose();

end

function TimerCallback(obj, event, udCounterCtrl, channel)

fprintf('channel %d Current UpDown counter counts  :%d\n\n', ...
    channel, udCounterCtrl.Value);

end
