clc;
clear;
close all;

%% STEP 12 - COMPLETE 5G OFDM MODEM

%% Step 12.1 - System Parameters

% OFDM parameters
Nfft = 64;
cpLength = 16;

% Number of OFDM data symbols
numOFDMSymbols = 1000;

% QPSK parameters
M = 4;

% Test SNR
snrTest = 20;

% Channel parameters
pathDelays = [0 2 4];
pathGains = [1.00 0.50 0.25];

% Number of bits per QPSK symbol
bitsPerSymbol = log2(M);

% Total number of QPSK symbols
numQPSKSymbols = Nfft * numOFDMSymbols;

% Total number of transmitted bits
numBits = numQPSKSymbols * bitsPerSymbol;

%% Generate Random Transmitted Bits

txBits = randi([0 1],numBits,1);

fprintf('\n===== STEP 12.1: SYSTEM SETUP =====\n');

fprintf('FFT Size                 : %d\n',Nfft);
fprintf('Cyclic Prefix Length     : %d\n',cpLength);
fprintf('Number of OFDM Symbols   : %d\n',numOFDMSymbols);
fprintf('QPSK Modulation Order    : %d\n',M);
fprintf('Test SNR                 : %d dB\n',snrTest);

fprintf('Number of Transmitted Bits : %d\n',numBits);

fprintf('Multipath Delays         : ');
fprintf('%d ',pathDelays);
fprintf('samples\n');

fprintf('Multipath Gains          : ');
fprintf('%.2f ',pathGains);
fprintf('\n');
%% Step 12.2 - QPSK Modulation

% Convert bits into QPSK symbol indices
txSymbolIndices = bi2de( ...
    reshape(txBits,bitsPerSymbol,[]).', ...
    'left-msb');

% QPSK modulation
txQPSK = pskmod( ...
    txSymbolIndices, ...
    M, ...
    pi/4);

%% Reshape QPSK Symbols into OFDM Symbols

txQPSKMatrix = reshape( ...
    txQPSK, ...
    Nfft, ...
    numOFDMSymbols);

fprintf('\n===== STEP 12.2: QPSK MODULATION =====\n');

fprintf('Total QPSK Symbols       : %d\n',length(txQPSK));

fprintf('OFDM Symbol Size         : %d QPSK symbols\n',Nfft);

fprintf('OFDM Symbol Count        : %d\n',numOFDMSymbols);
%% Step 12.3 - OFDM Modulation using IFFT

% Perform IFFT on each OFDM symbol
txIFFT = ifft( ...
    txQPSKMatrix, ...
    Nfft, ...
    1);

%% Add Cyclic Prefix

txWithCP = [
    txIFFT(end-cpLength+1:end,:);
    txIFFT
    ];

%% Serialize OFDM Signal

txOFDM = txWithCP(:);

fprintf('\n===== STEP 12.3: OFDM TRANSMITTER =====\n');

fprintf('IFFT Output Size        : %d x %d\n', ...
    size(txIFFT,1),size(txIFFT,2));

fprintf('Cyclic Prefix Length    : %d samples\n',cpLength);

fprintf('OFDM Symbol Length      : %d samples\n', ...
    Nfft + cpLength);

fprintf('Total Transmitted Samples : %d\n', ...
    length(txOFDM));
%% Step 12.4 - Multipath Channel + AWGN

% Create multipath channel impulse response
channelImpulseResponse = zeros(max(pathDelays) + 1, 1);

for k = 1:length(pathDelays)
    channelImpulseResponse(pathDelays(k) + 1) = pathGains(k);
end

% Pass OFDM signal through multipath channel
rxMultipath = filter( ...
    channelImpulseResponse, ...
    1, ...
    txOFDM);

% Add AWGN noise
rxChannel = awgn( ...
    rxMultipath, ...
    snrTest, ...
    'measured');

fprintf('\n===== STEP 12.4: CHANNEL =====\n');

fprintf('Channel Type            : Multipath + AWGN\n');

fprintf('Path Delays             : ');
fprintf('%d ',pathDelays);
fprintf('samples\n');

fprintf('Path Gains              : ');
fprintf('%.2f ',pathGains);
fprintf('\n');

fprintf('Channel SNR             : %d dB\n',snrTest);

fprintf('Received Samples        : %d\n',length(rxChannel));
%% Step 12.5 - OFDM Receiver: CP Removal + FFT

% Reshape received signal into OFDM symbols
rxWithCP = reshape( ...
    rxChannel, ...
    Nfft + cpLength, ...
    numOFDMSymbols);

% Remove cyclic prefix
rxWithoutCP = rxWithCP(cpLength+1:end,:);

% Convert time domain back to frequency domain
rxFFT = fft( ...
    rxWithoutCP, ...
    Nfft, ...
    1);

fprintf('\n===== STEP 12.5: OFDM RECEIVER =====\n');

fprintf('Received OFDM Matrix    : %d x %d\n', ...
    size(rxWithCP,1),size(rxWithCP,2));

fprintf('CP Removed              : %d samples\n',cpLength);

fprintf('FFT Output Size         : %d x %d\n', ...
    size(rxFFT,1),size(rxFFT,2));
%% Step 12.6 - Channel Response + ZF Equalization

% Calculate channel frequency response
channelFrequencyResponse = fft( ...
    channelImpulseResponse, ...
    Nfft);

% Perform Zero-Forcing equalization
rxEqualized = zeros(size(rxFFT));

for k = 1:Nfft

    rxEqualized(k,:) = ...
        rxFFT(k,:) ./ channelFrequencyResponse(k);

end

fprintf('\n===== STEP 12.6: ZF EQUALIZATION =====\n');

fprintf('Channel estimation      : Known channel reference\n');
fprintf('Equalizer                : Zero-Forcing (ZF)\n');

fprintf('Equalized Symbols       : %d\n', ...
    numel(rxEqualized));
%% Step 12.7 - QPSK Demodulation and BER

% Convert equalized symbols into a column vector
rxEqualizedSerial = rxEqualized(:);

% QPSK demodulation
rxSymbolIndices = pskdemod( ...
    rxEqualizedSerial, ...
    M, ...
    pi/4);

% Convert symbol indices back to bits
rxBitsMatrix = de2bi( ...
    rxSymbolIndices, ...
    bitsPerSymbol, ...
    'left-msb');

rxBits = rxBitsMatrix.';
rxBits = rxBits(:);

% Calculate bit errors
bitErrors = sum(txBits ~= rxBits);

% Calculate BER
ber = bitErrors / numBits;

fprintf('\n===== STEP 12.7: BER RESULT =====\n');

fprintf('Test SNR       = %d dB\n',snrTest);

fprintf('Bit Errors     = %d\n',bitErrors);

fprintf('Total Bits     = %d\n',numBits);

fprintf('BER            = %.8f\n',ber);
%% Step 12.8 - EVM Analysis

% Calculate error vector
evmError = rxEqualizedSerial - txQPSK;

% Calculate RMS EVM
rmsEVM = sqrt( ...
    mean(abs(evmError).^2) / ...
    mean(abs(txQPSK).^2));

% Convert EVM to percentage
evmPercentage = rmsEVM * 100;

fprintf('\n===== STEP 12.8: EVM RESULT =====\n');

fprintf('Test SNR       = %d dB\n',snrTest);

fprintf('RMS EVM        = %.6f\n',rmsEVM);

fprintf('EVM Percentage = %.2f %%\n',evmPercentage);

%% Plot Received Constellation

figure;

plot( ...
    real(rxEqualizedSerial), ...
    imag(rxEqualizedSerial), ...
    '.');

grid on;

axis equal;

xlabel('In-Phase');

ylabel('Quadrature');

title('Equalized QPSK Constellation - Complete OFDM Modem');
%% Step 12.9 - Complete Modem BER vs SNR

snrRangeComplete = 0:2:20;

berComplete = zeros(size(snrRangeComplete));

for s = 1:length(snrRangeComplete)

    % Add AWGN at current SNR
    rxTest = awgn( ...
        rxMultipath, ...
        snrRangeComplete(s), ...
        'measured');

    % Reshape into OFDM symbols
    rxTestWithCP = reshape( ...
        rxTest, ...
        Nfft + cpLength, ...
        numOFDMSymbols);

    % Remove cyclic prefix
    rxTestWithoutCP = ...
        rxTestWithCP(cpLength+1:end,:);

    % FFT
    rxTestFFT = fft( ...
        rxTestWithoutCP, ...
        Nfft, ...
        1);

    % ZF equalization
    rxTestEqualized = zeros(size(rxTestFFT));

    for k = 1:Nfft

        rxTestEqualized(k,:) = ...
            rxTestFFT(k,:) ./ channelFrequencyResponse(k);

    end

    % Serialize
    rxTestSerial = rxTestEqualized(:);

    % QPSK demodulation
    rxTestSymbols = pskdemod( ...
        rxTestSerial, ...
        M, ...
        pi/4);

    % Convert symbols to bits
    rxTestBitsMatrix = de2bi( ...
        rxTestSymbols, ...
        bitsPerSymbol, ...
        'left-msb');

    rxTestBits = rxTestBitsMatrix.';
    rxTestBits = rxTestBits(:);

    % BER calculation
    bitErrorsTest = sum(txBits ~= rxTestBits);

    berComplete(s) = ...
        bitErrorsTest / numBits;

end

%% Display BER Results

fprintf('\n===== STEP 12.9: COMPLETE MODEM BER VS SNR =====\n');

for s = 1:length(snrRangeComplete)

    fprintf( ...
        'SNR = %2d dB   BER = %.8f\n', ...
        snrRangeComplete(s), ...
        berComplete(s));

end

%% Plot BER vs SNR

figure;

semilogy( ...
    snrRangeComplete, ...
    berComplete, ...
    'o-', ...
    'LineWidth',1.5);

grid on;

xlabel('SNR (dB)');

ylabel('Bit Error Rate (BER)');

title('Complete 5G OFDM Modem - BER vs SNR');
%% Step 12.10 - Complete Modem Summary

fprintf('\n============================================\n');
fprintf('      COMPLETE 5G OFDM MODEM SUMMARY\n');
fprintf('============================================\n');

fprintf('FFT Size              : %d\n',Nfft);
fprintf('Cyclic Prefix         : %d samples\n',cpLength);
fprintf('OFDM Symbols          : %d\n',numOFDMSymbols);
fprintf('Modulation            : QPSK\n');
fprintf('Channel               : Multipath + AWGN\n');
fprintf('Equalizer             : Zero-Forcing (ZF)\n');
fprintf('Channel Knowledge     : Known / Ideal Reference\n');
fprintf('Test SNR              : %d dB\n',snrTest);

fprintf('\n20 dB Performance\n');
fprintf('Bit Errors            : %d\n',bitErrors);
fprintf('BER                   : %.8f\n',ber);
fprintf('RMS EVM               : %.6f\n',rmsEVM);
fprintf('EVM Percentage        : %.2f %%\n',evmPercentage);

fprintf('\n============================================\n');

