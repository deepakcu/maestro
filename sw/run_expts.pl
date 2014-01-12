#!/usr/bin/perl

$infile  = "expt_config";
$outfile = "expt_results";
open($outfh,'>',$outfile) || die "-E- $!";
open($infh,'<',$infile) || die "-E- $!";

while($line = <$infh>) {
	chomp($line);
	next if($line =~ /^#/);
	$line =~ /([A-Z_]+)\s+\=\(([^)]+)\)/;
	my($param,$val) = ($1,$2);
	$val =~ s/\'//g;
	if($param =~ /PORTION/) {
		$PORTION = $val; }
	if($param =~ /TERM_THRESHOLD/) {
		$TERMTHRESH = $val; }
	if($param =~ /TERM_CHECK_INTERVAL/) {
		$iamnotused1 = $val; }
	if($param =~ /FPGA_PROCESSORS/) {
		$FPGA_PROCS = $val; }
	if($param eq "N") {
		$MAX_N = $val; }
	if($param eq "K") {
		$SORT_SEL = $val; }
	if($param =~ /FILTER_THRESHOLD/) {
		$FILTER_THRESHOLD = $val; }
	if($param =~ /GAP_CYCLES/) {
		$INTERPKT_GAP = $val; }
	if($param =~ /WORKERS/) {
		$WORKERS = $val+1; }
	if($param =~ /TYPE/) {
		@types = split(/,/,$val); }
	if($param =~ /ALGO/) {
		@algos = split(/,/,$val); 
		print "@algos \n"; }
	if($param =~ /DATASET/) {
		@datasets = split(/,/,$val); 
		print "@datasets \n"; }
}

foreach $TYPE (@types) {
    
    $infile = "./conf/0.conf";
    open($confh,'>',$infile) || die "-E- $!";
    printf $confh "$TYPE\t10.1.1.1\t400";
    close($confh);


$infile = "log";
foreach $ALGORITHM (@algos) {

    if($ALGORITHM =~ /Pagerank/) {
    	$EXPT = "pr"; }
    if($ALGORITHM =~ /Maxval/) {
    	$EXPT = "maxval"; }
    if($ALGORITHM =~ /Katz/) {
    	$EXPT = "katz"; }

    foreach $DATASET (@datasets) {

	system("cp ./dataset/$DATASET ./input/$EXPT\_graph/part0");

	$NODES = $DATASET;
	if($DATASET =~ /k/) {
		$NODES = $NODES."000";
		$NODES =~ s/k//g;
	}

	##---- pr.sh begin ----##
	#$ALGORITHM	=
	#$WORKERS	=
	#$NODES		=
	#$PORTION	=

	$GRAPH		="input/$EXPT\_graph";
	$RESULT		="result/$EXPT";
	$SNAPSHOT	=1; #Deepak changed from 10 to 1
	$SOURCE		=0;
	#$TERMTHRESH	=; #Deepak changed from 0 to 1 (improves response time)
	$PORTION_SIZE_IN_FPGA=50;

	$BUFMSG=2;
	$DOWNLOAD="true";
	$NIF="true";

	system("perl setup_cluster.pl $WORKERS $NODES $ALGORITHM $DOWNLOAD $NIF $MAX_N $FILTER_THRESHOLD $INTERPKT_GAP $SORT_SEL $FPGA_PROCS");

	system("./example-dsm --runner=$ALGORITHM --workers=$WORKERS --graph_dir=$GRAPH --result_dir=$RESULT --num_nodes=$NODES --snapshot_interval=$SNAPSHOT --portion=$PORTION --shortestpath_source=$SOURCE --termcheck_threshold=$TERMTHRESH --bufmsg=$BUFMSG --v=0 > log");
	#system("cp log run_expt_results/m${ALGORITHM}-${NODES}-${PORTION}");

	##---- pr.sh end ----##

	open($infh,'<',$infile) || die "-E- $!";
	print $outfh "\nRUN RESULTS OF $ALGORITHM FOR TYPE=$TYPE, NODES=$NODES, PORTION=$PORTION, WORKERS=$WORKERS";
	if($TYPE =~ /fpga/) {
		print $outfh ", K=$SORT_SEL, FPGA PROCS=$FPGA_PROCS \n"; }
	else {
		print $outfh "\n"; }
	while (<$infh>) { 
		chomp($_);
		if($_ =~ /TCHECK ([0-9.]+).*current ([0-9.]+).*/) {
			printf $outfh "%.3f		%.3f \n",$1,$2; }
		if($_ =~ /STAT MaiterKernel2:map--> total_time: ([0-9.]+)/) {
			printf $outfh "Total map time = %.3f \n",$1; }
		if($_ =~ /STAT MaiterKernel1:run--> total_time: ([0-9.]+)/) {
			printf $outfh "Total load time = %.3f \n",$1; }
		if($_ =~ /STAT MaiterKernel3:run--> total_time: ([0-9.]+)/) {
			printf $outfh "Total run time = %.3f \n",$1; }
	}
	close($infh);

    }
}
}
exit(0);
