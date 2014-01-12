#!/usr/bin/perl
use warnings;


=begin comment
Summary:	Splits original graph into W equal parts (W=#workers)
		where each worker receives node ID % workers
		
Usage:		./split.pl	<number of workers>	

Output:		Produces parts in part0.p, part1.p etc.
=end comment
=cut



#Generate partition data outout from .out Chaco output file. Use info to generate
#individual partitions
$partfile = $ARGV[0];
$workers  = $ARGV[1];
$EXPT 	  = $ARGV[2];

#$partfile =~ /dataset\/[a-z]+\/.*worker\/(.*k)/;
$partfile =~ /([0-9]+)/;
$name = $1."k";
print "$name\n";

print "Usage: split.pl <partition output file> <num workers> <algorithm>\n";

#Input file must be generated using gengraph.sh
#Open original graph file
open GRAPH,'<',$partfile || die "-E- $!";

#################Determine reciprocal edges####################
#parse into 2D array
my @graphNodeList;
while(<GRAPH>) {
	chomp;
	push @graphNodeList, [split];
}
close(GRAPH);


my @filehandles;
#make array of 10 file handles
for($i=0; $i<$workers; $i++)
{
    #localize the file glob, so FILE is unique to
    #    the inner loop.
    local *FILE;
    #open(FILE,'>', "./dataset/$EXPT/$workers"."worker/$name.$i") || die;
    open(FILE,'>', "../dataset/$EXPT/$workers"."worker/$name.$i") || die;
    #push the typeglobe to the end of the array
    push(@filehandles, *FILE);
}

for $ref ( @graphNodeList ) {
	@node 	= @$ref;
	$src 	= shift(@node);
	$worker = $src%$workers;
	#print "Src = $src Worker is $worker \n";
       	
	$F=$filehandles[$worker];
	#print $F "@$ref \n";
	print $F "$src\t@node \n";
}


#loop through the file handles.
#   treat $file as a normal file handle
foreach $file (@filehandles)
{
    #print $file "File $count";
    close $file;
    #$count++;
}

