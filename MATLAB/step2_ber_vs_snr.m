clc;
clear;
close all;

%% Step 2 - BER vs SNR Analysis

% Number of bits
numBits = 100000;

% Generate random bits
txBits = randi([0 1], numBits, 1);

%% QPSK Modulation

% Convert bits into pairs
txBitPairs = reshape(txBits, 2, []).';

% Convert bit pairs to decimal symbols
txSymbolsDecimal = bi2de(txBitPairs, 'left-msb');

% QPSK modulation
txSymbols = pskmod(txSymbolsDecimal, 4, pi/4);

%% SNR Range

snrRange = 0:2:20;

% Array to store BER values
berValues = zeros(size(snrRange));

%% Test Different SNR Values

for k = 1:length(snrRange)

    % Add AWGN noise
    rxSymbols = awgn(txSymbols, snrRange(k), 'measured');

    % QPSK Demodulation
    rxSymbolsDecimal = pskdemod(rxSymbols, 4, pi/4);

    % Convert decimal symbols back to bits
    rxBitPairs = de2bi(rxSymbolsDecimal, 2, 'left-msb');

    % Convert matrix to column vector
    rxBits = reshape(rxBitPairs.', [], 1);

    % Calculate BER
    [numErrors, ber] = biterr(txBits, rxBits);

    % Store BER
    berValues(k) = ber;

    fprintf('SNR = %2d dB   Bit Errors = %5d   BER = %.6f\n', ...
        snrRange(k), numErrors, ber);
end

%% Plot BER vs SNR

figure;

semilogy(snrRange, berValues, 'o-', 'LineWidth', 1.5);

grid on;

xlabel('SNR (dB)');
ylabel('Bit Error Rate (BER)');
title('QPSK BER Performance over AWGN Channel');
