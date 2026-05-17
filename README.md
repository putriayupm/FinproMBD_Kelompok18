# Soil-Based Fertilizer Scheduling System

**Fundamental of Embedded System – Final Project**
Program Studi Teknik Komputer, Fakultas Teknik
Universitas Indonesia – 2026

An AVR Assembly–based embedded system that monitors soil moisture in real-time and automatically recommends fertilizer scheduling based on soil conditions. The system is built using two Arduino Uno microcontrollers in a Master-Slave configuration communicating via the SPI protocol.

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [System Architecture](#system-architecture)
- [Hardware Requirements](#hardware-requirements)
- [Software Requirements](#software-requirements)
- [Pin Configuration](#pin-configuration)
- [How It Works](#how-it-works)
- [Moisture Thresholds](#moisture-thresholds)
- [Installation and Setup](#installation-and-setup)
- [Testing Results](#testing-results)
- [Project Structure](#project-structure)
- [Team Members](#team-members)
- [Future Improvements](#future-improvements)

---

## Overview

Soil moisture is one of the most critical factors that determine plant growth and fertilization effectiveness. Manual monitoring is time-consuming and often results in inefficient fertilizer use. This project addresses that problem by building an automated, real-time soil monitoring and fertilizer scheduling system using AVR Assembly programming on the Arduino Uno platform.

The system reads soil moisture via an analog sensor, processes the data through ADC (Analog-to-Digital Conversion), and provides three forms of output:

- **Visual** — LED indicators (Red, Green, Yellow)
- **Audio** — Buzzer notification
- **Textual** — Serial Monitor with status and fertilizer recommendations

---

## Features

- Real-time soil moisture monitoring with stable ADC readings
- Master-Slave SPI communication between two Arduino Uno boards
- Three-state LED indicator (Dry / Optimal / Wet)
- Buzzer alert when soil is at optimal fertilizing condition
- Serial output with humidity percentage, status, and recommendation
- Toggle button to turn the monitoring system ON/OFF with 20ms debounce
- Pure AVR Assembly implementation with direct register-level hardware control

---

## System Architecture

```
┌─────────────────┐         SPI          ┌─────────────────┐
│   ARDUINO UNO   │ ◄──────────────────► │   ARDUINO UNO   │
│    (MASTER)     │                      │    (SLAVE)      │
│                 │                      │                 │
│  - UART         │                      │  - ADC          │
│  - LED Control  │                      │  - Soil Sensor  │
│  - Buzzer       │                      │    Reading      │
│  - Button Input │                      │                 │
└────────┬────────┘                      └────────┬────────┘
         │                                        │
         ├─ Red LED  (Dry)                        │
         ├─ Green LED (Optimal)                   └─ Soil Moisture Sensor
         ├─ Yellow LED (Wet)
         ├─ Buzzer
         ├─ Button
         └─ Serial Monitor (UART)
```

**Slave Arduino** reads the soil moisture sensor through the ADC, inverts the value (since the sensor outputs a low reading when wet), scales it to a 0–100% percentage, and loads it into the SPDR register.

**Master Arduino** polls a toggle button, requests humidity data from the Slave via SPI, controls the LEDs and buzzer based on configured thresholds, and transmits status and recommendation strings through UART to the Serial Monitor.

---

## Hardware Requirements

| No | Component | Quantity |
|----|-----------|----------|
| 1 | Arduino Uno | 2 |
| 2 | Soil Moisture Sensor | 1 |
| 3 | LED (Red, Green, Yellow) | 3 |
| 4 | Resistor 220Ω | 3 |
| 5 | Push Button | 1 |
| 6 | Buzzer | 1 |
| 7 | Jumper Wires | As needed |
| 8 | Breadboard | 1 |

---

## Software Requirements

- **Arduino IDE** — for compiling and uploading the `.S` Assembly files
- **Proteus** — for circuit simulation and virtual testing
- **Draw.io** — for flowchart design
- **AVR-GCC Toolchain** (bundled with Arduino IDE) — for AVR Assembly compilation

---

## Pin Configuration

### Master Arduino

| Pin | Function | Component |
|-----|----------|-----------|
| PD2 | Input (with pull-up) | Toggle Button |
| PD4 | Output | Red LED (Dry) |
| PD5 | Output | Green LED (Optimal) |
| PD6 | Output | Yellow LED (Wet) |
| PD7 | Output | Buzzer |
| PB2 (SS) | Output | SPI Slave Select |
| PB3 (MOSI) | Output | SPI Data Out |
| PB4 (MISO) | Input | SPI Data In |
| PB5 (SCK) | Output | SPI Clock |
| TX/RX | UART | Serial Monitor |

### Slave Arduino

| Pin | Function | Component |
|-----|----------|-----------|
| A0 (PC0) | Analog Input | Soil Moisture Sensor |
| PB2 (SS) | Input | SPI Slave Select |
| PB3 (MOSI) | Input | SPI Data In |
| PB4 (MISO) | Output | SPI Data Out |
| PB5 (SCK) | Input | SPI Clock |

---

## How It Works

### Master Flow

1. Initialize UART, SPI (as Master), and configure I/O ports.
2. Continuously poll the toggle button.
3. If the system is **ON**:
   - Pull SS low and request humidity data from the Slave via SPI.
   - Receive the humidity percentage into register `R17`.
   - Compare against `THRESHOLD_DRY (40)` and `THRESHOLD_WET (61)`.
   - Light the appropriate LED, sound the buzzer if optimal, and print the status and recommendation via UART.
4. If the system is **OFF**:
   - Turn off all LEDs and the buzzer.
   - Print `SENSOR OFF` once.
5. Loop with a 500ms delay.

### Slave Flow

1. Initialize SPI (as Slave) and configure the ADC with `ADLAR` set (left-adjusted).
2. Start an ADC conversion and wait for it to complete.
3. Read `ADCH` and invert the value (`255 - ADCH`) because the sensor outputs low when wet.
4. Scale to percentage by multiplying by 100 and taking the high byte of the result.
5. Preload the result into `SPDR` so the Master always reads the latest value.
6. Loop continuously.

---

## Moisture Thresholds

| Condition | Range | LED | Buzzer | Status | Recommendation |
|-----------|-------|-----|:------:|--------|----------------|
| Dry | `< 40%` | Red | OFF | `TERLALU KERING` | `SIRAM DULU` |
| Optimal | `40% – 60%` | Green | ON | `OPTIMAL` | `PUPUK SEKARANG!` |
| Wet | `≥ 61%` | Yellow | OFF | `TERLALU BASAH` | `TUNGGU KERING` |

---

## Installation and Setup

### 1. Clone the Repository

```bash
git clone https://github.com/<your-username>/soil-fertilizer-scheduler.git
cd soil-fertilizer-scheduler
```

### 2. Wire the Circuit

Build the hardware according to the [Pin Configuration](#pin-configuration) section, or open the Proteus simulation file to test the system virtually.

### 3. Upload the Code

**For the Slave Arduino:**

1. Open `Slave.S` in the Arduino IDE.
2. Select Board: Arduino Uno.
3. Select the correct COM port for the Slave board.
4. Click Upload.

**For the Master Arduino:**

1. Open `Master.S` in the Arduino IDE.
2. Select Board: Arduino Uno.
3. Select the correct COM port for the Master board.
4. Click Upload.

### 4. Run the System

1. Open the Serial Monitor (baud rate **9600**) on the Master Arduino.
2. Press the toggle button to activate the system.
3. Insert the soil moisture sensor into the soil and observe the readings, LEDs, and buzzer.

---

## Testing Results

The system was tested with two extreme soil samples (dry and wet) to validate the full logic chain (sensor → ADC → SPI → decision → output).

| Test Case | Sensor State | Expected Output | Result |
|-----------|--------------|-----------------|:------:|
| Dry soil (< 40%) | Inserted in dry sample | Red LED + `TERLALU KERING` + `SIRAM DULU` | Pass |
| Optimal soil (40–60%) | Moderately moist sample | Green LED + Buzzer + `OPTIMAL` + `PUPUK SEKARANG!` | Pass |
| Wet soil (≥ 61%) | Over-watered sample | Yellow LED + `TERLALU BASAH` + `TUNGGU KERING` | Pass |
| Toggle button | Press to OFF / ON | All outputs disabled / re-enabled | Pass |

### Key Technical Notes

- **Sensor inversion** (`255 - ADCH`) was required because the sensor outputs low values when wet and high values when dry.
- **SPI synchronization** was achieved by preloading `SPDR` on the Slave so the Master always receives the latest reading.
- **Polling** was used instead of interrupts due to interrupt vector conflicts in the Arduino IDE.
- A **20ms debounce** was added to the button to prevent false triggering.

---

## Project Structure

```
soil-fertilizer-scheduler/
├── Master.S              # Master Arduino Assembly code
├── Slave.S               # Slave Arduino Assembly code
├── proteus/
│   └── simulation.pdsprj # Proteus circuit simulation
├── flowchart/
│   ├── master_flow.png   # Master Arduino flowchart
│   └── slave_flow.png    # Slave Arduino flowchart
├── docs/
│   └── PROJECT_REPORT.pdf
└── README.md
```

---

## Team Members

**Kelompok 18** — Program Studi Teknik Komputer, Universitas Indonesia

| Name | NPM | Role |
|------|-----|------|
| Abyan Ammar Zaki | 2406421005 | Proteus, Code, Laporan |
| Nadia Izzati | 2406487033 | Code, Laporan |
| Nicholas Edmund | 2406352986 | Code, Laporan |
| Putri Ayu Pembayun M | 2406422304 | Github, Code, Laporan |

---

## Future Improvements

- **EEPROM logging** — store historical moisture data for trend analysis.
- **Automatic irrigation system** — trigger a water pump when the soil is dry.
- **Temperature sensor integration** — for more accurate fertilizer dosage recommendations.
- **Wireless connectivity** (ESP8266/ESP32) — enable remote monitoring via a mobile app.
- **LCD display** — onboard visualization without requiring a serial monitor.
