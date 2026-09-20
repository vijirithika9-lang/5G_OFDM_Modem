clc;
clear;
close all;

%% Step 5 - OFDM BER vs SNR over AWGN Channel

% Number of bits
numBits = 100000;

% OFDM parameters
Nfft = 64;
cpLength = 16;

% SNR range
snrRange = 0:2:20;

% Store BER values
berValues = zeros(size(snrRange));

%% Generate random bits

txBits = randi([0 1], numBits, 1);

% Make number of bits even
if mod(length(txBits),2) ~= 0
    txBits = txBits(1:end-1);
end

%% QPSK Modulation

bitPairs = reshape(txBits, 2, []).';

txSymbolsDecimal = bi2de(bitPairs, 'left-msb');

txQPSK = pskmod(txSymbolsDecimal, 4, pi/4);

%% Arrange symbols into OFDM symbols

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

%% Test different SNR values

for k = 1:length(snrRange)

    %% AWGN Channel

    rxSignal = awgn(txSignal, snrRange(k), 'measured');

    %% Receiver

    % Convert serial signal to OFDM symbols

    rxWithCP = reshape( ...
        rxSignal, ...
        Nfft + cpLength, ...
        numOFDMSymbols);

    %% Remove Cyclic Prefix

    rxWithoutCP = rxWithCP(cpLength+1:end, :);

    %% FFT

    rxFrequencyDomain = fft(rxWithoutCP, Nfft, 1);

    %% Parallel to Serial

    rxQPSK = rxFrequencyDomain(:);

    %% QPSK Demodulation

    rxSymbolsDecimal = pskdemod( ...
        rxQPSK, ...
        4, ...
        pi/4);

    %% Convert symbols to bits

    rxBitPairs = de2bi( ...
        rxSymbolsDecimal, ...
        2, ...
        'left-msb');

    rxBits = reshape(rxBitPairs.', [], 1);

    %% Calculate BER

    txBitsUsed = txBits(1:length(rxBits));

    [numErrors, ber] = biterr(txBitsUsed, rxBits);

    berValues(k) = ber;

    fprintf( ...
        'SNR = %2d dB   Bit Errors = %5d   BER = %.6f\n', ...
        snrRange(k), ...
        numErrors, ...
        ber);
end

%% Plot BER vs SNR

figure;

semilogy( ...
    snrRange, ...
    berValues, ...
    'o-', ...
    'LineWidth', ...
    1.5);

grid on;

xlabel('SNR (dB)');
ylabel('Bit Error Rate (BER)');

title('OFDM BER Performance over AWGN Channel');
