ALGORITHM=Shortestpath
WORKERS=2
GRAPH=input/sp_graph
RESULT=result/sp
NODES=400000
SNAPSHOT=1 #Deepak changed from 10 to 1
SOURCE=0
TERMTHRESH=0
PORTION=0.05
BUFMSG=1000

for BUFMSG in 10000
do
./example-dsm --runner=$ALGORITHM --workers=$WORKERS --graph_dir=$GRAPH --result_dir=$RESULT --num_nodes=$NODES --snapshot_interval=$SNAPSHOT --portion=$PORTION --shortestpath_source=$SOURCE --termcheck_threshold=$TERMTHRESH --bufmsg=$BUFMSG --v=3 > log

cp track_log logs/m${ALGORITHM}-${NODES}-${PORTION}-${BUFMSG}
done
