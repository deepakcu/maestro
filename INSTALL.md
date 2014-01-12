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
```
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
```

Compiling FPGA Bitstream
------------------------
To generate the FPGA bitstream, run make inside fpga source folder

```
> cd fpga/DE4_Ethernet
> make
```
Compilation takes approximately 40 minutes on an Intel Core i7/8G RAM machine. When successful, you should see the DE4_Ethernet.sof programming bit generted in the FPGA source folder.

Preparing the Board
-------------------
1. Insert the Hynix DDR2 DRAM module that ships with the Altera DE-4 package into the M1 DDR2 slot in the Altera DE-4 board.
2. Set the 100MHz clock on the DE-4 board by setting the SW0 switch 00 (both ON) position.
3. Set the SW0 switch on the DE-4 board to ON position to operate in JTAG mode.
4. Attach a CAT-5 standard Ethernet cable between ETH0 port of DE-4 board and the PC (Note: You must use a standard Ethernet cable and not a cross-over cable).
5. Attach the USB JTAG cable to the board. 
6. Power on the board.

Compiling Software
------------------
1. Compile Maestro software 

```
> cd /home/deepak/Desktop/git/maestro/sw
> make
```
2. The binary (example_dsm) will be generated under maestro/sw/bin/release/examples/. Create a soft-link for this binary under maestro/sw
```
maestro/sw> ln -s bin/release/examples/example-dsm ./example-dsm
```

Running Maestro
---------------
1. The input graph that needs to be processed must be placed in a directory input/<application_name> (e.g. input/pr_graph). The graph must be described using an adjacency list format as:
```
<node ID><tab><space separated node IDs of neighbors>
```

Example:
```
0       2133 2713 5974 8907
1       1533 1827 3247 3804 5615 5956 7526 9568 9650 9768 9921
2       3467
3       8486
4       9557
5       4560
6       2305
7       7684 8269
```

The input graph may be user supplied or generated using a script (see details here).

2.  


Generating a Synthetic Graph
----------------------------


