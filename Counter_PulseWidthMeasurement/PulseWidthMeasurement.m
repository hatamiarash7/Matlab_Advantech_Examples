%    1. Set the 'deviceDescription' for opening the device. 
%    2. Set the 'channelStart' as the first channel for PwMeter.
%    3. Set the 'groupCount' to decide how many sequential groups to 
%       measure pulse width.

function PulseWidthMeasurement()

% Make Automation.BDaq assembly visible to MATLAB.
BDaq = NET.addAssembly('Automation.BDaq');

% Configure the following three parameters before running the demo.
% The default device of project is demo device, users can choose other 
% devices according to their needs. 
deviceDescription = 'DemoDevice,BID#0'; 
channel = int32(0);

% Step 1: Create a 'PwMeterCtrl' for Pulse Width Measurement function.
pwMterCtrl = Automation.BDaq.PwMeterCtrl();

try
    % Step 2: Select a device by device number or device description and 
    % specify the access mode. In this example we use 
    % AccessWriteWithReset(default) mode so that we can fully control the 
    % device, including configuring, sampling, etc.
    pwMterCtrl.SelectedDevice = Automation.BDaq.DeviceInformation(...
        deviceDescription);
    
    % Step 3: Set necessary parameters for counter operation.
    pwMterCtrl.Channel = channel;
    
    % Step 4: Start PulseWidthMeasurement
    pwMterCtrl.Enabled = true;
    
    % Step 5: Get Pulse Width value.
    fprintf('PulseWidthMeasurement is in progress...\n');
    fprintf('Connect the input signal to the connector.\n');
    t = timer('TimerFcn', {@TimerCallback, pwMterCtrl}, 'period', 1, ...
        'executionmode', 'fixedrate', 'StartDelay', 1);
    start(t);
    input('Press Enter key to quit!\n\n','s');
 
    % Step 6: Stop PulseWidthMeasurement
    pwMterCtrl.Enabled = false;
    stop(t);
    delete(t);
catch e
    % Something is wrong. 
    errStr = e.message;
    disp(errStr);
end   

% Step 7: Close device and release any allocated resource.
pwMterCtrl.Dispose();

end

function TimerCallback(obj, event, pwMterCtrl)

fprintf('High Period:%f s, Low Period: %f s\n', ...
    pwMterCtrl.Value.HiPeriod, pwMterCtrl.Value.LoPeriod);

end

























