maestro
=======

A Framework to Accelerate Iterative Algorithms with Asynchronous Accumulative Updates on FPGAs

Maestro is an open-source distributed computing framework for executing iterative algorithms in clusters that have FPGAs and general-purpose CPUs. Iterative algorithms represent a pervasive class of data mining, web search and scientific computing applications. In iterative algorithms, a final result is derived by performing repetitive computations on an input data set (e.g. PageRank, Dijkstra's shortest path). Existing techniques to parallelize such algorithms typically use software frameworks such as MapReduce and Hadoop to distribute data for an iteration across multiple CPU-based workstations in a cluster and collect per-iteration results. These platforms are marked by the need to synchronize data computations at iteration boundaries, impeding system performance. 

Maestro uses asynchronous accumulative updates to break these synchronization barriers. These updates allow for the accumulation of intermediate results for numerous data points without the need for iteration-based barriers allowing individual nodes in a cluster to independently make progress towards the final outcome. Computation is dynamically prioritized to accelerate algorithm convergence. We have implemented a general-class of iterative algorithms have been implemented on a cluster of four FPGAs. A speedup of 371X is demonstrated for a multi-node system of four Altera DE-4 boards versus an equivalent Hadoop-based CPU-workstation cluster.
