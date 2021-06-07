%    1. Set the 'deviceDescription' for opening the device. 
%    2. Set the 'channelStart' as the first channel for frequency measure.
%    3. Set the 'channelCount' to decide how many sequential channels to 
%       measure frequency.

function FrequencyMeasurement()

% Make Automation.BDaq assembly visible to MATLAB.
BDaq = NET.addAssembly('Automation.BDaq');

% Configure the following parameters before running the demo.
% The default device of project is demo device, users can choose other 
% devices according to their needs. 
deviceDescription = 'DemoDevice,BID#0'; 
channel = int32(0);
collectionPeriod = double(0);

% Step 1: Create a 'FreqMeterCtrl' for Frequency Measurement function.
freqMeterCtrl = Automation.BDaq.FreqMeterCtrl();

try
    % Step 2: Select a device by device number or device description and 
    % specify the access mode. In this example we use 
    % AccessWriteWithReset(default) mode so that we can fully control the 
    % device, including configuring, sampling, etc.
    freqMeterCtrl.SelectedDevice = Automation.BDaq.DeviceInformation(...
        deviceDescription);
    
    % Step 3: Set necessary parameters for Frequency measurement operation.
    freqMeterCtrl.Channel = channel;
    freqMeterCtrl.CollectionPeriod = collectionPeriod;
    
    % Step 4: Start Frequency Measurement
    freqMeterCtrl.Enabled = true;
    
    % Step 5: Read frequency value.
    fprintf('FrequencyMeasurement is in progress...\n');
    fprintf('Connect the input signal to CNT#_CLK pin');
    fprintf(' if you choose external clock!\n');
    t = timer('TimerFcn', {@TimerCallback, freqMeterCtrl, channel}, ... 
        'period', 1, 'executionmode', 'fixedrate', 'StartDelay', 1);
    start(t);
    input('Press Enter key to quit!\n\n','s');
 
    % Step 6: Stop Frequency Measurement
    freqMeterCtrl.Enabled = false;
    stop(t);
    delete(t);
catch e
    % Something is wrong. 
    errStr = e.message;
    disp(errStr);
end   

% Step 7: Close device and release any allocated resource.
freqMeterCtrl.Dispose();

end

function TimerCallback(obj, event, freqMeterCtrl, channel)

fprintf('channel %d Current frequency: %fHz\n', channel, ...
    freqMeterCtrl.Value);

end

























