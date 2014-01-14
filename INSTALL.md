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
maestro/
├── fpga
│   └── DE4_Ethernet_0 (Source folder for compiling the FPGA bitstream)
│       ├── DE4_Ethernet.qpf (Quartus project)
│       ├── DE4_Ethernet.qsf (Quartus project settings and pin assignments for Terasic DE-4)
│       ├── de4_ethernet.v   (Project top-level file)
│       ├── DE4_SOPC.qsys    (Qsys system generation file)
│       ├── float_mega       (Megafunctions)
│       ├── ip               (Altera Avalon read and write master template and presets)
│       │   ├── Master_Template
│       │   └── presets
│       ├── Makefile         (Make script)
│       ├── src              (Source folder for modified NetFPGA datapath)
├── INSTALL.md               (This file)
├── LICENSE                  (Apache 2.0 license)
├── README.md                
├── sw                       (Maestro software base folder)
│   ├── bin
│   │   └── release          
│   │       ├── CMakeCache.txt (Software environment variables defined here)
│   │       ├── examples
│   │       │   ├── CMakeFiles
│   │       │   ├── example-dsm (Maestro software executable generated here)
│   │       │   └── Makefile
│   ├── conf (Configuration of each worker - indicates whether worker is CPU/FPGA)
│   │   ├── 0.conf
│   │   ├── 1.conf
│   │   ├── ...
│   │   ├── mpi-cluster (Cluster configuration - indicates master and slave workers)
│   ├── config (TCL script to bring-up Ethernet port interfaces
│   ├── config_gige.tcl
│   ├── config.tcl
│   ├── destip.tcl
│   ├── example-dsm -> bin/release/examples/example-dsm (Soft-link to executable example-dsm)
│   ├── gengraph_pr.sh (Synthetic graph generation)
│   ├── gengraph.sh    (Synthetic graph generation)
│   ├── input          (Place input graphs that need to be processed in this folder)
│   │   ├── pr_graph
│   │   │   ├── part0  (Sample input graph)
│   │   └── sp_graph
│   ├── ip_arp_tables.txt
│   ├── ip_tables.pl
│   ├── jtag_config (Scripts to bring-up Ethernet port interfaces of Altera DE-4)
│   ├── maxval.sh
│   ├── pr.sh (Script to start graph processing)
│   ├── result
│   │   └── pr (Results folder)
│   ├── setup_cluster.pl (Automation scripts for multi-board clusters)
│   ├── src (Maestro C++ sources)


```

Compiling FPGA Bitstream
------------------------
1. Navigate to FPGA source folder
```
> cd fpga/DE4_Ethernet
```

2. Open Quartus project
```
> quartus DE4_Ethernet.qpf&
```

3. In Quartus, open Qsys system generator 
4. Open DE4_Ethernet.qsys system file in the fpga/DE4_Ethernet source folder
5. Click generate
6. After successful system generation, compile the design in Quartus. Compilation takes approximately 40 minutes on an Intel Core i7/8G RAM machine. When successful, you should see the DE4_Ethernet.sof programming bit generted in the FPGA source folder.

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
> cd maestro/sw
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
Maestro provides a script - gengraph.sh that you can customize to generate synthetic graphs. Several attributes of the generated graph can be customized by modifying gengraph.sh

Sample gengraph.sh
```
WORKERS=2              #total workers = masters+slaves
NODES=10000            #total graph nodes

#for sp
GRAPH=input/pr_graph   #location where the graph will be generated
LOGN_DEGREE_M=-0.5     #logN degree
LOGN_DEGREE_S=2.3      #logS degree
LOGN_WEIGHT_M=0        #graph weight                 
LOGN_WEIGHT_S=1.0      #weight
WEIGHTED=false         #true for weighted graphs, else false
WEIGHTGEN=2            #1/logn(m,s)
```

1. Configure cluster 

