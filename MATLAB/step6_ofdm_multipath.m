clc;
clear;
close all;

%% Step 6 - OFDM over Multipath Fading Channel

% Number of bits
numBits = 100000;

% OFDM parameters
Nfft = 64;
cpLength = 16;

% SNR range
snrRange = 0:2:20;

% Store BER values
berValues = zeros(size(snrRange));

%% Multipath Channel Parameters

% Path delays
pathDelays = [0 2 4];

% Path gains
pathGains = [1 0.5 0.25];

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

%% Arrange QPSK symbols into OFDM symbols

numQPSKSymbols = length(txQPSK);

numOFDMSymbols = floor(numQPSKSymbols / Nfft);

txQPSK = txQPSK(1:numOFDMSymbols*Nfft);

ofdmInput = reshape(txQPSK, Nfft, numOFDMSymbols);

%% IFFT

ofdmTimeDomain = ifft(ofdmInput, Nfft, 1);

%% Add Cyclic Prefix

cyclicPrefix = ...
    ofdmTimeDomain(end-cpLength+1:end, :);

ofdmWithCP = ...
    [cyclicPrefix; ofdmTimeDomain];

%% Parallel to Serial

txSignal = ofdmWithCP(:);

%% Create Multipath Channel

channelImpulseResponse = zeros(max(pathDelays)+1,1);

channelImpulseResponse(pathDelays+1) = pathGains;

%% Display Channel

fprintf('\n');
fprintf('===== STEP 6: MULTIPATH CHANNEL =====\n');

fprintf('Path delays : ');
fprintf('%d ', pathDelays);
fprintf('samples\n');

fprintf('Path gains  : ');
fprintf('%.2f ', pathGains);
fprintf('\n');

%% Pass Signal Through Multipath Channel

channelOutput = conv(txSignal, channelImpulseResponse);

% Remove channel tail
channelOutput = channelOutput(1:length(txSignal));

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
        rxWithCP(cpLength+1:end, :);

    %% FFT

    rxFrequencyDomain = ...
        fft(rxWithoutCP, Nfft, 1);

    %% Serial Conversion

    rxQPSK = rxFrequencyDomain(:);

    %% QPSK Demodulation

    rxSymbolsDecimal = ...
        pskdemod(rxQPSK, 4, pi/4);

    %% Convert Symbols to Bits

    rxBitPairs = ...
        de2bi(rxSymbolsDecimal, 2, 'left-msb');

    rxBits = reshape(rxBitPairs.', [], 1);

    %% BER Calculation

    txBitsUsed = txBits(1:length(rxBits));

    [numErrors, ber] = ...
        biterr(txBitsUsed, rxBits);

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
    'LineWidth', 1.5);

grid on;

xlabel('SNR (dB)');
ylabel('Bit Error Rate (BER)');

title('OFDM BER over Multipath Fading Channel');

%% Plot Channel Impulse Response

figure;

stem( ...
    0:length(channelImpulseResponse)-1, ...
    channelImpulseResponse, ...
    'filled');

grid on;

xlabel('Sample Delay');
ylabel('Channel Gain');

title('Multipath Channel Impulse Response');