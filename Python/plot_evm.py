import re
from pathlib import Path

project_folder = Path("/MATLAB Drive/5G_OFDM_Modem")

result_file = (
    project_folder
    / "Results"
    / "step19_8_BER_EVM_results.txt"
)

output_file = (
    project_folder
    / "Results"
    / "python_evm_data.txt"
)

if not result_file.exists():
    print("ERROR: MATLAB result file not found.")
    print(result_file)
    raise SystemExit

text = result_file.read_text(encoding="utf-8")

pattern = re.compile(
    r"SNR =\s*(\d+)\s*dB\s*\|\s*"
    r"No-EQ BER =\s*[0-9.]+,\s*EVM =\s*([0-9.]+)%\s*\|\s*"
    r"Known-ZF BER =\s*[0-9.]+,\s*EVM =\s*([0-9.]+)%\s*\|\s*"
    r"Pilot-LS-ZF BER =\s*[0-9.]+,\s*EVM =\s*([0-9.]+)%"
)

matches = pattern.findall(text)

if not matches:
    print("ERROR: No EVM data found.")
    raise SystemExit

with output_file.open("w", encoding="utf-8") as f:

    f.write("SNR,No_EQ_EVM,Known_ZF_EVM,Pilot_LS_ZF_EVM\n")

    for match in matches:

        snr = match[0]
        no_eq_evm = match[1]
        known_zf_evm = match[2]
        pilot_zf_evm = match[3]

        f.write(
            f"{snr},{no_eq_evm},{known_zf_evm},{pilot_zf_evm}\n"
        )

print()
print("=" * 60)
print("EVM DATA PREPARATION COMPLETED")
print("=" * 60)
print(f"SNR points processed : {len(matches)}")
print()
print("Output file:")
print(output_file)
print("=" * 60)
