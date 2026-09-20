clc;
clear;
close all;

%% STEP 14 - KNOWN CHANNEL ZF vs PILOT-BASED ZF

%% Step 14.1 - System Parameters

% OFDM parameters
Nfft = 64;
cpLength = 16;

% Number of OFDM data symbols
numDataSymbols = 1000;

% QPSK parameters
M = 4;
bitsPerSymbol = log2(M);

% SNR range
snrRange = 0:2:20;

% Multipath channel parameters
pathDelays = [0 2 4];
pathGains = [1.00 0.50 0.25];

% Number of bits
numDataQPSKSymbols = Nfft * numDataSymbols;
numDataBits = numDataQPSKSymbols * bitsPerSymbol;

%% Display System Information

fprintf('\n============================================\n');
fprintf(' STEP 14: KNOWN CHANNEL vs PILOT-BASED ZF\n');
fprintf('============================================\n');

fprintf('FFT Size              : %d\n',Nfft);
fprintf('Cyclic Prefix         : %d samples\n',cpLength);
fprintf('OFDM Data Symbols     : %d\n',numDataSymbols);
fprintf('Modulation            : QPSK\n');

fprintf('SNR Range             : ');
fprintf('%d ',snrRange);
fprintf('dB\n');

fprintf('Multipath Delays      : ');
fprintf('%d ',pathDelays);
fprintf('samples\n');

fprintf('Multipath Gains       : ');
fprintf('%.2f ',pathGains);
fprintf('\n');

fprintf('Total Data Bits       : %d\n',numDataBits);

fprintf('\nStep 14.1 completed successfully.\n');
%% Step 14.2 - Common Data and OFDM Frame Generation

% Set random seed for reproducibility
rng(100);

%% Generate Common Random Data Bits

txBits = randi([0 1],numDataBits,1);

%% QPSK Modulation

txSymbolIndices = bi2de( ...
    reshape(txBits,bitsPerSymbol,[]).', ...
    'left-msb');

txQPSK = pskmod( ...
    txSymbolIndices, ...
    M, ...
    pi/4);

%% Arrange QPSK Symbols into OFDM Symbols

txDataMatrix = reshape( ...
    txQPSK, ...
    Nfft, ...
    numDataSymbols);

%% OFDM IFFT

txIFFT = ifft( ...
    txDataMatrix, ...
    Nfft, ...
    1);

%% Add Cyclic Prefix

txWithCP = [
    txIFFT(end-cpLength+1:end,:);
    txIFFT
    ];

%% Serialize OFDM Data

txFrame = txWithCP(:);

%% Display Information

fprintf('\n===== STEP 14.2: COMMON DATA GENERATION =====\n');

fprintf('Random Seed           : 100\n');
fprintf('Generated Data Bits   : %d\n',length(txBits));
fprintf('QPSK Symbols          : %d\n',length(txQPSK));
fprintf('OFDM Symbols          : %d\n',numDataSymbols);
fprintf('Samples per OFDM      : %d\n',Nfft + cpLength);
fprintf('Total Frame Samples   : %d\n',length(txFrame));

fprintf('Common data generated for both systems.\n');
%% Step 14.3 - Common Multipath Channel

% Create channel impulse response
channelImpulseResponse = zeros(max(pathDelays)+1,1);

for p = 1:length(pathDelays)
    channelImpulseResponse(pathDelays(p)+1) = pathGains(p);
end

%% Pass the Common OFDM Frame Through Multipath Channel

rxMultipath = filter( ...
    channelImpulseResponse, ...
    1, ...
    txFrame);

%% Display Channel Information

fprintf('\n===== STEP 14.3: COMMON MULTIPATH CHANNEL =====\n');

fprintf('Channel Type         : Multipath\n');

fprintf('Path Delays          : ');
fprintf('%d ',pathDelays);
fprintf('samples\n');

fprintf('Path Gains           : ');
fprintf('%.2f ',pathGains);
fprintf('\n');

fprintf('Input Samples        : %d\n',length(txFrame));
fprintf('Output Samples       : %d\n',length(rxMultipath));

fprintf('Common multipath channel created.\n');
%% Step 14.4 - Known Channel ZF Receiver

% Calculate the known channel frequency response
channelFrequencyResponse = fft( ...
    channelImpulseResponse, ...
    Nfft);

% Store BER results
berKnownChannelZF = zeros(length(snrRange),1);

fprintf('\n===== STEP 14.4: KNOWN CHANNEL ZF =====\n');

fprintf('Equalizer            : Zero-Forcing (ZF)\n');
fprintf('Channel Knowledge    : Known / Ideal\n');

%% Process Each SNR

for snrIndex = 1:length(snrRange)

    currentSNR = snrRange(snrIndex);

    % Add AWGN
    rxNoisy = awgn( ...
        rxMultipath, ...
        currentSNR, ...
        'measured');

    %% Reshape into OFDM Symbols

    rxMatrix = reshape( ...
        rxNoisy, ...
        Nfft + cpLength, ...
        numDataSymbols);

    %% Remove Cyclic Prefix

    rxWithoutCP = rxMatrix(cpLength+1:end,:);

    %% FFT

    rxFFT = fft( ...
        rxWithoutCP, ...
        Nfft, ...
        1);

    %% Zero-Forcing Equalization

    rxEqualized = zeros(size(rxFFT));

    for k = 1:Nfft

        rxEqualized(k,:) = ...
            rxFFT(k,:) ./ channelFrequencyResponse(k);

    end

    %% QPSK Demodulation

    rxEqualizedSerial = rxEqualized(:);

    rxSymbolIndices = pskdemod( ...
        rxEqualizedSerial, ...
        M, ...
        pi/4);

    %% Convert Symbols to Bits

    rxBitsMatrix = de2bi( ...
        rxSymbolIndices, ...
        bitsPerSymbol, ...
        'left-msb');

    rxBits = rxBitsMatrix.';
    rxBits = rxBits(:);

    %% Calculate BER

    bitErrors = sum(rxBits ~= txBits);

    berKnownChannelZF(snrIndex) = ...
        bitErrors / length(txBits);

    fprintf( ...
        'SNR = %2d dB   BER = %.8f\n', ...
        currentSNR, ...
        berKnownChannelZF(snrIndex));

end
%% Step 14.5 - Pilot-Based Channel Estimation + ZF

% Generate one known pilot OFDM symbol

pilotSymbolIndices = (0:Nfft-1).';

pilotSymbols = pskmod( ...
    mod(pilotSymbolIndices,M), ...
    M, ...
    pi/4);

%% Pilot OFDM Modulation

pilotIFFT = ifft( ...
    pilotSymbols, ...
    Nfft);

pilotWithCP = [
    pilotIFFT(end-cpLength+1:end);
    pilotIFFT
];

%% Create Pilot + Data Frame

txPilotFrame = [
    pilotWithCP;
    txFrame
];

% Store BER results
berPilotZF = zeros(length(snrRange),1);

fprintf('\n===== STEP 14.5: PILOT-BASED ZF =====\n');

fprintf('Equalizer            : Zero-Forcing (ZF)\n');
fprintf('Channel Knowledge    : Pilot-Based Estimate\n');
fprintf('Pilot OFDM Symbols   : 1\n');

%% Process Each SNR

for snrIndex = 1:length(snrRange)

    currentSNR = snrRange(snrIndex);

    %% Pass Pilot + Data Through Same Channel

    rxPilotMultipath = filter( ...
        channelImpulseResponse, ...
        1, ...
        txPilotFrame);

    %% Add AWGN

    rxPilotNoisy = awgn( ...
        rxPilotMultipath, ...
        currentSNR, ...
        'measured');

    %% Reshape Received Frame

    rxPilotMatrix = reshape( ...
        rxPilotNoisy, ...
        Nfft + cpLength, ...
        numDataSymbols + 1);

    %% Separate Pilot and Data

    rxPilot = rxPilotMatrix(:,1);

    rxData = rxPilotMatrix(:,2:end);

    %% Remove Pilot Cyclic Prefix

    rxPilotWithoutCP = ...
        rxPilot(cpLength+1:end);

    %% FFT Pilot

    rxPilotFrequency = fft( ...
        rxPilotWithoutCP, ...
        Nfft);

    %% Estimate Channel

    estimatedChannel = ...
        rxPilotFrequency ./ pilotSymbols;

    %% Remove Data Cyclic Prefix

    rxDataWithoutCP = ...
        rxData(cpLength+1:end,:);

    %% FFT Data

    rxDataFFT = fft( ...
        rxDataWithoutCP, ...
        Nfft, ...
        1);

    %% Zero-Forcing Equalization

    rxDataEqualized = zeros(size(rxDataFFT));

    for k = 1:Nfft

        rxDataEqualized(k,:) = ...
            rxDataFFT(k,:) ./ estimatedChannel(k);

    end

    %% QPSK Demodulation

    rxDataSerial = rxDataEqualized(:);

    rxSymbolIndices = pskdemod( ...
        rxDataSerial, ...
        M, ...
        pi/4);

    %% Convert Symbols to Bits

    rxBitsMatrix = de2bi( ...
        rxSymbolIndices, ...
        bitsPerSymbol, ...
        'left-msb');

    rxBits = rxBitsMatrix.';
    rxBits = rxBits(:);

    %% Calculate BER

    bitErrors = sum(rxBits ~= txBits);

    berPilotZF(snrIndex) = ...
        bitErrors / length(txBits);

    fprintf( ...
        'SNR = %2d dB   BER = %.8f\n', ...
        currentSNR, ...
        berPilotZF(snrIndex));

end
%% Step 14.6 - BER Comparison

fprintf('\n===== STEP 14.6: BER COMPARISON =====\n');

%% Display Comparison Table

fprintf('\n');
fprintf(' SNR(dB)     Known Channel ZF     Pilot-Based ZF\n');
fprintf('---------------------------------------------------\n');

for i = 1:length(snrRange)

    fprintf( ...
        ' %3d        %.8f          %.8f\n', ...
        snrRange(i), ...
        berKnownChannelZF(i), ...
        berPilotZF(i));

end

%% Plot BER Comparison

figure;

semilogy( ...
    snrRange, ...
    berKnownChannelZF, ...
    '-o', ...
    'LineWidth',2);

hold on;

semilogy( ...
    snrRange, ...
    berPilotZF, ...
    '-s', ...
    'LineWidth',2);

grid on;

xlabel('SNR (dB)');
ylabel('Bit Error Rate (BER)');

title('Known Channel ZF vs Pilot-Based ZF');

legend( ...
    'Known Channel ZF', ...
    'Pilot-Based ZF', ...
    'Location','southwest');

xlim([0 20]);

hold off;
%% Step 14.7 - Final Performance Summary

fprintf('\n============================================\n');
fprintf('       STEP 14 PERFORMANCE SUMMARY\n');
fprintf('============================================\n');

fprintf('FFT Size              : %d\n',Nfft);
fprintf('Cyclic Prefix         : %d samples\n',cpLength);
fprintf('OFDM Data Symbols     : %d\n',numDataSymbols);
fprintf('Modulation            : QPSK\n');
fprintf('Channel               : Multipath + AWGN\n');

fprintf('\nChannel Parameters\n');
fprintf('Path Delays           : ');
fprintf('%d ',pathDelays);
fprintf('samples\n');

fprintf('Path Gains            : ');
fprintf('%.2f ',pathGains);
fprintf('\n');

fprintf('\nEqualization Methods\n');
fprintf('1. Known Channel ZF\n');
fprintf('2. Pilot-Based Channel Estimation + ZF\n');

fprintf('\nBER Results\n');
fprintf('SNR(dB)     Known-ZF        Pilot-ZF\n');
fprintf('----------------------------------------\n');

for i = 1:length(snrRange)

    fprintf( ...
        '%3d       %.8f      %.8f\n', ...
        snrRange(i), ...
        berKnownChannelZF(i), ...
        berPilotZF(i));

end

fprintf('\n============================================\n');
fprintf('Step 14 completed successfully.\n');
fprintf('============================================\n');


fprintf('\nBER comparison graph generated successfully.\n');