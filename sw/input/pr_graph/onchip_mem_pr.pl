#!/usr/bin/perl
use POSIX;
## -------------------------------------------------------------------------------
## Filename: memory.pl
## Author  : Lekshmi G Krishnan
## Date    : 1st Sept 2012
## Desc    : This PERL Script will process an input file of the format
##	     Address || <32 bit data> and generates a memory initialization
##	     file for onchip memory. See description below. This script outputs 
##	     all numbers in hexadecimal format.
## -------------------------------------------------------------------------------

use warnings;

## -------------------------------------------------------------------------------
## Create an output file
## -------------------------------------------------------------------------------

$infile = $ARGV[0];
$outfile = "./maxval.mif";
$tempfile = "./temp.mif";
$key_cnt = $ARGV[1];

## -------------------------------------------------------------------------------
## Subroutine to print header statements to Memory Initialization file 
## -------------------------------------------------------------------------------

sub printheaders() {
	$header = 
#	"-- Copyright (C) 1991-2012 Altera Corporation\n".
#	"-- Your use of Altera Corporation's design tools, logic functions \n".
#	"-- and other software and tools, and its AMPP partner logic \n".
#	"-- functions, and any output files from any of the foregoing \n".
#	"-- (including device programming or simulation files), and any \n".
#	"-- associated documentation or information are expressly subject \n".
#	"-- to the terms and conditions of the Altera Program License \n".
#	"-- Subscription Agreement, Altera MegaCore Function License \n".
#	"-- Agreement, or other applicable license agreement, including, \n".
#	"-- without limitation, that your use is for the sole purpose of \n".
#	"-- programming logic devices manufactured by Altera and sold by \n".
#	"-- Altera or its authorized distributors.  Please refer to the \n".
#	"-- applicable agreement for further details.\n\n".
#	"-- Quartus II generated Memory Initialization File (.mif)\n\n".
	"WIDTH=256;\n".
	"DEPTH=128;\n\n".
	"ADDRESS_RADIX=HEX;\n".
	"DATA_RADIX=HEX;\n\n".
	"CONTENT BEGIN\n";

	printf $out_fh $header;
}

## -------------------------------------------------------------------------------
## Read input and output files
## -------------------------------------------------------------------------------
open ($in_fh, '<', "$infile") || die "-E- $!";
open ($out_fh, '>', "$tempfile") || die "outfile already exists\n";

## -------------------------------------------------------------------------------
## To read 8 memory locations, concatenate the data into 256 bit word,
##	and write to memory address locations in following format 
## ""    Address   : <256 bit data>; ""
## "" Address + 32 : <256 bit data>; "" 
## -------------------------------------------------------------------------------

$loop_var = 0;
$data_val = ("");
$addr = "00000000";

printheaders();

$depth = 0;
while($line = <$in_fh>) {
	@temp_array = split(/\s+/,$line);
	shift(@temp_array); 
	$temp_val = sprintf("%08x",$temp_array[0]);
	$loop_var++;
	if(($loop_var == 3) && ($key_cnt != 0)) {
		my $packed_float = pack "f", $temp_array[0];
		my $hex_float  = sprintf("%08x", 
                       unpack("L",  pack("f", $temp_array[0]))); 
		$temp_val = $hex_float;
	}
	if(($loop_var == 4) && ($key_cnt != 0)) { #print priority field in hex
		my $packed_float = pack "f", $temp_array[0];
		my $hex_float  = sprintf("%08x", 
                      unpack("L",  pack("f", $temp_array[0]))); 
		$temp_val = $hex_float;
	}
	if(($loop_var == 5)&&($key_cnt != 0)) {
		$temp_val = ($temp_array[0] / 32);	
		$temp_val = sprintf("%08x",$temp_val);
	}
	if(($loop_var == 7) && ($key_cnt != 0)) {
		my $packed_float = pack "f", $temp_array[0];
		my $hex_float  = sprintf("%08x", 
                       unpack("L",  pack("f", $temp_array[0]))); 
		$temp_val = $hex_float;
		$key_cnt = $key_cnt - 1;
	}
#	$data_val = $data_val.$temp_val;
	$data_val = $temp_val.$data_val;

	if($loop_var == 8) {
		printf $out_fh "$addr : $data_val;\n";
		$depth = $depth + 1;
		$data_val = ("");
		$loop_var = 0;
		$addr = sprintf("%08x",((hex $addr) + 1));
	}
}
if($loop_var != 0) {
	$remdr = 8 - $loop_var;
	while($remdr != 0) {
#		$data_val = $data_val."ffffffff";
		$data_val = "ffffffff".$data_val;
		$remdr = $remdr - 1;
	}
	printf $out_fh "$addr : $data_val;\n";
	$depth = $depth + 1;
}
print $out_fh "END;";

close($in_fh);
close($out_fh);

$pwrof2 = log($depth)/log(2);
$pwrof2 = ceil($pwrof2);
$depth = 2 ** $pwrof2;

open ($out_fh, '>', "$outfile") || die "outfile already exists\n";
open ($in_fh, '<', "$tempfile") || die "outfile already exists\n";
while($line = <$in_fh>){
	$line =~ s/DEPTH=128/DEPTH=$depth/g;
	printf $out_fh $line;
}
close($in_fh);
close($out_fh);

exit(0);
