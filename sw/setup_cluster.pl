#!/usr/bin/perl
# Author(s) Lekshmi Krishnan, Deepak Unnikrishnan
# Automates Maestro cluster setup

use warnings;
use Class::Struct;
use Parallel::ForkManager;
use LWP::Simple;
use List::MoreUtils qw(firstidx);

@record;

#Directory configuration
$QUARTUS_HOME="/home/deepak/altera/12.0";
$MAESTRO_BASE="/home/deepak/Desktop/maestro";
$MAESTRO_FPGA_BASE=$MAESTRO_BASE."/fpga/DE4_Ethernet_0";
$MAITER_BASE=$MAESTRO_BASE."/Maiter";

#Arguments - must be passed from pr.sh/maxval.sh
$workers	=$ARGV[0]; #Total workers+master node
$nodes		=$ARGV[1]; #total graph nodes
$algo		=$ARGV[2]; #algorithm = 0 for PR and Katz, 1 for maxval
$max_n		=$ARGV[3]; #sample size
$filter_threshold=$ARGV[4]; #filter threshold (manually set)
$interpkt_gap	=$ARGV[5]; #cycles bw packets
$fpga_proc	=$ARGV[6]; #number of processors

print "\n\n\nfpga procs = $filter_threshold\n\n\n";

$fltr_thresh_hex = unpack("L",  pack("f", $filter_threshold)); #conv fraction to hex for threshold

$algo_select = 0;
if($algo =~ /Maxval/) {
	$algo_select = 1; }

#Parse master and slave info from configuration files
open FILE, "$MAITER_BASE/conf/mpi-cluster" or die $!;
@hosts=<FILE>;
$master = (split(' ',shift(@hosts)))[0];
foreach(@hosts) {
	push(@slaves,(split(' ',$_))[0]);
}
close FILE;

#Parse .conf files to obtain nodetype info
for($i=0;$i<($workers-1);$i++) {
	print "Opening file $i.conf\n";
	open FILE, "./conf/$i.conf" or die $!;
	print "Opened file $i.conf\n";
	$line=<FILE>;
	push(@slave_types,(split(' ',$line))[0]);
}

$nodes = "0x".sprintf("%08x", $nodes);
$workers = "0x".sprintf("%08x", ($workers-1));
$max_n = "0x".sprintf("%08x", $max_n);
$filter_threshold = "0x".sprintf("%08x", $filter_threshold);
$fltr_thresh_hex = "0x".sprintf("%08x", $fltr_thresh_hex);
$interpkt_gap = "0x".sprintf("%08x", $interpkt_gap);

#print "Filter threshold = $fltr_thresh_hex\n";
#### Fix this later
#### Workaround NFS kernel crash in slave nodes - Workaround restart NFS server everytime #####
my $pm= Parallel::ForkManager->new(4);
foreach $slave (@slaves) {

	my $pid = $pm->start and next;
	#print "Master is $master and this is $_\n";
	if($slave =~/$master/i) {
		print "Skipping $slave\n";
	}
	else {
		print "Restarting NFS in $slave\n";
		system("ssh $slave sudo sh /home/deepak/Desktop/stop_nfs.sh "); 
        	system("ssh $slave sudo sh /home/deepak/Desktop/setup_nfs.sh "); 
	}
	$pm->finish;
}
$pm->wait_all_children;


#=begin comment
foreach $slave (@slaves) {
        #$command="ssh $_ /etc/init.d/avahi-daemon stop";
	
	my $pid = $pm->start and next;
	my $index = firstidx { $_ eq $slave } @slaves;

	#print "Index is $index\n";	
	print "Processing slave $slave\n";
        print "Stopping avahi daemon in $slave\n";
        system("ssh $slave service avahi-daemon stop"); 
        system("ssh $slave service smbd stop"); 

        if($slave_types[$index] eq "fpga") {
                #Download the bit file	
		print "Downloading bitstream in host ".$slaves[$index]."\n";
		system("ssh $slave $QUARTUS_HOME/quartus/bin/download_sof $MAESTRO_FPGA_BASE/DE4_Ethernet.sof");	

		#Execute script to bring up Ethernet ports
		$shard_id = $index;	
		system("ssh $slave  $QUARTUS_HOME/quartus/sopc_builder/bin/system-console --script=$MAITER_BASE/config.tcl");

		#Execute script to write Maestro parameters to NetFPGA registers 
		system("ssh $slave  $QUARTUS_HOME/quartus/sopc_builder/bin/system-console --script=$MAITER_BASE/set_num_keys.tcl $nodes $workers $shard_id $max_n $fltr_thresh_hex $interpkt_gap $fpga_proc $algo_select");
        }

	$pm->finish;

}

$pm->wait_all_children;
#=end comment
#=cut

#Bring up ethernet interfaces
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
$record{'karma'} = $obj;

$obj = MACH_RECORD->new(	name 	=> 'deepak-OptiPlex-780',
				subnet 	=> '20.1.1.0/24',
				eth1_ip => '20.1.1.2',
				fpga_ip => '20.1.1.1',
				eth0_mac=> 'bc:30:5b:a7:d2:f5',
				eth1_mac=> '00:14:d1:17:6b:e2');
$record{'deepak-OptiPlex-780'} = $obj;

$obj = MACH_RECORD->new(	name 	=> 'rcg-studio',
				subnet 	=> '30.1.1.0/24',
				eth1_ip => '30.1.1.2',
				fpga_ip => '30.1.1.1',
				eth0_mac=> '00:00:00:00:00:00',
				eth1_mac=> '00:00:00:00:00:00');
$record{'rcg-studio'} = $obj;

$obj = MACH_RECORD->new(	name 	=> 'maya',
				subnet 	=> '40.1.1.0/24',
				eth1_ip => '40.1.1.2',
				fpga_ip => '40.1.1.1',
				eth0_mac=> '00:00:00:00:00:00',
				eth1_mac=> '00:00:00:00:00:00');
$record{'maya'} = $obj;


#Each m/c must statically set IP addresses for the Ethernet interface
#to which the FPGA is connected. IP addrses is the e.g format 10.1.1.1/24
#where 24 is the netmask (google for more info). A machine must also
#set the ARP address (the mac address of the target link) to establish
#communication (e.g. 00:4e:36:23:24:23)

#The following are executed remotely from master in all slaves
#slaves and masters must be able to ssh at both root and user modes
$num_slaves = $#slaves + 1;
foreach $slave (@slaves) {

	print "\n	IP Table configuration for Machine ".$record{$slave}->name."\n\n";
	$i = 0;
	#Set interface IP
	&printExec($slave,"sudo ifconfig eth1 0"); 							#Reset eth1 IP
	#&printExec($slave,"sudo ifconfig eth1 ".$record{$slave}->eth1_ip."/24");			#Set eth1 IP
	
	&printExec($slave,"sudo route del -net ".$record{$slave}->subnet."");			#Delete any previous routes 
	&printExec($slave,"sudo route add -net ".$record{$slave}->subnet." dev eth1");			#Add route
	&printExec($slave,"sudo arp -d ".$record{$slave}->fpga_ip." -i eth1");					#Delete previous ARP entry
	&printExec($slave,"sudo arp -s ".$record{$slave}->fpga_ip." ".$netfpga_mac." dev eth1");	#Set ARP entry

	while($i<$num_slaves) {

		$slave_i = $slaves[$i];
		$i = $i+1;
		next if($slave_i=~/$slave/);

		$name=$record{$slave_i}->name;
	}
}
exit(0);

sub printExec {
	$machine = $_[0];
	$command = $_[1];
	print "[$machine]>$command\n";
	system("ssh $machine $command"); 
}
