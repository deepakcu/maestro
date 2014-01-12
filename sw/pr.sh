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
#cp track_log logs/m${ALGORITHM}-${NODES}-${PORTION}-${BUFMSG}
echo "Hello"
done
