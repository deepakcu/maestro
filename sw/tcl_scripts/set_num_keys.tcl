#=======================================================================================
# Project     : Altera NetFPGA Design
# 
# Description : Altera NetFPGA ARP Configuration Setting Script
#
# Revision Control Information
#
# Author      : RCG
# Revision    : 
# Date        : 
# ======================================================================================

# Define Variable
# ===============
# Register Set 1
#3c:97:0e:05:86:81
#Set the number of keys for the algorithm here


#get number of nodes, number of workers and shard ID from calling script
if {$argc!=3} {
	puts "Usage set_num_keys.tcl <#nodes> <#workers> <#shardID>"
}

set nodes 		[lindex $argv 0];
set workers 		[lindex $argv 1];
set shard_id 		[lindex $argv 2];
set max_n_values	[lindex $argv 3];				
set filter_threshold 	[lindex $argv 4];				
set interpkt_gap_cycles	[lindex $argv 5];				
set max_fpga_procs	[lindex $argv 6]; #1,2,4 or 8
set algo_selection	[lindex $argv 7]; #0 for pagerank/katz, 1 for maxval

#set max_n_values	[lindex $argv 3];				0x00000080;  	#0x400->1024 in decimal
#set FILTER_THRESHOLD 	[lindex $argv 4];				0x3a83126f; #0x3727c5ac; #= 0.000010;
#set INTERPKT_GAP_CYCLES	[lindex $argv 5];				0X00000100;


set NUMBER_OF_KV_PAIRS 		$nodes; 
set NUM_WORKERS 		$workers;
set SHARD_ID 			$shard_id;
set MAX_N_VALUES 		$max_n_values;
set FILTER_THRESHOLD 		0x38d1b717; #0x3727c5ac; #0x38d1b717; #$filter_threshold;
set INTERPKT_GAP_CYCLES		$interpkt_gap_cycles;
set MAX_FPGA_PROCS		$max_fpga_procs;
set ALGO_SELECTION		$algo_selection;

set NUMBER_OF_KV_PAIRS_PER_WORKER	[expr $NUMBER_OF_KV_PAIRS/$NUM_WORKERS]; # changes for multinode

# Define Variable
# ===============
# Register Set 1

set jtag_master [lindex [get_service_paths master] 0];

if 1 {
# Register Address Offset
# Dest IP
set ROUTER_OP_LUT_ARP_TABLE_ENTRY_NEXT_HOP_IP_REG 							0x80001a0;
set ROUTER_OP_LUT_ARP_TABLE_ENTRY_MAC_HI_REG 								0x8000180;
set ROUTER_OP_LUT_ARP_TABLE_ENTRY_MAC_LO_REG 								0x8000190;
}

if 1 {
# Register Address Offset
# LPM
set ROUTER_OP_LUT_ROUTE_TABLE_ENTRY_IP_REG 					0x8000120;
set ROUTER_OP_LUT_ROUTE_TABLE_ENTRY_MASK_REG 					0x8000130;
set ROUTER_OP_LUT_ROUTE_TABLE_ENTRY_NEXT_HOP_IP_REG 				0x8000140;
set ROUTER_OP_LUT_ROUTE_TABLE_ENTRY_OUTPUT_PORT_REG 				0x8000150;
set ROUTER_OP_LUT_ROUTE_TABLE_RD_ADDR_REG					0x8000160;				
}

set ROUTER_OP_LUT_DST_IP_FILTER_TABLE_ENTRY_IP_REG                              0x80001d0;

# Starting Altera NetFPGA ARP Configuration System Console
# =================================================
puts "=============================================================================="
puts "	Configure Maestro FPGA parameters                   			"
puts "==============================================================================\n\n"

# Open JTAG Master Service
# ========================
open_service master $jtag_master;

# Writing the first set of Registers
#master_write_32 $jtag_master $ROUTER_OP_LUT_ARP_TABLE_ENTRY_NEXT_HOP_IP_REG $NEXT_HOP_IP_REG_01;
master_write_32 $jtag_master $ROUTER_OP_LUT_ARP_TABLE_ENTRY_NEXT_HOP_IP_REG $NUMBER_OF_KV_PAIRS_PER_WORKER;
master_write_32 $jtag_master $ROUTER_OP_LUT_ARP_TABLE_ENTRY_MAC_HI_REG $SHARD_ID;
master_write_32 $jtag_master $ROUTER_OP_LUT_ARP_TABLE_ENTRY_MAC_LO_REG $NUM_WORKERS;
master_write_32 $jtag_master $ROUTER_OP_LUT_ROUTE_TABLE_ENTRY_IP_REG $MAX_N_VALUES;
master_write_32 $jtag_master $ROUTER_OP_LUT_ROUTE_TABLE_ENTRY_MASK_REG $FILTER_THRESHOLD;
master_write_32 $jtag_master $ROUTER_OP_LUT_ROUTE_TABLE_ENTRY_NEXT_HOP_IP_REG $INTERPKT_GAP_CYCLES;

master_write_32 $jtag_master $ROUTER_OP_LUT_ROUTE_TABLE_ENTRY_OUTPUT_PORT_REG $MAX_FPGA_PROCS;
master_write_32 $jtag_master $ROUTER_OP_LUT_DST_IP_FILTER_TABLE_ENTRY_IP_REG $ALGO_SELECTION;


#Read values for sanity check
puts "Total keys=\t\t [master_read_32 $jtag_master $ROUTER_OP_LUT_ARP_TABLE_ENTRY_NEXT_HOP_IP_REG 1]"; #This register will be used to store the number of keys
puts "Shard ID=\t\t [master_read_32 $jtag_master $ROUTER_OP_LUT_ARP_TABLE_ENTRY_MAC_HI_REG 1]";
puts "Total workers=\t\t [master_read_32 $jtag_master $ROUTER_OP_LUT_ARP_TABLE_ENTRY_MAC_LO_REG 1]";
puts "Sample size=\t\t [master_read_32 $jtag_master $ROUTER_OP_LUT_ROUTE_TABLE_ENTRY_IP_REG 1]"; 
puts "Filter threshold=\t\t [master_read_32 $jtag_master $ROUTER_OP_LUT_ROUTE_TABLE_ENTRY_MASK_REG 1]"; 
puts "Interpkt gap cycles=\t\t [master_read_32 $jtag_master $ROUTER_OP_LUT_ROUTE_TABLE_ENTRY_NEXT_HOP_IP_REG 1]"; 
puts "Max fpga procs=\t\t [master_read_32 $jtag_master $ROUTER_OP_LUT_ROUTE_TABLE_ENTRY_OUTPUT_PORT_REG 1]"; 
puts "Algo selection=\t\t [master_read_32 $jtag_master $ROUTER_OP_LUT_DST_IP_FILTER_TABLE_ENTRY_IP_REG 1]"; 



close_service master $jtag_master;
puts "\nInfo: Closed JTAG Master Service\n\n";
