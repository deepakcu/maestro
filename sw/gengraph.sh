WORKERS=2 #total workers = masters+slaves
NODES=10000 #total graph nodes
LOGN_WEIGHT_M=0			
LOGN_WEIGHT_S=1.0 #sigma
WEIGHTGEN=1

UPLOADDFS=false
HADOOPPATH=/home/yzhang/hadoop-priter-0.1/bin/hadoop


:<<BLOCK
#for sp
GRAPH=input/maxval_graph
LOGN_DEGREE_M=-0.5
LOGN_DEGREE_S=2.3
LOGN_WEIGHT_M=0			
LOGN_WEIGHT_S=1.0
WEIGHTED=false
WEIGHTGEN=2			#1/logn(m,s)
BLOCK

:<<BLOCK
#for sp
GRAPH=input/sp_graph
LOGN_DEGREE_M=-0.5
LOGN_DEGREE_S=2.3
LOGN_WEIGHT_M=0			
LOGN_WEIGHT_S=1.0
WEIGHTED=true
WEIGHTGEN=2			#1/logn(m,s)
BLOCK

#:<<BLOCK #uncomment the block
#for pr
GRAPH=input/pr_graph
LOGN_DEGREE_M=-0.5
LOGN_DEGREE_S=2.3
WEIGHTED=false
#BLOCK

:<<BLOCK
#for ad
GRAPH=input/ad_graph
LOGN_DEGREE_M=-0.5
LOGN_DEGREE_S=2.3
LOGN_WEIGHT_M=0.4		
LOGN_WEIGHT_S=0.8
WEIGHTED=true
WEIGHTGEN=1			#log(1+logn(m,s))
BLOCK

:<<BLOCK
#for katz
GRAPH=input/katz_graph
LOGN_DEGREE_M=-0.5
LOGN_DEGREE_S=2.3
WEIGHTED=false
BLOCK

./example-dsm --runner=GraphGen --workers=$WORKERS --graph_dir=$GRAPH --graph_size=$NODES --logn_degree_m=$LOGN_DEGREE_M --logn_degree_s=$LOGN_DEGREE_S --logn_weight_m=$LOGN_WEIGHT_M --logn_weight_s=$LOGN_WEIGHT_S --weighted=$WEIGHTED --weightgen_method=$WEIGHTGEN --uploadDFS=$UPLOADDFS --dfs_path=$GRAPH --hadoop_path=$HADOOPPATH --v=1


