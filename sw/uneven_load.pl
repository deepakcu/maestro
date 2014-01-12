#!/usr/bin/perl
use warnings;
use POSIX;

print "Usage: ./uneven_load.pl <partfile> <key distn file> <total keys> <number of workers>\n";

if($#ARGV < 3) {
	print "input all arguments...exiting...\n";
	exit(0);
}

$grinput = $ARGV[0];
$keydist = $ARGV[1];
$keytotal = $ARGV[2];
$workers = $ARGV[3];

@workerkeys = "";
$total = 0;
$shard_id = 0;
%hash;


open($infh,'<',$keydist) || die "-E- $!";

while($line = <$infh>) {
	chomp($line);
	$temp = ($keytotal/100) * $line;
	$temp = ceil($temp);	
	$total = $total + $temp; 
	if($total>$keytotal) {
		$temp = $temp + $keytotal - $total;
	}
	push(@workerkeys,$temp);
}
close($infh);
shift(@workerkeys);
print "Num of keys = $keytotal, # workers = $workers \n# keys for each worker = @workerkeys \n";


sub constructMap {
	for($shard_id=0;$shard_id<$workers;$shard_id++) {
		open (PART, '<', "subpart".$shard_id.".part") || die "-E- $!";
		$node_index=0;
		while(<PART>) {
			chomp($_);
			@array		= split(/\s+/,$_);	
			$orig_node 	= shift(@array);
			$mapped_node 	= ($node_index*$workers)+$shard_id;
			$node_index++;
			$hash{$orig_node} = $mapped_node;
		}
		close PART;
	}
}

sub doMap {
	my $workers = $_[0];
	my @nodeList;
	for($shard_id=0;$shard_id<$workers;$shard_id++) {
		open (PART,'<',"subpart".$shard_id.".part") || die "-E- $!";
		@nodeList=();
		while(<PART>) {
			chomp;
			push @nodeList, [split];
		}
		close PART;

		#loop and map
		for $i ( 0 .. $#nodeList ) {
		        for $j ( 0 .. $#{$nodeList[$i]} ) {
			    $nodeList[$i][$j] = $hash{$nodeList[$i][$j]};
		        }
    		}	

		#write mapped output 
		open PARTOUT, '>', "subpart$shard_id.out" or die "-E- $!";
		foreach $ref ( @nodeList ) {
			$src = shift(@$ref);
			print PARTOUT "$src\t@$ref \n";				
		}
		close(PARTOUT);
	}
}

sub printMap {

	open (MAPOP, '>', "map_uneven") || die "-E- $!";
	while ( my ($key, $value) = each(%hash) ) {
        	print MAPOP "$key => $value\n";
    	}
	close MAPOP;
}


sub printRevMap {
	open (MAPOP, '>', "revmap_uneven") || die "-E- $!";
	while ( my ($key, $value) = each(%rhash) ) {
        	print MAPOP "$key => $value\n";
    	}
	close MAPOP;
}

open($infh,'<',$grinput) || die "-E- $!";
while($shard_id<$workers) {
	$linecnt = 0;
	$outfile = "subpart".$shard_id.".part";
	open($outfh,'>',$outfile) || die "-E- $!";
	print "shard id is $shard_id and worker keys is $workerkeys[$shard_id]\n";
	while($linecnt<$workerkeys[$shard_id]) {
		$line = <$infh>;
		chomp($line);
		printf $outfh "$line\n";
		$linecnt = $linecnt+1;
	}
	close($outfh);
	$shard_id = $shard_id + 1;
}
close($infh);
&constructMap($workers);
&printMap();
&doMap($workers);

print "Processing done. output files are subpart0.out subpart1.out etc\n";

if($ARGV[4]) {
	%rhash = reverse %hash;
	&printRevMap();
	$procoutput = $ARGV[4];
	open ($infh,'<',$procoutput) || die "-E- $!";
	open ($outfh,'>',$procoutput.".out") || die "-E- $!";

	while($line = <$infh>) {
		chomp($line);
		@temparr = split(/\s+/,$line);
		$key = shift(@temparr);
		$mapped_key = $rhash{$key};
		$line =~ s/$key/$mapped_key/;
		print $outfh "$line\n";
	}
	close($infh);
	close($outfh);
}

exit(0);
