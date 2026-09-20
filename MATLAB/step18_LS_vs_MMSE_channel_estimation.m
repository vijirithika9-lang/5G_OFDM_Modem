%% STEP 18 - LS vs MMSE CHANNEL ESTIMATION
% Step 18.1 - MMSE Channel Estimation

clear;
clc;
close all;

%% System Parameters

Nfft = 64;
cpLength = 16;

M = 4;
bitsPerSymbol = log2(M);

snrTest = 10;

pathDelays = [0 2 4];
pathGains  = [1.00 0.50 0.25];

fprintf('\n============================================\n');
fprintf('       STEP 18: LS vs MMSE CHANNEL ESTIMATION\n');
fprintf('============================================\n');

fprintf('FFT Size              : %d\n',Nfft);
fprintf('Cyclic Prefix         : %d samples\n',cpLength);
fprintf('Modulation            : QPSK\n');
fprintf('Test SNR              : %d dB\n',snrTest);

%% Generate Pilot

pilotSymbolIndices = (0:Nfft-1).';

pilotSymbols = pskmod( ...
    mod(pilotSymbolIndices,M), ...
    M, ...
    pi/4);

%% OFDM Pilot Modulation

pilotIFFT = ifft(pilotSymbols,Nfft);

pilotWithCP = [
    pilotIFFT(end-cpLength+1:end);
    pilotIFFT
];

%% Multipath Channel

channelImpulseResponse = ...
    zeros(max(pathDelays)+1,1);

for p = 1:length(pathDelays)

    channelImpulseResponse(pathDelays(p)+1) = ...
        pathGains(p);

end

channelFrequencyResponse = ...
    fft(channelImpulseResponse,Nfft);

%% Transmit Pilot Through Channel

rxPilotMultipath = ...
    filter(channelImpulseResponse,1,pilotWithCP);

rxPilotNoisy = ...
    awgn(rxPilotMultipath,snrTest,'measured');

%% Remove CP

rxPilotNoCP = ...
    rxPilotNoisy(cpLength+1:end);

%% FFT

receivedPilotFrequency = ...
    fft(rxPilotNoCP,Nfft);

%% LS Channel Estimation

estimatedChannelLS = ...
    receivedPilotFrequency ./ pilotSymbols;

%% MMSE Channel Estimation

noiseToSignalRatio = ...
    10^(-snrTest/10);

estimatedChannelMMSE = zeros(Nfft,1);

for k = 1:Nfft

    H = channelFrequencyResponse(k);

    % MMSE shrinkage factor
    mmseFactor = ...
        abs(H)^2 / ...
        (abs(H)^2 + noiseToSignalRatio);

    estimatedChannelMMSE(k) = ...
        mmseFactor * estimatedChannelLS(k);

end

%% Calculate Estimation Errors

errorLS = ...
    estimatedChannelLS - channelFrequencyResponse;

errorMMSE = ...
    estimatedChannelMMSE - channelFrequencyResponse;

rmseLS = sqrt( ...
    mean(abs(errorLS).^2));

rmseMMSE = sqrt( ...
    mean(abs(errorMMSE).^2));

%% Display Results

fprintf('\n===== CHANNEL ESTIMATION RESULTS =====\n');

fprintf('Estimation Method      : LS\n');
fprintf('LS RMSE                : %.6f\n',rmseLS);

fprintf('\nEstimation Method      : MMSE\n');
fprintf('MMSE RMSE              : %.6f\n',rmseMMSE);

%% Plot Channel Magnitude

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

plot( ...
    0:Nfft-1, ...
    abs(estimatedChannelMMSE), ...
    ':', ...
    'LineWidth',1.8);

grid on;

xlabel('Subcarrier Index');

ylabel('|H(k)|');

title('LS vs MMSE Channel Estimation');

legend( ...
    'Actual Channel', ...
    'LS Estimate', ...
    'MMSE Estimate');

fprintf('\nChannel estimation comparison graph generated successfully.\n');
%% Step 18.2 - LS vs MMSE Channel Estimation RMSE vs SNR

fprintf('\n===== STEP 18.2: LS vs MMSE RMSE vs SNR =====\n');

snrRange = 0:2:20;

rmseLS_SNR = zeros(length(snrRange),1);
rmseMMSE_SNR = zeros(length(snrRange),1);

for s = 1:length(snrRange)

    currentSNR = snrRange(s);

    % Transmit pilot through channel
    rxPilotMultipath = ...
        filter(channelImpulseResponse,1,pilotWithCP);

    % Add AWGN
    rxPilotNoisy = ...
        awgn(rxPilotMultipath,currentSNR,'measured');

    % Remove CP
    rxPilotNoCP = ...
        rxPilotNoisy(cpLength+1:end);

    % FFT
    receivedPilotFrequency = ...
        fft(rxPilotNoCP,Nfft);

    % LS estimation
    estimatedChannelLS = ...
        receivedPilotFrequency ./ pilotSymbols;

    % MMSE estimation
    noiseToSignalRatio = ...
        10^(-currentSNR/10);

    estimatedChannelMMSE = zeros(Nfft,1);

    for k = 1:Nfft

        H = channelFrequencyResponse(k);

        mmseFactor = ...
            abs(H)^2 / ...
            (abs(H)^2 + noiseToSignalRatio);

        estimatedChannelMMSE(k) = ...
            mmseFactor * estimatedChannelLS(k);

    end

    % LS RMSE
    errorLS = ...
        estimatedChannelLS - channelFrequencyResponse;

    rmseLS_SNR(s) = sqrt( ...
        mean(abs(errorLS).^2));

    % MMSE RMSE
    errorMMSE = ...
        estimatedChannelMMSE - channelFrequencyResponse;

    rmseMMSE_SNR(s) = sqrt( ...
        mean(abs(errorMMSE).^2));

    fprintf( ...
        'SNR = %2d dB   LS RMSE = %.6f   MMSE RMSE = %.6f\n', ...
        currentSNR, ...
        rmseLS_SNR(s), ...
        rmseMMSE_SNR(s));

end

%% Plot RMSE Comparison

figure;

plot( ...
    snrRange, ...
    rmseLS_SNR, ...
    '-o', ...
    'LineWidth',1.5);

hold on;

plot( ...
    snrRange, ...
    rmseMMSE_SNR, ...
    '-s', ...
    'LineWidth',1.5);

grid on;

xlabel('SNR (dB)');

ylabel('Channel Estimation RMSE');

title('LS vs MMSE Channel Estimation RMSE');

legend( ...
    'LS', ...
    'MMSE', ...
    'Location','northeast');

fprintf('\nLS vs MMSE RMSE graph generated successfully.\n');
%% Step 18.3 - LS-ZF vs MMSE-Estimated-Channel ZF BER

fprintf('\n===== STEP 18.3: LS-ZF vs MMSE-ESTIMATED-CHANNEL ZF =====\n');

numOFDMSymbols = 1000;

numQPSKSymbols = Nfft * numOFDMSymbols;

numBits = numQPSKSymbols * bitsPerSymbol;

rng(500);

%% Generate Common Data

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

%% BER Arrays

berLS_ZF = zeros(length(snrRange),1);
berMMSE_ZF = zeros(length(snrRange),1);

%% SNR Loop

for s = 1:length(snrRange)

    currentSNR = snrRange(s);

    %% Data Through Channel

    rxDataMultipath = ...
        filter(channelImpulseResponse,1,txDataFrame);

    rxDataNoisy = ...
        awgn(rxDataMultipath,currentSNR,'measured');

    %% Data Receiver

    rxDataMatrix = ...
        reshape(rxDataNoisy,Nfft+cpLength,numOFDMSymbols);

    rxDataNoCP = ...
        rxDataMatrix(cpLength+1:end,:);

    rxDataFFT = ...
        fft(rxDataNoCP,Nfft,1);

    %% Pilot Through Channel

    rxPilotMultipath = ...
        filter(channelImpulseResponse,1,pilotWithCP);

    rxPilotNoisy = ...
        awgn(rxPilotMultipath,currentSNR,'measured');

    rxPilotNoCP = ...
        rxPilotNoisy(cpLength+1:end);

    receivedPilotFrequency = ...
        fft(rxPilotNoCP,Nfft);

    %% LS Channel Estimate

    estimatedChannelLS = ...
        receivedPilotFrequency ./ pilotSymbols;

    %% MMSE Channel Estimate

    noiseToSignalRatio = ...
        10^(-currentSNR/10);

    estimatedChannelMMSE = zeros(Nfft,1);

    for k = 1:Nfft

        H = channelFrequencyResponse(k);

        mmseFactor = ...
            abs(H)^2 / ...
            (abs(H)^2 + noiseToSignalRatio);

        estimatedChannelMMSE(k) = ...
            mmseFactor * estimatedChannelLS(k);

    end

    %% ZF Using LS Channel Estimate

    rxLS_ZF = zeros(size(rxDataFFT));

    for k = 1:Nfft

        rxLS_ZF(k,:) = ...
            rxDataFFT(k,:) ./ estimatedChannelLS(k);

    end

    %% ZF Using MMSE Channel Estimate

    rxMMSE_ZF = zeros(size(rxDataFFT));

    for k = 1:Nfft

        rxMMSE_ZF(k,:) = ...
            rxDataFFT(k,:) ./ estimatedChannelMMSE(k);

    end

    %% LS-ZF Demodulation

    rxLS_Serial = rxLS_ZF(:);

    rxLS_Symbols = ...
        pskdemod(rxLS_Serial,M,pi/4);

    rxLS_BitsMatrix = ...
        de2bi(rxLS_Symbols,bitsPerSymbol,'left-msb');

    rxLS_Bits = ...
        reshape(rxLS_BitsMatrix.',[],1);

    %% MMSE-Estimate ZF Demodulation

    rxMMSE_Serial = rxMMSE_ZF(:);

    rxMMSE_Symbols = ...
        pskdemod(rxMMSE_Serial,M,pi/4);

    rxMMSE_BitsMatrix = ...
        de2bi(rxMMSE_Symbols,bitsPerSymbol,'left-msb');

    rxMMSE_Bits = ...
        reshape(rxMMSE_BitsMatrix.',[],1);

    %% BER

    berLS_ZF(s) = ...
        sum(txBits ~= rxLS_Bits) / numBits;

    berMMSE_ZF(s) = ...
        sum(txBits ~= rxMMSE_Bits) / numBits;

    fprintf( ...
        'SNR = %2d dB   LS-ZF BER = %.8f   MMSE-Estimate-ZF BER = %.8f\n', ...
        currentSNR, ...
        berLS_ZF(s), ...
        berMMSE_ZF(s));

end

%% BER Comparison Plot

figure;

semilogy( ...
    snrRange, ...
    berLS_ZF, ...
    '-o', ...
    'LineWidth',1.5);

hold on;

semilogy( ...
    snrRange, ...
    berMMSE_ZF, ...
    '-s', ...
    'LineWidth',1.5);

grid on;

xlabel('SNR (dB)');

ylabel('BER');

title('LS-ZF vs MMSE-Estimated-Channel ZF');

legend( ...
    'LS Channel + ZF', ...
    'MMSE Channel + ZF', ...
    'Location','southwest');

fprintf('\nBER comparison graph generated successfully.\n');
%% Step 18.4 - LS vs MMSE Channel Estimation EVM

fprintf('\n===== STEP 18.4: LS vs MMSE EVM =====\n');

evmLS = zeros(length(snrRange),1);
evmMMSE = zeros(length(snrRange),1);

for s = 1:length(snrRange)

    currentSNR = snrRange(s);

    %% Data Through Channel

    rxDataMultipath = ...
        filter(channelImpulseResponse,1,txDataFrame);

    rxDataNoisy = ...
        awgn(rxDataMultipath,currentSNR,'measured');

    %% Receiver

    rxDataMatrix = ...
        reshape(rxDataNoisy,Nfft+cpLength,numOFDMSymbols);

    rxDataNoCP = ...
        rxDataMatrix(cpLength+1:end,:);

    rxDataFFT = ...
        fft(rxDataNoCP,Nfft,1);

    %% Pilot Through Channel

    rxPilotMultipath = ...
        filter(channelImpulseResponse,1,pilotWithCP);

    rxPilotNoisy = ...
        awgn(rxPilotMultipath,currentSNR,'measured');

    rxPilotNoCP = ...
        rxPilotNoisy(cpLength+1:end);

    receivedPilotFrequency = ...
        fft(rxPilotNoCP,Nfft);

    %% LS Channel Estimate

    estimatedChannelLS = ...
        receivedPilotFrequency ./ pilotSymbols;

    %% MMSE Channel Estimate

    noiseToSignalRatio = ...
        10^(-currentSNR/10);

    estimatedChannelMMSE = zeros(Nfft,1);

    for k = 1:Nfft

        H = channelFrequencyResponse(k);

        mmseFactor = ...
            abs(H)^2 / ...
            (abs(H)^2 + noiseToSignalRatio);

        estimatedChannelMMSE(k) = ...
            mmseFactor * estimatedChannelLS(k);

    end

    %% LS-ZF Equalization

    rxLS_ZF = zeros(size(rxDataFFT));

    for k = 1:Nfft

        rxLS_ZF(k,:) = ...
            rxDataFFT(k,:) ./ estimatedChannelLS(k);

    end

    %% MMSE-Estimate ZF Equalization

    rxMMSE_ZF = zeros(size(rxDataFFT));

    for k = 1:Nfft

        rxMMSE_ZF(k,:) = ...
            rxDataFFT(k,:) ./ estimatedChannelMMSE(k);

    end

    %% Serialize

    rxLS_Serial = rxLS_ZF(:);

    rxMMSE_Serial = rxMMSE_ZF(:);

    %% EVM

    errorLS = ...
        rxLS_Serial - txQPSK;

    errorMMSE = ...
        rxMMSE_Serial - txQPSK;

    rmsEVM_LS = sqrt( ...
        mean(abs(errorLS).^2) / ...
        mean(abs(txQPSK).^2));

    rmsEVM_MMSE = sqrt( ...
        mean(abs(errorMMSE).^2) / ...
        mean(abs(txQPSK).^2));

    evmLS(s) = rmsEVM_LS * 100;

    evmMMSE(s) = rmsEVM_MMSE * 100;

    fprintf( ...
        'SNR = %2d dB   LS EVM = %.4f %%   MMSE EVM = %.4f %%\n', ...
        currentSNR, ...
        evmLS(s), ...
        evmMMSE(s));

end

%% EVM Comparison Plot

figure;

plot( ...
    snrRange, ...
    evmLS, ...
    '-o', ...
    'LineWidth',1.5);

hold on;

plot( ...
    snrRange, ...
    evmMMSE, ...
    '-s', ...
    'LineWidth',1.5);

grid on;

xlabel('SNR (dB)');

ylabel('EVM (%)');

title('LS vs MMSE Channel Estimation EVM');

legend( ...
    'LS Channel + ZF', ...
    'MMSE Channel + ZF', ...
    'Location','northeast');

fprintf('\nEVM comparison graph generated successfully.\n');
