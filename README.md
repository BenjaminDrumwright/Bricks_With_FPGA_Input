Bricks with FPGA Paddle Control - User Manual and Build Guide

Project Overview
Our version of Bricks is an enhanced Python-based arcade game inspired by Breakout, featuring multiball gameplay, power-ups/power-downs, scorekeeping, and a session scoreboard. This version integrates real-time paddle control using an FPGA (Basys 3 board) via UART, replacing traditional keyboard input with ultra-low-latency hardware control.

Special Libraries Required (Software Side)
To run the software on a personal machine:
Python 3.8+


pygame (pip install pygame)


pyserial (pip install pyserial)


Windows or Linux machine with a UART COM port



How to Build and Run the Game
Connect your Basys 3 FPGA via Micro-USB



Confirm which COM port it appears as (e.g., COM5 on Windows, /dev/ttyUSB0 on Linux)


Program the FPGA


Use Vivado to synthesize and load the paddle_controller project


Use the uart_tx.vhd and paddle_controller.vhd files


Use the correct .xdc constraints for the Basys 3


Edit main.py and set correct COM port:

 fpga_serial = serial.Serial('COM5', 115200, timeout=0.01)

Open Python IDLE

Open game.py file -> select run module



Gameplay Features:
Paddle moves via FPGA buttons


Scoreboard keeps top 10 scores


Power-ups: Expand paddle, multiball


Power-downs: Shrink paddle, reverse controls


Leveling up every time bricks are cleared



Known Bugs and Issues
Scoreboard is session-based and not persistent across game runs


Paddle may skip pixels when rapidly alternating buttons


Equipment Required
Basys 3 FPGA
Laptop or PC (Windows or Linux with USB COM port)




