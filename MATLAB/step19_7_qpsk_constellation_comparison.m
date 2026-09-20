%% STEP 19.7 - QPSK CONSTELLATION COMPARISON
% Active-Subcarrier OFDM
% No Equalization vs Known-Channel ZF vs Pilot-Based LS-ZF

clc;
clear;
close all;

fprintf('\n');
fprintf('============================================\n');
fprintf(' STEP 19.7: QPSK CONSTELLATION COMPARISON\n');
fprintf('============================================\n');

%% System Parameters

Nfft = 64;
cpLength = 16;

M = 4;
numOFDMSymbols = 1000;

snrTest = 20;

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

    channelImpulseResponse(pathDelays(p)+1) = ...
        pathGains(p);

end

%% Channel Frequency Response

channelFrequencyResponse = ...
    fft(channelImpulseResponse,Nfft);

%% Generate QPSK Data

numQPSKSymbols = ...
    numActiveSubcarriers * numOFDMSymbols;

rng(1200);

txSymbolIndices = ...
    randi([0 M-1],numQPSKSymbols,1);

txQPSK = ...
    pskmod(txSymbolIndices,M,pi/4);

%% Create OFDM Grid

txGrid = zeros(Nfft,numOFDMSymbols);

txGrid(activeIndices,:) = ...
    reshape( ...
    txQPSK, ...
    numActiveSubcarriers, ...
    numOFDMSymbols);

%% IFFT

txIFFT = ...
    ifft(txGrid,Nfft,1);

%% Add Cyclic Prefix

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

%% Add AWGN

rxNoisy = ...
    awgn( ...
    rxMultipath, ...
    snrTest, ...
    'measured');

%% Receiver

rxMatrix = ...
    reshape( ...
    rxNoisy, ...
    Nfft+cpLength, ...
    numOFDMSymbols);

%% Remove CP

rxNoCP = ...
    rxMatrix(cpLength+1:end,:);

%% FFT

rxFFT = ...
    fft(rxNoCP,Nfft,1);

%% Extract Active Subcarriers

rxActive = ...
    rxFFT(activeIndices,:);

%% ==========================================
% SYSTEM 1: NO EQUALIZATION
% ===========================================

rxNoEQ = rxActive(:);

%% ==========================================
% SYSTEM 2: KNOWN-CHANNEL ZF
% ===========================================

knownActiveChannel = ...
    channelFrequencyResponse(activeIndices);

rxKnownZF = zeros(size(rxActive));

for k = 1:numActiveSubcarriers

    rxKnownZF(k,:) = ...
        rxActive(k,:) ./ knownActiveChannel(k);

end

rxKnownZFSerial = ...
    rxKnownZF(:);

%% ==========================================
% PILOT TRANSMISSION
% ===========================================

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

%% Pilot Through Channel

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

%% Remove CP

rxPilotNoCP = ...
    rxPilotNoisy(cpLength+1:end);

%% FFT

receivedPilotFrequency = ...
    fft(rxPilotNoCP,Nfft);

%% Pilot-Based LS Channel Estimation

estimatedChannel = ...
    receivedPilotFrequency(activeIndices) ...
    ./ pilotSymbols;

%% ==========================================
% SYSTEM 3: PILOT LS + ZF
% ===========================================

rxPilotLSZF = zeros(size(rxActive));

for k = 1:numActiveSubcarriers

    rxPilotLSZF(k,:) = ...
        rxActive(k,:) ./ estimatedChannel(k);

end

rxPilotLSZFSerial = ...
    rxPilotLSZF(:);

%% ==========================================
% EVM CALCULATION
% ===========================================

errorNoEQ = ...
    rxNoEQ - txQPSK;

errorKnownZF = ...
    rxKnownZFSerial - txQPSK;

errorPilotLSZF = ...
    rxPilotLSZFSerial - txQPSK;

evmNoEQ = ...
    sqrt(mean(abs(errorNoEQ).^2) / ...
    mean(abs(txQPSK).^2)) * 100;

evmKnownZF = ...
    sqrt(mean(abs(errorKnownZF).^2) / ...
    mean(abs(txQPSK).^2)) * 100;

evmPilotLSZF = ...
    sqrt(mean(abs(errorPilotLSZF).^2) / ...
    mean(abs(txQPSK).^2)) * 100;

%% ==========================================
% CONSTELLATION PLOT
% ===========================================

figure;

subplot(1,3,1);

plot(real(rxNoEQ),imag(rxNoEQ),'.');

grid on;

axis equal;

xlabel('In-Phase');

ylabel('Quadrature');

title(sprintf('No Equalization\nEVM = %.2f%%',evmNoEQ));

xlim([-2 2]);
ylim([-2 2]);

%% Known Channel ZF

subplot(1,3,2);

plot(real(rxKnownZFSerial), ...
     imag(rxKnownZFSerial),'.');

grid on;

axis equal;

xlabel('In-Phase');

ylabel('Quadrature');

title(sprintf('Known-Channel ZF\nEVM = %.2f%%',evmKnownZF));

xlim([-2 2]);
ylim([-2 2]);

%% Pilot LS + ZF

subplot(1,3,3);

plot(real(rxPilotLSZFSerial), ...
     imag(rxPilotLSZFSerial),'.');

grid on;

axis equal;

xlabel('In-Phase');

ylabel('Quadrature');

title(sprintf('Pilot LS + ZF\nEVM = %.2f%%',evmPilotLSZF));

xlim([-2 2]);
ylim([-2 2]);

sgtitle('5G-Oriented OFDM QPSK Constellation Comparison');

fprintf('\n');
fprintf('Constellation comparison generated successfully.\n');

%% ==========================================
% SUMMARY
% ===========================================

fprintf('\n============================================\n');
fprintf(' STEP 19.7 SUMMARY\n');
fprintf('============================================\n');

fprintf('FFT Size             : %d\n',Nfft);

fprintf('Active Subcarriers   : %d\n', ...
    numActiveSubcarriers);

fprintf('Modulation           : QPSK\n');

fprintf('Test SNR             : %d dB\n',snrTest);

fprintf('Channel              : Multipath + AWGN\n');

fprintf('\n');

fprintf('No Equalization EVM  : %.4f %%\n',evmNoEQ);

fprintf('Known ZF EVM         : %.4f %%\n',evmKnownZF);

fprintf('Pilot LS-ZF EVM      : %.4f %%\n',evmPilotLSZF);

fprintf('\nSTEP 19.7 completed successfully.\n');
