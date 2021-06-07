%    1. Set the 'deviceDescription' for opening the device. 
%    2. Set the 'channelStart' as the first channel for pulse generation.
%    3. Set the 'channelCount' to decide how many sequential channels to  
%       operate pulse generation.
%    4. Set the 'frequency' to decide the frequency of pulse for
%       selected channel.

function PulseOutputwithTimerInterrupt()

% Make Automation.BDaq assembly visible to MATLAB.
BDaq = NET.addAssembly('Automation.BDaq');

% Configure the following parameters before running the demo.
% The default device of project is demo device, users can choose other 
% devices according to their needs. 
deviceDescription = 'DemoDevice,BID#0'; 
moduleIndex = int32(0);
channel = int32(0);
frequency = double(10.0);

% Step 1: Step 1: Create a 'TimerPulseCtrl' for Pulse Output with 
% Timer Interrupt function.
timerPulseCtrl = Automation.BDaq.TimerPulseCtrl();

try
    % Step 2: Select a device by device number or device description and 
    % specify the access mode. In this example we use 
    % AccessWriteWithReset(default) mode so that we can fully control the 
    % device, including configuring, sampling, etc.
    devInfo = Automation.BDaq.DeviceInformation(deviceDescription);
    devInfo.ModuleIndex = moduleIndex;
    timerPulseCtrl.SelectedDevice = devInfo;
    
    % Step 3: Set necessary parameters for counter operation.
    timerPulseCtrl.Channel = channel;
    timerPulseCtrl.Frequency = frequency;
    
    fprintf('PulseOutputwithTimerInterrupt is in progress...\n');
    fprintf('Test signal to the Out pin !\n');
    
    % Step 4: Start PulseOutputwithTimerInterrupt
    timerPulseCtrl.Enabled = true;
    input('Press Enter key to quit!\n','s');
    
    % Step 5: Stop PulseOutputwithTimerInterrupt
    timerPulseCtrl.Enabled = false;    
catch e
    % Something is wrong. 
    errStr = e.message;
    disp(errStr);
end   

% Step 6: Close device and release any allocated resource.
timerPulseCtrl.Dispose();

end
























