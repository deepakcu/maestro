Maestro Installation
====================
Maestro was evaluated in a laboratary cluster consisting of one to four Altera DE-4 FPGA boards. This document first describes the system system on a single FPGA board. Next, we describe how the 1 FPGA setup can be scaled to a cluster consisting of multiple FPGA boards.

Hardware Requirements
---------------------
1. [Altera DE4-230 Development and Education Board from Terasic Technologies](www.de4.terasic.com)
2. Laptop/PC workstation running Ubuntu 12.04 with atleast 2GB RAM and 100GB hard drive space

Software Requirements
---------------------
1. [Altera Quartus II Software 12.0 or higher with device support for Stratix IV](http://www.altera.com/products/software/sfw-index.jsp) - Please note that Maestro was evaluated only using Quartus II 12.0. You may have to modify project settings to suit other Quartus versions. 
2. Eclipse with C/C++ Development Tools
3. To build Maestro software, you will need a minimum of the following:

* CMake (> 2.6)
* OpenMPI
* Python (2.*)
* gcc/g++ (> 4)
* protocol buffers

If available, the following libraries will be used:

* Python development headers; SWIG
* TCMalloc
* google-perftools
* google-flags
* google-logging

On Ubuntu, the required libraries can be acquired by running:

```
>sudo apt-get install build-essential cmake g++ libboost-dev libboost-python-dev 
>sudo apt-get install libboost-thread-dev liblzo2-dev libnuma-dev libopenmpi-dev 
>sudo apt-get install libprotobuf-dev libcr-dev libibverbs-dev openmpi-bin protobuf-compiler liblapack-dev
```
 
the optional libraries can be install via:

```
>sudo apt-get install libgoogle-perftools-dev python-dev swig
```

4. For debugging Maestro, it is recommended to install Wireshark

```
>sudo apt-get install wireshark
```

Maestro Source Structure
------------------------

fpga/
└── DE4_Ethernet_0
    ├── accumulator_channel.v
    ├── accumulator.v
    ├── altpllpll_bb.v
    ├── altpllpll.qip
    ├── altpllpll.v
    ├── binary_adder_tree.v
    ├── coherence_controller.sv
    ├── collector.sv
    ├── command_defines.v
    ├── compute.sv
    ├── compute_system_hw.tcl
    ├── compute_system.sv
    ├── data_loader.v

