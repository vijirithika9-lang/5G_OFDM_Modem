clc;
clear;
close all;

%% Step 4 - OFDM Transmitter and Receiver

% Number of bits
numBits = 100000;

% OFDM parameters
Nfft = 64;
cpLength = 16;

%% =========================
% TRANSMITTER
% ==========================

% Generate random bits
txBits = randi([0 1], numBits, 1);

% Make number of bits even
if mod(length(txBits),2) ~= 0
    txBits = txBits(1:end-1);
end

%% QPSK Modulation

bitPairs = reshape(txBits, 2, []).';

qpskSymbolsDecimal = bi2de(bitPairs, 'left-msb');

txQPSK = pskmod(qpskSymbolsDecimal, 4, pi/4);

%% Arrange QPSK symbols into OFDM symbols

numQPSKSymbols = length(txQPSK);

numOFDMSymbols = floor(numQPSKSymbols / Nfft);

txQPSK = txQPSK(1:numOFDMSymbols*Nfft);

ofdmInput = reshape(txQPSK, Nfft, numOFDMSymbols);

%% IFFT

ofdmTimeDomain = ifft(ofdmInput, Nfft, 1);

%% Add Cyclic Prefix

cyclicPrefix = ofdmTimeDomain(end-cpLength+1:end, :);

ofdmWithCP = [cyclicPrefix; ofdmTimeDomain];

%% Parallel to Serial

txSignal = ofdmWithCP(:);

%% =========================
% CHANNEL
% ==========================

% For now, assume ideal channel
rxSignal = txSignal;

%% =========================
% RECEIVER
% ==========================

% Convert serial signal back to OFDM symbols

rxWithCP = reshape(rxSignal, Nfft + cpLength, numOFDMSymbols);

%% Remove Cyclic Prefix

rxWithoutCP = rxWithCP(cpLength+1:end, :);

%% FFT

rxFrequencyDomain = fft(rxWithoutCP, Nfft, 1);

%% Convert Parallel to Serial

rxQPSK = rxFrequencyDomain(:);

%% QPSK Demodulation

rxQPSK = rxQPSK(1:length(txQPSK));

rxSymbolsDecimal = pskdemod(rxQPSK, 4, pi/4);

%% Convert Symbols to Bits

rxBitPairs = de2bi(rxSymbolsDecimal, 2, 'left-msb');

rxBits = reshape(rxBitPairs.', [], 1);

%% =========================
% BER CALCULATION
% ==========================

txBitsUsed = txBits(1:length(rxBits));

[numErrors, ber] = biterr(txBitsUsed, rxBits);

%% Display Results

fprintf('\n');
fprintf('===== STEP 4: OFDM RECEIVER =====\n');
fprintf('Number of transmitted bits : %d\n', length(txBitsUsed));
fprintf('Number of bit errors       : %d\n', numErrors);
fprintf('BER                        : %.10f\n', ber);

%% Plot Transmitted and Received Signal

figure;

plot(real(txSignal(1:500)));
hold on;
plot(real(rxSignal(1:500)));

grid on;

xlabel('Sample Index');
ylabel('Amplitude');

title('OFDM Transmitted vs Received Signal');

legend('Transmitted Signal','Received Signal');

%% Plot Constellation

figure;

plot(real(rxQPSK), imag(rxQPSK), '.');

grid on;
axis equal;

xlabel('In-Phase');
ylabel('Quadrature');

title('Received QPSK Constellation');