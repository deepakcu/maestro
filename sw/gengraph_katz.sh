WORKERS=$1
NODES=$2
LOGN_WEIGHT_M=0			
LOGN_WEIGHT_S=1.0
WEIGHTGEN=1

UPLOADDFS=false
HADOOPPATH=/home/yzhang/hadoop-priter-0.1/bin/hadoop


#:<<BLOCK
#for katz
GRAPH=dataset/katz
LOGN_DEGREE_M=-0.5
LOGN_DEGREE_S=2.3
WEIGHTED=false
#BLOCK

./example-dsm --runner=GraphGen --workers=$WORKERS --graph_dir=$GRAPH --graph_size=$NODES --logn_degree_m=$LOGN_DEGREE_M --logn_degree_s=$LOGN_DEGREE_S --logn_weight_m=$LOGN_WEIGHT_M --logn_weight_s=$LOGN_WEIGHT_S --weighted=$WEIGHTED --weightgen_method=$WEIGHTGEN --uploadDFS=$UPLOADDFS --dfs_path=$GRAPH --hadoop_path=$HADOOPPATH --v=1


