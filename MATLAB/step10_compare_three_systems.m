clc;
clear;
close all;

%% Step 10 - Three-System BER Comparison

% SNR range
snrRange = 0:2:20;

%% Step 6 - Multipath Without Equalization

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

%% Step 7 - Known Channel + ZF Equalization

berKnownChannelZF = [
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

%% Step 9 - Pilot-Based Channel Estimation + ZF

berPilotZF = [
    0.292814
    0.222921
    0.190901
    0.109245
    0.079005
    0.035021
    0.023137
    0.011834
    0.001000
    0.000000
    0.000000
    ];

%% Plot All Three Systems

figure;

semilogy( ...
    snrRange, ...
    berWithoutEqualization, ...
    'o-', ...
    'LineWidth',1.5);

hold on;

semilogy( ...
    snrRange, ...
    berKnownChannelZF, ...
    's-', ...
    'LineWidth',1.5);

semilogy( ...
    snrRange, ...
    berPilotZF, ...
    '^-', ...
    'LineWidth',1.5);

grid on;

xlabel('SNR (dB)');
ylabel('Bit Error Rate (BER)');

title('OFDM BER Comparison: Multipath, Known-Channel ZF and Pilot-Based ZF');

legend( ...
    'Multipath - No Equalization', ...
    'Known Channel - ZF Equalization', ...
    'Pilot-Based Channel Estimation - ZF', ...
    'Location','southwest');

hold off;