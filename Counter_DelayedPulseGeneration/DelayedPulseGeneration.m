%    1. Set the 'deviceDescription' for opening the device. 
%    2. Set the 'channelStart' as the first channel for one Pulse shot.
%    3. Set the 'channelCount' to decide how many sequential channels to  
%       operate oneShot.

function DelayedPulseGeneration()

% Make Automation.BDaq assembly visible to MATLAB.
BDaq = NET.addAssembly('Automation.BDaq');

% Configure the following parameters before running the demo.
% The default device of project is demo device, users can choose other 
% devices according to their needs. 
deviceDescription = 'DemoDevice,BID#0'; 
channel = int32(0);
delayCount = int32(1000);

% Step 1: Create a 'OneShotCtrl' for Delayed Pulse Generation function.
oneShotCtrl = Automation.BDaq.OneShotCtrl();

% Step 2: Set the notification event Handler by which we can known 
% the state of operation effectively.
addlistener(oneShotCtrl, 'OneShot', @oneShotCtrl_OneShot);

try
    % Step 3: Select a device by device number or device description and 
    % specify the access mode. In this example we use 
    % AccessWriteWithReset(default) mode so that we can fully control the 
    % device, including configuring, sampling, etc.
    oneShotCtrl.SelectedDevice = Automation.BDaq.DeviceInformation(...
        deviceDescription);
    
    % Step 4: Set necessary parameters for counter operation.
    oneShotCtrl.Channel = channel;
    oneShotCtrl.DelayCount = delayCount;
    
    % Step 5: Start DelayedPulseGeneration. 
    fprintf('DelayedPulseGeneration is in progress...\n');
    fprintf('Give a low level signal to Gate pin and Test');
    fprintf(' the pulse signal on the Out pin !\n');
    oneShotCtrl.Enabled = true;
    
    % Step 6: Do anything you are interesting while the device is working.
    input('Press Enter key to quit!\n','s');
    
    % Step 7: stop DelayedPulseGeneration function
    oneShotCtrl.Enabled = false;
    clear functions 
catch e
    % Something is wrong. 
    errStr = e.message;
    disp(errStr);
end   

% Step 8: Close device and release any allocated resource.
oneShotCtrl.Dispose();

end

function oneShotCtrl_OneShot(sender, e)

persistent delayedPulseOccursCount;
if isempty(delayedPulseOccursCount)
    delayedPulseOccursCount = 0;
end
delayedPulseOccursCount = delayedPulseOccursCount + 1;
fprintf('\nchannel %d ''s Delayed Pulse occurs %d time(times)\n', ...
    e.Channel, delayedPulseOccursCount);

end 























