#!/usr/bin/perl

## -------------------------------------------------------------------------------
## Filename: memory.pl
## Author  : Lekshmi G Krishnan
## Date    : 1st Sept 2012
## Desc    : This PERL Script will process an input Key || Value formatted file 
##	     and generates a ddr input file of the form Address || Data. See 
##	     description below. This script outputs all numbers in decimal format.
## -------------------------------------------------------------------------------

use warnings;

## -------------------------------------------------------------------------------
## Create an output file and a temporary output file
## -------------------------------------------------------------------------------

$infile = $ARGV[0];
$num_workers = $ARGV[1];
$outfile = "./maxval.txt.fmt";
$temp_file = "./val_mem.txt.fmt";

## -------------------------------------------------------------------------------
## Read input and output files
## -------------------------------------------------------------------------------

if(!$ARGV[0]) {
	print "Give an input file\n";
	exit(0);
}

$cpucount = 0;
while($cpucount < $num_workers){
print "The file being processed is $infile\n";

$infile = $ARGV[0].$cpucount.".p";

open ($in_fh, '<', "$infile") || die "-E- $!";
open ($out_fh, '>', "$outfile") || die "outfile already exists\n";
open ($temp_out, '>', "$temp_file") || die "cant create temp out file\n";

print "The file being processed is $infile\n";

## -------------------------------------------------------------------------------
## Determine total number of keys 
## -------------------------------------------------------------------------------
$count = 0;
while (<$in_fh>) {
	$count++;
}

## -------------------------------------------------------------------------------
## To read key and append to out file in format 
## "" Address || key value delta_val priority value_ptr size 0 0 ""
## Create memory format of the type "" Address key "",  
##				    "" Address value ""
##				    "" Address delta_val ""    etc
## -------------------------------------------------------------------------------
$key_addr = "00000000";
open ($in_fh, '<', "$infile") || die "-E- $!";

$val_addr = sprintf("%08d",($key_addr + ($count * 8 * 4))); #dpk
print "Values are at address starting at $val_addr\n"; 

while($line = <$in_fh>) {
	chomp($line);
	@temp_array = split(/\s+/,$line);
	@self_link_array = split(/\s+/,$line);

	shift(@self_link_array);
	$self_links=0;
	foreach $link (@self_link_array) {
		if($link % $num_workers==$cpucount) {
			$self_links = $self_links + 1;
		}
	}

	$value = 0.2;
	$dfactor = (0.8)/($#temp_array);
	#@write_arr = ($temp_array[0],"0","0",$temp_array[0],$val_addr,$#temp_array,"0","0");	
	#dpk - for maxval example, initialize val as key and delta val as key
#	@write_arr = ($temp_array[0],$temp_array[0],$temp_array[0],$temp_array[0],$val_addr,$#temp_array,"0","0");	
#	@write_arr = ($temp_array[0], $value, "0", $temp_array[0],$val_addr,$#temp_array,$dfactor,"0");	

#	@write_arr = ($temp_array[0], $temp_array[0], "0", $temp_array[0],$val_addr,$#temp_array,"0",$#temp_array);	 #connected components
	@write_arr = ($temp_array[0], "0", $value, $temp_array[0],$val_addr,$#temp_array,$dfactor,$self_links);	#pagerank/katz
#	@write_arr = ($temp_array[0],$value, $value,$temp_array[0],$val_addr,$#temp_array,$dfactor,"0");	

	$loop_var = 0;
	while($loop_var < 8) {
		printf $out_fh "$key_addr $write_arr[$loop_var]\n";
		$loop_var++;
		$key_addr = sprintf("%08d",($key_addr + 4)); #dpk
	}

## -----------------------------------------------------------------------
## Read and append value of each key to the corresponding address pointers
## Memory organization desired is "" Address || val1 val2 ... FFFFFFFF FFFFFFFF ""
##		 	     ""	 Address + 8 || val1 val2 val3 ...     FFFFFFFF ""
## Print to file as previous format
## -----------------------------------------------------------------------

	$remdr = 8 - ($#temp_array % 8);

	shift(@temp_array);
	foreach $entry (@temp_array) {
		printf $temp_out "$val_addr $entry\n";
		$val_addr = sprintf("%08d",($val_addr + 4)); #dpk
	}
	while($remdr != 0 && $remdr!=8) {
		printf $temp_out "$val_addr 4294967295\n"; 
		$val_addr = sprintf("%08d",($val_addr + 4)); #dpk
		$remdr = $remdr - 1;
	}
}

close($in_fh);
close($out_fh);
close($temp_out);

## -------------------------------------------------------------------------------
## Append temp out file to original output file 
## -------------------------------------------------------------------------------

open ($out_fh, '>>', "$outfile") || die "outfile already exists\n";
open ($temp_out, '<', "$temp_file") || die "cant create temp out file\n";

while($line = <$temp_out>){
	chomp($line);
	printf $out_fh "$line\n";
}

close($out_fh);
close($temp_out);
#unlink($temp_file);

## -----------------------------------------------------------------------
## To generate onchip memory MIF file
## -----------------------------------------------------------------------

`./onchip_mem_pr.pl $outfile $count`;

## -----------------------------------------------------------------------
## Rename outfile to <input_file>.mif
## -----------------------------------------------------------------------

$filename = "./".$infile.".fmt";
rename($outfile,$filename);
print "Formatting done. Your output file is -- $filename -- Thank you.\n";

@newname = split(/\./,$infile);
$mifname = "./".$newname[0].".mif";
rename("./maxval.mif",$mifname);
print "Onchip memory formatting done. Your output file is -- $mifname -- Thank you.\n";

$cpucount ++;
}

exit(0);
