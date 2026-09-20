%% STEP 17 - ADVANCED CHANNEL ESTIMATION
% LS Channel Estimation using OFDM Pilot

clear;
clc;
close all;

%% Step 17.1 - System Parameters

Nfft = 64;
cpLength = 16;

M = 4;
bitsPerSymbol = log2(M);

snrTest = 10;
pathDelays = [0 2 4];
pathGains  = [1.00 0.50 0.25];

fprintf('\n============================================\n');
fprintf('       STEP 17: ADVANCED CHANNEL ESTIMATION\n');
fprintf('============================================\n');

fprintf('FFT Size              : %d\n', Nfft);
fprintf('Cyclic Prefix         : %d samples\n', cpLength);
fprintf('Modulation            : QPSK\n');
fprintf('Test SNR              : %d dB\n', snrTest);

%% Step 17.2 - Generate Pilot Symbols

pilotSymbolIndices = (0:Nfft-1).';

pilotSymbols = pskmod( ...
    mod(pilotSymbolIndices,M), ...
    M, ...
    pi/4);

fprintf('\nPilot symbols generated: %d\n', length(pilotSymbols));

%% Step 17.3 - OFDM Pilot Generation

pilotIFFT = ifft(pilotSymbols,Nfft);

pilotWithCP = [
    pilotIFFT(end-cpLength+1:end);
    pilotIFFT
];

fprintf('Pilot OFDM samples     : %d\n', length(pilotWithCP));

%% Step 17.4 - Multipath Channel

channelImpulseResponse = zeros(max(pathDelays)+1,1);

for p = 1:length(pathDelays)

    channelImpulseResponse(pathDelays(p)+1) = ...
        pathGains(p);

end

channelFrequencyResponse = ...
    fft(channelImpulseResponse,Nfft);

fprintf('\nChannel Path Delays     : ');
fprintf('%d ',pathDelays);
fprintf('samples\n');

fprintf('Channel Path Gains      : ');
fprintf('%.2f ',pathGains);
fprintf('\n');

%% Step 17.5 - Pass Pilot Through Channel

rxPilotMultipath = ...
    filter(channelImpulseResponse,1,pilotWithCP);

rxPilotNoisy = ...
    awgn(rxPilotMultipath,snrTest,'measured');

%% Step 17.6 - Remove Cyclic Prefix

rxPilotNoCP = ...
    rxPilotNoisy(cpLength+1:end);

%% Step 17.7 - FFT of Received Pilot

receivedPilotFrequency = ...
    fft(rxPilotNoCP,Nfft);

%% Step 17.8 - LS Channel Estimation

estimatedChannelLS = ...
    receivedPilotFrequency ./ pilotSymbols;

fprintf('\n===== LS CHANNEL ESTIMATION =====\n');

fprintf('Estimation Method      : Least Squares (LS)\n');
fprintf('Received Pilot Size    : %d\n', ...
    length(receivedPilotFrequency));

fprintf('Estimated Channel Size : %d\n', ...
    length(estimatedChannelLS));

%% Step 17.9 - Channel Estimation Error

channelEstimationError = ...
    estimatedChannelLS - channelFrequencyResponse;

rmseChannel = sqrt( ...
    mean(abs(channelEstimationError).^2));

fprintf('\nChannel Estimation RMSE : %.6f\n', ...
    rmseChannel);

%% Step 17.10 - Plot Actual vs Estimated Channel

figure;

plot( ...
    0:Nfft-1, ...
    abs(channelFrequencyResponse), ...
    'LineWidth',1.5);

hold on;

plot( ...
    0:Nfft-1, ...
    abs(estimatedChannelLS), ...
    '--', ...
    'LineWidth',1.5);

grid on;

xlabel('Subcarrier Index');
ylabel('|H(k)|');

title('Actual vs LS Estimated Channel');

legend( ...
    'Actual Channel', ...
    'LS Estimated Channel');

%% Step 17.11 - Phase Comparison

figure;

plot( ...
    0:Nfft-1, ...
    angle(channelFrequencyResponse), ...
    'LineWidth',1.5);

hold on;

plot( ...
    0:Nfft-1, ...
    angle(estimatedChannelLS), ...
    '--', ...
    'LineWidth',1.5);

grid on;

xlabel('Subcarrier Index');
ylabel('Phase (radians)');

title('Actual vs LS Estimated Channel Phase');

legend( ...
    'Actual Channel', ...
    'LS Estimated Channel');

fprintf('\n============================================\n');
fprintf('       STEP 17.1 COMPLETED\n');
fprintf('============================================\n');
%% Step 17.2 - LS Channel Estimation RMSE vs SNR

fprintf('\n===== STEP 17.2: LS RMSE vs SNR =====\n');

snrRange = 0:2:20;

rmseLS = zeros(length(snrRange),1);

for s = 1:length(snrRange)

    currentSNR = snrRange(s);

    % Pass pilot through multipath channel
    rxPilotMultipath = ...
        filter(channelImpulseResponse,1,pilotWithCP);

    % Add AWGN
    rxPilotNoisy = ...
        awgn(rxPilotMultipath,currentSNR,'measured');

    % Remove cyclic prefix
    rxPilotNoCP = ...
        rxPilotNoisy(cpLength+1:end);

    % FFT
    receivedPilotFrequency = ...
        fft(rxPilotNoCP,Nfft);

    % LS channel estimation
    estimatedChannelLS = ...
        receivedPilotFrequency ./ pilotSymbols;

    % Estimation error
    channelEstimationError = ...
        estimatedChannelLS - channelFrequencyResponse;

    % RMSE
    rmseLS(s) = sqrt( ...
        mean(abs(channelEstimationError).^2));

    fprintf( ...
        'SNR = %2d dB   LS Channel RMSE = %.6f\n', ...
        currentSNR, ...
        rmseLS(s));

end

%% Plot LS Channel Estimation RMSE

figure;

plot( ...
    snrRange, ...
    rmseLS, ...
    '-o', ...
    'LineWidth',1.5);

grid on;

xlabel('SNR (dB)');
ylabel('Channel Estimation RMSE');

title('LS Channel Estimation RMSE vs SNR');

fprintf('\nLS RMSE vs SNR graph generated successfully.\n');
%% Step 17.3 - LS Channel Estimation Based Data Equalization

fprintf('\n===== STEP 17.3: LS-BASED DATA EQUALIZATION =====\n');

%% Generate Random Data

numOFDMSymbols = 1000;

numQPSKSymbols = Nfft * numOFDMSymbols;

numBits = numQPSKSymbols * bitsPerSymbol;

rng(400);

txBits = randi([0 1],numBits,1);

txSymbolIndices = ...
    bi2de(reshape(txBits,bitsPerSymbol,[]).','left-msb');

txQPSK = ...
    pskmod(txSymbolIndices,M,pi/4);

%% OFDM Modulation

txDataMatrix = ...
    reshape(txQPSK,Nfft,numOFDMSymbols);

txIFFT = ...
    ifft(txDataMatrix,Nfft,1);

txWithCP = [
    txIFFT(end-cpLength+1:end,:);
    txIFFT
];

txDataFrame = txWithCP(:);

%% Transmit Through Multipath Channel

rxDataMultipath = ...
    filter(channelImpulseResponse,1,txDataFrame);

%% Add AWGN

rxDataNoisy = ...
    awgn(rxDataMultipath,snrTest,'measured');

%% Receiver Reshape

rxDataMatrix = ...
    reshape(rxDataNoisy,Nfft+cpLength,numOFDMSymbols);

%% Remove Cyclic Prefix

rxDataNoCP = ...
    rxDataMatrix(cpLength+1:end,:);

%% FFT

rxDataFFT = ...
    fft(rxDataNoCP,Nfft,1);

%% LS Channel Estimation

% Reuse the LS channel estimated from the pilot

estimatedChannel = estimatedChannelLS;

%% ZF Equalization Using LS Estimate

rxEqualizedLS = zeros(size(rxDataFFT));

for k = 1:Nfft

    rxEqualizedLS(k,:) = ...
        rxDataFFT(k,:) ./ estimatedChannel(k);

end

%% Serialize Equalized Symbols

rxEqualizedSerial = ...
    rxEqualizedLS(:);

%% QPSK Demodulation

rxSymbolIndices = ...
    pskdemod(rxEqualizedSerial,M,pi/4);

%% Convert Symbols to Bits

rxBitsMatrix = ...
    de2bi(rxSymbolIndices,bitsPerSymbol,'left-msb');

rxBits = ...
    reshape(rxBitsMatrix.',[],1);

%% BER Calculation

bitErrorsLS = ...
    sum(txBits ~= rxBits);

berLS = ...
    bitErrorsLS / numBits;

fprintf('\n===== LS-BASED DATA RESULT =====\n');

fprintf('Test SNR              : %d dB\n',snrTest);

fprintf('Equalizer             : Zero-Forcing (ZF)\n');

fprintf('Channel Estimation    : Least Squares (LS)\n');

fprintf('Bit Errors            : %d\n',bitErrorsLS);

fprintf('Total Bits            : %d\n',numBits);

fprintf('BER                   : %.8f\n',berLS);

%% LS Equalized Constellation

figure;

plot( ...
    real(rxEqualizedSerial), ...
    imag(rxEqualizedSerial), ...
    '.');

grid on;

xlabel('In-Phase');

ylabel('Quadrature');

title('QPSK Constellation After LS Channel Estimation + ZF');

axis equal;

fprintf('\nLS-based equalization completed successfully.\n');
%% Step 17.4 - Known Channel ZF vs LS Estimated Channel ZF

fprintf('\n===== STEP 17.4: KNOWN CHANNEL vs LS CHANNEL =====\n');

snrRange = 0:2:20;

berKnownZF = zeros(length(snrRange),1);
berLSZF = zeros(length(snrRange),1);

for s = 1:length(snrRange)

    currentSNR = snrRange(s);

    %% Common received data

    rxDataMultipath = ...
        filter(channelImpulseResponse,1,txDataFrame);

    rxDataNoisy = ...
        awgn(rxDataMultipath,currentSNR,'measured');

    rxDataMatrix = ...
        reshape(rxDataNoisy,Nfft+cpLength,numOFDMSymbols);

    rxDataNoCP = ...
        rxDataMatrix(cpLength+1:end,:);

    rxDataFFT = ...
        fft(rxDataNoCP,Nfft,1);

    %% Generate received pilot

    rxPilotMultipath = ...
        filter(channelImpulseResponse,1,pilotWithCP);

    rxPilotNoisy = ...
        awgn(rxPilotMultipath,currentSNR,'measured');

    rxPilotNoCP = ...
        rxPilotNoisy(cpLength+1:end);

    receivedPilotFrequency = ...
        fft(rxPilotNoCP,Nfft);

    %% LS Channel Estimation

    estimatedChannelLS = ...
        receivedPilotFrequency ./ pilotSymbols;

    %% Known Channel ZF

    rxKnownZF = zeros(size(rxDataFFT));

    for k = 1:Nfft

        rxKnownZF(k,:) = ...
            rxDataFFT(k,:) ./ channelFrequencyResponse(k);

    end

    %% LS Estimated Channel ZF

    rxLSZF = zeros(size(rxDataFFT));

    for k = 1:Nfft

        rxLSZF(k,:) = ...
            rxDataFFT(k,:) ./ estimatedChannelLS(k);

    end

    %% Known Channel Demodulation

    rxKnownSerial = rxKnownZF(:);

    rxKnownSymbols = ...
        pskdemod(rxKnownSerial,M,pi/4);

    rxKnownBitsMatrix = ...
        de2bi(rxKnownSymbols,bitsPerSymbol,'left-msb');

    rxKnownBits = ...
        reshape(rxKnownBitsMatrix.',[],1);

    %% LS Channel Demodulation

    rxLSSerial = rxLSZF(:);

    rxLSSymbols = ...
        pskdemod(rxLSSerial,M,pi/4);

    rxLSBitsMatrix = ...
        de2bi(rxLSSymbols,bitsPerSymbol,'left-msb');

    rxLSBits = ...
        reshape(rxLSBitsMatrix.',[],1);

    %% BER

    berKnownZF(s) = ...
        sum(txBits ~= rxKnownBits) / numBits;

    berLSZF(s) = ...
        sum(txBits ~= rxLSBits) / numBits;

    fprintf( ...
        'SNR = %2d dB   Known ZF BER = %.8f   LS-ZF BER = %.8f\n', ...
        currentSNR, ...
        berKnownZF(s), ...
        berLSZF(s));

end

%% Plot Comparison

figure;

semilogy( ...
    snrRange, ...
    berKnownZF, ...
    '-o', ...
    'LineWidth',1.5);

hold on;

semilogy( ...
    snrRange, ...
    berLSZF, ...
    '-s', ...
    'LineWidth',1.5);

grid on;

xlabel('SNR (dB)');
ylabel('BER');

title('Known Channel ZF vs LS Estimated Channel ZF');

legend( ...
    'Known Channel ZF', ...
    'LS Estimated Channel ZF', ...
    'Location','southwest');

fprintf('\nKnown Channel ZF vs LS-ZF graph generated successfully.\n');
%% Step 17.5 - Final Step 17 Summary

fprintf('\n============================================\n');
fprintf('      STEP 17: ADVANCED CHANNEL ESTIMATION\n');
fprintf('============================================\n');

fprintf('FFT Size              : %d\n',Nfft);
fprintf('Cyclic Prefix         : %d samples\n',cpLength);
fprintf('Modulation            : QPSK\n');
fprintf('Channel               : Multipath + AWGN\n');
fprintf('Path Delays           : ');
fprintf('%d ',pathDelays);
fprintf('samples\n');

fprintf('\nLS Channel Estimation\n');
fprintf('Test SNR              : %d dB\n',snrTest);
fprintf('Channel RMSE          : %.6f\n',rmseChannel);

fprintf('\nLS-Based ZF Receiver\n');
fprintf('Bit Errors            : %d\n',bitErrorsLS);
fprintf('Total Bits            : %d\n',numBits);
fprintf('BER                   : %.8f\n',berLS);

fprintf('\n============================================\n');
fprintf('       STEP 17 COMPLETED SUCCESSFULLY\n');
fprintf('============================================\n');
