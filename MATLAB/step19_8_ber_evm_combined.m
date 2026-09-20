clc;
clear;
close all;

%% ============================================================
% STEP 19.8
% Combined BER + EVM Analysis
%
% Systems Compared:
% 1. No Equalization
% 2. Known-Channel ZF Equalization
% 3. Pilot-Based LS Channel Estimation + ZF Equalization
%
% OFDM Configuration:
% FFT Size          = 64
% Active Subcarriers = 52
% Modulation        = QPSK
% Multipath Channel = 3 paths
% =============================================================

%% ------------------------------------------------------------
% 1. SYSTEM PARAMETERS
% ------------------------------------------------------------

Nfft = 64;
cpLength = 16;

% 52 active subcarriers
activeSubcarriers = [-26:-1 1:26];

% Convert subcarrier numbers to MATLAB indices
activeIndices = mod(activeSubcarriers, Nfft) + 1;

numActiveSubcarriers = length(activeIndices);

% QPSK
M = 4;
bitsPerSymbol = log2(M);

% Number of OFDM symbols
numOFDMSymbols = 1000;

% SNR range
snrRange = 0:2:20;

% Multipath channel
pathDelays = [0 2 4];
pathGains  = [1.00 0.50 0.25];

%% ------------------------------------------------------------
% 2. RANDOM SEED
% ------------------------------------------------------------

rng(800);

%% ------------------------------------------------------------
% 3. GENERATE TRANSMITTED BITS
% ------------------------------------------------------------

numBits = ...
    numActiveSubcarriers * ...
    numOFDMSymbols * ...
    bitsPerSymbol;

txBits = randi([0 1], numBits, 1);

%% ------------------------------------------------------------
% 4. CONVERT BITS TO QPSK SYMBOLS
% ------------------------------------------------------------

% Group bits into pairs
txBitPairs = reshape( ...
    txBits, ...
    bitsPerSymbol, ...
    []).';

% Convert each pair of bits to decimal symbol index
txSymbolIndices = bi2de( ...
    txBitPairs, ...
    'left-msb');

% QPSK modulation
txQPSK = pskmod( ...
    txSymbolIndices, ...
    M, ...
    pi/4);

%% ------------------------------------------------------------
% 5. ARRANGE QPSK SYMBOLS INTO OFDM SYMBOLS
% ------------------------------------------------------------

txQPSKMatrix = reshape( ...
    txQPSK, ...
    numActiveSubcarriers, ...
    numOFDMSymbols);

%% ------------------------------------------------------------
% 6. CREATE FREQUENCY-DOMAIN OFDM SIGNAL
% ------------------------------------------------------------

txFrequency = zeros( ...
    Nfft, ...
    numOFDMSymbols);

% Put QPSK data only on active subcarriers
txFrequency(activeIndices, :) = txQPSKMatrix;

%% ------------------------------------------------------------
% 7. IFFT
% ------------------------------------------------------------

txTime = ifft( ...
    txFrequency, ...
    Nfft, ...
    1);

%% ------------------------------------------------------------
% 8. ADD CYCLIC PREFIX
% ------------------------------------------------------------

txWithCP = [
    txTime(end-cpLength+1:end, :);
    txTime
];

%% ------------------------------------------------------------
% 9. SERIALIZE TRANSMITTED SIGNAL
% ------------------------------------------------------------

txSignal = txWithCP(:);

%% ------------------------------------------------------------
% 10. CREATE MULTIPATH CHANNEL
% ------------------------------------------------------------

channelImpulseResponse = zeros( ...
    1, ...
    max(pathDelays) + 1);

for k = 1:length(pathDelays)

    channelImpulseResponse( ...
        pathDelays(k) + 1) = ...
        pathGains(k);

end

%% ------------------------------------------------------------
% 11. CHANNEL FREQUENCY RESPONSE
% ------------------------------------------------------------

channelFrequencyResponse = fft( ...
    [ ...
    channelImpulseResponse ...
    zeros(1, ...
    Nfft - length(channelImpulseResponse)) ...
    ], ...
    Nfft);

%% ------------------------------------------------------------
% 12. INITIALIZE RESULT ARRAYS
% ------------------------------------------------------------

berNoEQ = zeros( ...
    size(snrRange));

berKnownZF = zeros( ...
    size(snrRange));

berPilotLSZF = zeros( ...
    size(snrRange));

evmNoEQ = zeros( ...
    size(snrRange));

evmKnownZF = zeros( ...
    size(snrRange));

evmPilotLSZF = zeros( ...
    size(snrRange));

%% ============================================================
% 13. SNR LOOP
% =============================================================

for snrIndex = 1:length(snrRange)

    snr = snrRange(snrIndex);

    %% --------------------------------------------------------
    % 13.1 MULTIPATH CHANNEL
    % ---------------------------------------------------------

    rxMultipath = filter( ...
        channelImpulseResponse, ...
        1, ...
        txSignal);

    %% --------------------------------------------------------
    % 13.2 ADD AWGN
    % ---------------------------------------------------------

    rxSignal = awgn( ...
        rxMultipath, ...
        snr, ...
        'measured');

    %% --------------------------------------------------------
    % 13.3 RESHAPE RECEIVED SIGNAL
    % ---------------------------------------------------------

    rxWithCP = reshape( ...
        rxSignal, ...
        Nfft + cpLength, ...
        numOFDMSymbols);

    %% --------------------------------------------------------
    % 13.4 REMOVE CYCLIC PREFIX
    % ---------------------------------------------------------

    rxWithoutCP = ...
        rxWithCP(cpLength+1:end, :);

    %% --------------------------------------------------------
    % 13.5 FFT
    % ---------------------------------------------------------

    rxFrequency = fft( ...
        rxWithoutCP, ...
        Nfft, ...
        1);

    %% --------------------------------------------------------
    % 13.6 EXTRACT ACTIVE SUBCARRIERS
    % ---------------------------------------------------------

    rxActive = ...
        rxFrequency(activeIndices, :);

    %% ========================================================
    % SYSTEM 1
    % NO EQUALIZATION
    % =========================================================

    rxNoEQ = rxActive;

    %% --------------------------------------------------------
    % EVM - NO EQUALIZATION
    % ---------------------------------------------------------

    errorNoEQ = ...
        rxNoEQ - txQPSKMatrix;

    evmNoEQ(snrIndex) = ...
        sqrt( ...
        mean(abs(errorNoEQ(:)).^2) / ...
        mean(abs(txQPSKMatrix(:)).^2) ...
        ) * 100;

    %% --------------------------------------------------------
    % QPSK DEMODULATION
    % ---------------------------------------------------------

    rxSymbolsNoEQ = pskdemod( ...
        rxNoEQ(:), ...
        M, ...
        pi/4);

    %% --------------------------------------------------------
    % SYMBOLS TO BITS
    %
    % Transpose is IMPORTANT.
    % It preserves the original bit ordering.
    % ---------------------------------------------------------

    rxBitsNoEQ = reshape( ...
        de2bi( ...
        rxSymbolsNoEQ, ...
        bitsPerSymbol, ...
        'left-msb').', ...
        [], ...
        1);

    %% --------------------------------------------------------
    % BER - NO EQUALIZATION
    % ---------------------------------------------------------

    berNoEQ(snrIndex) = ...
        mean(txBits ~= rxBitsNoEQ);

    %% ========================================================
    % SYSTEM 2
    % KNOWN-CHANNEL ZERO-FORCING EQUALIZATION
    % =========================================================

    %% --------------------------------------------------------
    % Extract channel response of active subcarriers
    % ---------------------------------------------------------

    channelActive = ...
        channelFrequencyResponse(activeIndices);

    % IMPORTANT:
    % Force the channel response to 52 x 1
    channelActive = ...
        channelActive(:);

    %% --------------------------------------------------------
    % Repeat channel for all OFDM symbols
    % ---------------------------------------------------------

    channelActiveMatrix = ...
        repmat( ...
        channelActive, ...
        1, ...
        numOFDMSymbols);

    %% --------------------------------------------------------
    % ZERO-FORCING EQUALIZATION
    % ---------------------------------------------------------

    rxKnownZF = ...
        rxActive ./ channelActiveMatrix;

    %% --------------------------------------------------------
    % EVM - KNOWN CHANNEL ZF
    % ---------------------------------------------------------

    errorKnownZF = ...
        rxKnownZF - txQPSKMatrix;

    evmKnownZF(snrIndex) = ...
        sqrt( ...
        mean(abs(errorKnownZF(:)).^2) / ...
        mean(abs(txQPSKMatrix(:)).^2) ...
        ) * 100;

    %% --------------------------------------------------------
    % QPSK DEMODULATION
    % ---------------------------------------------------------

    rxSymbolsKnownZF = ...
        pskdemod( ...
        rxKnownZF(:), ...
        M, ...
        pi/4);

    %% --------------------------------------------------------
    % SYMBOLS TO BITS
    % ---------------------------------------------------------

    rxBitsKnownZF = reshape( ...
        de2bi( ...
        rxSymbolsKnownZF, ...
        bitsPerSymbol, ...
        'left-msb').', ...
        [], ...
        1);

    %% --------------------------------------------------------
    % BER - KNOWN CHANNEL ZF
    % ---------------------------------------------------------

    berKnownZF(snrIndex) = ...
        mean(txBits ~= rxBitsKnownZF);

    %% ========================================================
    % SYSTEM 3
    % PILOT-BASED LS CHANNEL ESTIMATION + ZF
    % =========================================================

    %% --------------------------------------------------------
    % Generate pilot symbols
    % ---------------------------------------------------------

    pilotIndices = ...
        (0:Nfft-1).';

    pilotSymbols = ...
        pskmod( ...
        mod(pilotIndices, M), ...
        M, ...
        pi/4);

    %% --------------------------------------------------------
    % Pilot IFFT
    % ---------------------------------------------------------

    pilotIFFT = ...
        ifft( ...
        pilotSymbols, ...
        Nfft);

    %% --------------------------------------------------------
    % Add CP to pilot
    % ---------------------------------------------------------

    pilotWithCP = [
        pilotIFFT(end-cpLength+1:end);
        pilotIFFT
    ];

    %% --------------------------------------------------------
    % Pass pilot through channel
    % ---------------------------------------------------------

    pilotRx = filter( ...
        channelImpulseResponse, ...
        1, ...
        pilotWithCP);

    %% --------------------------------------------------------
    % Add AWGN to pilot
    % ---------------------------------------------------------

    pilotRx = awgn( ...
        pilotRx, ...
        snr, ...
        'measured');

    %% --------------------------------------------------------
    % Remove pilot CP
    % ---------------------------------------------------------

    pilotRxNoCP = ...
        pilotRx(cpLength+1:end);

    %% --------------------------------------------------------
    % FFT PILOT
    % ---------------------------------------------------------

    pilotReceivedFrequency = ...
        fft( ...
        pilotRxNoCP, ...
        Nfft);

    %% --------------------------------------------------------
    % LS CHANNEL ESTIMATION
    % H_est = Y / X
    % ---------------------------------------------------------

    estimatedChannel = ...
        pilotReceivedFrequency ./ pilotSymbols;

    %% --------------------------------------------------------
    % Extract active subcarriers
    % ---------------------------------------------------------

    estimatedActiveChannel = ...
        estimatedChannel(activeIndices);

    % IMPORTANT:
    % Force estimated channel to 52 x 1
    estimatedActiveChannel = ...
        estimatedActiveChannel(:);

    %% --------------------------------------------------------
    % Repeat estimated channel for all OFDM symbols
    % ---------------------------------------------------------

    estimatedActiveMatrix = ...
        repmat( ...
        estimatedActiveChannel, ...
        1, ...
        numOFDMSymbols);

    %% --------------------------------------------------------
    % ZF EQUALIZATION USING PILOT ESTIMATE
    % ---------------------------------------------------------

    rxPilotLSZF = ...
        rxActive ./ estimatedActiveMatrix;

    %% --------------------------------------------------------
    % EVM - PILOT LS + ZF
    % ---------------------------------------------------------

    errorPilotLSZF = ...
        rxPilotLSZF - txQPSKMatrix;

    evmPilotLSZF(snrIndex) = ...
        sqrt( ...
        mean(abs(errorPilotLSZF(:)).^2) / ...
        mean(abs(txQPSKMatrix(:)).^2) ...
        ) * 100;

    %% --------------------------------------------------------
    % QPSK DEMODULATION
    % ---------------------------------------------------------

    rxSymbolsPilotLSZF = ...
        pskdemod( ...
        rxPilotLSZF(:), ...
        M, ...
        pi/4);

    %% --------------------------------------------------------
    % SYMBOLS TO BITS
    % ---------------------------------------------------------

    rxBitsPilotLSZF = reshape( ...
        de2bi( ...
        rxSymbolsPilotLSZF, ...
        bitsPerSymbol, ...
        'left-msb').', ...
        [], ...
        1);

    %% --------------------------------------------------------
    % BER - PILOT LS + ZF
    % ---------------------------------------------------------

    berPilotLSZF(snrIndex) = ...
        mean(txBits ~= rxBitsPilotLSZF);

    %% ========================================================
    % DISPLAY RESULTS
    % =========================================================

    fprintf( ...
        ['SNR = %2d dB | ' ...
        'No-EQ BER = %.6f, EVM = %.2f%% | ' ...
        'Known-ZF BER = %.6f, EVM = %.2f%% | ' ...
        'Pilot-LS-ZF BER = %.6f, EVM = %.2f%%\n'], ...
        snr, ...
        berNoEQ(snrIndex), ...
        evmNoEQ(snrIndex), ...
        berKnownZF(snrIndex), ...
        evmKnownZF(snrIndex), ...
        berPilotLSZF(snrIndex), ...
        evmPilotLSZF(snrIndex));

end

%% ============================================================
% 14. BER COMPARISON PLOT
% =============================================================

figure;

semilogy( ...
    snrRange, ...
    berNoEQ, ...
    '-o', ...
    'LineWidth', ...
    1.5);

hold on;

semilogy( ...
    snrRange, ...
    berKnownZF, ...
    '-s', ...
    'LineWidth', ...
    1.5);

semilogy( ...
    snrRange, ...
    berPilotLSZF, ...
    '-^', ...
    'LineWidth', ...
    1.5);

grid on;

xlabel('SNR (dB)');

ylabel('Bit Error Rate (BER)');

title( ...
    'Step 19.8 - BER Comparison');

legend( ...
    'No Equalization', ...
    'Known-Channel ZF', ...
    'Pilot-Based LS + ZF', ...
    'Location', ...
    'southwest');

%% ============================================================
% 15. EVM COMPARISON PLOT
% =============================================================

figure;

plot( ...
    snrRange, ...
    evmNoEQ, ...
    '-o', ...
    'LineWidth', ...
    1.5);

hold on;

plot( ...
    snrRange, ...
    evmKnownZF, ...
    '-s', ...
    'LineWidth', ...
    1.5);

plot( ...
    snrRange, ...
    evmPilotLSZF, ...
    '-^', ...
    'LineWidth', ...
    1.5);

grid on;

xlabel('SNR (dB)');

ylabel('EVM (%)');

title( ...
    'Step 19.8 - EVM Comparison');

legend( ...
    'No Equalization', ...
    'Known-Channel ZF', ...
    'Pilot-Based LS + ZF', ...
    'Location', ...
    'northeast');

%% ============================================================
% 16. FINAL SUMMARY
% =============================================================

fprintf('\n');
fprintf('=============================================\n');
fprintf('       STEP 19.8 COMPLETED\n');
fprintf('=============================================\n');

fprintf('FFT Size             : %d\n', Nfft);

fprintf('Active Subcarriers   : %d\n', ...
    numActiveSubcarriers);

fprintf('Unused Subcarriers   : %d\n', ...
    Nfft - numActiveSubcarriers);

fprintf('Modulation           : QPSK\n');

fprintf('OFDM Symbols         : %d\n', ...
    numOFDMSymbols);

fprintf('Channel              : Multipath + AWGN\n');

fprintf('Path Delays          : ');
fprintf('%d ', pathDelays);
fprintf('samples\n');

fprintf('Path Gains           : ');
fprintf('%.2f ', pathGains);
fprintf('\n');

fprintf('Metrics              : BER + EVM\n');

fprintf('Systems Compared     : No-EQ / Known-ZF / Pilot-LS-ZF\n');

fprintf('=============================================\n');