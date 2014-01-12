#!/usr/bin/perl
use Class::Struct;
$outfile = "ip_arp_tables.txt";
@record;

struct(MACH_RECORD => {
	name=>'$', 
	subnet => '$', 
	eth1_ip=>'$', 
	fpga_ip=>'$', 
	eth0_mac=>'$', 
	eth1_mac=>'$', 
});

$netfpga_mac = '00:4e:46:32:43:00';

$obj = MACH_RECORD->new(	name 	=> 'karma',
				subnet 	=> '10.1.1.0/24',
				eth1_ip => '10.1.1.2',
				fpga_ip => '10.1.1.1',
				eth0_mac=> '00:21:70:5c:2c:be',
				eth1_mac=> '00:14:d1:17:6b:ee');
push(@record,$obj);

$obj = MACH_RECORD->new(	name 	=> 'deepak-OptiPlex-780',
				subnet 	=> '20.1.1.0/24',
				eth1_ip => '20.1.1.2',
				fpga_ip => '20.1.1.1',
				eth0_mac=> 'bc:30:5b:a7:d2:f5',
				eth1_mac=> '00:14:d1:17:6b:e2');
push(@record,$obj);

$obj = MACH_RECORD->new(	name 	=> 'rcg_studio',
				subnet 	=> '30.1.1.0/24',
				eth1_ip => '30.1.1.2',
				fpga_ip => '30.1.1.1',
				eth0_mac=> '00:00:00:00:00:00',
				eth1_mac=> '00:00:00:00:00:00');
push(@record,$obj);

$obj = MACH_RECORD->new(	name 	=> 'maya',
				subnet 	=> '40.1.1.0/24',
				eth1_ip => '40.1.1.2',
				fpga_ip => '40.1.1.1',
				eth0_mac=> '00:00:00:00:00:00',
				eth1_mac=> '00:00:00:00:00:00');
push(@record,$obj);

$i = 0;

open($outfh,'>',$outfile) || die "-E- $!";

while($i<4) {
	$j = ($i + 1)%4;
	$k = ($i + 2)%4;
	$l = ($i + 3)%4;
	
	print $outfh "\n	IP-ARP Table configuration for Machine".$record[$i]->name."\n\n";

	#following block will directly call the route and arp add, hence commented
=begin comment
	#configure IP table for karma
	`sudo route add -net $record[$i]->subnet dev eth1`;
	`sudo route add -net $record[$j]->subnet dev eth0`; 
	`sudo route add -net $record[$k]->subnet dev eth0`;
	`sudo route add -net $record[$l]->subnet dev eth0`;

	#configure ARP table
	`sudo arp -s $record[$i]->fpga_ip $netfpga_mac dev eth1`;
	`sudo arp -s $record[$j]->fpga_ip $record[$j]->eth0_mac dev eth0`;
	`sudo arp -s $record[$k]->fpga_ip $record[$k]->eth0_mac dev eth0`;
	`sudo arp -s $record[$l]->fpga_ip $record[$l]->eth0_mac dev eth0`;
=end comment
=cut

	#configure IP table for karma
	$line =  "sudo route add -net ".$record[$i]->subnet." dev eth1\n";
	print $outfh $line;
	$line = "sudo route add -net ".$record[$j]->subnet." dev eth0\n"; 
	print $outfh $line;
	$line = "sudo route add -net ".$record[$k]->subnet." dev eth0\n";
	print $outfh $line;
	$line = "sudo route add -net ".$record[$l]->subnet." dev eth0\n";
	print $outfh $line;

	#configure ARP table
	$line = "sudo arp -s ".$record[$i]->fpga_ip." ".$netfpga_mac." dev eth1\n";
	print $outfh $line;
	$line = "sudo arp -s ".$record[$j]->fpga_ip." ".$record[$j]->eth0_mac." dev eth0\n";
	print $outfh $line;
	$line = "sudo arp -s ".$record[$k]->fpga_ip." ".$record[$k]->eth0_mac." dev eth0\n";
	print $outfh $line;
	$line = "sudo arp -s ".$record[$l]->fpga_ip." ".$record[$l]->eth0_mac." dev eth0\n";
	print $outfh $line;

	$i = $i+1;
}
close($outfh);
print "Tables configured. Please check output file ip_arp_tables.txt\n";
exit(0);

=begin comment
	#configure IP table for karma
	print "sudo route add -net ".$record[$i]->subnet." dev eth1\n";
	print "sudo route add -net ".$record[$j]->subnet." dev eth0\n"; 
	print "sudo route add -net ".$record[$k]->subnet." dev eth0\n";
	print "sudo route add -net ".$record[$l]->subnet." dev eth0\n";
	#configure ARP table
	print "sudo arp -s ".$record[$i]->fpga_ip." ".$netfpga_mac." dev eth1\n";
	print "sudo arp -s ".$record[$j]->fpga_ip." ".$record[$j]->eth0_mac." dev eth0\n";
	print "sudo arp -s ".$record[$k]->fpga_ip." ".$record[$k]->eth0_mac." dev eth0\n";
	print "sudo arp -s ".$record[$l]->fpga_ip." ".$record[$l]->eth0_mac." dev eth0\n";
=end comment
=cut
