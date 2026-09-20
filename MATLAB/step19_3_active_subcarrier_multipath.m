%% STEP 19.3 - ACTIVE-SUBCARRIER OFDM WITH MULTIPATH

clc;
clear;
close all;

fprintf('\n');
fprintf('============================================\n');
fprintf(' STEP 19.3: ACTIVE-SUBCARRIER OFDM + MULTIPATH\n');
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

%% Generate Data

numQPSKSymbols = ...
    numActiveSubcarriers * numOFDMSymbols;

numBits = ...
    numQPSKSymbols * bitsPerSymbol;

rng(800);

txBits = randi([0 1],numBits,1);

txSymbolIndices = ...
    bi2de( ...
    reshape(txBits,bitsPerSymbol,[]).', ...
    'left-msb');

txQPSK = ...
    pskmod(txSymbolIndices,M,pi/4);

%% Frequency-Domain OFDM Grid

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

%% AWGN

rxFrame = ...
    awgn( ...
    rxMultipath, ...
    snrTest, ...
    'measured');

%% Receiver Reshaping

rxMatrix = ...
    reshape( ...
    rxFrame, ...
    Nfft+cpLength, ...
    numOFDMSymbols);

%% Remove Cyclic Prefix

rxNoCP = ...
    rxMatrix(cpLength+1:end,:);

%% FFT

rxFFT = ...
    fft(rxNoCP,Nfft,1);

%% Extract Active Subcarriers

rxActiveData = ...
    rxFFT(activeIndices,:);

rxQPSK = ...
    rxActiveData(:);

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

%% Results

fprintf('\n===== SYSTEM CONFIGURATION =====\n');

fprintf('FFT Size                  : %d\n',Nfft);

fprintf('Cyclic Prefix             : %d samples\n',cpLength);

fprintf('Total Subcarriers         : %d\n',Nfft);

fprintf('Active Subcarriers        : %d\n', ...
    numActiveSubcarriers);

fprintf('Unused Subcarriers        : %d\n', ...
    Nfft-numActiveSubcarriers);

fprintf('Modulation                : QPSK\n');

fprintf('OFDM Symbols              : %d\n', ...
    numOFDMSymbols);

fprintf('Test SNR                  : %d dB\n', ...
    snrTest);

fprintf('\n===== MULTIPATH CHANNEL =====\n');

fprintf('Path Delays               : ');

fprintf('%d ',pathDelays);

fprintf('samples\n');

fprintf('Path Gains                : ');

fprintf('%.2f ',pathGains);

fprintf('\n');

fprintf('\n===== BER RESULT =====\n');

fprintf('Bit Errors                : %d\n', ...
    bitErrors);

fprintf('Total Bits                : %d\n', ...
    numBits);

fprintf('BER                       : %.8f\n', ...
    BER);

%% Channel Impulse Response

figure;

stem( ...
    0:length(channelImpulseResponse)-1, ...
    channelImpulseResponse, ...
    'filled');

grid on;

xlabel('Delay (samples)');

ylabel('Amplitude');

title('Multipath Channel Impulse Response');

fprintf('\nChannel impulse response graph generated successfully.\n');

%% Received Constellation

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

title('Active-Subcarrier OFDM: Multipath Constellation');

legend( ...
    'Transmitted', ...
    'Received');

fprintf('Constellation graph generated successfully.\n');

%% Active Subcarrier Spectrum

figure;

stem( ...
    0:Nfft-1, ...
    abs(rxFFT(:,1)), ...
    'filled');

grid on;

xlabel('Subcarrier Index');

ylabel('Magnitude');

title('Received OFDM Subcarrier Spectrum');

fprintf('Received subcarrier spectrum generated successfully.\n');

fprintf('\nSTEP 19.3 completed successfully.\n');
