%    1. Set the 'deviceDescription' for opening the device. 
%    2. Set the 'startPort' as the first port for Di scanning.
%    3. Set the 'portCount' to decide how many sequential ports to 
%       operate Di scanning.

function DIInterrupt()

% Make Automation.BDaq assembly visible to MATLAB.
BDaq = NET.addAssembly('Automation.BDaq');

% Configure the following parameters before running the demo.
% The default device of project is demo device, users can choose other 
% devices according to their needs. 
deviceDescription = 'DemoDevice,BID#0';

errorCode = Automation.BDaq.ErrorCode.Success;
% Step 1: Create a 'InstantDiCtrl' for DI function.
instantDiCtrl = Automation.BDaq.InstantDiCtrl();

% Step 2: Set the notification event Handler by which we can known the 
% state of operation effectively.
addlistener(instantDiCtrl, 'Interrupt', @instantDiCtrl_Interrupt);

try
    % Step 3: Select a device by device number or device description and 
    % specify the access mode. In this example we use 
    % AccessWriteWithReset(default) mode so that we can fully control the 
    % device, including configuring, sampling, etc.
    instantDiCtrl.SelectedDevice = Automation.BDaq.DeviceInformation(...
        deviceDescription);
    
    diintChannels = instantDiCtrl.DiintChannels;
    if ~isempty(diintChannels)
       fprintf('DI channel %d is used to detect interrupt!\n\n',...
           diintChannels(1).Channel); 
    else
       e = MException('DAQError:NotSupport', ...
           'The device doesn''t support DI channel interrupt!');
       throw (e);
    end
    
    % Step 4: Set necessary parameters for DI operation.
    diintChannels(1).Enabled = true;
    
    % Step 5: Start DIInterrupt
    errorCode = instantDiCtrl.SnapStart();
    if BioFailed(errorCode)
        throw Exception(); 
    end
    
    % Step 6: Do anything you are interesting while the device is working.
    input('DI Snap has started, press Enter key to quit !\n', 's');
    
    % Step 7: Stop DIInterrupt
    diintChannels(1).Enabled = false;
    errorCode = instantDiCtrl.SnapStop();
    if BioFailed(errorCode)
        throw Exception(); 
    end
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

% Step 8: Close device, release any allocated resource.
instantDiCtrl.Dispose();

end

function result = BioFailed(errorCode)

result =  errorCode < Automation.BDaq.ErrorCode.Success && ...
    errorCode >= Automation.BDaq.ErrorCode.ErrorHandleNotValid;

end

function instantDiCtrl_Interrupt(sender, e)

fprintf('DI channel %d interrupt occurred!\n', e.SrcNum);
instantDiCtrl = sender;
for j = 0:(instantDiCtrl.Features.PortCount - 1)
    fprintf('DI port %d status is 0x%X\n', j, e.PortData.Get(j));
end
fprintf('\n');

end






















