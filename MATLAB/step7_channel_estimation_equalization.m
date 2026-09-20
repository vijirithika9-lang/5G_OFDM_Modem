clc;
clear;
close all;

%% Step 7 - Channel Estimation and Equalization

% Number of bits
numBits = 100000;

% OFDM parameters
Nfft = 64;
cpLength = 16;

% SNR range
snrRange = 0:2:20;

% BER storage
berValues = zeros(size(snrRange));

%% Multipath Channel

pathDelays = [0 2 4];
pathGains = [1 0.5 0.25];

% Channel impulse response
channelImpulseResponse = zeros(max(pathDelays)+1,1);
channelImpulseResponse(pathDelays+1) = pathGains;

%% Generate Random Bits

txBits = randi([0 1], numBits, 1);

% Make number of bits even
if mod(length(txBits),2) ~= 0
    txBits = txBits(1:end-1);
end

%% QPSK Modulation

bitPairs = reshape(txBits, 2, []).';

txSymbolsDecimal = bi2de(bitPairs, 'left-msb');

txQPSK = pskmod(txSymbolsDecimal, 4, pi/4);

%% Arrange Symbols into OFDM Symbols

numQPSKSymbols = length(txQPSK);

numOFDMSymbols = floor(numQPSKSymbols/Nfft);

txQPSK = txQPSK(1:numOFDMSymbols*Nfft);

ofdmInput = reshape(txQPSK, Nfft, numOFDMSymbols);

%% IFFT

ofdmTimeDomain = ifft(ofdmInput, Nfft, 1);

%% Add Cyclic Prefix

cyclicPrefix = ...
    ofdmTimeDomain(end-cpLength+1:end,:);

ofdmWithCP = ...
    [cyclicPrefix; ofdmTimeDomain];

%% Parallel to Serial

txSignal = ofdmWithCP(:);

%% Pass Through Multipath Channel

channelOutput = conv( ...
    txSignal, ...
    channelImpulseResponse);

% Keep original signal length
channelOutput = ...
    channelOutput(1:length(txSignal));

%% Test Different SNR Values

for k = 1:length(snrRange)

    %% Add AWGN

    rxSignal = awgn( ...
        channelOutput, ...
        snrRange(k), ...
        'measured');

    %% Receiver

    rxWithCP = reshape( ...
        rxSignal, ...
        Nfft + cpLength, ...
        numOFDMSymbols);

    %% Remove Cyclic Prefix

    rxWithoutCP = ...
        rxWithCP(cpLength+1:end,:);

    %% FFT

    rxFrequencyDomain = ...
        fft(rxWithoutCP,Nfft,1);

    %% Channel Estimation

    % Estimate channel frequency response
    H = fft(channelImpulseResponse,Nfft);

    % Repeat channel response for all OFDM symbols
    H_matrix = repmat(H,1,numOFDMSymbols);

    %% Equalization

    % Zero-Forcing Equalizer
    equalizedSymbols = ...
        rxFrequencyDomain ./ H_matrix;

    %% Parallel to Serial

    rxQPSK = equalizedSymbols(:);

    %% QPSK Demodulation

    rxSymbolsDecimal = ...
        pskdemod(rxQPSK,4,pi/4);

    %% Convert Symbols to Bits

    rxBitPairs = ...
        de2bi(rxSymbolsDecimal,2,'left-msb');

    rxBits = ...
        reshape(rxBitPairs.',[],1);

    %% BER

    txBitsUsed = ...
        txBits(1:length(rxBits));

    [numErrors,ber] = ...
        biterr(txBitsUsed,rxBits);

    berValues(k) = ber;

    fprintf( ...
        'SNR = %2d dB   Bit Errors = %5d   BER = %.6f\n', ...
        snrRange(k), ...
        numErrors, ...
        ber);

end

%% Plot BER

figure;

semilogy( ...
    snrRange, ...
    berValues, ...
    'o-', ...
    'LineWidth',1.5);

grid on;

xlabel('SNR (dB)');
ylabel('Bit Error Rate (BER)');

title('OFDM BER with Channel Estimation and Equalization');

%% Plot Channel Frequency Response

figure;

plot( ...
    0:Nfft-1, ...
    abs(H), ...
    'o-');

grid on;

xlabel('Subcarrier Index');
ylabel('|H(f)|');

title('Estimated Channel Frequency Response');