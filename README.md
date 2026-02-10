# FPGA-Digital-Voting-Machine
A robust Verilog-based Electronic Voting System implemented on an FPGA. This project features voter authentication, duplicate vote prevention, and real-time result calculation.

## Features

 - *​Voter Authentication: Limits voting to valid IDs (0-9).*
 - ​*Security: Prevents "double-voting" by tracking individual voter status in a registry.*
 - *Real-time Processing: Live vote counts displayed during the session.*
 - *Auto-Winner Logic: Upon completion, the system automatically identifies and displays the Winner and Runner-up.*
 - *Hardware Optimized: Includes button debouncing and time-multiplexed 7-segment display control.*

## Hardware Requirements

 - *​FPGA Board: Xilinx Artix-7 (e.g., Basys 3)*
 - *Inputs: 8x Switches (Rep Selection & Voter ID), 3x Push Buttons (Vote, Finish, Reset).*
 - *Outputs: 4-Digit 7-Segment Display, 1x Error LED.*

## How to Run

​- *Open Xilinx Vivado.*
- *Create a new project and select your FPGA board.*
- *Add voting_machine.v as a design source.*
- *Add constraints.xdc as a constraint file.*
- *Run Synthesis, Implementation, and Generate Bitstream.*
- *Program the board and start voting!*
