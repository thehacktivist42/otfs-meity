import math

WIDTH = 1024
HALF_WIDTH = WIDTH // 2
SCALE = 32768.0

with open("data/fft/twiddles_real.hex", "w") as f_real, open("data/fft/twiddles_imag.hex", "w") as f_imag:
    for k in range(HALF_WIDTH):
        # Calculate complex exponential (e^(-j * 2pi * k / N))
        angle = -2.0 * math.pi * k / WIDTH
        
        # Scale to Q15 format
        real_val = round(math.cos(angle) * SCALE)
        imag_val = round(math.sin(angle) * SCALE)
        
        # Handle the edge case where +1.0 * 32768 = 32768 (overflows 16-bit signed max of 32767)
        if real_val == 32768: real_val = 32767
        if imag_val == 32768: imag_val = 32767
        
        # Convert to 16-bit two's complement integer
        real_int = int(real_val) & 0xFFFF
        imag_int = int(imag_val) & 0xFFFF
        
        # Write 4-character zero-padded hex strings to the files
        f_real.write(f"{real_int:04X}\n")
        f_imag.write(f"{imag_int:04X}\n")

print(f"Generated {HALF_WIDTH} twiddle factors.")