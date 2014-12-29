Maestro
=======

A Framework to Accelerate Iterative Algorithms with Asynchronous Accumulative Updates on FPGAs

What is Maestro?
----------------
Maestro is a distributed cluster computing framework to accelerate iterative algorithms using FPGAs. 

Iterative Algorithms
--------------------
Iterative algorithms represent a pervasive class of data mining, web search and scientific computing applications. In iterative algorithms, a final result is derived by performing repetitive computations on an input data set (e.g. PageRank, Dijkstra's shortest path). Existing techniques to parallelize such algorithms  use software frameworks such as MapReduce and Hadoop to distribute data for an iteration across multiple CPU-based workstations in a cluster and collect per-iteration results. These platforms are marked by the need to synchronize data computations at iteration boundaries, impeding system performance. 

Why Maestro?
------------
Maestro uses asynchronous accumulative updates to break these synchronization barriers. These updates allow for the accumulation of intermediate results for numerous data points without the need for iteration-based barriers allowing individual nodes in a cluster to independently make progress towards the final outcome. Computation is dynamically prioritized to accelerate algorithm convergence. 

Maestro Speedup
---------------
We have implemented a general-class of iterative algorithms on a cluster of four Altera DE-4 FPGAs. Our experiments show that Maestro cluster of 4 Altera DE-4 FPGA boards offers upto 140X speedup over Hadoop. 

Obtaining Source Code
---------------------
Please follow instructions in the INSTALL file

License
-------
Maestro is licensed under Apache 2.0 license
