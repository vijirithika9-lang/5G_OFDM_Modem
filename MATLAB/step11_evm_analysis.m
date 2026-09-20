clc;
clear;
close all;

%% Step 11 - EVM Analysis

% OFDM parameters
Nfft = 64;
cpLength = 16;

% Test SNR
snrTest = 20;

% Number of QPSK symbols
numSymbols = 10000;

%% Generate Random QPSK Symbols

txSymbolsDecimal = randi([0 3],numSymbols,1);

%% QPSK Modulation

txQPSK = pskmod( ...
    txSymbolsDecimal, ...
    4, ...
    pi/4);

%% Display Reference Constellation

figure;

plot( ...
    real(txQPSK), ...
    imag(txQPSK), ...
    '.');

grid on;

axis equal;

xlabel('In-Phase');

ylabel('Quadrature');

title('Reference QPSK Constellation');

%% Display Ideal QPSK Points

idealSymbols = pskmod( ...
    (0:3).', ...
    4, ...
    pi/4);

fprintf('\n===== STEP 11.1: EVM ANALYSIS SETUP =====\n');

fprintf('Number of QPSK symbols = %d\n',numSymbols);

fprintf('Test SNR = %d dB\n',snrTest);

fprintf('Ideal QPSK constellation points:\n');

disp(idealSymbols);
%% Step 11.2 - AWGN Channel and EVM Calculation

% Add AWGN noise
rxQPSK = awgn( ...
    txQPSK, ...
    snrTest, ...
    'measured');

%% Calculate Error Vector

errorVector = rxQPSK - txQPSK;

%% Calculate RMS EVM

rmsEVM = sqrt( ...
    mean(abs(errorVector).^2) / ...
    mean(abs(txQPSK).^2));

%% Convert EVM to Percentage

evmPercentage = rmsEVM * 100;

%% Display EVM Result

fprintf('\n===== STEP 11.2: EVM RESULT =====\n');

fprintf('Test SNR       = %d dB\n',snrTest);

fprintf('RMS EVM        = %.6f\n',rmsEVM);

fprintf('EVM Percentage = %.2f %%\n',evmPercentage);

%% Plot Received Constellation

figure;

plot( ...
    real(rxQPSK), ...
    imag(rxQPSK), ...
    '.');

grid on;

axis equal;

xlabel('In-Phase');

ylabel('Quadrature');

title('Received QPSK Constellation with AWGN');
%% Step 11.3 - EVM vs SNR

snrRangeEVM = 0:2:20;

evmValues = zeros(size(snrRangeEVM));

for i = 1:length(snrRangeEVM)

    % Add AWGN
    rxSymbols = awgn( ...
        txQPSK, ...
        snrRangeEVM(i), ...
        'measured');

    % Error vector
    errorVector = rxSymbols - txQPSK;

    % RMS EVM
    rmsEVM = sqrt( ...
        mean(abs(errorVector).^2) / ...
        mean(abs(txQPSK).^2));

    % Store EVM
    evmValues(i) = rmsEVM * 100;

end

%% Display EVM Results

fprintf('\n===== STEP 11.3: EVM VS SNR =====\n');

for i = 1:length(snrRangeEVM)

    fprintf('SNR = %2d dB   EVM = %.2f %%\n', ...
        snrRangeEVM(i), ...
        evmValues(i));

end

%% Plot EVM vs SNR

figure;

plot( ...
    snrRangeEVM, ...
    evmValues, ...
    'o-', ...
    'LineWidth',1.5);

grid on;

xlabel('SNR (dB)');

ylabel('RMS EVM (%)');

title('EVM vs SNR for QPSK');
%% Step 11.4 - Save EVM Results

fprintf('\n===== STEP 11.4: EVM RESULTS =====\n');

fprintf('SNR (dB)        EVM (%%)\n');
fprintf('-----------------------\n');

for i = 1:length(snrRangeEVM)

    fprintf('%2d              %.4f\n', ...
        snrRangeEVM(i), ...
        evmValues(i));

end
