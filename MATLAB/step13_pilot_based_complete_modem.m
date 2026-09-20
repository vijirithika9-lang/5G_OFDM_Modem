clc;
clear;
close all;

%% STEP 13 - PILOT-BASED COMPLETE OFDM MODEM

%% Step 13.1 - System Parameters and Pilot/Data Generation

% OFDM parameters
Nfft = 64;
cpLength = 16;

% Number of data OFDM symbols
numDataSymbols = 1000;

% QPSK parameters
M = 4;
bitsPerSymbol = log2(M);

% Test SNR
snrTest = 20;

% Multipath channel parameters
pathDelays = [0 2 4];
pathGains = [1.00 0.50 0.25];

%% Generate Random Data Bits

numDataQPSKSymbols = Nfft * numDataSymbols;
numDataBits = numDataQPSKSymbols * bitsPerSymbol;

txBits = randi([0 1],numDataBits,1);

%% QPSK Modulation

txSymbolIndices = bi2de( ...
    reshape(txBits,bitsPerSymbol,[]).', ...
    'left-msb');

txDataQPSK = pskmod( ...
    txSymbolIndices, ...
    M, ...
    pi/4);

%% Arrange Data into OFDM Symbols

txDataMatrix = reshape( ...
    txDataQPSK, ...
    Nfft, ...
    numDataSymbols);

%% Generate Known Pilot Symbols

pilotSymbolIndices = (0:Nfft-1).';

pilotSymbols = pskmod( ...
    mod(pilotSymbolIndices,M), ...
    M, ...
    pi/4);

%% Display Setup Information

fprintf('\n===== STEP 13.1: PILOT-BASED MODEM SETUP =====\n');

fprintf('FFT Size                 : %d\n',Nfft);
fprintf('Cyclic Prefix Length     : %d\n',cpLength);
fprintf('Data OFDM Symbols       : %d\n',numDataSymbols);
fprintf('Pilot OFDM Symbols      : 1\n');
fprintf('QPSK Modulation Order   : %d\n',M);
fprintf('Test SNR                : %d dB\n',snrTest);

fprintf('Data Bits               : %d\n',numDataBits);

fprintf('Pilot Symbols           : %d\n',length(pilotSymbols));

fprintf('Multipath Delays        : ');
fprintf('%d ',pathDelays);
fprintf('samples\n');

fprintf('Multipath Gains         : ');
fprintf('%.2f ',pathGains);
fprintf('\n');
%% Step 13.2 - Pilot and Data OFDM Waveform Generation

%% Generate Pilot OFDM Symbol

% IFFT of pilot
pilotIFFT = ifft(pilotSymbols,Nfft);

% Add cyclic prefix to pilot
pilotWithCP = [
    pilotIFFT(end-cpLength+1:end);
    pilotIFFT
    ];

%% Generate Data OFDM Symbols

% IFFT of data symbols
dataIFFT = ifft( ...
    txDataMatrix, ...
    Nfft, ...
    1);

% Add cyclic prefix to every data OFDM symbol
dataWithCP = [
    dataIFFT(end-cpLength+1:end,:);
    dataIFFT
    ];

%% Combine Pilot and Data

txFrame = [
    pilotWithCP;
    dataWithCP(:)
    ];

fprintf('\n===== STEP 13.2: OFDM FRAME GENERATION =====\n');

fprintf('Pilot Samples           : %d\n',length(pilotWithCP));

fprintf('Data Samples            : %d\n',numel(dataWithCP));

fprintf('Total Frame Samples     : %d\n',length(txFrame));

fprintf('Samples per OFDM Symbol : %d\n',Nfft + cpLength);
%% Step 13.3 - Multipath Channel + AWGN

% Create multipath channel impulse response
channelImpulseResponse = zeros(max(pathDelays) + 1,1);

for k = 1:length(pathDelays)

    channelImpulseResponse(pathDelays(k) + 1) = ...
        pathGains(k);

end

%% Pass Complete OFDM Frame Through Multipath Channel

rxMultipath = filter( ...
    channelImpulseResponse, ...
    1, ...
    txFrame);

%% Add AWGN Noise

rxFrame = awgn( ...
    rxMultipath, ...
    snrTest, ...
    'measured');

fprintf('\n===== STEP 13.3: CHANNEL =====\n');

fprintf('Channel Type            : Multipath + AWGN\n');

fprintf('Path Delays             : ');
fprintf('%d ',pathDelays);
fprintf('samples\n');

fprintf('Path Gains              : ');
fprintf('%.2f ',pathGains);
fprintf('\n');

fprintf('Channel SNR             : %d dB\n',snrTest);

fprintf('Transmitted Samples     : %d\n',length(txFrame));

fprintf('Received Samples        : %d\n',length(rxFrame));
%% Step 13.4 - Pilot Extraction and Channel Estimation

%% Reshape Received Frame into OFDM Symbols

rxFrameMatrix = reshape( ...
    rxFrame, ...
    Nfft + cpLength, ...
    numDataSymbols + 1);

%% Extract Pilot OFDM Symbol

rxPilotWithCP = rxFrameMatrix(:,1);

%% Remove Cyclic Prefix from Pilot

rxPilotWithoutCP = ...
    rxPilotWithCP(cpLength+1:end);

%% FFT of Received Pilot

rxPilotFrequency = fft( ...
    rxPilotWithoutCP, ...
    Nfft);

%% Channel Estimation

estimatedChannel = ...
    rxPilotFrequency ./ pilotSymbols;

fprintf('\n===== STEP 13.4: PILOT CHANNEL ESTIMATION =====\n');

fprintf('Received Pilot Samples : %d\n', ...
    length(rxPilotWithCP));

fprintf('Pilot CP Removed       : %d samples\n', ...
    cpLength);

fprintf('Estimated Channel Size : %d\n', ...
    length(estimatedChannel));

fprintf('Channel estimated using known pilot.\n');
%% Step 13.5 - Data Extraction and ZF Equalization

%% Extract Data OFDM Symbols

rxDataWithCP = rxFrameMatrix(:,2:end);

%% Remove Cyclic Prefix

rxDataWithoutCP = ...
    rxDataWithCP(cpLength+1:end,:);

%% FFT of Received Data

rxDataFFT = fft( ...
    rxDataWithoutCP, ...
    Nfft, ...
    1);

%% Zero-Forcing Equalization Using Estimated Channel

rxDataEqualized = zeros(size(rxDataFFT));

for k = 1:Nfft

    rxDataEqualized(k,:) = ...
        rxDataFFT(k,:) ./ estimatedChannel(k);

end

%% Serialize Equalized Data

rxDataEqualizedSerial = ...
    rxDataEqualized(:);

fprintf('\n===== STEP 13.5: DATA EQUALIZATION =====\n');

fprintf('Data OFDM Symbols      : %d\n',numDataSymbols);

fprintf('FFT Size               : %d\n',Nfft);

fprintf('Equalizer              : Zero-Forcing (ZF)\n');

fprintf('Channel Used           : Pilot-Based Estimate\n');

fprintf('Equalized QPSK Symbols : %d\n', ...
    length(rxDataEqualizedSerial));
%% Step 13.6 - QPSK Demodulation and BER

% QPSK demodulation
rxSymbolIndices = pskdemod( ...
    rxDataEqualizedSerial, ...
    M, ...
    pi/4);

% Convert QPSK symbols back to bits
rxBitsMatrix = de2bi( ...
    rxSymbolIndices, ...
    bitsPerSymbol, ...
    'left-msb');

rxBits = rxBitsMatrix.';
rxBits = rxBits(:);

%% BER Calculation

bitErrors = sum(txBits ~= rxBits);

ber = bitErrors / numDataBits;

fprintf('\n===== STEP 13.6: PILOT-BASED BER RESULT =====\n');

fprintf('Test SNR       = %d dB\n',snrTest);

fprintf('Bit Errors     = %d\n',bitErrors);

fprintf('Total Bits     = %d\n',numDataBits);

fprintf('BER            = %.8f\n',ber);
%% Step 13.7 - EVM Analysis

% Calculate error vector
evmError = rxDataEqualizedSerial - txDataQPSK;

% Calculate RMS EVM
rmsEVM = sqrt( ...
    mean(abs(evmError).^2) / ...
    mean(abs(txDataQPSK).^2));

% Convert EVM to percentage
evmPercentage = rmsEVM * 100;

fprintf('\n===== STEP 13.7: PILOT-BASED EVM =====\n');

fprintf('Test SNR       = %d dB\n',snrTest);

fprintf('RMS EVM        = %.6f\n',rmsEVM);

fprintf('EVM Percentage = %.2f %%\n',evmPercentage);

%% Plot Equalized QPSK Constellation

figure;

plot( ...
    real(rxDataEqualizedSerial), ...
    imag(rxDataEqualizedSerial), ...
    '.');

grid on;

axis equal;

xlabel('In-Phase');

ylabel('Quadrature');

title('Pilot-Based OFDM - Equalized QPSK Constellation');
%% Step 13.8 - Pilot-Based Complete Modem BER vs SNR

snrRangePilot = 0:2:20;

berPilotComplete = zeros(size(snrRangePilot));

for s = 1:length(snrRangePilot)

    %% Pass Frame Through Channel

    rxTestMultipath = filter( ...
        channelImpulseResponse, ...
        1, ...
        txFrame);

    rxTestFrame = awgn( ...
        rxTestMultipath, ...
        snrRangePilot(s), ...
        'measured');

    %% Reshape Received Frame

    rxTestMatrix = reshape( ...
        rxTestFrame, ...
        Nfft + cpLength, ...
        numDataSymbols + 1);

    %% Extract Pilot

    rxTestPilotCP = rxTestMatrix(:,1);

    % Remove CP
    rxTestPilot = ...
        rxTestPilotCP(cpLength+1:end);

    % FFT
    rxTestPilotFFT = fft( ...
        rxTestPilot, ...
        Nfft);

    %% Estimate Channel

    estimatedChannelTest = ...
        rxTestPilotFFT ./ pilotSymbols;

    %% Extract Data

    rxTestDataCP = rxTestMatrix(:,2:end);

    % Remove CP
    rxTestData = ...
        rxTestDataCP(cpLength+1:end,:);

    % FFT
    rxTestDataFFT = fft( ...
        rxTestData, ...
        Nfft, ...
        1);

    %% ZF Equalization

    rxTestEqualized = zeros(size(rxTestDataFFT));

    for k = 1:Nfft

        rxTestEqualized(k,:) = ...
            rxTestDataFFT(k,:) ./ estimatedChannelTest(k);

    end

    %% Serialize

    rxTestSerial = rxTestEqualized(:);

    %% QPSK Demodulation

    rxTestSymbols = pskdemod( ...
        rxTestSerial, ...
        M, ...
        pi/4);

    %% Convert Symbols to Bits

    rxTestBitsMatrix = de2bi( ...
        rxTestSymbols, ...
        bitsPerSymbol, ...
        'left-msb');

    rxTestBits = rxTestBitsMatrix.';
    rxTestBits = rxTestBits(:);

    %% BER

    bitErrorsTest = sum(txBits ~= rxTestBits);

    berPilotComplete(s) = ...
        bitErrorsTest / numDataBits;

end

%% Display Results

fprintf('\n===== STEP 13.8: PILOT-BASED COMPLETE MODEM BER =====\n');

for s = 1:length(snrRangePilot)

    fprintf( ...
        'SNR = %2d dB   BER = %.8f\n', ...
        snrRangePilot(s), ...
        berPilotComplete(s));

end

%% Plot BER vs SNR

figure;

semilogy( ...
    snrRangePilot, ...
    berPilotComplete, ...
    'o-', ...
    'LineWidth',1.5);

grid on;

xlabel('SNR (dB)');

ylabel('Bit Error Rate (BER)');

title('Pilot-Based Complete OFDM Modem - BER vs SNR');
