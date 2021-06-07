%    1. Set the 'deviceDescription' for opening the device. 
%    2. Set the 'channelStart' as the first channel for  analog data
%       Output. 
%    3. Set the 'channelCount' to decide how many sequential channels to
%       output analog data. 

function StaticAO()

% Make Automation.BDaq assembly visible to MATLAB.
BDaq = NET.addAssembly('Automation.BDaq');

% Define how many data to makeup a waveform period.
oneWavePointCount = int32(512);

% Configure the following three parameters before running the demo.
% The default device of project is demo device, users can set other devices 
% according to their needs. 
deviceDescription = 'DemoDevice,BID#0';
channelStart = int32(0);
channelCount = int32(1);

% Declare the type of signal. If you want to specify the type of output 
% signal, please change 'style' parameter in the GenerateWaveform function.
parent_id = H5T.copy('H5T_NATIVE_UINT');
WaveStyle = H5T.enum_create(parent_id);
H5T.enum_insert(WaveStyle, 'Sine', 0);
H5T.enum_insert(WaveStyle, 'Sawtooth', 1);
H5T.enum_insert(WaveStyle, 'Square', 2);
H5T.close(parent_id);

errorCode = Automation.BDaq.ErrorCode.Success;

% Step 1: Create a 'InstantAoCtrl' for Instant AO function.
instantAoCtrl = Automation.BDaq.InstantAoCtrl();

try
    % Step 2: Select a device by device number or device description and 
    % specify the access mode. In this example we use 
    % AccessWriteWithReset(default) mode so that we can fully control the 
    % device, including configuring, sampling, etc.
    instantAoCtrl.SelectedDevice = Automation.BDaq.DeviceInformation(...
        deviceDescription);
    
    % Step 3: Output data. 
    % Generate waveform data.
    scaledWaveForm = NET.createArray('System.Double', channelCount * ...
        oneWavePointCount);
    errorCode = GenerateWaveform(instantAoCtrl, channelStart, ...
        channelCount, scaledWaveForm, channelCount * oneWavePointCount, ...
        H5T.enum_nameof(WaveStyle, int32(0)));
    if BioFailed(errorCode)    
        throw Exception();
    end

    % Output data
    scaleData = NET.createArray('System.Double', int32(64));
    
    t = timer('TimerFcn',{@TimerCallback, instantAoCtrl, ...
        oneWavePointCount, scaleData, scaledWaveForm, channelStart, ...
        channelCount}, 'period', 0.1, 'executionmode', 'fixedrate', ...
        'StartDelay', 1);
    start(t);
    input('Outputting data...Press Enter key to quit!', 's');
    if isvalid(t)
    disp('StaticAO is completed compulsorily!');    
    stop(t);
    delete(t); 
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

% Step 4: Close device and release any allocated resource.
instantAoCtrl.Dispose();
H5T.close(WaveStyle);

end

function errorcode = GenerateWaveform(instantAoCtrl, channelStart,...
    channelCount, waveBuffer, SamplesCount, style)

errorcode = Automation.BDaq.ErrorCode.Success;
chanCountMax = int32(instantAoCtrl.Features.ChannelCountMax);
oneWaveSamplesCount = int32(SamplesCount / channelCount);

description = System.Text.StringBuilder();
unit = Automation.BDaq.ValueUnit;
ranges = NET.createArray('Automation.BDaq.MathInterval', chanCountMax); 

% get every channel's value range ,include external reference voltage
% value range which you should key it in manually.
channels = instantAoCtrl.Channels;
for i = 1:chanCountMax
    channel = channels.Get(i - 1);
    valRange = channel.ValueRange;
    if Automation.BDaq.ValueRange.V_ExternalRefBipolar == valRange ...
            || valRange == Automation.BDaq.ValueRange.V_ExternalRefUnipolar
        if instantAoCtrl.Features.ExternalRefAntiPolar
            if valRange == Automation.BDaq.ValueRange.V_ExternalRefBipolar
                referenceValue = double(...
                    instantAoCtrl.ExtRefValueForBipolar);
                if referenceValue >= 0
                    ranges(i).Max = referenceValue;
                    ranges(i).Min = 0 - referenceValue;
                else
                    ranges(i).Max = 0 - referenceValue;
                    ranges(i).Min = referenceValue;                    
                end
            else
               referenceValue = double(...
                   instantAoCtrl.ExtRefValueForUnipolar); 
               if referenceValue >= 0
                   ranges(i).Max = 0;
                   ranges(i).Min = 0 - referenceValue;
               else
                   ranges(i).Max = 0 - referenceValue;
                   ranges(i).Min = 0;
               end 
            end
        else
            if valRange == Automation.BDaq.ValueRange.V_ExternalRefBipolar
                referenceValue = double(...
                    instantAoCtrl.ExtRefValueForBipolar);
                if referenceValue >= 0
                    ranges(i).Max = referenceValue;
                    ranges(i).Min = 0 - referenceValue;
                else
                    ranges(i).Max = 0 - referenceValue;
                    ranges(i).Min = referenceValue;                    
                end
            else
                referenceValue = double(...
                    instantAoCtrl.ExtRefValueForUnipolar);
                if referenceValue >= 0
                    ranges(i).Max = referenceValue;
                    ranges(i).Min = 0;
                else
                    ranges(i).Max = 0;
                    ranges(i).Min = 0 - referenceValue;
                end
            end
        end
    else     
        [errorcode, ranges(i), unit] = ...
            Automation.BDaq.BDaqApi.AdxGetValueRangeInformation(...
            valRange, int32(0), description);
        if BioFailed(errorcode)
            return
        end
    end
end

% generate waveform data and put them into the buffer which the parameter
% 'waveBuffer' give in, the Amplitude these waveform
for i = 0:(oneWaveSamplesCount - 1)
    for j = channelStart:(channelStart + channelCount - 1)
        % pay attention to channel rollback(when startChannel+
        % channelCount>chanCountMax)
        channel = int32(rem(j, chanCountMax));
        
        amplitude = double((ranges.Get(channel).Max -...
            ranges.Get(channel).Min) / 2);
        offset = double((ranges.Get(channel).Max + ...
            ranges.Get(channel).Min) / 2);
        switch style
            case 'Sine'
                waveBuffer.Set(i * channelCount + j - channelStart,...
                    amplitude * sin(double(i) * 2.0 * pi / ...
                    double(oneWaveSamplesCount)) + offset);
            case 'Sawtooth'
                if (i >= 0) && (i < (oneWaveSamplesCount / 4.0))
                    waveBuffer.Set(i * channelCount + j - channelStart,...
                        amplitude * (double(i) / ...
                        (double(oneWaveSamplesCount) / 4.0)) + offset);
                else
                    if (i >= (oneWaveSamplesCount / 4.0)) && ...
                            (i < 3 * (oneWaveSamplesCount / 4.0))
                        waveBuffer.Set(i * channelCount + j - ...
                            channelStart, amplitude * ((2.0 * ...
                            (double(oneWaveSamplesCount) / 4.0) - ...
                            double(i)) / (double(oneWaveSamplesCount) ...
                            / 4.0)) + offset);
                    else
                        waveBuffer.Set(i * channelCount + j - ...
                            channelStart, amplitude * ((double(i) - ...
                            double(oneWaveSamplesCount)) / ...
                            (double(oneWaveSamplesCount) / 4.0)) + offset);
                    end
                end
            case 'Square'
                if (i >= 0) && (i < (oneWaveSamplesCount / 2))
                    waveBuffer.Set(i * channelCount + j - channelStart, ...
                        amplitude * 1.0 + offset);
                else
                     waveBuffer.Set(i * channelCount + j - channelStart,...
                         amplitude * (-1.0) + offset);
                end
        end
    end
end

end

function result = BioFailed(errorCode)

result =  errorCode < Automation.BDaq.ErrorCode.Success && ...
    errorCode >= Automation.BDaq.ErrorCode.ErrorHandleNotValid;

end

function TimerCallback(obj, event, instantAoCtrl, oneWavePointCount, ...
    scaleData, scaledWaveForm, channelStart, channelCount)

persistent i ;
if isempty(i)
    i = 0;
else
    i = i + 1;
end
j = 0;
if i <= (oneWavePointCount - 1)
    if j <= (channelCount - 1)
        scaleData.Set(j, scaledWaveForm.Get(channelCount * i + j));
        errorCode = instantAoCtrl.Write(channelStart,...
            channelCount, scaleData);
        if BioFailed(errorCode)
            e = MException('DAQWarning:Notcompleted', ...
                'StaticAO is completed compulsorily!');
            throw (e);
        end
    end
else
    fprintf('\nStaticAO is completed, and press Enter key to quit!');
    clear functions;
    stop(obj);
    delete(obj);
end

end
 



















