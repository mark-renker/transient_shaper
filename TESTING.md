# Local Testing Guide for Audio Transient Shaper

This guide will help you test and explore the transient shaper design on your local machine, even if you're new to digital design and simulation.

## Overview

You'll be using:
- **Icarus Verilog** (iverilog): A free Verilog simulator
- **Cocotb**: A Python-based testbench framework
- **GTKWave**: A waveform viewer to visualize signals

## Prerequisites Installation

### macOS (using Homebrew)

```bash
# Install Homebrew if you don't have it
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Icarus Verilog
brew install icarus-verilog

# Install GTKWave for viewing waveforms
brew install --cask gtkwave

# Install Python packages
pip3 install cocotb pytest
```

### Linux (Ubuntu/Debian)

```bash
sudo apt-get update
sudo apt-get install iverilog gtkwave python3-pip
pip3 install cocotb pytest
```

### Windows

Use WSL (Windows Subsystem for Linux) and follow the Linux instructions above, or:
1. Download Icarus Verilog from http://bleez.freeshell.org/iverilog/
2. Install Python from https://www.python.org/
3. Install cocotb: `pip install cocotb pytest`

## Running the Tests

### Step 1: Navigate to the Project

```bash
cd ~/Desktop/transient_shaper
```

### Step 2: Run the Tests

```bash
cd test
make
```

This will:
1. Compile the Verilog source files
2. Run the cocotb test suite
3. Generate a waveform file (`tb.vcd`)

**What you should see:**
```
Test 1: Passthrough mode (no attack/sustain boost)
Passthrough output: 32
Test 2: Attack boost enabled
Attack boost output: 48
Test 3: Sustain boost enabled
Sustain boost output: 40
Test 4: Impulse response with attack boost
...
All tests passed!
```

### Step 3: View the Waveforms

After the tests complete, open the waveform viewer:

```bash
gtkwave tb.vcd tb.gtkw
```

**GTKWave Quick Guide:**
- **Left panel**: Signal hierarchy - expand `tb` to see all signals
- **Middle panel**: Signal list - double-click to add signals to the waveform view
- **Bottom panel**: Waveform display showing signal values over time
- **Zoom**: Use the zoom buttons or scroll wheel
- **Markers**: Click on the waveform to place markers and measure timing

**Signals to explore:**
- `ui_in`: 8-bit input (audio + control bits)
- `uo_out`: 8-bit processed output
- `clk`: Clock signal
- `rst_n`: Reset signal (active low)
- `uut.fast_env`: Fast envelope follower inside the design
- `uut.slow_env`: Slow envelope follower inside the design
- `uut.attack_boost`: Attack enhancement value
- `uut.sustain_boost`: Sustain enhancement value

## Understanding the Design

### Input Format (`ui_in`)

The 8-bit input is structured as:
```
Bit 7: attack_amt (0=off, 1=boost)
Bit 6: sustain_amt (0=off, 1=boost)
Bits [5:0]: audio_in (0-63 range)
```

**Example input values:**
```
0b00100000 = 32 → Audio=32, no boost
0b10100000 = 160 → Audio=32, attack boost ON
0b01100000 = 96 → Audio=32, sustain boost ON
0b11111111 = 255 → Audio=63 (max), both boosts ON
```

### How It Works

1. **Audio Input** → Two parallel envelope followers (fast & slow)
2. **Fast Envelope** → Tracks attack (transients)
3. **Slow Envelope** → Tracks sustain (sustained portions)
4. **Modulation** → Boosts attack/sustain by 50% when enabled
5. **Output** → Original signal + envelope-derived gain

## Modifying the Test

You can experiment by editing `test/test.py`:

```python
# Try different input values
dut.ui_in.value = 0b10110000  # Your custom value

# Wait and see the result
await ClockCycles(dut.clk, 50)
output = safe_int(dut.uo_out.value)
dut._log.info(f"My test output: {output}")
```

Then re-run:
```bash
make clean
make
```

## Exploring the Verilog Code

### Main Module: `src/tt_um_markr_transientshaper.v`

This is the top-level wrapper that connects to Tiny Tapeout pins.

### Core Logic: `src/transient_shaper_core.v`

This contains the actual signal processing:

**Envelope Followers** (Lines 16-24):
```verilog
fast_env <= (fast_env * 3 + audio_in) >> 2;  // Time constant = 0.25
slow_env <= (slow_env * 7 + audio_in) >> 3;  // Time constant = 0.125
```

**Modulation** (Lines 35-37):
```verilog
attack_boost <= attack_amt ? (fast_env >> 1) : 0;   // 50% boost
sustain_boost <= sustain_amt ? (slow_env >> 1) : 0;
audio_out <= audio_in + attack_boost + sustain_boost;
```

## Experimentation Ideas

### 1. Change Time Constants

Edit `src/transient_shaper_core.v`:
```verilog
// Make attack faster
fast_env <= (fast_env * 1 + audio_in) >> 1;  // More aggressive

// Make sustain slower
slow_env <= (slow_env * 15 + audio_in) >> 4;  // Smoother
```

### 2. Adjust Boost Amount

```verilog
// Increase boost from 50% to 75%
attack_boost <= attack_amt ? (fast_env * 3 >> 2) : 0;
```

### 3. Add More Test Cases

Edit `test/test.py` to test different scenarios:
```python
dut._log.info("Test: Drum hit simulation")
# Simulate a kick drum: loud attack, quick decay
dut.ui_in.value = 0b10111111  # Max attack
await ClockCycles(dut.clk, 2)
dut.ui_in.value = 0b10010000  # Drop to medium
await ClockCycles(dut.clk, 10)
dut.ui_in.value = 0b10000100  # Drop to low
await ClockCycles(dut.clk, 20)
```

### 4. Visualize Different Inputs

Create a custom test that sweeps through different audio levels:
```python
for level in range(0, 64, 4):  # 0, 4, 8, 12, ..., 60
    dut.ui_in.value = 0b10000000 | level  # Attack on, varying audio
    await ClockCycles(dut.clk, 10)
    output = safe_int(dut.uo_out.value)
    dut._log.info(f"Input: {level}, Output: {output}")
```

## Troubleshooting

### "make: command not found"
Install make: `brew install make` (macOS) or `sudo apt-get install build-essential` (Linux)

### "cocotb-config not found"
Install cocotb: `pip3 install cocotb`

### "Cannot find module test"
Make sure you're in the `test/` directory when running `make`

### GTKWave shows no signals
1. In GTKWave, go to File → Open New Tab
2. Navigate to `test/tb.vcd`
3. Expand the hierarchy in the left panel
4. Double-click signals to add them

### Tests fail with "X/Z values"
This is normal for gate-level simulation. Run RTL tests only:
```bash
make clean
make  # Don't set GATES=yes
```

## Next Steps

Once you're comfortable with simulation:

1. **Modify the design** to implement your own ideas
2. **Add new features** like multiple time constants or variable boost amounts
3. **Create new test cases** for different audio scenarios
4. **Explore synthesis** by checking the GDS build artifacts in GitHub Actions
5. **Submit to Tiny Tapeout** when you're ready to fabricate your design!

## Resources

- **Tiny Tapeout Docs**: https://tinytapeout.com/
- **Verilog Tutorial**: https://www.chipverify.com/verilog/verilog-tutorial
- **Cocotb Documentation**: https://docs.cocotb.org/
- **GTKWave Manual**: http://gtkwave.sourceforge.net/gtkwave.pdf

## Questions?

- Check the [Tiny Tapeout Discord](https://tinytapeout.com/discord)
- Review example projects at https://tinytapeout.com/runs/
- Read the comprehensive docs at https://tinytapeout.com/hdl/

Happy hacking! 🎛️
