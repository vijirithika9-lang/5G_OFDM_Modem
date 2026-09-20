%% STEP 19.6 - ACTIVE-SUBCARRIER OFDM EVM COMPARISON
% No Equalization vs Known-Channel ZF vs Pilot-Based LS-ZF

clc;
clear;
close all;

fprintf('\n');
fprintf('============================================\n');
fprintf(' STEP 19.6: ACTIVE-SUBCARRIER EVM ANALYSIS\n');
fprintf('============================================\n');

%% System Parameters

Nfft = 64;
cpLength = 16;

M = 4;
bitsPerSymbol = log2(M);

numOFDMSymbols = 1000;

snrRange = 0:2:20;

%% Active Subcarriers

activeSubcarriers = [-26:-1 1:26];

activeIndices = ...
    mod(activeSubcarriers,Nfft) + 1;

numActiveSubcarriers = ...
    length(activeIndices);

%% Multipath Channel

pathDelays = [0 2 4];

pathGains = [1.00 0.50 0.25];

channelImpulseResponse = ...
    zeros(max(pathDelays)+1,1);

for p = 1:length(pathDelays)

    channelImpulseResponse( ...
        pathDelays(p)+1) = pathGains(p);

end

%% Channel Frequency Response

channelFrequencyResponse = ...
    fft(channelImpulseResponse,Nfft);

%% Data Generation

numQPSKSymbols = ...
    numActiveSubcarriers * numOFDMSymbols;

numBits = ...
    numQPSKSymbols * bitsPerSymbol;

rng(1100);

txBits = randi([0 1],numBits,1);

txSymbolIndices = ...
    bi2de( ...
    reshape(txBits,bitsPerSymbol,[]).', ...
    'left-msb');

txQPSK = ...
    pskmod(txSymbolIndices,M,pi/4);

%% OFDM Grid

txGrid = zeros(Nfft,numOFDMSymbols);

txGrid(activeIndices,:) = ...
    reshape( ...
    txQPSK, ...
    numActiveSubcarriers, ...
    numOFDMSymbols);

%% IFFT

txIFFT = ...
    ifft(txGrid,Nfft,1);

%% Add CP

txWithCP = [
    txIFFT(end-cpLength+1:end,:);
    txIFFT
];

%% Serialize

txFrame = txWithCP(:);

%% Pilot Generation

pilotSymbols = ones(numActiveSubcarriers,1);

pilotGrid = zeros(Nfft,1);

pilotGrid(activeIndices) = ...
    pilotSymbols;

pilotIFFT = ...
    ifft(pilotGrid,Nfft);

pilotWithCP = [
    pilotIFFT(end-cpLength+1:end);
    pilotIFFT
];

%% EVM Arrays

evmNoEqualization = ...
    zeros(length(snrRange),1);

evmKnownZF = ...
    zeros(length(snrRange),1);

evmPilotLSZF = ...
    zeros(length(snrRange),1);

%% SNR Loop

for s = 1:length(snrRange)

    currentSNR = snrRange(s);

    %% DATA THROUGH CHANNEL

    rxDataMultipath = ...
        filter( ...
        channelImpulseResponse, ...
        1, ...
        txFrame);

    rxDataNoisy = ...
        awgn( ...
        rxDataMultipath, ...
        currentSNR, ...
        'measured');

    %% Receiver

    rxMatrix = ...
        reshape( ...
        rxDataNoisy, ...
        Nfft+cpLength, ...
        numOFDMSymbols);

    rxNoCP = ...
        rxMatrix(cpLength+1:end,:);

    rxFFT = ...
        fft(rxNoCP,Nfft,1);

    %% Active Subcarriers

    rxActiveData = ...
        rxFFT(activeIndices,:);

    %% ==================================
    % SYSTEM 1: NO EQUALIZATION
    % ==================================

    rxNoEQ = rxActiveData(:);

    errorNoEQ = ...
        rxNoEQ - txQPSK;

    rmsEVM_NoEQ = sqrt( ...
        mean(abs(errorNoEQ).^2) / ...
        mean(abs(txQPSK).^2));

    evmNoEqualization(s) = ...
        rmsEVM_NoEQ * 100;

    %% ==================================
    % SYSTEM 2: KNOWN-CHANNEL ZF
    % ==================================

    knownActiveChannel = ...
        channelFrequencyResponse(activeIndices);

    rxKnownZF = zeros(size(rxActiveData));

    for k = 1:numActiveSubcarriers

        rxKnownZF(k,:) = ...
            rxActiveData(k,:) ...
            ./ knownActiveChannel(k);

    end

    rxKnownZFSerial = ...
        rxKnownZF(:);

    errorKnownZF = ...
        rxKnownZFSerial - txQPSK;

    rmsEVM_KnownZF = sqrt( ...
        mean(abs(errorKnownZF).^2) / ...
        mean(abs(txQPSK).^2));

    evmKnownZF(s) = ...
        rmsEVM_KnownZF * 100;

    %% ==================================
    % PILOT TRANSMISSION
    % ==================================

    rxPilotMultipath = ...
        filter( ...
        channelImpulseResponse, ...
        1, ...
        pilotWithCP);

    rxPilotNoisy = ...
        awgn( ...
        rxPilotMultipath, ...
        currentSNR, ...
        'measured');

    rxPilotNoCP = ...
        rxPilotNoisy(cpLength+1:end);

    receivedPilotFrequency = ...
        fft(rxPilotNoCP,Nfft);

    %% Pilot-Based LS Estimate

    estimatedChannel = ...
        receivedPilotFrequency(activeIndices) ...
        ./ pilotSymbols;

    %% ==================================
    % SYSTEM 3: PILOT LS + ZF
    % ==================================

    rxPilotLSZF = ...
        zeros(size(rxActiveData));

    for k = 1:numActiveSubcarriers

        rxPilotLSZF(k,:) = ...
            rxActiveData(k,:) ...
            ./ estimatedChannel(k);

    end

    rxPilotLSZFSerial = ...
        rxPilotLSZF(:);

    errorPilotLSZF = ...
        rxPilotLSZFSerial - txQPSK;

    rmsEVM_PilotLSZF = sqrt( ...
        mean(abs(errorPilotLSZF).^2) / ...
        mean(abs(txQPSK).^2));

    evmPilotLSZF(s) = ...
        rmsEVM_PilotLSZF * 100;

    %% Display

    fprintf( ...
        'SNR = %2d dB   No-EQ EVM = %.4f %%   Known-ZF EVM = %.4f %%   Pilot-LS-ZF EVM = %.4f %%\n', ...
        currentSNR, ...
        evmNoEqualization(s), ...
        evmKnownZF(s), ...
        evmPilotLSZF(s));

end

%% EVM Comparison Plot

figure;

semilogy( ...
    snrRange, ...
    evmNoEqualization, ...
    '-o', ...
    'LineWidth',1.5);

hold on;

semilogy( ...
    snrRange, ...
    evmKnownZF, ...
    '-s', ...
    'LineWidth',1.5);

semilogy( ...
    snrRange, ...
    evmPilotLSZF, ...
    '-^', ...
    'LineWidth',1.5);

grid on;

xlabel('SNR (dB)');

ylabel('EVM (%)');

title('Active-Subcarrier OFDM EVM Comparison');

legend( ...
    'No Equalization', ...
    'Known-Channel ZF', ...
    'Pilot-Based LS + ZF', ...
    'Location','northeast');

fprintf('\nEVM comparison graph generated successfully.\n');

%% Final Summary

fprintf('\n============================================\n');
fprintf(' STEP 19.6 SUMMARY\n');
fprintf('============================================\n');

fprintf('FFT Size             : %d\n',Nfft);

fprintf('Active Subcarriers   : %d\n', ...
    numActiveSubcarriers);

fprintf('Modulation           : QPSK\n');

fprintf('Channel              : Multipath + AWGN\n');

fprintf('Metrics              : EVM\n');

fprintf('Systems Compared     : No-EQ / Known-ZF / Pilot-LS-ZF\n');

fprintf('\nSTEP 19.6 completed successfully.\n');
