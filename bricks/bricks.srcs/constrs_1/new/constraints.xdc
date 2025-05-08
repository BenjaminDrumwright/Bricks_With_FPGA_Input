# ===============================
# Clock (100 MHz)
# ===============================
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

# ===============================
# Reset (SW0)
# ===============================
set_property PACKAGE_PIN V17 [get_ports rst]
set_property IOSTANDARD LVCMOS33 [get_ports rst]

# ===============================
# Buttons
# ===============================
set_property PACKAGE_PIN W19 [get_ports btnL]
set_property IOSTANDARD LVCMOS33 [get_ports btnL]

set_property PACKAGE_PIN T17 [get_ports btnR]
set_property IOSTANDARD LVCMOS33 [get_ports btnR]

set_property PACKAGE_PIN U18 [get_ports btnC]
set_property IOSTANDARD LVCMOS33 [get_ports btnC]

set_property PACKAGE_PIN T18 [get_ports btnT]
set_property IOSTANDARD LVCMOS33 [get_ports btnT]

set_property PACKAGE_PIN U17 [get_ports btnB]
set_property IOSTANDARD LVCMOS33 [get_ports btnB]

# ===============================
# UART TX to PC over USB (FTDI)
# ===============================
set_property PACKAGE_PIN A18 [get_ports uart_tx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_tx]