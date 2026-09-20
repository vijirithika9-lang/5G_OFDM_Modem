clc;
clear;
close all;

%% Step 8 - Compare BER Before and After Equalization

% SNR range
snrRange = 0:2:20;

%% Step 6 - BER without Equalization

berWithoutEqualization = [
    0.216569
    0.175716
    0.137584
    0.101583
    0.071093
    0.047075
    0.027889
    0.016485
    0.008763
    0.003481
    0.000900
    ];

%% Step 7 - BER with ZF Equalization

berWithEqualization = [
    0.188980
    0.141365
    0.095030
    0.059589
    0.031090
    0.012554
    0.003811
    0.000450
    0.000060
    0.000000
    0.000000
    ];

%% Plot BER Comparison

figure;

semilogy( ...
    snrRange, ...
    berWithoutEqualization, ...
    'o-', ...
    'LineWidth',1.5);

hold on;

semilogy( ...
    snrRange, ...
    berWithEqualization, ...
    's-', ...
    'LineWidth',1.5);

grid on;

xlabel('SNR (dB)');
ylabel('Bit Error Rate (BER)');

title('OFDM BER Comparison Before and After Equalization');

legend( ...
    'Without Equalization', ...
    'With ZF Equalization', ...
    'Location','southwest');

hold off;