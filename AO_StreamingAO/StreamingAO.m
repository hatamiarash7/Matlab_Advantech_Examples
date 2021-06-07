%    1. Set the 'deviceDescription' for opening the device. 
%    2. Set the 'channelStart' as the first channel for  analog data
%       Output. 
%    3. Set the 'channelCount' to decide how many sequential channels to
%       output analog data. 
%    4. Set the 'intervalCount'to decide what occasion to signal event;
%       when one section it is capacity decided by 'intervalCount*
%       channelCount' in kernel buffer(the capacity decided by 'sampleCount
%       *channelCount' )output over,driver signal a 'DataTransmitted' event 
%       to notify APP.
%       ( ***Notes: the buffer is divided up with many sections begin with
%               buffer's head, the last section may not be equal to
%               'intervalCount*channelCount' if the 'sampleCount' is not an
%               integer multiple of 'intervalCount',but the last section 
%               output over , driver signal 'DataTransmitted' event too. 
%               ***)
%    5. Set the 'sampleCount' to decide the capacity of buffer in kernel.
%    6. Set the 'convertClkRate' to tell driver output data rate for each 
%       channel.  

function StreamingAO()

% Make Automation.BDaq assembly visible to MATLAB.
BDaq = NET.addAssembly('Automation.BDaq');

% Define how many data to makeup a waveform period.
oneWavePointCount = int32(2048);

% Configure the following six parameters before running the demo.
% The default device of project is demo device, users can choose 
% other devices according to their needs. 
deviceDescription = 'DemoDevice,BID#0';
channelStart = int32(0);
channelCount = int32(1);
% For each channel, to decide the capacity of buffer in kernel.
% divided by 2 is ensure that: intervalCount is greater than or
% equal to half of the sampleCount. 
% user can set 'intervalCount' according to demand for each channel;
intervalCount = int32(oneWavePointCount / 2);
% Recommend: sampleCount is an integer multiple of intervalCount, and is 
% equal to twice or greater for each channel;
sampleCount = int32(oneWavePointCount);
convertClkRate = int32(1000);

% Declare the type of signal. If you want to specify the type of output 
% signal, please change 'style' parameter in the GenerateWaveform function.
parent_id = H5T.copy('H5T_NATIVE_UINT');
WaveStyle = H5T.enum_create(parent_id);
H5T.enum_insert(WaveStyle, 'Sine', 0);
H5T.enum_insert(WaveStyle, 'Sawtooth', 1);
H5T.enum_insert(WaveStyle, 'Square', 2);
H5T.close(parent_id);

errorCode = Automation.BDaq.ErrorCode.Success;

% Step 1: Create a 'BufferedAoCtrl' for buffered AO function.
bufferedAoCtrl = Automation.BDaq.BufferedAoCtrl();

% Step 2: Set the notification event Handler by which we can known the 
% state of operation effectively.
addlistener(bufferedAoCtrl, 'Stopped', ...
    @bufferedAoCtrl_Stopped);
addlistener(bufferedAoCtrl, 'Underrun', ...
    @bufferedAoCtrl_Underrun);
addlistener(bufferedAoCtrl, 'TransitStopped', ...
    @bufferedAoCtrl_TransitStopped);
addlistener(bufferedAoCtrl, 'DataTransmitted', ...
    @bufferedAoCtrl_DataTransmitted);

try
    % Step 3: Select a device by device number or device description and 
    % specify the access mode. In this example we use 
    % AccessWriteWithReset(default) mode so that we can fully control the 
    % device, including configuring, sampling, etc.
    bufferedAoCtrl.SelectedDevice = Automation.BDaq.DeviceInformation(...
        deviceDescription);
    % specify the running mode: streaming-buffered.
    bufferedAoCtrl.Streaming = true;
    
    % Step 4: Set necessary parameters for Asynchronous One Buffered 
    % AO operation. 
    scanChannel = bufferedAoCtrl.ScanChannel;
    scanChannel.ChannelStart = channelStart;
    scanChannel.ChannelCount = channelCount;
    scanChannel.IntervalCount = intervalCount;
    scanChannel.Samples = sampleCount;
    
    convertClock = bufferedAoCtrl.ConvertClock;
    convertClock.Rate = convertClkRate;
    
    % Step 5: prepare the buffered AO.
    errorCode = bufferedAoCtrl.Prepare();
    if BioFailed(errorCode)    
        throw Exception();
    end    
    
    % Generate waveform data
    userBufferLength = int32(channelCount * sampleCount);
    scaledWaveForm = NET.createArray('System.Double', userBufferLength);
    errorCode = GenerateWaveform(bufferedAoCtrl, channelStart, ...
        channelCount, scaledWaveForm, userBufferLength, ...
        H5T.enum_nameof(WaveStyle, int32(0)));
    if BioFailed(errorCode)    
        throw Exception();
    end
    bufferedAoCtrl.SetData(scaledWaveForm.Length, scaledWaveForm);
    
    % Step 6: Start streaming AO, 'streaming' indicates using asynchronous
    % streaming mode, which means the method returns immediately and 
    % output data continue to stop enforced.
    errorCode = bufferedAoCtrl.Start();
    if BioFailed(errorCode)    
        throw Exception();
    end
    
    % Step 7: Do anything you are interesting while the device is
    % outputting data.
    input('Outputting data... Press Enter key to quit!', 's');
    
    % step 8: Stop the operation if it is running.
    errorCode = bufferedAoCtrl.Stop(1);
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

% Step 9: Close device and release any allocated resource.
bufferedAoCtrl.Dispose();
H5T.close(WaveStyle);

end

function bufferedAoCtrl_DataTransmitted(sender, e)

fprintf('\nBufferedAO DataTransmitted: offset = %d, count = %d', ...
    e.Offset, e.Count);
% in this example, we generate the data once and output it again and again,
% if you want to renew it, reference the follow code.
% ((BufferedAoCtrl)sender).SetData( e.Count,Wavebuffer);

end

function bufferedAoCtrl_TransitStopped(sender, e)

fprintf('\nBufferedAO TransitStopped: offset = %d, count = %d', ...
    e.Offset, e.Count);

end

function bufferedAoCtrl_Underrun(sender, e)

fprintf('\nBufferedAO Underrun: offset = %d, count = %d', ...
    e.Offset, e.Count);

end

function bufferedAoCtrl_Stopped(sender, e)

fprintf('\nBufferedAO Stopped: offset = %d, count = %d', ...
    e.Offset, e.Count);

end

function errorcode = GenerateWaveform(buffAoCtrl, channelStart, ...
    channelCount, waveBuffer, SamplesCount, style)

errorcode = Automation.BDaq.ErrorCode.Success;
chanCountMax = int32(buffAoCtrl.Features.ChannelCountMax);
oneWaveSamplesCount = int32(SamplesCount / channelCount);

description = System.Text.StringBuilder();
unit = Automation.BDaq.ValueUnit;
ranges = NET.createArray('Automation.BDaq.MathInterval',chanCountMax); 

% get every channel's value range ,include external reference voltage
% value range which you should key it in manually.
channels = buffAoCtrl.Channels;
for i = 1:chanCountMax
    channel = channels.Get(i - 1);
    valRange = channel.ValueRange;
    if Automation.BDaq.ValueRange.V_ExternalRefBipolar == valRange ...
            || valRange == Automation.BDaq.ValueRange.V_ExternalRefUnipolar
        if buffAoCtrl.Features.ExternalRefAntiPolar
            if valRange == Automation.BDaq.ValueRange.V_ExternalRefBipolar
                referenceValue = double(...
                    buffAoCtrl.ExtRefValueForBipolar);
                if referenceValue >= 0
                    ranges(i).Max = referenceValue;
                    ranges(i).Min = 0 - referenceValue;
                else
                    ranges(i).Max = 0 - referenceValue;
                    ranges(i).Min = referenceValue;                    
                end
            else
               referenceValue = double(...
                   buffAoCtrl.ExtRefValueForUnipolar); 
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
                    buffAoCtrl.ExtRefValueForBipolar);
                if referenceValue >= 0
                    ranges(i).Max = referenceValue;
                    ranges(i).Min = 0 - referenceValue;
                else
                    ranges(i).Max = 0 - referenceValue;
                    ranges(i).Min = referenceValue;                    
                end
            else
                referenceValue = double(...
                    buffAoCtrl.ExtRefValueForUnipolar);
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
                    waveBuffer.Set(i * channelCount + j - channelStart, ...
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
























