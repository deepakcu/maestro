ALGORITHM=Katz
WORKERS=5
GRAPH=input/katz_graph
RESULT=result/katz
NODES=5200000
SNAPSHOT=1 #Deepak changed from 10 to 1
SOURCE=0
TERMTHRESH=0.1 #Deepak changed from 0 to 1 (improves response time)
#deepak - automatically adjust portion size according to graph size
PORTION_SIZE_IN_FPGA=50

PORTION=0.1
#PORTION=$(awk -v fpga_portion=$PORTION_SIZE_IN_FPGA -v nodes=$NODES -v workers=$WORKERS 'BEGIN { print fpga_portion/(nodes/(workers-1)) }')
#Deepak try adjusting portion size in CPU
#PORTION=0.05
MAX_N=1024
FILTER_THRESHOLD=0
FPGA_PROCS=7
INTERPKT_GAP=9000
echo "Portion is $PORTION"
#PORTION=0.0005
#PORTION=0.05
#BUFMSG=1000
BUFMSG=2

DOWNLOAD="true"
NIF="true"

while getopts ":dn" opt; do
  case $opt in
    d)
      echo "Actions = Download+N/W Interface UP" >&2
      DOWNLOAD="true" 
      NIF="true"     
      ;;
    n)
      echo "Action = N/W Interface UP" >&2
      DOWNLOAD="false";
      NIF="true"
      ;;

    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done
#perl setup_cluster.pl $WORKERS $NODES $ALGORITHM $DOWNLOAD $NIF $MAX_N $FILTER_THRESHOLD $INTERPKT_GAP $SORT_SEL $FPGA_PROCS
perl setup_cluster.pl $WORKERS $NODES $ALGORITHM $DOWNLOAD $NIF $MAX_N $FILTER_THRESHOLD $INTERPKT_GAP 128 $FPGA_PROCS
for BUFMSG in 2
do
./example-dsm --runner=$ALGORITHM --workers=$WORKERS --graph_dir=$GRAPH --result_dir=$RESULT --num_nodes=$NODES --snapshot_interval=$SNAPSHOT --portion=$PORTION --katz_source=$SOURCE --termcheck_threshold=$TERMTHRESH --bufmsg=$BUFMSG  --v=0 > log

#cp track_log logs/m${ALGORITHM}-${NODES}-${PORTION}-${BUFMSG}
done
