# Formal Verification for Transient Shaper

This directory contains formal verification setup for the audio transient shaper design using SymbiYosys (sby) and Z3 solver.

## What is Formal Verification?

Unlike simulation (which tests specific scenarios), formal verification mathematically **proves** that your design satisfies certain properties for **all possible input combinations**. This provides exhaustive coverage that simulation cannot achieve.

## Files

- **transient_shaper_formal.sv** - SystemVerilog wrapper with formal properties (assertions and coverage)
- **transient_shaper_bmc.sby** - Bounded Model Checking configuration (fast, checks properties up to N cycles)
- **transient_shaper_prove.sby** - Proof configuration (attempts mathematical proofs)
- **transient_shaper_cover.sby** - Coverage configuration (finds traces that satisfy cover statements)

## Properties Being Verified

### Safety Properties (Assertions)

1. **Reset Behavior**: All internal states reset to zero when `rst_n` is low
2. **Output Bounds**: Output never exceeds 255 (8-bit maximum)
3. **Envelope Bounds**: Envelope followers stay within 0-255 range
4. **Attack Boost Calculation**: When enabled, boost = fast_envelope / 2
5. **Sustain Boost Calculation**: When enabled, boost = slow_envelope / 2
6. **Disabled Behavior**: State doesn't change when `ena` is low
7. **Zero Input Decay**: Envelopes decay toward zero with zero input
8. **Convergence**: Envelopes converge toward steady-state input values

### Coverage Goals (Cover Statements)

1. Both attack and sustain boost enabled simultaneously
2. Attack boost only
3. Sustain boost only
4. Maximum input value (63)
5. Transition from high to low input
6. High output values (>200)

## Running Formal Verification

### Quick Start

```bash
cd formal

# 1. Bounded Model Checking (fast, ~30 seconds)
sby -f transient_shaper_bmc.sby

# 2. Full Proof (slower, ~2-5 minutes)
sby -f transient_shaper_prove.sby

# 3. Coverage Analysis (finds interesting traces)
sby -f transient_shaper_cover.sby
```

### Understanding Results

**BMC (Bounded Model Checking)**:
- Checks all properties for specific depths (e.g., 50 clock cycles)
- ✅ `PASS` = No violations found within the depth limit
- ❌ `FAIL` = Counterexample found (property violated)
- Output: `transient_shaper_bmc/` directory with results

**Prove Mode**:
- Attempts mathematical proofs using induction
- ✅ `PASS` = Property proven for all time
- ❌ `FAIL` = Counterexample found
- ⚠️ `UNKNOWN` = Could not prove within depth/time limit
- Output: `transient_shaper_prove/` directory with results

**Cover Mode**:
- Finds traces that satisfy coverage goals
- ✅ `PASS` = Coverage goal reached
- Output: `transient_shaper_cover/` directory with VCD traces

### Viewing Results

```bash
# Check status
cat transient_shaper_bmc/status

# View counterexample (if any failure occurred)
gtkwave transient_shaper_bmc/engine_0/trace.vcd

# View coverage traces
gtkwave transient_shaper_cover/engine_0/trace0.vcd
gtkwave transient_shaper_cover/engine_0/trace1.vcd
```

### Interpreting Logfiles

```bash
# View detailed log
less transient_shaper_bmc/logfile.txt

# Key sections to look for:
# - "Checking assertions..." (property checking)
# - "PASS" or "FAIL" markers
# - "Counterexample trace" (if failure)
```

## Advanced Usage

### Increase Verification Depth

Edit the `.sby` file and change the `depth` parameter:

```ini
[options]
bmc: depth 100  # Increase from 50 to 100
```

**Trade-off**: Higher depth = more thorough but slower

### Try Different Solvers

If you have other solvers installed (yices, boolector), edit the `[engines]` section:

```ini
[engines]
smtbmc yices
# or
smtbmc boolector
```

### Parallel Verification

Run multiple engines in parallel:

```ini
[engines]
smtbmc z3
smtbmc yices
```

### Add Custom Properties

Edit `transient_shaper_formal.sv` and add new assertions:

```systemverilog
// Example: Verify that fast envelope responds faster than slow
always @(posedge clk) begin
    if (rst_n && ena && past_valid && audio_in > $past(audio_in)) begin
        // When input increases, fast_env should grow more than slow_env
        assert_fast_responds_quicker: assert(
            (fast_env - past_fast_env) >= (slow_env - past_slow_env)
        );
    end
end
```

Then re-run verification.

## Common Issues

### "Module not found"

Make sure you're in the `formal/` directory when running `sby`:
```bash
cd ~/transient_shaper/formal
sby -f transient_shaper_bmc.sby
```

### "Solver timeout"

The proof is too complex. Try:
1. Reduce depth: `depth 10` instead of `depth 20`
2. Use BMC mode instead of prove mode
3. Split complex properties into simpler ones

### "Assertion failed"

A counterexample was found! This means your design violates a property:

1. Open the trace: `gtkwave transient_shaper_bmc/engine_0/trace.vcd`
2. Examine the signals leading up to the failure
3. Check if the property is too strict or if there's a real bug

### "Yosys error"

Check for Verilog syntax errors:
```bash
yosys -p "read_verilog -formal ../src/transient_shaper_core.v; read_verilog -formal transient_shaper_formal.sv"
```

## Comparison: Formal vs Simulation

| Aspect | Simulation | Formal Verification |
|--------|-----------|---------------------|
| Coverage | Specific test cases | **All possible inputs** |
| Speed | Fast | Slower (minutes) |
| Proof | No | **Mathematical proof** |
| Bugs Found | Common cases | **Corner cases** |
| Setup | Simple | More complex |

## Next Steps

1. ✅ Run BMC to verify basic properties
2. ✅ Check coverage to ensure interesting cases are reachable
3. ✅ Run prove mode for inductive proofs
4. 📝 Add domain-specific properties (e.g., audio-specific constraints)
5. 🚀 Integrate into CI/CD pipeline (GitHub Actions)

## Resources

- **SymbiYosys Docs**: https://symbiyosys.readthedocs.io/
- **SystemVerilog Assertions**: https://www.systemverilog.io/sva
- **Yosys Manual**: https://yosyshq.net/yosys/documentation.html
- **Formal Verification Guide**: https://zipcpu.com/tutorial/

## CI/CD Integration

To add formal verification to your GitHub Actions workflow:

```yaml
- name: Run Formal Verification
  run: |
    pip install click
    cd formal
    $HOME/.local/bin/sby -f transient_shaper_bmc.sby
```

This ensures every commit is formally verified before merge!

---

**Note**: These formal verification files are completely separate from your Tiny Tapeout submission. Tiny Tapeout only uses files in the `src/` directory, so you can submit your design anytime regardless of formal verification status.

---

**Happy Formal Verification! 🎛️🔬**
