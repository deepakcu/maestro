# =======================================================================================
# Project     : NetFPGA DE4
# 
# Description : Triple Speed Ethernet PCS Configuration Setting Script
#
# Revision Control Information
#
# Author      : RCG
# Revision    : 
# Date        : 
# ======================================================================================

# Define Variable
# ===============
set jtag_master [lindex [get_service_paths master] 0];

# Register Address Offset
# PCS

set PCS_REV_ADDRESS 				[expr {$MAC_3_BASE_ADDRESS + 0x244}];
set PCS_SCRATCH_ADDRESS 			[expr {$MAC_3_BASE_ADDRESS + 0x240}];
set PCS_IF_MODE_ADDRESS 			[expr {$MAC_3_BASE_ADDRESS + 0x250}];
set PCS_CONTROL_ADDRESS 			[expr {$MAC_3_BASE_ADDRESS + 0x200}];
set PCS_STATUS_ADDRESS 				[expr {$MAC_3_BASE_ADDRESS + 0x204}];
set PCS_PARTNER_ABILITY_ADDRESS 	[expr {$MAC_3_BASE_ADDRESS + 0x214}];

# Configure TSE PCS
# ==============================
# PCS Variable
set tse_pcs_register_value_temp 0;

# Starting Marvell PHY Configuration System Console
# =================================================
puts "=============================================================================="
puts "	Starting TSE PCS Configuration System Console                   			"
puts "==============================================================================\n\n"

# Open JTAG Master Service
# ========================
open_service master $jtag_master;
puts "\nInfo: Opened JTAG Master Service";

puts "\n\n\nInfo: Configure TSE PCS\n\n";

puts "TSE PCS read rev 		= [master_read_32 $jtag_master $PCS_REV_ADDRESS 1]";
puts "TSE PCS write scratch 	= $PCS_SCRATCH";
master_write_32 $jtag_master $PCS_SCRATCH_ADDRESS $PCS_SCRATCH;
puts "TSE PCS read scratch 	= [master_read_32 $jtag_master $PCS_SCRATCH_ADDRESS 1]";


# PCS if_mode
set tse_pcs_register_value_temp [master_read_32 $jtag_master $PCS_IF_MODE_ADDRESS 1];
set tse_pcs_register_value_temp [expr {$tse_pcs_register_value_temp & 0xFFE0}];

if { $PCS_SGMII_ENA == 1} {
	set tse_pcs_register_value_temp [expr {$tse_pcs_register_value_temp | 0x0001}];
}

if { $PCS_SGMII_AN == 1 } {
	set tse_pcs_register_value_temp [expr {$tse_pcs_register_value_temp | 0x0002}];
}

switch -exact -- $PCS_SGMII_ETH_SPEED {
10 { set tse_pcs_register_value_temp [expr {$tse_pcs_register_value_temp | 0x0000}] }
100 { set tse_pcs_register_value_temp [expr {$tse_pcs_register_value_temp | 0x0004}] }
1000 { set tse_pcs_register_value_temp [expr {$tse_pcs_register_value_temp | 0x0008}] }
default { 
set tse_pcs_register_value_temp [expr {$tse_pcs_register_value_temp | 0x0008}];
puts "Set PCS SGMII SPEED to default value (1000Mbps)"
}
};

if { $PCS_SGMII_HALF_DUPLEX == 1 } {
	set tse_pcs_register_value_temp [expr {$tse_pcs_register_value_temp | 0x0010}];
}

master_write_32 $jtag_master $PCS_IF_MODE_ADDRESS $tse_pcs_register_value_temp;
puts "TSE PCS read if_mode		= [master_read_32 $jtag_master $PCS_IF_MODE_ADDRESS 1]";


#### PCS Control Register
set tse_pcs_register_value_temp [master_read_32 $jtag_master $PCS_CONTROL_ADDRESS 1];
set tse_pcs_register_value_temp [expr {$tse_pcs_register_value_temp & 0xaFFF}];

if { $PCS_CTRL_ENABLE_AN == 1} {
	set tse_pcs_register_value_temp [expr {$tse_pcs_register_value_temp | 0x1300}];
}

master_write_32 $jtag_master $PCS_CONTROL_ADDRESS $tse_pcs_register_value_temp;
puts "TSE PCS read control register	= [master_read_32 $jtag_master $PCS_CONTROL_ADDRESS 1]";


# Waiting PCS Link Up
#puts "Restarting Auto-Negotiation.....";
#set tse_pcs_register_value_temp [master_read_32 $jtag_master 0x200 1];
#set tse_pcs_register_value_temp [expr {$tse_pcs_register_value_temp & 0xFdFF}];
#set tse_pcs_register_value_temp [expr {$tse_pcs_register_value_temp | 0x0200}];
#master_write_32 $jtag_master 0x200 $tse_pcs_register_value_temp;

#set tse_pcs_register_value_temp [master_read_32 $jtag_master 0x204 1];
#set tse_pcs_register_value_temp [expr {$tse_pcs_register_value_temp & 0x0020}];

#set PCS_COUNT_TEMP 0;
#set PCS_TIMEOUT 1000;
#set tse_pcs_register_value_temp 0;
#if {$PCS_CTRL_ENABLE_AN == 1} {
#	while { ($tse_pcs_register_value_temp == 0x00000000) && ($PCS_COUNT_TEMP < $PCS_TIMEOUT) } {
#		set tse_pcs_register_value_temp [master_read_32 $jtag_master 0x204 1];
    	#puts "$tse_pcs_register_value_temp";
#		set tse_pcs_register_value_temp [expr {$tse_pcs_register_value_temp & 0x0020}];
		
		#puts "$tse_pcs_register_value_temp";
		
#		if {($tse_pcs_register_value_temp == 0x00000020) && ($PCS_COUNT_TEMP < $PCS_TIMEOUT)} {
#			puts "Auto-Negotiation Completed";
#		}
		
#		set AN_COUNT_TEMP [expr {$PCS_COUNT_TEMP + 1}];
		
#		if {$AN_COUNT_TEMP == $PCS_TIMEOUT} {
#			puts "Auto-Negotiation Failed with time-out!";
#		}
#	}
#}

puts "Waiting Link Up.....";

set PCS_COUNT_TEMP 0;
set PCS_TIMEOUT 1000;
set tse_pcs_register_value_temp 0;

while { ($tse_pcs_register_value_temp == 0x00000000) && ($PCS_COUNT_TEMP < $PCS_TIMEOUT) } {
	set tse_pcs_register_value_temp [master_read_32 $jtag_master $PCS_STATUS_ADDRESS 1];
	#puts "PCS PHY ID	= [master_read_32 $jtag_master 0x204 1]";
	set tse_pcs_register_value_temp [expr {$tse_pcs_register_value_temp & 0x0004}];
	
	
	if {($tse_pcs_register_value_temp == 0x00000004) && ($PCS_COUNT_TEMP < $PCS_TIMEOUT)} {
		puts "Link is established!";
	}
	
	set PCS_COUNT_TEMP [expr {$PCS_COUNT_TEMP + 1}];
	
	if {$PCS_COUNT_TEMP == $PCS_TIMEOUT} {
		puts "Link lost with time-out!";
	}
}

#### PCS Partner_Ability for SGMII
puts "Partner Ability:\n";

set PCS_COUNT_TEMP 0;
set tse_pcs_register_value_temp 0;
while { ($tse_pcs_register_value_temp == 0x00000000) && ($PCS_COUNT_TEMP < $PCS_TIMEOUT) } {
	set tse_pcs_register_value_temp [master_read_32 $jtag_master $PCS_PARTNER_ABILITY_ADDRESS 1];
	#puts "Partner Ability	= [master_read_32 $jtag_master 0x204 1]";
	set tse_pcs_register_value_temp [expr {$tse_pcs_register_value_temp & 0x8000}];
	
	
	if {($tse_pcs_register_value_temp == 0x00008000) && ($PCS_COUNT_TEMP < $PCS_TIMEOUT)} {
		puts "Copper link interface is up.";
	}
	
	set PCS_COUNT_TEMP [expr {$PCS_COUNT_TEMP + 1}];
	
	if {$PCS_COUNT_TEMP == $PCS_TIMEOUT} {
		puts "Copper link interface is down.";
	}
}

set tse_pcs_register_value_temp [master_read_32 $jtag_master $PCS_PARTNER_ABILITY_ADDRESS 1];
set tse_pcs_register_value_temp [expr {$tse_pcs_register_value_temp & 0x1000}];

if { $tse_pcs_register_value_temp == 0x00001000} {
	puts "Copper operating in Full Duplex mode.";
} else {
	puts "Copper operating in Half Duplex mode.";
}

set tse_pcs_register_value_temp [master_read_32 $jtag_master $PCS_PARTNER_ABILITY_ADDRESS 1];
set tse_pcs_register_value_temp [expr {$tse_pcs_register_value_temp & 0x0c00}];

if { $tse_pcs_register_value_temp == 0x00000000 } {
	puts "Copper operating Speed 10Mbps";
} elseif { $tse_pcs_register_value_temp == 0x00000400 } {
	puts "Copper operating Speed 100Mbps";
} elseif { $tse_pcs_register_value_temp == 0x00000800 } {
	puts "Copper operating Speed 1000Mbps";
} else {
	puts "Copper operating Speed Error!";
}

close_service master $jtag_master;
puts "\nInfo: Closed JTAG Master Service\n\n";