**5G-Oriented OFDM Modem Simulation**

A MATLAB and Python based **5G-oriented OFDM modem simulation** demonstrating digital communication concepts including QPSK modulation, OFDM transmission, multipath channel modeling, channel estimation, equalization, BER analysis, and EVM analysis.

📌 Project Overview

This project implements and analyzes an OFDM communication system under **multipath fading and AWGN noise**.

The project progressively develops the modem from basic QPSK and OFDM concepts to channel estimation, equalization, active subcarrier allocation, BER comparison, and EVM analysis.

The main objective is to understand how a practical wireless communication system behaves under channel impairments and how receiver-side signal processing can improve communication performance.

🎯 Objectives

* Understand QPSK digital modulation and demodulation
* Implement an OFDM transmitter and receiver
* Model multipath wireless channels
* Add AWGN noise at different SNR levels
* Implement channel estimation techniques
* Implement Zero-Forcing (ZF) and MMSE equalization
* Use pilot-based channel estimation
* Analyze BER performance
* Analyze Error Vector Magnitude (EVM)
* Compare different receiver configurations
* Integrate MATLAB simulation results with Python-based analysis

🛠️ Technologies Used

* **MATLAB** – Communication system simulation and signal processing
* **Python** – Result processing and analysis
* **QPSK** – Digital modulation
* **OFDM** – Orthogonal Frequency Division Multiplexing
* **LS Channel Estimation** – Pilot-based channel estimation
* **ZF Equalization** – Zero-Forcing equalization
* **MMSE Equalization** – Minimum Mean Square Error equalization
* **BER** – Bit Error Rate analysis
* **EVM** – Error Vector Magnitude analysis

⚙️ System Configuration

| Parameter           | Configuration    |
| ------------------- | ---------------- |
| FFT Size            | 64               |
| Active Subcarriers  | 52               |
| Unused Subcarriers  | 12               |
| Modulation          | QPSK             |
| OFDM Symbols        | 1000             |
| Channel             | Multipath + AWGN |
| Path Delays         | 0, 2, 4 samples  |
| Path Gains          | 1.00, 0.50, 0.25 |
| SNR Range           | 0 to 20 dB       |
| SNR Step            | 2 dB             |
| Performance Metrics | BER + EVM        |

📡 System Architecture

```text
Random Bits
     │
     ▼
QPSK Modulation
     │
     ▼
Active Subcarrier Mapping
     │
     ▼
IFFT
     │
     ▼
Cyclic Prefix Addition
     │
     ▼
Multipath Channel + AWGN
     │
     ▼
Cyclic Prefix Removal
     │
     ▼
FFT
     │
     ▼
Channel Estimation
     │
     ▼
Equalization
     │
     ▼
QPSK Demodulation
     │
     ▼
Recovered Bits
     │
     ├──────────────► BER Analysis
     │
     └──────────────► EVM Analysis
```

🔬 Receiver Configurations Compared

The final analysis compares three receiver configurations:

### 1. No Equalization

The received OFDM signal is demodulated without compensating for the channel response.

### 2. Known-Channel ZF

The channel frequency response is known directly from the simulated channel and is compensated using Zero-Forcing equalization.

### 3. Pilot-LS-ZF

Known pilot subcarriers are used to estimate the channel using Least Squares (LS) estimation, followed by Zero-Forcing equalization.

📊 Final Performance Analysis

At **20 dB SNR**, the final simulation produced:

| Receiver         |      BER |    EVM |
| ---------------- | -------: | -----: |
| No Equalization  | 0.000192 | 52.25% |
| Known-Channel ZF | 0.000000 | 11.05% |
| Pilot-LS-ZF      | 0.000000 | 18.55% |

The results demonstrate how channel compensation and equalization affect the recovered OFDM signal under the simulated multipath channel.

📈 Generated Results

The project generates:

* BER vs SNR analysis
* EVM vs SNR analysis
* QPSK constellation comparisons
* Channel estimation results
* ZF vs MMSE comparisons
* Active-subcarrier analysis
* MATLAB result files
* Python-processed result files

Final Step 19.8 figures:

```text
Figures/
├── step19_8_BER_comparison.png
└── step19_8_EVM_comparison.png
```

🐍 MATLAB + Python Workflow

The project also demonstrates MATLAB-to-Python integration for result analysis.

```text
MATLAB Simulation
       │
       ▼
BER + EVM Results
       │
       ▼
Results/*.txt
       │
       ▼
Python Analysis
       │
       ▼
Processed BER / EVM Data
```

Python scripts are available in the `Python/` directory.

📁 Project Structure

```text
5G_OFDM_Modem/
│
├── MATLAB/
│   ├── step1_qpsk.m
│   ├── step2_ber_vs_snr.m
│   ├── step3_ofdm_transmitter.m
│   ├── step4_ofdm_receiver.m
│   ├── ...
│   ├── step18_LS_vs_MMSE_channel_estimation.m
│   ├── step19_1_5G_subcarrier_allocation.m
│   ├── ...
│   └── step19_8_ber_evm_combined.m
│
├── Python/
│   ├── analyze_step19_8.py
│   ├── analyze_results.py
│   ├── plot_ber.py
│   ├── plot_evm.py
│   └── README.txt
│
├── Results/
│   ├── BER result files
│   ├── EVM result files
│   └── Python processed data
│
├── Figures/
│   ├── BER comparison figures
│   ├── EVM comparison figures
│   └── constellation figures
│
└── README.md
```

▶️ How to Run

### MATLAB

1. Open the project in MATLAB.
2. Navigate to the `MATLAB` folder.
3. Run the scripts sequentially to understand the development of the OFDM modem.
4. For the final combined analysis, run:

```matlab
step19_8_ber_evm_combined
```

5. Check the generated files in:

```text
Results/
Figures/
```

### Python

The Python scripts can be used to process the MATLAB-generated result files.

Example from MATLAB:

```matlab
pythonFile = "/MATLAB Drive/5G_OFDM_Modem/Python/analyze_results.py";
code = fileread(pythonFile);
pyrun("exec(code)", code=code);
```

📚 Learning Outcomes

Through this project, I developed practical understanding of:

* Digital communication systems
* QPSK modulation
* OFDM principles
* IFFT/FFT based transmission
* Cyclic prefix
* Multipath fading
* AWGN channel modeling
* Channel estimation
* Pilot-based estimation
* Least Squares estimation
* ZF equalization
* MMSE equalization
* BER performance analysis
* EVM analysis
* MATLAB signal-processing workflows
* MATLAB and Python integration

⚠️ Project Scope

This is a **5G-oriented educational and simulation project**, not a complete 3GPP 5G NR physical-layer implementation.

The project focuses on understanding important OFDM and wireless communication concepts through simulation.

🚀 Future Improvements

Possible future extensions include:

* 16-QAM and 64-QAM modulation
* Adaptive modulation and coding
* More realistic 5G NR numerology
* Resource block allocation
* MIMO-OFDM
* OFDM synchronization
* Carrier Frequency Offset estimation
* Timing synchronization
* More advanced channel models
* Improved MMSE channel estimation
* FPGA/RTL implementation of selected modem blocks

👩‍💻 Author

Vijayalakshmi T B

Electronics and Communication Engineering Student

Interested in:

* VLSI
* Digital Design
* Embedded Systems
* Wireless Communication
* IoT
* Hardware-Software Integration

---

⭐ This project was developed as a hands-on learning project to strengthen practical skills in **digital communication, DSP, MATLAB, Python, and wireless system design**.
