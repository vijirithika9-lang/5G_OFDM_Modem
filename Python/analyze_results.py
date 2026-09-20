import re
from pathlib import Path

# Project folder
project_folder = Path("/MATLAB Drive/5G_OFDM_Modem")

# MATLAB result file
result_file = (
    project_folder
    / "Results"
    / "step19_8_BER_EVM_results.txt"
)

if not result_file.exists():
    print("ERROR: Result file not found.")
    print(result_file)
    raise SystemExit

# Read MATLAB results
text = result_file.read_text(encoding="utf-8")

pattern = re.compile(
    r"SNR =\s*(\d+)\s*dB\s*\|\s*"
    r"No-EQ BER =\s*([0-9.]+),\s*EVM =\s*([0-9.]+)%\s*\|\s*"
    r"Known-ZF BER =\s*([0-9.]+),\s*EVM =\s*([0-9.]+)%\s*\|\s*"
    r"Pilot-LS-ZF BER =\s*([0-9.]+),\s*EVM =\s*([0-9.]+)%"
)

matches = pattern.findall(text)

if not matches:
    print("ERROR: No valid data found.")
    raise SystemExit

print()
print("=" * 70)
print("          5G OFDM MODEM - PYTHON RESULT ANALYSIS")
print("=" * 70)

print()
print("SNR(dB) | No-EQ BER | Known-ZF BER | Pilot-LS-ZF BER")
print("-" * 60)

for match in matches:
    snr = int(match[0])
    no_eq = float(match[1])
    known_zf = float(match[3])
    pilot_zf = float(match[5])

    print(
        f"{snr:7d} | "
        f"{no_eq:10.6f} | "
        f"{known_zf:13.6f} | "
        f"{pilot_zf:15.6f}"
    )

# Final 20 dB values
final = matches[-1]

print()
print("=" * 70)
print("20 dB PERFORMANCE")
print("=" * 70)

print(f"No Equalization BER   : {float(final[1]):.6f}")
print(f"Known-Channel ZF BER  : {float(final[3]):.6f}")
print(f"Pilot LS + ZF BER     : {float(final[5]):.6f}")

print()
print(f"No Equalization EVM   : {float(final[2]):.2f}%")
print(f"Known-Channel ZF EVM  : {float(final[4]):.2f}%")
print(f"Pilot LS + ZF EVM     : {float(final[6]):.2f}%")

print()
print("=" * 70)
print("PYTHON RESULT ANALYSIS COMPLETED")
print("=" * 70)
