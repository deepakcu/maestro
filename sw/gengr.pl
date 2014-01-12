#!/usr/bin/perl


@algos = ("pr","maxval","katz");
@workers = (1,2,4);

@DATASETS = ('100k','200k','300k','400k','500k','600k','700k','800k','900k','1000k','1100k','1200k','1300k');
#@DATASET1 = ('200k','400k','600k','800k','1000k','1200k','1400k','1600k','1800k','2000k','2200k','2400k','2600k');
@DATASET1 = ('2600k');
@DATASET2 = ('400k','800k','1200k','1600k','2000k','2400k','2800k','3200k','3600k','4000k','4400k','4800k','5200k');

foreach $EXPT (@algos) {

#	foreach $worker(@workers) {

	foreach $dataset (@DATASET1) {
		$nodes = $dataset;
		if($dataset =~ /k/) {
			$nodes = $nodes."000";
			$nodes =~ s/k//g;
		}
		$shard = $worker + 1;
#		system("sudo sh gengraph_$EXPT.sh 2 $nodes");
		#$i = 0;
		#while($i < $worker) {
		#	print "	$i\n";
		#system("mv ./input/$EXPT/part$worker ./dataset/$EXPT/$worker.worker/.");
#		system("mv ./dataset/$EXPT/part0 ./dataset/$EXPT/4worker/$dataset");
		#	$i = $i + 1;
		#}
		system("./split_workers.pl ./dataset/$EXPT/2worker/$dataset 2 $EXPT");
	}
#	system("rm gengraph_$EXPT.sh");

}


exit(0);




sub printEnd {
	
	open($outfh1,'>>',"gengraph_$_[0].sh") || die "-E- $!";

	if($_[0] =~ /pr/) {
		print $outfh1 "GRAPH=input/pr_graph\n";
		print $outfh1 "LOGN_DEGREE_M=-0.5\n";
		print $outfh1 "LOGN_DEGREE_S=2.3\n";
		print $outfh1 "WEIGHTED=false\n";
	}

	if($_[0] =~ /maxval/) {
	$line = "GRAPH=input/maxval_graph\n".
		"LOGN_DEGREE_M=-0.5\n".
		"LOGN_DEGREE_S=2.3\n".
		"LOGN_WEIGHT_M=0	\n".		
		"LOGN_WEIGHT_S=1.0\n".
		"WEIGHTED=false\n".
		"WEIGHTGEN=2			#1/logn(m,s)\n";
	print $outfh1 $line;
	}

	if($_[0] =~ /katz/) {
	$line = "GRAPH=input/katz_graph\n".
		"LOGN_DEGREE_M=-0.5\n".
		"LOGN_DEGREE_S=2.3\n".
		"WEIGHTED=false\n";
	print $outfh1 $line;
	}

	print $outfh1 './example-dsm --runner=GraphGen --workers=$WORKERS --graph_dir=$GRAPH --graph_size=$NODES --logn_degree_m=$LOGN_DEGREE_M --logn_degree_s=$LOGN_DEGREE_S --logn_weight_m=$LOGN_WEIGHT_M --logn_weight_s=$LOGN_WEIGHT_S --weighted=$WEIGHTED --weightgen_method=$WEIGHTGEN --uploadDFS=$UPLOADDFS --dfs_path=$GRAPH --hadoop_path=$HADOOPPATH --v=1';

	close($outfh1);
}

