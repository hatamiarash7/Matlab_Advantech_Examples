%    1. Set the 'deviceDescription' for opening the device. 
%    2. Set the 'startPort' as the first port for Do outputting.
%    3. Set the 'portCount' to decide how many sequential ports to 
%       operate Do outputting.
%    4. Set pattern match channels and values for supported ports in 
%       system device manager configuration.

function DIPatternMatchInterrupt()

% Make Automation.BDaq assembly visible to MATLAB.
BDaq = NET.addAssembly('Automation.BDaq');

% Configure the following three parameters before running the demo.
% The default device of project is demo device, users can choose other 
% devices according to their needs. 
deviceDescription = 'DemoDevice,BID#0';
enabledChannels = uint8(255);
patternMatchValue = uint8(255);
errorCode = Automation.BDaq.ErrorCode.Success;

% Step 1: Create a 'InstantDiCtrl' for DI function.
instantDiCtrl = Automation.BDaq.InstantDiCtrl();

% Step 2: Set the notification event Handler by which we can known the 
% state of operation effectively.
addlistener(instantDiCtrl, 'PatternMatch', @instantDiCtrl_PatternMatch);

try
    % Step 3: Select a device by device number or device description and 
    % specify the access mode. In this example we use 
    % AccessWriteWithReset(default) mode so that we can fully control the 
    % device, including configuring, sampling, etc.
    instantDiCtrl.SelectedDevice = Automation.BDaq.DeviceInformation(...
        deviceDescription);
    
    diPmintPorts = instantDiCtrl.DiPmintPorts;
    if ~isempty(diPmintPorts)
       fprintf('DI Port %d is used to detect pattern match!\n', ...
           diPmintPorts(1).Port); 
    else
       e = MException('DAQError:NotSupport', ...
           'The device doesn''t support DI pattern match interrupt!');
       throw (e);
    end
    
    % Step 4: Set necessary parameters for DI operation.
    % Enable channel to decide which port is used, default is no channel 
    % enabled
    diPmintPorts(1).Mask = enabledChannels;
    diPmintPorts(1).Pattern = patternMatchValue;
    
    % Step 5: Start PatternMatchInterrupt
    errorCode = instantDiCtrl.SnapStart();
    if BioFailed(errorCode)
        throw Exception(); 
    end
    
    % Step 6: Do anything you are interesting while the device is working.
    input('Snap has started, press Enter key to quit!\n\n','s');
    
    % Step 7: Stop PatternMatchInterrupt
    diPmintPorts(1).Mask = 0;
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

function instantDiCtrl_PatternMatch(sender, e)

fprintf('DI Port %d pattern match occurred!\n', e.SrcNum);
instantDiCtrl = sender;
for i=0:(instantDiCtrl.Features.PortCount - 1)
    fprintf('DI port %d status :0x%X\n', i, e.PortData.Get(i));
end
fprintf('\n');

end






















