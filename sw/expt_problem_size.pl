#!/usr/bin/perl
use warnings;

my $algo_dir="input/pr_graph";
my @dataset_files=('100k','200k','300k','400k','500k','600k','700k','800k','900k','1000k','1100k','1200k','1300k');

foreach $dataset (@dataset_files) {
	system("cp dataset/$dataset $algo_dir/part0");
	system("sudo sh pr.sh ");
}


