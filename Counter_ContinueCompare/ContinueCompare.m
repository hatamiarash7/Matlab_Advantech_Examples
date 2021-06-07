%    1. Set the 'deviceDescription' for opening the device. 
%    2. Set the 'channel' as the channel for Continue Compare counter.
%    3. Set the compare value table.

function ContinueCompare()

% Make Automation.BDaq assembly visible to MATLAB.
BDaq = NET.addAssembly('Automation.BDaq');

global comValueTab
comValueTab = NET.createArray('System.Int32', [2,3]);

% Configure the following parameters before running the demo.
% The default device of project is demo device, users can choose other 
% devices according to their needs. 
deviceDescription = 'PCI-1784,BID#0'; 
channel = int32(0);
% Initialize the compare value table.
comValueTab(1,1) = 20;
comValueTab(1,2) = 25;
comValueTab(1,3) = 30;
comValueTab(2,1) = 50;
comValueTab(2,2) = 100;
comValueTab(2,3) = 150;

% Step 1: Create a 'UdCounterCtrl' for UpDown Counter function.
udCounterCtrl = Automation.BDaq.UdCounterCtrl();

% Step 2: Set the notification event Handler by which we can known the 
% state of operation effectively.
addlistener(udCounterCtrl, 'UdCntrEvent', @udCounterCtrl_ConCmpValue);

try
    % Step 3: Select a device by device number or device description and 
    % specify the access mode. In this example we use 
    % AccessWriteWithReset(default) mode so that we can fully control the 
    % device, including configuring, sampling, etc.
    udCounterCtrl.SelectedDevice = Automation.BDaq.DeviceInformation(...
        deviceDescription);
    
    % Step 4: Set necessary parameters for counter operation.
    udCounterCtrl.Channel = channel;
    
    % Step 5: Set counting type for UpDown Counter.
    % counting type : CountingNone,DownCount,UpCount,PulseDirection,
    % TwoPulse,AbPhaseX1,AbPhaseX2,AbPhaseX4.
    signalCountingType = Automation.BDaq.SignalCountingType.AbPhaseX1;
    udCounterCtrl.CountingType = signalCountingType;
    
    % Step 6: Set compare table.
    strArray = NET.createArray('System.Int32', comValueTab.GetLength(1));
    for i = 1 : comValueTab.GetLength(1)
        strArray(i) = comValueTab(1, i);
    end
    udCounterCtrl.CompareSetTable(comValueTab.GetLength(1), ...
        strArray);
    
    % Step 7: Start UpDown Counter. 
    udCounterCtrl.Enabled = true;
    
    % Step 8: Read counting value: connect the input signal to channels
    % you selected to get event counter value.
    fprintf('UpDown Counter is in progress...\n');
    fprintf('Connect the input signal to the connector.\n');
    t = timer('TimerFcn',{@TimerCallback, udCounterCtrl, channel}, ...
        'period', 1, 'executionmode', 'fixedrate', 'StartDelay', 1);
    start(t);
    input('Press Enter key to quit!\n\n','s');
 
    % Step 9: Stop UpDown Counter and stop timer.
    udCounterCtrl.CompareClear();
    udCounterCtrl.Enabled = false;
    stop(t);
    delete(t);
catch e
    % Something is wrong. 
    errStr = e.message;
    disp(errStr);
end   

% Step 10: Close device and release any allocated resource.
clear functions
clear global
udCounterCtrl.Dispose();

end

function TimerCallback(obj, event, udCounterCtrl, channel)

fprintf('Channel %d current  counts  :%d\n', ...
    channel, udCounterCtrl.Value);

end

function udCounterCtrl_ConCmpValue(sender, e)

global comValueTab
persistent conCmpOccursCount tabIndex evntID evntCompID;
if isempty(conCmpOccursCount)
    conCmpOccursCount = 0;
end
if isempty(tabIndex)
    tabIndex = 0;
end
if isempty(evntID)
evntID = NET.createArray('System.Int32', int32(8));
evntID.Set(0, int32(Automation.BDaq.EventId.EvtCntCompareTableEnd0));
evntID.Set(1, int32(Automation.BDaq.EventId.EvtCntCompareTableEnd1));
evntID.Set(2, int32(Automation.BDaq.EventId.EvtCntCompareTableEnd2));
evntID.Set(3, int32(Automation.BDaq.EventId.EvtCntCompareTableEnd3));
evntID.Set(4, int32(Automation.BDaq.EventId.EvtCntCompareTableEnd4));
evntID.Set(5, int32(Automation.BDaq.EventId.EvtCntCompareTableEnd5));
evntID.Set(6, int32(Automation.BDaq.EventId.EvtCntCompareTableEnd6));
evntID.Set(7, int32(Automation.BDaq.EventId.EvtCntCompareTableEnd7));
end
if isempty(evntCompID)
evntCompID = NET.createArray('System.Int32', int32(8));
evntCompID.Set(0, int32(Automation.BDaq.EventId.EvtCntPatternMatch0));
evntCompID.Set(1, int32(Automation.BDaq.EventId.EvtCntPatternMatch1));
evntCompID.Set(2, int32(Automation.BDaq.EventId.EvtCntPatternMatch2));
evntCompID.Set(3, int32(Automation.BDaq.EventId.EvtCntPatternMatch3));
evntCompID.Set(4, int32(Automation.BDaq.EventId.EvtCntPatternMatch4));
evntCompID.Set(5, int32(Automation.BDaq.EventId.EvtCntPatternMatch5));
evntCompID.Set(6, int32(Automation.BDaq.EventId.EvtCntPatternMatch6));
evntCompID.Set(7, int32(Automation.BDaq.EventId.EvtCntPatternMatch7));
end

channel = sender.Channel;
udCounterCtrl = sender;
if (evntCompID.Get(channel) == e.SrcId)||(evntID.Get(channel) == e.SrcId)
    conCmpOccursCount = conCmpOccursCount + 1;
    fprintf('\nChannel %d Compare occurs %d time(times)\n', ...
        channel, conCmpOccursCount);
    nRow = rem(tabIndex, 2);
    nCol = rem((conCmpOccursCount - 1),3);
    fprintf('Compare value is %d.\n\n',comValueTab.Get(nRow,nCol)); 
end

% Change the compare value table.
if evntID.Get(channel) == e.SrcId
    tabIndex = tabIndex + 1;
    num = rem(tabIndex, 2);
    strArray = NET.createArray('System.Int32', comValueTab.GetLength(1));
    for i = 0 : comValueTab.GetLength(1) - 1
        strArray.Set(i, comValueTab.Get(num, i));
    end
    udCounterCtrl.CompareSetTable(comValueTab.GetLength(1), ...
        strArray);
end

end


