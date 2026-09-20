clc;
clear;
close all;

numBits = 10000;

txBits = randi([0 1], numBits, 1);

disp(txBits(1:20));
qpskMod = comm.QPSKModulator( ...
    'BitInput', true);

txSymbols = qpskMod(txBits);
figure;
scatterplot(txSymbols);
title('QPSK Transmitted Constellation');
snr = 2;

rxSymbols = awgn(txSymbols, snr, 'measured');
figure;
scatterplot(rxSymbols);
title('QPSK Constellation After AWGN');
qpskDemod = comm.QPSKDemodulator( ...
    'BitOutput', true);

rxBits = qpskDemod(rxSymbols);
[numErrors, ber] = biterr(txBits, rxBits);

fprintf('Number of bit errors = %d\n', numErrors);
fprintf('BER = %f\n', ber);