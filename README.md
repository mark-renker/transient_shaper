![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg) ![](../../workflows/fpga/badge.svg)

# Audio Transient Shaper

This project implements a real-time audio transient shaper for Tiny Tapeout. It enhances or reduces the attack and sustain portions of audio signals using envelope-based processing.

- [Read the documentation for project](docs/info.md)

## How it works

The transient shaper processes audio in real-time by:

1. **Dual Envelope Detection**: Uses separate fast and slow envelope followers to track signal dynamics
2. **Attack Enhancement**: Boosts the initial transient portion of audio signals when enabled
3. **Sustain Modulation**: Separately controls the sustained portion of the signal
4. **Real-time Processing**: Operates at 24MHz for low-latency audio processing

## Interface

- **Input**: 6-bit audio input + 2 control bits (attack enable, sustain enable)
- **Output**: 8-bit processed audio output
- **Clock**: 24MHz
- **Reset**: Active-low asynchronous reset

### Pin Configuration

- `ui_in[5:0]`: Audio input (6-bit unsigned)
- `ui_in[6]`: Sustain amount control
- `ui_in[7]`: Attack amount control
- `uo_out[7:0]`: Processed audio output (8-bit)

## Testing

The design includes comprehensive testbenches for simulation. Run tests with:

```bash
cd test
make
```

## What is Tiny Tapeout?

Tiny Tapeout is an educational project that aims to make it easier and cheaper than ever to get your digital and analog designs manufactured on a real chip.

To learn more and get started, visit https://tinytapeout.com.

## Technical Details

- **Platform**: Tiny Tapeout (digital ASIC)
- **Tile size**: 1
- **Technology**: SKY130
- **Clock frequency**: 24MHz
- **Signal path**: All-digital processing

## Resources

- [FAQ](https://tinytapeout.com/faq/)
- [Digital design lessons](https://tinytapeout.com/digital_design/)
- [Learn how semiconductors work](https://tinytapeout.com/siliwiz/)
- [Join the community](https://tinytapeout.com/discord)
- [Build your design locally](https://www.tinytapeout.com/guides/local-hardening/)

## Author

Mark Renker

## License

Licensed under Apache-2.0
