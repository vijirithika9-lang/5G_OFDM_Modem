import re
from pathlib import Path

# ============================================================
# STEP 24.1
# Python Analysis of MATLAB Step 19.8 Results
# ============================================================

# ------------------------------------------------------------
# 1. File locations
# ------------------------------------------------------------

project_folder = Path("/MATLAB Drive/5G_OFDM_Modem")

result_file = (
    project_folder
    / "Results"
    / "step19_8_BER_EVM_results.txt"
)

# ------------------------------------------------------------
# 2. Check whether result file exists
# ------------------------------------------------------------

if not result_file.exists():
    print("ERROR: MATLAB result file was not found.")
    print()
    print("Expected location:")
    print(result_file)
    print()
    print("Please make sure the file name is:")
    print("step19_8_BER_EVM_results.txt")

    raise SystemExit

# ------------------------------------------------------------
# 3. Read MATLAB result file
# ------------------------------------------------------------

text = result_file.read_text(encoding="utf-8")

# ------------------------------------------------------------
# 4. Extract numerical data
# ------------------------------------------------------------

pattern = re.compile(
    r"SNR =\s*(\d+)\s*dB\s*\|\s*"
    r"No-EQ BER =\s*([0-9.]+),\s*EVM =\s*([0-9.]+)%\s*\|\s*"
    r"Known-ZF BER =\s*([0-9.]+),\s*EVM =\s*([0-9.]+)%\s*\|\s*"
    r"Pilot-LS-ZF BER =\s*([0-9.]+),\s*EVM =\s*([0-9.]+)%"
)

matches = pattern.findall(text)

# ------------------------------------------------------------
# 5. Check extracted data
# ------------------------------------------------------------

if not matches:
    print("ERROR: No Step 19.8 data could be extracted.")
    print("Check the formatting of the MATLAB result file.")
    raise SystemExit

# ------------------------------------------------------------
# 6. Store data
# ------------------------------------------------------------

snr = []
no_eq_ber = []
known_zf_ber = []
pilot_lszf_ber = []

no_eq_evm = []
known_zf_evm = []
pilot_lszf_evm = []

for match in matches:

    snr.append(int(match[0]))

    no_eq_ber.append(float(match[1]))
    no_eq_evm.append(float(match[2]))

    known_zf_ber.append(float(match[3]))
    known_zf_evm.append(float(match[4]))

    pilot_lszf_ber.append(float(match[5]))
    pilot_lszf_evm.append(float(match[6]))

# ------------------------------------------------------------
# 7. Display extracted data
# ------------------------------------------------------------

print()
print("=" * 65)
print("        5G OFDM MODEM - PYTHON ANALYSIS")
print("=" * 65)

print()

print("Data successfully loaded from MATLAB.")
print(f"Number of SNR points : {len(snr)}")
print(f"SNR range            : {min(snr)} to {max(snr)} dB")

print()

print("-" * 65)
print("BER RESULTS")
print("-" * 65)

print(
    f"{'SNR':>6}"
    f"{'No-EQ':>15}"
    f"{'Known-ZF':>15}"
    f"{'Pilot-LS-ZF':>18}"
)

print("-" * 65)

for i in range(len(snr)):

    print(
        f"{snr[i]:>6} "
        f"{no_eq_ber[i]:>15.6f}"
        f"{known_zf_ber[i]:>15.6f}"
        f"{pilot_lszf_ber[i]:>18.6f}"
    )

print()

print("-" * 65)
print("EVM RESULTS")
print("-" * 65)

print(
    f"{'SNR':>6}"
    f"{'No-EQ':>15}"
    f"{'Known-ZF':>15}"
    f"{'Pilot-LS-ZF':>18}"
)

print("-" * 65)

for i in range(len(snr)):

    print(
        f"{snr[i]:>6} "
        f"{no_eq_evm[i]:>14.2f}%"
        f"{known_zf_evm[i]:>14.2f}%"
        f"{pilot_lszf_evm[i]:>17.2f}%"
    )

# ------------------------------------------------------------
# 8. Final SNR analysis
# ------------------------------------------------------------

final_index = -1

print()
print("=" * 65)
print("20 dB PERFORMANCE")
print("=" * 65)

print(f"No Equalization BER       : {no_eq_ber[final_index]:.6f}")
print(f"Known-Channel ZF BER      : {known_zf_ber[final_index]:.6f}")
print(f"Pilot LS + ZF BER         : {pilot_lszf_ber[final_index]:.6f}")

print()

print(f"No Equalization EVM       : {no_eq_evm[final_index]:.2f}%")
print(f"Known-Channel ZF EVM      : {known_zf_evm[final_index]:.2f}%")
print(f"Pilot LS + ZF EVM         : {pilot_lszf_evm[final_index]:.2f}%")

print()

print("=" * 65)
print("PYTHON ANALYSIS COMPLETED")
print("=" * 65)