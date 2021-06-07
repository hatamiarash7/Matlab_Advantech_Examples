%    1. Set the 'deviceDescription' for opening the device. 
%    2. Set the 'channelStart' as the first channel for pulse generation.
%    3. Set the 'channelCount' to decide how many sequential channels to   
%       operate pulse generation.
%    4. Set the 'poHiPeriod' to decide the high level pulse width for 
%       selected channel. 
%    5. Set the 'poLoPeriod' to decide the low level pulse width for 
%       selected channel.

function PWMOutput()

% Make Automation.BDaq assembly visible to MATLAB.
BDaq = NET.addAssembly('Automation.BDaq');

% Configure the following four parameters before running the demo.
% The default device of project is demo device, users can choose other 
% devices according to their needs. 
deviceDescription = 'DemoDevice,BID#0'; 
channel = int32(0);
pulseWidth = Automation.BDaq.PulseWidth(double(0.08), double(0.02));

% Step 1: Create a 'PwModulatorCtrl' for PWM Output function.
pwModulatorCtrl = Automation.BDaq.PwModulatorCtrl();

try
    % Step 2: Select a device by device number or device description and 
    % specify the access mode. In this example we use 
    % AccessWriteWithReset(default) mode so that we can fully control the 
    % device, including configuring, sampling, etc.
    pwModulatorCtrl.SelectedDevice = Automation.BDaq.DeviceInformation(...
        deviceDescription);
    
    % Step 3: Set necessary parameters for counter operation.
    pwModulatorCtrl.Channel = channel;
    pwModulatorCtrl.PulseWidth = pulseWidth;
    
    % Step 4: Start PWMOutput 
    fprintf('PWMOutput is in progress...\nTest signal to the Out pin!');
    pwModulatorCtrl.Enabled = true;
    
    % Step 5: Stop PWMOutput
    input('\nPress Enter key to quit!\n','s');
    pwModulatorCtrl.Enabled = false;
catch e
    % Something is wrong. 
    errStr = e.message;
    disp(errStr);
end   

% Step 6: Close device and release any allocated resource.
pwModulatorCtrl.Dispose();

end


























