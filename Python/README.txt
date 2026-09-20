5G OFDM MODEM
Python Analysis Component
=========================

## PROJECT OVERVIEW

This Python component is part of the 5G OFDM Modem simulation project.

The main OFDM communication system is developed in MATLAB. Python is used as a supporting analysis tool to read the MATLAB simulation results, process BER and EVM data, and prepare the results for further visualization and analysis.

The project focuses on:

* OFDM communication
* QPSK modulation
* Multipath channel
* AWGN noise
* Channel equalization
* BER analysis
* EVM analysis
* Performance comparison

## PYTHON FILES

1. analyze_step19_8.py

---

Purpose:
Reads the Step 19.8 MATLAB result file and performs BER and EVM analysis.

Input:
Results/step19_8_BER_EVM_results.txt

Main functions:

* Reads MATLAB-generated results
* Extracts SNR values
* Extracts BER values
* Extracts EVM values
* Displays BER comparison
* Displays EVM comparison
* Displays 20 dB performance

This file demonstrates the MATLAB-to-Python analysis workflow.

2. analyze_results.py

---

Purpose:
Provides a structured summary of the MATLAB simulation results.

Input:
Results/step19_8_BER_EVM_results.txt

Main functions:

* Reads simulation results
* Extracts BER and EVM values
* Displays BER for different SNR values
* Displays final 20 dB performance
* Compares:

  * No Equalization
  * Known-Channel ZF
  * Pilot LS + ZF

Python standard libraries are used for this analysis.

3. plot_ber.py

---

Purpose:
Extracts BER data from the MATLAB result file and prepares it for plotting.

Input:
Results/step19_8_BER_EVM_results.txt

Output:
Results/python_ber_data.txt

The generated data contains:

* SNR
* No Equalization BER
* Known-Channel ZF BER
* Pilot LS + ZF BER

The output can be used to generate BER versus SNR performance plots.

4. plot_evm.py

---

Purpose:
Extracts EVM data from the MATLAB result file and prepares it for plotting.

Input:
Results/step19_8_BER_EVM_results.txt

Output:
Results/python_evm_data.txt

The generated data contains:

* SNR
* No Equalization EVM
* Known-Channel ZF EVM
* Pilot LS + ZF EVM

The output can be used to generate EVM versus SNR performance plots.

## DATA FLOW

MATLAB OFDM Simulation
        |
        V
BER + EVM Calculation
        |
        V
Results/step19_8_BER_EVM_results.txt
        |
        V
Python Analysis
        |
+----------------------+
|                      |
v                      v
BER Analysis           EVM Analysis
|                      |
v                      v
python_ber_data.txt     python_evm_data.txt

## SNR CONFIGURATION

The Step 19.8 simulation uses 11 SNR points:

0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20 dB

Each SNR value is evaluated independently to measure BER and EVM performance.

## SYSTEMS COMPARED

The Python analysis compares three receiver conditions:

1. No Equalization
   The received OFDM signal is detected without channel equalization.

2. Known-Channel ZF
   Zero-Forcing equalization is performed using the known channel frequency response.

3. Pilot LS + ZF
   Pilot-based Least Squares channel estimation is followed by Zero-Forcing equalization.

## IMPORTANT NOTE

This project is a simulation-based, 5G-oriented OFDM communication project.

It is not a complete 3GPP 5G NR PHY implementation.

The Python component is used for result processing and analysis, while MATLAB is the primary environment for the OFDM communication simulation.

## REQUIREMENTS

Python 3.13 or compatible Python 3 version.

The current analysis scripts mainly use Python standard libraries such as:

* re
* pathlib

No external Python packages are required for the result-processing scripts.

## HOW TO RUN FROM MATLAB

Example:

1. Set the Python file path:

pythonFile = "/MATLAB Drive/5G_OFDM_Modem/Python/analyze_results.py";

2. Read the Python file:

code = fileread(pythonFile);

3. Execute it through MATLAB:

pyrun("exec(code)", code=code);

## PROJECT STRUCTURE

5G_OFDM_Modem/
|
+-- MATLAB/
|   +-- OFDM simulation scripts
|
+-- Results/
|   +-- MATLAB result files
|   +-- python_ber_data.txt
|   +-- python_evm_data.txt
|
+-- Figures/
|   +-- MATLAB-generated figures
|
+-- Python/
+-- analyze_step19_8.py
+-- analyze_results.py
+-- plot_ber.py
+-- plot_evm.py
+-- README.txt

## AUTHOR

ECE Engineering Student Project

Project:
5G OFDM Modem with Channel Estimation,
Equalization, BER and EVM Analysis

Tools:
MATLAB + Python

# END OF README