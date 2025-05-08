## ===== CLOCK =====
## 125 MHz clock on PYNQ-Z2 from onboard oscillator (G14)
set_property PACKAGE_PIN K17 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -name clk -period 20.000 [get_ports clk]

## ===== UART TX (FPGA → Pi RX GPIO15) =====
## Connects to Pi Pin 10 (GPIO15)
set_property PACKAGE_PIN Y7 [get_ports tx]
set_property IOSTANDARD LVCMOS33 [get_ports tx]

## ===== UART RX (Pi TX GPIO14 → FPGA) =====
## Connects to Pi Pin 8 (GPIO14)
set_property PACKAGE_PIN W6 [get_ports rx]
set_property IOSTANDARD LVCMOS33 [get_ports rx]

## ===== Reset Button (BTN0 on PYNQ-Z2) =====
## Optional: push button reset
set_property PACKAGE_PIN D19 [get_ports rst]
set_property IOSTANDARD LVCMOS33 [get_ports rst]
