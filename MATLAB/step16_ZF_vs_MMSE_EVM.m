clc;
clear;
close all;

%% STEP 16 - ZF vs MMSE CONSTELLATION AND EVM

%% Step 16.1 - System Parameters

% OFDM parameters
Nfft = 64;
cpLength = 16;

% Number of OFDM symbols
numOFDMSymbols = 1000;

% QPSK parameters
M = 4;
bitsPerSymbol = log2(M);

% Test SNR
snrTest = 10;

% Multipath channel parameters
pathDelays = [0 2 4];
pathGains = [1.00 0.50 0.25];

% Total QPSK symbols
numQPSKSymbols = Nfft * numOFDMSymbols;

% Total bits
numBits = numQPSKSymbols * bitsPerSymbol;

%% Display System Information

fprintf('\n============================================\n');
fprintf(' STEP 16: ZF vs MMSE CONSTELLATION + EVM\n');
fprintf('============================================\n');

fprintf('FFT Size              : %d\n',Nfft);
fprintf('Cyclic Prefix         : %d samples\n',cpLength);
fprintf('OFDM Symbols          : %d\n',numOFDMSymbols);
fprintf('Modulation            : QPSK\n');
fprintf('Test SNR              : %d dB\n',snrTest);

fprintf('Path Delays           : ');
fprintf('%d ',pathDelays);
fprintf('samples\n');

fprintf('Path Gains            : ');
fprintf('%.2f ',pathGains);
fprintf('\n');

fprintf('Total Data Bits       : %d\n',numBits);

fprintf('\nStep 16.1 completed successfully.\n');
%% Step 16.2 - Common Data and OFDM Frame Generation

% Fixed random seed for reproducibility
rng(300);

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

fprintf('\n===== STEP 16.2: COMMON OFDM DATA =====\n');

fprintf('Random Seed           : 300\n');
fprintf('Data Bits             : %d\n',length(txBits));
fprintf('QPSK Symbols          : %d\n',length(txQPSK));
fprintf('OFDM Symbols          : %d\n',numOFDMSymbols);
fprintf('Samples per OFDM      : %d\n',Nfft + cpLength);
fprintf('Total Frame Samples   : %d\n',length(txFrame));

fprintf('Common OFDM frame generated.\n');
%% Step 16.3 - Multipath Channel and AWGN

%% Create Channel Impulse Response

channelImpulseResponse = zeros(max(pathDelays)+1,1);

for p = 1:length(pathDelays)

    channelImpulseResponse(pathDelays(p)+1) = ...
        pathGains(p);

end

%% Channel Frequency Response

channelFrequencyResponse = fft( ...
    channelImpulseResponse, ...
    Nfft);

%% Pass OFDM Frame Through Multipath Channel

rxMultipath = filter( ...
    channelImpulseResponse, ...
    1, ...
    txFrame);

%% Add AWGN at Test SNR

rxNoisy = awgn( ...
    rxMultipath, ...
    snrTest, ...
    'measured');

%% Display Information

fprintf('\n===== STEP 16.3: CHANNEL =====\n');

fprintf('Channel Type         : Multipath + AWGN\n');

fprintf('Path Delays          : ');
fprintf('%d ',pathDelays);
fprintf('samples\n');

fprintf('Path Gains           : ');
fprintf('%.2f ',pathGains);
fprintf('\n');

fprintf('Test SNR             : %d dB\n',snrTest);

fprintf('Transmitted Samples  : %d\n',length(txFrame));
fprintf('Received Samples     : %d\n',length(rxNoisy));

fprintf('Channel and AWGN applied successfully.\n');
%% Step 16.4 - ZF Equalization and EVM

%% Reshape Received Signal into OFDM Symbols

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

%% Zero-Forcing Equalization

rxZF = zeros(size(rxFFT));

for k = 1:Nfft

    rxZF(k,:) = ...
        rxFFT(k,:) ./ channelFrequencyResponse(k);

end

%% Serialize Equalized Symbols

rxZFSerial = rxZF(:);

%% Calculate ZF EVM

zfErrorVector = ...
    rxZFSerial - txQPSK;

rmsEVM_ZF = sqrt( ...
    mean(abs(zfErrorVector).^2) / ...
    mean(abs(txQPSK).^2));

evmPercentage_ZF = rmsEVM_ZF * 100;

%% Display ZF EVM

fprintf('\n===== STEP 16.4: ZF EVM =====\n');

fprintf('Equalizer            : Zero-Forcing\n');
fprintf('Test SNR             : %d dB\n',snrTest);

fprintf('RMS EVM              : %.6f\n',rmsEVM_ZF);
fprintf('EVM Percentage       : %.2f %%\n',evmPercentage_ZF);

%% ZF Constellation

figure;

plot( ...
    real(rxZFSerial), ...
    imag(rxZFSerial), ...
    '.');

grid on;

xlabel('In-Phase');
ylabel('Quadrature');

title('ZF Equalized QPSK Constellation');

axis equal;
%% Step 16.5 - MMSE Equalization and EVM

%% Calculate Noise-to-Signal Ratio

noiseToSignalRatio = 10^(-snrTest/10);

%% MMSE Equalization

rxMMSE = zeros(size(rxFFT));

for k = 1:Nfft

    H = channelFrequencyResponse(k);

    mmseWeight = ...
        conj(H) / ...
        (abs(H)^2 + noiseToSignalRatio);

    rxMMSE(k,:) = ...
        mmseWeight * rxFFT(k,:);

end

%% Serialize Equalized Symbols

rxMMSESerial = rxMMSE(:);

%% Calculate MMSE EVM

mmseErrorVector = ...
    rxMMSESerial - txQPSK;

rmsEVM_MMSE = sqrt( ...
    mean(abs(mmseErrorVector).^2) / ...
    mean(abs(txQPSK).^2));

evmPercentage_MMSE = rmsEVM_MMSE * 100;

%% Display MMSE EVM

fprintf('\n===== STEP 16.5: MMSE EVM =====\n');

fprintf('Equalizer            : MMSE\n');
fprintf('Test SNR             : %d dB\n',snrTest);

fprintf('RMS EVM              : %.6f\n',rmsEVM_MMSE);
fprintf('EVM Percentage       : %.2f %%\n',evmPercentage_MMSE);

%% MMSE Constellation

figure;

plot( ...
    real(rxMMSESerial), ...
    imag(rxMMSESerial), ...
    '.');

grid on;

xlabel('In-Phase');
ylabel('Quadrature');

title('MMSE Equalized QPSK Constellation');

axis equal;
%% Step 16.6 - ZF vs MMSE EVM Comparison

fprintf('\n===== STEP 16.6: EVM COMPARISON =====\n');

fprintf('\n');
fprintf('Equalizer        RMS EVM        EVM Percentage\n');
fprintf('------------------------------------------------\n');

fprintf( ...
    'ZF               %.6f        %.2f %%\n', ...
    rmsEVM_ZF, ...
    evmPercentage_ZF);

fprintf( ...
    'MMSE             %.6f        %.2f %%\n', ...
    rmsEVM_MMSE, ...
    evmPercentage_MMSE);

%% Create EVM Comparison Figure

figure;

evmValues = [
    evmPercentage_ZF;
    evmPercentage_MMSE
    ];

bar(evmValues);

grid on;

set(gca, ...
    'XTick',1:2, ...
    'XTickLabel',{'ZF','MMSE'});

ylabel('EVM (%)');

title('ZF vs MMSE EVM Comparison');

%% Display Comparison

fprintf('\nEVM comparison graph generated successfully.\n');
%% Step 16.7 - Final Step 16 Summary

fprintf('\n============================================\n');
fprintf('       STEP 16: ZF vs MMSE EVM ANALYSIS\n');
fprintf('============================================\n');

fprintf('Test SNR              : %d dB\n', snrTest);
fprintf('FFT Size              : %d\n', Nfft);
fprintf('Cyclic Prefix         : %d samples\n', cpLength);
fprintf('OFDM Symbols          : %d\n', numOFDMSymbols);
fprintf('Modulation            : QPSK\n');
fprintf('Channel               : Multipath + AWGN\n');

fprintf('\nZF Equalizer\n');
fprintf('RMS EVM               : %.6f\n', rmsEVM_ZF);
fprintf('EVM Percentage        : %.2f %%\n', evmPercentage_ZF);

fprintf('\nMMSE Equalizer\n');
fprintf('RMS EVM               : %.6f\n', rmsEVM_MMSE);
fprintf('EVM Percentage        : %.2f %%\n', evmPercentage_MMSE);

fprintf('\n============================================\n');
fprintf('          STEP 16 COMPLETED\n');
fprintf('============================================\n');

