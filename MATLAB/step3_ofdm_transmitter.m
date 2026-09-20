clc;
clear;
close all;

%% Step 3 - OFDM Transmitter

% Number of bits
numBits = 100000;

% OFDM parameters
Nfft = 64;              % Number of subcarriers
cpLength = 16;          % Cyclic Prefix length

%% Generate Random Bits

txBits = randi([0 1], numBits, 1);

%% QPSK Modulation

% Make number of bits even
if mod(length(txBits),2) ~= 0
    txBits = txBits(1:end-1);
end

% Group bits into pairs
bitPairs = reshape(txBits, 2, []).';

% Convert bit pairs to decimal symbols
qpskSymbolsDecimal = bi2de(bitPairs, 'left-msb');

% QPSK modulation
qpskSymbols = pskmod(qpskSymbolsDecimal, 4, pi/4);

%% Arrange Symbols into OFDM Subcarriers

numQPSKSymbols = length(qpskSymbols);

% Number of complete OFDM symbols
numOFDMSymbols = floor(numQPSKSymbols / Nfft);

% Keep only complete OFDM symbols
qpskSymbols = qpskSymbols(1:numOFDMSymbols*Nfft);

% Arrange symbols into parallel streams
ofdmInput = reshape(qpskSymbols, Nfft, numOFDMSymbols);

%% IFFT - OFDM Modulation

ofdmTimeDomain = ifft(ofdmInput, Nfft, 1);

%% Add Cyclic Prefix

cyclicPrefix = ofdmTimeDomain(end-cpLength+1:end, :);

ofdmWithCP = [cyclicPrefix; ofdmTimeDomain];

%% Convert Parallel to Serial

txOFDM = ofdmWithCP(:);

%% Display Information

fprintf('\n');
fprintf('===== STEP 3: OFDM TRANSMITTER =====\n');
fprintf('Number of input bits       : %d\n', length(txBits));
fprintf('Number of subcarriers      : %d\n', Nfft);
fprintf('Cyclic Prefix length       : %d\n', cpLength);
fprintf('Number of OFDM symbols     : %d\n', numOFDMSymbols);
fprintf('Transmitted OFDM samples   : %d\n', length(txOFDM));

%% Plot OFDM Time Domain Signal

figure;

plot(real(txOFDM(1:500)));

grid on;

xlabel('Sample Index');
ylabel('Amplitude');

title('OFDM Transmitted Signal - Time Domain');

%% Plot OFDM Signal Spectrum

figure;

plot(abs(fftshift(fft(txOFDM))));

grid on;

xlabel('Frequency Bin');
ylabel('Magnitude');

title('OFDM Transmitted Signal Spectrum');