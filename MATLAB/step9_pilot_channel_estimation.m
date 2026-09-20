clc;
clear;
close all;

%% Step 9 - Pilot-Based Channel Estimation

% Number of data bits
numBits = 100000;

% OFDM parameters
Nfft = 64;
cpLength = 16;

% SNR range
snrRange = 0:2:20;

%% Multipath Channel

pathDelays = [0 2 4];
pathGains = [1 0.5 0.25];

% Channel impulse response
channelImpulseResponse = zeros(max(pathDelays)+1,1);

channelImpulseResponse(pathDelays+1) = pathGains;

%% Generate Random Data Bits

txBits = randi([0 1], numBits, 1);

% Make number of bits even
if mod(length(txBits),2) ~= 0
    txBits = txBits(1:end-1);
end

%% QPSK Modulation

bitPairs = reshape(txBits,2,[]).';

txSymbolsDecimal = bi2de(bitPairs,'left-msb');

txQPSK = pskmod(txSymbolsDecimal,4,pi/4);

%% Arrange QPSK Data into OFDM Symbols

numQPSKSymbols = length(txQPSK);

numDataOFDMSymbols = floor(numQPSKSymbols/Nfft);

txQPSK = txQPSK(1:numDataOFDMSymbols*Nfft);

dataSymbols = reshape( ...
    txQPSK, ...
    Nfft, ...
    numDataOFDMSymbols);

%% Generate Known Pilot OFDM Symbol

pilotSymbols = ones(Nfft,1);

%% IFFT of Pilot

pilotTimeDomain = ifft(pilotSymbols,Nfft);

%% Add Cyclic Prefix to Pilot

pilotCP = pilotTimeDomain(end-cpLength+1:end);

pilotWithCP = [pilotCP; pilotTimeDomain];

%% IFFT of Data

dataTimeDomain = ifft(dataSymbols,Nfft,1);

%% Add Cyclic Prefix to Data

dataCP = dataTimeDomain(end-cpLength+1:end,:);

dataWithCP = [dataCP; dataTimeDomain];

%% Create Complete OFDM Frame

txFrame = [
    pilotWithCP
    dataWithCP(:)
];

%% Display Information

fprintf('\n===== STEP 9.1: PILOT-BASED OFDM FRAME =====\n');

fprintf('FFT Size              : %d\n',Nfft);
fprintf('Cyclic Prefix Length  : %d\n',cpLength);
fprintf('Number of Data OFDM Symbols : %d\n',numDataOFDMSymbols);
fprintf('Pilot OFDM Symbols    : 1\n');
fprintf('Total Transmitted Samples : %d\n',length(txFrame));

%% Plot Pilot Frequency Domain

figure;

stem(0:Nfft-1,abs(pilotSymbols),'filled');

grid on;

xlabel('Subcarrier Index');
ylabel('|Pilot|');

title('Known Pilot OFDM Symbol');
%% Step 9.2 - Pilot Transmission and Channel Reception

% Pass complete OFDM frame through multipath channel
channelOutput = conv( ...
    txFrame, ...
    channelImpulseResponse);

% Keep original frame length
channelOutput = ...
    channelOutput(1:length(txFrame));

%% Add AWGN

snrTest = 20;

rxFrame = awgn( ...
    channelOutput, ...
    snrTest, ...
    'measured');

%% Extract Received Pilot

pilotLength = Nfft + cpLength;

receivedPilotWithCP = ...
    rxFrame(1:pilotLength);

%% Remove Pilot Cyclic Prefix

receivedPilot = ...
    receivedPilotWithCP(cpLength+1:end);

%% FFT of Received Pilot

receivedPilotFrequency = ...
    fft(receivedPilot,Nfft);

%% Pilot-Based Channel Estimation

estimatedChannel = ...
    receivedPilotFrequency ./ pilotSymbols;

%% Display Channel Estimate

fprintf('\n===== STEP 9.2: PILOT CHANNEL ESTIMATION =====\n');

fprintf('Test SNR = %d dB\n',snrTest);

fprintf('Pilot transmitted successfully.\n');

fprintf('Received pilot extracted successfully.\n');

fprintf('Channel frequency response estimated using pilot.\n');

%% Plot Estimated Channel Frequency Response

figure;

plot( ...
    0:Nfft-1, ...
    abs(estimatedChannel), ...
    'o-', ...
    'LineWidth',1.5);

grid on;

xlabel('Subcarrier Index');

ylabel('|Estimated H(f)|');

title('Pilot-Based Estimated Channel Frequency Response');
%% Step 9.3 - Data Reception and ZF Equalization

% Extract data portion after pilot
receivedData = ...
    rxFrame(pilotLength+1:end);

% Reshape received data into OFDM symbols
receivedDataWithCP = reshape( ...
    receivedData, ...
    Nfft + cpLength, ...
    numDataOFDMSymbols);

%% Remove Cyclic Prefix

receivedDataWithoutCP = ...
    receivedDataWithCP(cpLength+1:end,:);

%% FFT

receivedDataFrequency = ...
    fft(receivedDataWithoutCP,Nfft,1);

%% Repeat Estimated Channel for All Data Symbols

estimatedChannelMatrix = ...
    repmat(estimatedChannel,1,numDataOFDMSymbols);

%% Zero-Forcing Equalization

equalizedSymbols = ...
    receivedDataFrequency ./ estimatedChannelMatrix;

%% Parallel to Serial

receivedQPSK = equalizedSymbols(:);

%% QPSK Demodulation

receivedSymbolsDecimal = ...
    pskdemod(receivedQPSK,4,pi/4);

%% Convert Symbols to Bits

receivedBitPairs = ...
    de2bi(receivedSymbolsDecimal,2,'left-msb');

receivedBits = ...
    reshape(receivedBitPairs.',[],1);

%% Select Matching Number of Transmitted Bits

txBitsUsed = ...
    txBits(1:length(receivedBits));

%% Calculate BER

[numErrors,ber] = ...
    biterr(txBitsUsed,receivedBits);

fprintf('\n===== STEP 9.3: PILOT-BASED OFDM BER =====\n');

fprintf('SNR = %d dB\n',snrTest);

fprintf('Bit Errors = %d\n',numErrors);

fprintf('BER = %.6f\n',ber);

%% Constellation Plot

figure;

plot( ...
    real(receivedQPSK), ...
    imag(receivedQPSK), ...
    '.');

grid on;

xlabel('In-Phase');

ylabel('Quadrature');

title('Equalized QPSK Constellation - Pilot Based Channel Estimation');
%% Step 9.5 - Pilot-Based BER vs SNR

berPilot = zeros(size(snrRange));

for k = 1:length(snrRange)

    %% Add AWGN at Current SNR

    rxFrame = awgn( ...
        channelOutput, ...
        snrRange(k), ...
        'measured');

    %% Extract Pilot

    receivedPilotWithCP = ...
        rxFrame(1:pilotLength);

    %% Remove Pilot CP

    receivedPilot = ...
        receivedPilotWithCP(cpLength+1:end);

    %% FFT of Received Pilot

    receivedPilotFrequency = ...
        fft(receivedPilot,Nfft);

    %% Estimate Channel Using Pilot

    estimatedChannel = ...
        receivedPilotFrequency ./ pilotSymbols;

    %% Extract Data

    receivedData = ...
        rxFrame(pilotLength+1:end);

    %% Reshape Data

    receivedDataWithCP = reshape( ...
        receivedData, ...
        Nfft + cpLength, ...
        numDataOFDMSymbols);

    %% Remove Data CP

    receivedDataWithoutCP = ...
        receivedDataWithCP(cpLength+1:end,:);

    %% FFT

    receivedDataFrequency = ...
        fft(receivedDataWithoutCP,Nfft,1);

    %% Channel Matrix

    estimatedChannelMatrix = ...
        repmat( ...
        estimatedChannel, ...
        1, ...
        numDataOFDMSymbols);

    %% ZF Equalization

    equalizedSymbols = ...
        receivedDataFrequency ./ estimatedChannelMatrix;

    %% Serial Conversion

    receivedQPSK = equalizedSymbols(:);

    %% QPSK Demodulation

    receivedSymbolsDecimal = ...
        pskdemod( ...
        receivedQPSK, ...
        4, ...
        pi/4);

    %% Convert to Bits

    receivedBitPairs = ...
        de2bi( ...
        receivedSymbolsDecimal, ...
        2, ...
        'left-msb');

    receivedBits = ...
        reshape( ...
        receivedBitPairs.', ...
        [], ...
        1);

    %% BER

    txBitsUsed = ...
        txBits(1:length(receivedBits));

    [numErrors,ber] = ...
        biterr( ...
        txBitsUsed, ...
        receivedBits);

    berPilot(k) = ber;

    fprintf( ...
        'SNR = %2d dB   Bit Errors = %5d   BER = %.6f\n', ...
        snrRange(k), ...
        numErrors, ...
        ber);

end

%% Plot Pilot-Based BER

figure;

semilogy( ...
    snrRange, ...
    berPilot, ...
    'o-', ...
    'LineWidth',1.5);

grid on;

xlabel('SNR (dB)');
ylabel('Bit Error Rate (BER)');

title('Pilot-Based OFDM BER vs SNR');

legend( ...
    'Pilot-Based Channel Estimation', ...
    'Location', ...
    'southwest');