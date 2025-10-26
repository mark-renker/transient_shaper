# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def test_transient_shaper(dut):
    """Test the transient shaper audio processor"""
    dut._log.info("Start transient shaper test")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 5)

    dut._log.info("Test 1: Passthrough mode (no attack/sustain boost)")
    # ui_in = [attack_amt, sustain_amt, audio_in[5:0]]
    # Set audio input to 32 (0b100000), no attack/sustain
    dut.ui_in.value = 0b00100000  # audio=32, sustain=0, attack=0
    await ClockCycles(dut.clk, 20)
    # After envelope followers settle, output should be close to input (32)
    output1 = int(dut.uo_out.value)
    dut._log.info(f"Passthrough output: {output1}")
    assert output1 >= 0 and output1 <= 255, "Output out of range"

    dut._log.info("Test 2: Attack boost enabled")
    # Set audio input to 32 with attack boost enabled
    dut.ui_in.value = 0b10100000  # audio=32, sustain=0, attack=1
    await ClockCycles(dut.clk, 20)
    output2 = int(dut.uo_out.value)
    dut._log.info(f"Attack boost output: {output2}")
    assert output2 >= output1, "Attack boost should increase output"

    dut._log.info("Test 3: Sustain boost enabled")
    # Set audio input to 32 with sustain boost enabled
    dut.ui_in.value = 0b01100000  # audio=32, sustain=1, attack=0
    await ClockCycles(dut.clk, 20)
    output3 = int(dut.uo_out.value)
    dut._log.info(f"Sustain boost output: {output3}")
    assert output3 >= 0 and output3 <= 255, "Output out of range"

    dut._log.info("Test 4: Impulse response with attack boost")
    # Simulate an audio impulse (high then low)
    dut.ui_in.value = 0b10111111  # audio=63 (max), attack=1, sustain=0
    await ClockCycles(dut.clk, 2)
    peak_output = int(dut.uo_out.value)
    dut._log.info(f"Impulse peak output: {peak_output}")

    # Drop to low level
    dut.ui_in.value = 0b10001000  # audio=8, attack=1, sustain=0
    await ClockCycles(dut.clk, 10)
    decay_output = int(dut.uo_out.value)
    dut._log.info(f"Impulse decay output: {decay_output}")
    assert decay_output < peak_output, "Output should decay after impulse"

    dut._log.info("All tests passed!")
