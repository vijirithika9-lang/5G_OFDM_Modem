%% STEP 19.4 - PILOT-BASED CHANNEL ESTIMATION + ZF EQUALIZATION

clc;
clear;
close all;

fprintf('\n');
fprintf('============================================\n');
fprintf(' STEP 19.4: PILOT-BASED CHANNEL ESTIMATION\n');
fprintf('============================================\n');

%% System Parameters

Nfft = 64;
cpLength = 16;

M = 4;
bitsPerSymbol = log2(M);

numOFDMSymbols = 1000;

snrTest = 20;

%% Active Subcarriers

activeSubcarriers = [-26:-1 1:26];

activeIndices = mod(activeSubcarriers,Nfft) + 1;

numActiveSubcarriers = length(activeIndices);

%% Multipath Channel

pathDelays = [0 2 4];
pathGains  = [1.00 0.50 0.25];

channelImpulseResponse = ...
    zeros(max(pathDelays)+1,1);

for p = 1:length(pathDelays)

    channelImpulseResponse( ...
        pathDelays(p)+1) = pathGains(p);

end

%% Actual Channel Frequency Response

channelFrequencyResponse = ...
    fft(channelImpulseResponse,Nfft);

%% Generate Pilot

pilotSymbols = ones(numActiveSubcarriers,1);

pilotGrid = zeros(Nfft,1);

pilotGrid(activeIndices) = pilotSymbols;

pilotIFFT = ...
    ifft(pilotGrid,Nfft);

pilotWithCP = [
    pilotIFFT(end-cpLength+1:end);
    pilotIFFT
];

%% Pass Pilot Through Multipath Channel

rxPilotMultipath = ...
    filter( ...
    channelImpulseResponse, ...
    1, ...
    pilotWithCP);

rxPilotNoisy = ...
    awgn( ...
    rxPilotMultipath, ...
    snrTest, ...
    'measured');

%% Remove Pilot CP

rxPilotNoCP = ...
    rxPilotNoisy(cpLength+1:end);

%% FFT

receivedPilotFrequency = ...
    fft(rxPilotNoCP,Nfft);

%% LS Channel Estimation

estimatedChannel = zeros(Nfft,1);

estimatedChannel(activeIndices) = ...
    receivedPilotFrequency(activeIndices) ...
    ./ pilotSymbols;

%% Generate Data

numQPSKSymbols = ...
    numActiveSubcarriers * numOFDMSymbols;

numBits = ...
    numQPSKSymbols * bitsPerSymbol;

rng(900);

txBits = randi([0 1],numBits,1);

txSymbolIndices = ...
    bi2de( ...
    reshape(txBits,bitsPerSymbol,[]).', ...
    'left-msb');

txQPSK = ...
    pskmod(txSymbolIndices,M,pi/4);

%% OFDM Data Grid

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

%% Multipath Channel

rxMultipath = ...
    filter( ...
    channelImpulseResponse, ...
    1, ...
    txFrame);

%% AWGN

rxFrame = ...
    awgn( ...
    rxMultipath, ...
    snrTest, ...
    'measured');

%% Receiver

rxMatrix = ...
    reshape( ...
    rxFrame, ...
    Nfft+cpLength, ...
    numOFDMSymbols);

rxNoCP = ...
    rxMatrix(cpLength+1:end,:);

rxFFT = ...
    fft(rxNoCP,Nfft,1);

%% Extract Active Subcarriers

rxActiveData = ...
    rxFFT(activeIndices,:);

%% ZF Equalization

estimatedActiveChannel = ...
    estimatedChannel(activeIndices);

rxEqualized = zeros(size(rxActiveData));

for k = 1:numActiveSubcarriers

    rxEqualized(k,:) = ...
        rxActiveData(k,:) ...
        ./ estimatedActiveChannel(k);

end

%% Serialize Equalized Data

rxQPSK = rxEqualized(:);

%% QPSK Demodulation

rxSymbolIndices = ...
    pskdemod( ...
    rxQPSK, ...
    M, ...
    pi/4);

rxBitsMatrix = ...
    de2bi( ...
    rxSymbolIndices, ...
    bitsPerSymbol, ...
    'left-msb');

rxBits = ...
    reshape( ...
    rxBitsMatrix.', ...
    [],1);

%% BER

bitErrors = ...
    sum(txBits ~= rxBits);

BER = ...
    bitErrors / numBits;

%% Channel Estimation RMSE

channelError = ...
    estimatedChannel(activeIndices) ...
    - channelFrequencyResponse(activeIndices);

channelRMSE = ...
    sqrt( ...
    mean(abs(channelError).^2));

%% Results

fprintf('\n===== SYSTEM CONFIGURATION =====\n');

fprintf('FFT Size                  : %d\n',Nfft);

fprintf('Cyclic Prefix             : %d samples\n',cpLength);

fprintf('Total Subcarriers         : %d\n',Nfft);

fprintf('Active Subcarriers        : %d\n', ...
    numActiveSubcarriers);

fprintf('Modulation                : QPSK\n');

fprintf('OFDM Symbols              : %d\n', ...
    numOFDMSymbols);

fprintf('Test SNR                  : %d dB\n', ...
    snrTest);

fprintf('\n===== CHANNEL ESTIMATION =====\n');

fprintf('Estimation Method         : LS Pilot-Based\n');

fprintf('Channel RMSE              : %.6f\n', ...
    channelRMSE);

fprintf('\n===== ZF EQUALIZATION =====\n');

fprintf('Equalizer                 : Zero-Forcing\n');

fprintf('Channel Used              : Pilot-Based Estimate\n');

fprintf('\n===== BER RESULT =====\n');

fprintf('Bit Errors                : %d\n', ...
    bitErrors);

fprintf('Total Bits                : %d\n', ...
    numBits);

fprintf('BER                       : %.8f\n', ...
    BER);

%% Actual vs Estimated Channel Magnitude

figure;

plot( ...
    activeSubcarriers, ...
    abs(channelFrequencyResponse(activeIndices)), ...
    '-o', ...
    'LineWidth',1.5);

hold on;

plot( ...
    activeSubcarriers, ...
    abs(estimatedChannel(activeIndices)), ...
    '-s', ...
    'LineWidth',1.5);

grid on;

xlabel('Active Subcarrier');

ylabel('Channel Magnitude');

title('Actual vs Pilot-Estimated Channel');

legend( ...
    'Actual Channel', ...
    'Pilot Estimated Channel', ...
    'Location','best');

fprintf('\nChannel estimation graph generated successfully.\n');

%% Equalized Constellation

figure;

plot( ...
    real(txQPSK), ...
    imag(txQPSK), ...
    'o');

hold on;

plot( ...
    real(rxQPSK), ...
    imag(rxQPSK), ...
    '.');

grid on;

xlabel('In-Phase');

ylabel('Quadrature');

title('Pilot-Based ZF Equalized QPSK');

legend( ...
    'Transmitted', ...
    'Equalized Received');

fprintf('Equalized constellation graph generated successfully.\n');

fprintf('\nSTEP 19.4 completed successfully.\n');
