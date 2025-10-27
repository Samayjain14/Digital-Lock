# Digital Lock System (FSM – Verilog)

This project implements a 4-digit digital lock using a Finite State Machine (FSM) in Verilog.  
The system validates a passcode digit-by-digit, supports relocking, and enters a lockout mode  
after 3 incorrect attempts. The design was simulated and verified using ModelSim 20.1.

---

## Project Features
- 4-digit password verification (e.g., 1-2-3-4)
- `unlocked` output set HIGH only when full sequence matches
- `wrong_try_pulse` identifies incorrect attempts
- Lockout enabled after 3 wrong tries
- Lockout state ignores further inputs temporarily
- `relock` forces return to locked state
- Complete functional verification with waveforms

---

## Inputs and Outputs

| Signal           | Width | Dir | Description |
|-----------------|-------|-----|-------------|
| clk              | 1     | In  | System clock |
| rst              | 1     | In  | Synchronous reset |
| digit            | 4     | In  | Numeric input (0–9 in binary) |
| valid            | 1     | In  | Digit entry strobe |
| relock           | 1     | In  | Return to locked state |
| unlocked         | 1     | Out | High when correct code is entered |
| wrong_try_pulse  | 1     | Out | High for one cycle on incorrect entry |
| lockout          | 1     | Out | High after 3 wrong attempts |

---

## How to Run (ModelSim)

### Using the automated script:
Open ModelSim Transcript and enter:

```tcl
quit -sim
cd "D:/Verilog excercises/Digital Lock FSM"
do "sim/run.do"
