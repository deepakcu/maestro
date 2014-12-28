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
4. Open DE4_SOPC.qsys system file in the fpga/DE4_Ethernet source folder
5. Click generate
6. After successful system generation, compile the design in Quartus. Compilation takes approximately 40 minutes on an Intel Core i7/8G RAM machine. When successful, you should see the DE4_Ethernet.sof programming bit generted in the FPGA source folder.

Notes: 

Note 1 - If Quartus compilation fails with any of the errors, use the following workaround:

```
Error: SystemVerilog error at <location>: can't resolve aggregate expression in connection to port <number> on instance "<string>" because the instance has no module binding

```

Workaround:
Add the file containing the module declaration (or an equivalent extern module declaration) to your Quartus II project.
Click Project->Add current file to the project

For example, you may have to manually add the following files to the project
```
fifo_arbiter.sv, 
snoopy_bus_arbiter.sv
top_k_fill.sv
collect.sv
```
Note 2 - If Quartus II analysis complains about the file compte_system.sv declared twice, remove the file compute_system.sv from the Quartus II Project. Right click compute_system.sv->remove file from the project.


[Qsys system and Quartus Project Overview]( 

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

2. Specifying cluster configuration. Maestro allows a worker to be designated as the master node. All 
other workers are designated as slave nodes. Cluster configuration must be described in the mpi-cluster file located at maestro/sw/conf/mpi-cluster. The first line in this file indicates the hostname or IP address of the master node and task slots (you can always set 
this number to 1).

For example, a sample mpi-cluster file for a 1 worker cluster is given below:

```
10.1.1.1 slots=1
10.1.1.1 slots=1
```

In this case, the worker with IP address (10.1.1.1) assumes the role of the master node and is responsible
for tasks such as initiation the computation, checking computation progress and terminating the computation.
Following lines in this file indicate the IP addresses of all slaves in the cluster (including that of the master
if master also owns part of the computation). For example, in the example considered, the task is shared
between the master (10.1.1.1) and slave (10.1.1.2).

Further, the type of each worker must be specified in individual configuration files under maestro/sw/conf directory.
Inside this folder, you will see configuration files in the following pattern: <worker_ID>.conf. Each file
corresponds to the ID of the worker and the type (CPU/FPGA) for that worker.

Sample type file for a CPU worker:
```
cpu    <ip_address_of_worker>  <tcp port>
```

Sample type file for an FPGA worker:
```
fpga    <ip_address_of_worker>  <tcp port>
```

For now, Maestro does not support heterogeneous workers (e.g. some CPUs and some FPGAs). So, you 
must make sure that all type files have similar worker types (e.g. all CPUs or all FPGAs).

3. Ensure that input files that require processing are placed under input/<application_name_graph> folder.
Note that synthetic graphs can be generated if you wish using details provided here.

4. Assign static IP to network interfaces. In this case, lets assume that the board is
attached to eth1 interface of the PC. Static IP can be set on the PC side using ifconfig command:

```
> ifconfig eth1 10.1.1.1/24
```

The static IP must be set for packets sent by FPGA to be correctly received on the PC.

5. Customize the algorithm file (e.g. pr.sh)

Sample algorithm file
```
ALGORITHM=Pagerank 	#Choose algorithm (Pagerank, Katz, Maxval)
WORKERS=5 		#workers=slaves+master E.g. for 2 FPGA machine, WORKERS=3
GRAPH=input/pr_graph 	#directory where graph is stored
RESULT=result/pr	#directory where results will be dumped
NODES=4800000		#graph size (in terms of nodes)
SNAPSHOT=1 		#ignore this parameter for now (used for fault-tolerance in maiter)
SOURCE=0		#source node for katz metric
TERMTHRESH=0.1 		#the algorithm stops when diff b/w two termchecks is less than this value
PORTION=0.1		#Fraction of samples that will be selected for update (read priter paper - q/N parameter in algorithm)
MAX_N=1024		#sample size (by default 1000 samples)
#FILTER_THRESHOLD=0.0001	#a manual threshold set to filter very small values being propagated through n/w (written to FPGA)
FILTER_THRESHOLD=0	#a manual threshold set to filter very small values being propagated through n/w (written to FPGA)
FPGA_PROCS=1		#how many processors within the FPGA ?
INTERPKT_GAP=32		#gap in clock cycles between two subsequent packet transmissions at sender side - can be adjusted to reduce transmission rate
BUFMSG=2		#not sure what this is used for (was present in original Maiter)

#setup_cluster will perform
#	1. bitstream download
#	2. automatic ip configuration in all machines
#	3. run scripts to bring up netfpga interfaces
#	4. run scripts to write to Maestro netfpga registers
perl setup_cluster.pl $WORKERS $NODES $ALGORITHM $MAX_N $FILTER_THRESHOLD $INTERPKT_GAP $FPGA_PROCS

for BUFMSG in 2
do
#deepak - correct one
sudo ./example-dsm --runner=$ALGORITHM --workers=$WORKERS --graph_dir=$GRAPH --result_dir=$RESULT --num_nodes=$NODES --snapshot_interval=$SNAPSHOT --portion=$PORTION --shortestpath_source=$SOURCE --termcheck_threshold=$TERMTHRESH > log
```


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

Please take a look at setup_cluseter.pl file to understand cluster setup.

6. Once the algorithm is run, results will be available under the folder
maestro/sw/results/<algorithm_name>/ as part files. In general, these part files have the ID of
each graph node followed by the attributed associated with the node (e.g. rank score of the webpage).


1. Specify cluster configuration in conf/mpi-cluster file

Example: Sample 1 worker cluster configuration
```
localhost slots=1
localhost slots=1
```

In this file, the first entry indicates the hostID (or IP address) of the worker.
This is followed by hostIDs (IP addresses) of all slaves in the cluster.

Example:Sample 2 worker cluster configuration
```
master_ip slots=1
master_ip slots=1
slave_ip slots=1
```

2. Ensure that all slaves are designated as CPU workers (for graph generation only).
In conf directory, update each workers ID file
Example:conf/0.conf
```
cpu    <ip_address_of_worker>  <tcp port>
```

For a 2 worker cluster, the conf files must look like
0.conf
```
cpu    <ip_address_of_worker>  <tcp port>
```

1.conf
```
cpu    <ip_address_of_worker>  <tcp port>
```

3. Run gengraph.sh
```
>sh gengraph.sh
```

4. Generated graphs are produced under maestro/sw/input/<application_graph>/ folder (e.g. maestro/sw/pr_graph) as part files.
For example, a part file would look like

Example:
```
0       2133 2713 5974 8907
1       1533 1827 3247 3804 5615 5956 7526 9568 9650 9768 9921
2       3467
3       8486
```




Youtube Screencasts
-------------------
1. [Architecture of Qsys system and Quartus Project](www.google.com)
2. [Maestro 1 worker setup](http://www.youtube.com/watch?v=Th3KHCItKj0
3. [Maestro 2 worker setup](http://www.youtube.com/watch?v=CZgDu77AdKg)
4. [Setting up Network File System](http://www.youtube.com/watch?v=i02i8_DVac0)
