clc;
clear;
close all;

%% STEP 15 - ZF vs MMSE EQUALIZATION

%% Step 15.1 - System Parameters

% OFDM parameters
Nfft = 64;
cpLength = 16;

% Number of OFDM symbols
numOFDMSymbols = 1000;

% QPSK parameters
M = 4;
bitsPerSymbol = log2(M);

% SNR range
snrRange = 0:2:20;

% Multipath channel parameters
pathDelays = [0 2 4];
pathGains = [1.00 0.50 0.25];

% Total number of QPSK symbols
numQPSKSymbols = Nfft * numOFDMSymbols;

% Total number of bits
numBits = numQPSKSymbols * bitsPerSymbol;

%% Display System Information

fprintf('\n============================================\n');
fprintf('       STEP 15: ZF vs MMSE EQUALIZATION\n');
fprintf('============================================\n');

fprintf('FFT Size              : %d\n',Nfft);
fprintf('Cyclic Prefix         : %d samples\n',cpLength);
fprintf('OFDM Symbols          : %d\n',numOFDMSymbols);
fprintf('Modulation            : QPSK\n');

fprintf('SNR Range             : ');
fprintf('%d ',snrRange);
fprintf('dB\n');

fprintf('Path Delays           : ');
fprintf('%d ',pathDelays);
fprintf('samples\n');

fprintf('Path Gains            : ');
fprintf('%.2f ',pathGains);
fprintf('\n');

fprintf('Total Data Bits       : %d\n',numBits);

fprintf('\nStep 15.1 completed successfully.\n');
%% Step 15.2 - Common Data and OFDM Frame Generation

% Fixed random seed for reproducibility
rng(200);

%% Generate Random Data Bits

txBits = randi([0 1],numBits,1);

%% QPSK Modulation

txSymbolIndices = bi2de( ...
    reshape(txBits,bitsPerSymbol,[]).', ...
    'left-msb');

txQPSK = pskmod( ...
    txSymbolIndices, ...
    M, ...
    pi/4);

%% Arrange QPSK Symbols into OFDM Symbols

txDataMatrix = reshape( ...
    txQPSK, ...
    Nfft, ...
    numOFDMSymbols);

%% OFDM IFFT

txIFFT = ifft( ...
    txDataMatrix, ...
    Nfft, ...
    1);

%% Add Cyclic Prefix

txWithCP = [
    txIFFT(end-cpLength+1:end,:);
    txIFFT
    ];

%% Serialize OFDM Frame

txFrame = txWithCP(:);

%% Display Information

fprintf('\n===== STEP 15.2: COMMON OFDM DATA =====\n');

fprintf('Random Seed           : 200\n');
fprintf('Data Bits             : %d\n',length(txBits));
fprintf('QPSK Symbols          : %d\n',length(txQPSK));
fprintf('OFDM Symbols          : %d\n',numOFDMSymbols);
fprintf('Samples per OFDM      : %d\n',Nfft + cpLength);
fprintf('Total Frame Samples   : %d\n',length(txFrame));

fprintf('Common OFDM frame generated.\n');
%% Step 15.3 - Common Multipath Channel

% Create channel impulse response
channelImpulseResponse = zeros(max(pathDelays)+1,1);

for p = 1:length(pathDelays)
    channelImpulseResponse(pathDelays(p)+1) = pathGains(p);
end

%% Calculate Channel Frequency Response

channelFrequencyResponse = fft( ...
    channelImpulseResponse, ...
    Nfft);

%% Pass OFDM Frame Through Multipath Channel

rxMultipath = filter( ...
    channelImpulseResponse, ...
    1, ...
    txFrame);

%% Display Channel Information

fprintf('\n===== STEP 15.3: COMMON MULTIPATH CHANNEL =====\n');

fprintf('Channel Type         : Multipath\n');

fprintf('Path Delays          : ');
fprintf('%d ',pathDelays);
fprintf('samples\n');

fprintf('Path Gains           : ');
fprintf('%.2f ',pathGains);
fprintf('\n');

fprintf('Input Samples        : %d\n',length(txFrame));
fprintf('Output Samples       : %d\n',length(rxMultipath));

fprintf('Channel frequency response calculated.\n');
fprintf('Common multipath channel created.\n');
%% Step 15.4 - Zero-Forcing Equalization

% Initialize BER array
berZF = zeros(length(snrRange),1);

fprintf('\n===== STEP 15.4: ZERO-FORCING EQUALIZATION =====\n');

fprintf('Equalizer             : Zero-Forcing (ZF)\n');
fprintf('Channel Knowledge     : Known / Ideal\n');

%% Process Each SNR

for snrIndex = 1:length(snrRange)

    currentSNR = snrRange(snrIndex);

    %% Add AWGN

    rxNoisy = awgn( ...
        rxMultipath, ...
        currentSNR, ...
        'measured');

    %% Reshape into OFDM Symbols

    rxMatrix = reshape( ...
        rxNoisy, ...
        Nfft + cpLength, ...
        numOFDMSymbols);

    %% Remove Cyclic Prefix

    rxWithoutCP = ...
        rxMatrix(cpLength+1:end,:);

    %% FFT

    rxFFT = fft( ...
        rxWithoutCP, ...
        Nfft, ...
        1);

    %% ZF Equalization

    rxEqualized = zeros(size(rxFFT));

    for k = 1:Nfft

        rxEqualized(k,:) = ...
            rxFFT(k,:) ./ channelFrequencyResponse(k);

    end

    %% QPSK Demodulation

    rxEqualizedSerial = rxEqualized(:);

    rxSymbolIndices = pskdemod( ...
        rxEqualizedSerial, ...
        M, ...
        pi/4);

    %% Convert Symbols to Bits

    rxBitsMatrix = de2bi( ...
        rxSymbolIndices, ...
        bitsPerSymbol, ...
        'left-msb');

    rxBits = rxBitsMatrix.';
    rxBits = rxBits(:);

    %% BER Calculation

    bitErrors = sum(rxBits ~= txBits);

    berZF(snrIndex) = ...
        bitErrors / length(txBits);

    fprintf( ...
        'SNR = %2d dB   BER = %.8f\n', ...
        currentSNR, ...
        berZF(snrIndex));

end
%% Step 15.5 - MMSE Equalization

% Initialize BER array
berMMSE = zeros(length(snrRange),1);

fprintf('\n===== STEP 15.5: MMSE EQUALIZATION =====\n');

fprintf('Equalizer             : Minimum Mean Square Error (MMSE)\n');
fprintf('Channel Knowledge     : Known / Ideal\n');

%% Process Each SNR

for snrIndex = 1:length(snrRange)

    currentSNR = snrRange(snrIndex);

    %% Add AWGN

    rxNoisy = awgn( ...
        rxMultipath, ...
        currentSNR, ...
        'measured');

    %% Estimate Noise-to-Signal Ratio

    noiseToSignalRatio = 10^(-currentSNR/10);

    %% Reshape into OFDM Symbols

    rxMatrix = reshape( ...
        rxNoisy, ...
        Nfft + cpLength, ...
        numOFDMSymbols);

    %% Remove Cyclic Prefix

    rxWithoutCP = ...
        rxMatrix(cpLength+1:end,:);

    %% FFT

    rxFFT = fft( ...
        rxWithoutCP, ...
        Nfft, ...
        1);

    %% MMSE Equalization

    rxEqualized = zeros(size(rxFFT));

    for k = 1:Nfft

        H = channelFrequencyResponse(k);

        mmseWeight = ...
            conj(H) / ...
            (abs(H)^2 + noiseToSignalRatio);

        rxEqualized(k,:) = ...
            mmseWeight * rxFFT(k,:);

    end

    %% QPSK Demodulation

    rxEqualizedSerial = rxEqualized(:);

    rxSymbolIndices = pskdemod( ...
        rxEqualizedSerial, ...
        M, ...
        pi/4);

    %% Convert Symbols to Bits

    rxBitsMatrix = de2bi( ...
        rxSymbolIndices, ...
        bitsPerSymbol, ...
        'left-msb');

    rxBits = rxBitsMatrix.';
    rxBits = rxBits(:);

    %% BER Calculation

    bitErrors = sum(rxBits ~= txBits);

    berMMSE(snrIndex) = ...
        bitErrors / length(txBits);

    fprintf( ...
        'SNR = %2d dB   BER = %.8f\n', ...
        currentSNR, ...
        berMMSE(snrIndex));

end
%% Step 15.6 - ZF vs MMSE BER Comparison

fprintf('\n===== STEP 15.6: ZF vs MMSE COMPARISON =====\n');

%% Display Comparison Table

fprintf('\n');
fprintf(' SNR(dB)        ZF BER          MMSE BER\n');
fprintf('---------------------------------------------\n');

for i = 1:length(snrRange)

    fprintf( ...
        ' %3d       %.8f       %.8f\n', ...
        snrRange(i), ...
        berZF(i), ...
        berMMSE(i));

end

%% Plot BER Comparison

figure;

semilogy( ...
    snrRange, ...
    berZF, ...
    '-o', ...
    'LineWidth',2);

hold on;

semilogy( ...
    snrRange, ...
    berMMSE, ...
    '-s', ...
    'LineWidth',2);

grid on;

xlabel('SNR (dB)');
ylabel('Bit Error Rate (BER)');

title('ZF vs MMSE Equalization');

legend( ...
    'Zero-Forcing (ZF)', ...
    'MMSE', ...
    'Location','southwest');

xlim([0 20]);

hold off;

fprintf('\nZF vs MMSE BER comparison graph generated successfully.\n');
%% Step 15.7 - Final Performance Summary

fprintf('\n============================================\n');
fprintf('       STEP 15 PERFORMANCE SUMMARY\n');
fprintf('============================================\n');

fprintf('FFT Size              : %d\n',Nfft);
fprintf('Cyclic Prefix         : %d samples\n',cpLength);
fprintf('OFDM Symbols          : %d\n',numOFDMSymbols);
fprintf('Modulation            : QPSK\n');
fprintf('Channel               : Multipath + AWGN\n');

fprintf('\nChannel Parameters\n');

fprintf('Path Delays           : ');
fprintf('%d ',pathDelays);
fprintf('samples\n');

fprintf('Path Gains            : ');
fprintf('%.2f ',pathGains);
fprintf('\n');

fprintf('\nEqualization Methods\n');
fprintf('1. Zero-Forcing (ZF)\n');
fprintf('2. Minimum Mean Square Error (MMSE)\n');

fprintf('\nBER Results\n');
fprintf('SNR(dB)        ZF BER          MMSE BER\n');
fprintf('---------------------------------------------\n');

for i = 1:length(snrRange)

    fprintf( ...
        '%3d        %.8f       %.8f\n', ...
        snrRange(i), ...
        berZF(i), ...
        berMMSE(i));

end

fprintf('\n============================================\n');
fprintf('Step 15 completed successfully.\n');
fprintf('============================================\n');
