# Fully Associative LRU Cache — Verilog

A compact **8-entry fully associative cache** implemented in synthesizable Verilog with an explicit **Least Recently Used (LRU)** replacement policy.

This repository is ready to upload directly to GitHub.

## Features

- 8 cache entries
- Fully associative lookup
- 8-bit byte address
- 4-byte block size
- 6-bit block/tag address (`addr[7:2]`)
- 8-bit data
- Read hit and write hit detection
- Write-allocate on write miss
- LRU replacement using 3-bit rank per entry
- Invalid entries are used before valid entries are evicted
- Asynchronous active-high reset
- Self-checking testbench with automatic PASS/FAIL checks
- Optional VCD waveform generation
- No external libraries or dependencies beyond a Verilog simulator

## Repository Structure

```text
LRU/
├── rtl/
│   └── cache_lru_fully_assoc.v
├── tb/
│   └── tb_cache_lru_fully_assoc.v
├── build/                         # Generated simulation files; ignored by Git
├── .gitignore
├── LICENSE
├── Makefile
└── README.md
```

## Architecture

The cache contains eight entries:

```text
                  addr[7:2]
                     │
                     ▼
              ┌─────────────┐
              │ Tag Search  │
              │ 8-way CAM   │
              └──────┬──────┘
                     │
              hit / miss
                     │
          ┌──────────┴──────────┐
          │                     │
        HIT                    MISS
          │                     │
          ▼                     ▼
   Read/Write Data      Find Invalid Entry
          │              or LRU Entry
          │                     │
          └──────────┬──────────┘
                     ▼
                Update LRU
```

Each cache entry stores:

| Field | Width | Purpose |
|---|---:|---|
| `valid_array` | 1 bit | Indicates whether the entry contains valid data |
| `tag_array` | 6 bits | Stores `addr[7:2]` |
| `data_array` | 8 bits | Stores one byte of data |
| `lru` | 3 bits | `0` = most recently used, `7` = least recently used |

## Interface

| Signal | Direction | Width | Description |
|---|---|---:|---|
| `clk` | input | 1 | Clock |
| `reset` | input | 1 | Active-high asynchronous reset |
| `addr` | input | 8 | Byte address |
| `data_in` | input | 8 | Write data |
| `we` | input | 1 | Write enable |
| `re` | input | 1 | Read enable |
| `data_out` | output | 8 | Data returned on a read hit |
| `hit` | output | 1 | Hit indication |

## LRU Policy

The implementation maintains a rank for every valid cache entry.

- `LRU = 0` → most recently used
- `LRU = 7` → least recently used

On a hit, the accessed entry becomes rank `0` and older entries are shifted toward the LRU end.

On a write miss:

1. Search for an invalid entry.
2. If one exists, allocate into it.
3. If the cache is full, find the entry with `LRU = 7`.
4. Replace that entry.
5. Mark the new entry as most recently used.

## Simulation

### Icarus Verilog

Install Icarus Verilog and run:

```bash
make
```

The testbench compiles and executes automatically.

Expected final result:

```text
========================================
ALL TESTS PASSED
========================================
```

### Compile only

```bash
make compile
```

### Run

```bash
make run
```

### Generate waveform

```bash
make wave
```

The waveform is written to:

```text
build/cache_lru.vcd
```

Open it with GTKWave:

```bash
gtkwave build/cache_lru.vcd
```

### Clean generated files

```bash
make clean
```

## What the Testbench Verifies

The self-checking testbench verifies:

1. Reset invalidates all entries.
2. Write misses allocate cache entries.
3. Newly written entries can be read back.
4. Read hits return the correct data.
5. Read hits update the LRU ordering.
6. A full cache replaces the least-recently-used entry.
7. The recently accessed entry is not incorrectly evicted.
8. Write hits update existing data without creating a duplicate entry.
9. A read miss reports `hit = 0`.
10. A read miss does not return stale valid data.
11. VCD waveform generation works.

## Example LRU Scenario

The testbench fills the cache with:

```text
00 → A0
04 → A1
08 → A2
0C → A3
10 → A4
14 → A5
18 → A6
1C → A7
```

Then it reads `00`.

That access makes address `00` the most recently used entry.

When address `20` is subsequently written, the cache is full. Therefore the least-recently-used entry is selected for replacement. The testbench verifies that `04` is evicted while `00` remains available.

## Design Notes

This is an educational cache model intended to demonstrate:

- Fully associative cache lookup
- Tag comparison
- Valid bits
- Write allocation
- LRU replacement
- Sequential cache-state updates
- Verilog testbench methodology

It intentionally stores one byte per cache block rather than implementing a complete multi-byte data array, memory interface, dirty bits, or write-back policy.

## Requirements

Any simulator supporting the Verilog/SystemVerilog constructs used by the project should work. The included Makefile is configured for:

- Icarus Verilog
- `make`
- GTKWave (optional, only for waveform viewing)

## GitHub Upload

The repository is already structured for direct upload.

```bash
git init
git add .
git commit -m "Add fully associative LRU cache in Verilog"
git branch -M main
git remote add origin <YOUR_GITHUB_REPOSITORY_URL>
git push -u origin main
```

No source-code path changes are required after downloading this repository.
