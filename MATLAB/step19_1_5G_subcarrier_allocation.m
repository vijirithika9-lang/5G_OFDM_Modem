%% STEP 19.1 - 5G-ORIENTED SUBCARRIER ALLOCATION

clc;
clear;
close all;

fprintf('\n');
fprintf('============================================\n');
fprintf('   STEP 19.1: 5G-ORIENTED SUBCARRIER ALLOCATION\n');
fprintf('============================================\n');

%% System Parameters

Nfft = 64;

M = 4;

bitsPerSymbol = log2(M);

%% Define Active Subcarriers

% DC subcarrier is kept unused

activeSubcarriers = [-26:-1 1:26];

activeIndices = mod(activeSubcarriers,Nfft) + 1;

numActiveSubcarriers = length(activeSubcarriers);

fprintf('\nFFT Size                  : %d\n',Nfft);
fprintf('Modulation                : QPSK\n');
fprintf('Total Subcarriers         : %d\n',Nfft);
fprintf('Active Subcarriers        : %d\n',numActiveSubcarriers);
fprintf('DC Subcarrier             : Unused\n');

%% Generate QPSK Symbols

numOFDMSymbols = 10;

numQPSKSymbols = ...
    numActiveSubcarriers * numOFDMSymbols;

numBits = ...
    numQPSKSymbols * bitsPerSymbol;

rng(600);

txBits = randi([0 1],numBits,1);

txSymbolIndices = ...
    bi2de( ...
    reshape(txBits,bitsPerSymbol,[]).', ...
    'left-msb');

txQPSK = ...
    pskmod(txSymbolIndices,M,pi/4);

%% Arrange Active Data

txActiveData = ...
    reshape( ...
    txQPSK, ...
    numActiveSubcarriers, ...
    numOFDMSymbols);

%% Create OFDM Frequency-Domain Grid

ofdmGrid = zeros(Nfft,numOFDMSymbols);

ofdmGrid(activeIndices,:) = txActiveData;

%% Display Information

fprintf('\n===== SUBCARRIER ALLOCATION =====\n');

fprintf('Data-bearing subcarriers    : %d\n', ...
    numActiveSubcarriers);

fprintf('Unused subcarriers           : %d\n', ...
    Nfft-numActiveSubcarriers);

fprintf('OFDM symbols                 : %d\n', ...
    numOFDMSymbols);

%% Plot Subcarrier Allocation

figure;

stem( ...
    0:Nfft-1, ...
    abs(ofdmGrid(:,1)), ...
    'filled');

grid on;

xlabel('Subcarrier Index');

ylabel('Magnitude');

title('5G-Oriented OFDM Subcarrier Allocation');

fprintf('\nSubcarrier allocation graph generated successfully.\n');
%% STEP 19.2 - ACTIVE SUBCARRIER OFDM TRANSMISSION & RECEPTION

clc;
clear;
close all;

fprintf('\n');
fprintf('============================================\n');
fprintf(' STEP 19.2: ACTIVE-SUBCARRIER OFDM SYSTEM\n');
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

%% Data Generation

numQPSKSymbols = ...
    numActiveSubcarriers * numOFDMSymbols;

numBits = ...
    numQPSKSymbols * bitsPerSymbol;

rng(700);

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

%% AWGN Channel

rxFrame = ...
    awgn( ...
    txFrame, ...
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

rxQPSK = rxActiveData(:);

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

fprintf('\n===== BER RESULT =====\n');

fprintf('Bit Errors                : %d\n', ...
    bitErrors);

fprintf('Total Bits               : %d\n', ...
    numBits);

fprintf('BER                       : %.8f\n', ...
    BER);

%% Frequency-Domain Subcarrier Plot

figure;

stem( ...
    0:Nfft-1, ...
    abs(txGrid(:,1)), ...
    'filled');

grid on;

xlabel('Subcarrier Index');

ylabel('Magnitude');

title('Active Subcarriers in OFDM');

fprintf('\nActive-subcarrier OFDM graph generated successfully.\n');

%% Transmitted vs Received Constellation

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

title('Transmitted vs Received QPSK Constellation');

legend( ...
    'Transmitted', ...
    'Received');

fprintf('Constellation graph generated successfully.\n');
