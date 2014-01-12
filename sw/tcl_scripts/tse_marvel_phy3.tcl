# =======================================================================================
# Project     : NetFPGA DE4
# 
# Description :  Marvel PHY Configuration Setting Script
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
# PHY

set PHY_CONFIG_ADDRESS 					[expr {$MAC_3_BASE_ADDRESS + 0x40}];  
set PHY_CONTROL_ADDRESS 				[expr {$MAC_3_BASE_ADDRESS + 0x280}];
set PHY_ADVERTISEMENT_ADDRESS 			[expr {$MAC_3_BASE_ADDRESS + 0x290}];
set PHY_1000_BASE_T_ADDRESS 			[expr {$MAC_3_BASE_ADDRESS + 0x2A4}];
set PHY_SPECIFIC_CONTROL_ADDRESS 		[expr {$MAC_3_BASE_ADDRESS + 0x2C0}];
set PHY_EXD_SPECIFIC_STATUS_ADDRESS 	[expr {$MAC_3_BASE_ADDRESS + 0x2EC}];
set PHY_SPECIFIC_STATUS_ADDRESS 		[expr {$MAC_3_BASE_ADDRESS + 0x2C4}];

# PHY Variable
set quad_phy_register_value_temp 0; 

# Starting Marvell PHY Configuration System Console
# =================================================
puts "=============================================================================="
puts "          Starting Marvell PHY Configuration System Console                   "
puts "==============================================================================\n\n"

# Open JTAG Master Service
# ========================
open_service master $jtag_master;
puts "\nInfo: Opened JTAG Master Service\n\n";

# Configure HSMC Ethernet PHY Doughter Board
# ===============================================
puts "\nInfo: Configure HSMC Ethernet PHY Daughter Board\n\n";

if { $PHY_ENABLE == 1} {
	puts "Configure PHY.";	
	master_write_32 $jtag_master $PHY_CONFIG_ADDRESS $PHY_ADDR;
	set quad_phy_register_value_temp 0;
	
	#### PHY Control Register (REG 0)
	set quad_phy_register_value_temp [master_read_32 $jtag_master $PHY_CONTROL_ADDRESS 1];
	set quad_phy_register_value_temp [expr {$quad_phy_register_value_temp & 0x8EBF}];

	switch -exact -- $PHY_ETH_SPEED {
	10 { set quad_phy_register_value_temp [expr {$quad_phy_register_value_temp | 0x0000}];
	puts "Set PHY SPEED to 10Mbps";
	}
	100 { set quad_phy_register_value_temp [expr {$quad_phy_register_value_temp | 0x2000}]; 
	puts "Set PHY SPEED to 100Mbps";
	}
	1000 { set quad_phy_register_value_temp [expr {$quad_phy_register_value_temp | 0x0040}];
	puts "Set PHY SPEED to 1000Mbps"; 
	}
	default { 
	set quad_phy_register_value_temp [expr {$quad_phy_register_value_temp | 0x0008}];
	puts "Set PHY SPEED to default value (1000Mbps)"
	}
	};

	if { $PHY_ENABLE_AN == 1} {
		set quad_phy_register_value_temp [expr {$quad_phy_register_value_temp | 0x1000}];
		puts "Enable PHY Auto-Negotiation";
	} else {
		puts "Disable PHY Auto-Negotiation";
	}

	if { $PHY_COPPER_DUPLEX == 1} {
		set quad_phy_register_value_temp [expr {$quad_phy_register_value_temp | 0x0100}];
		puts "Enable PHY In Full Duplex Mode";
	} else {
		puts "Enable PHY In Half Duplex Mode";
	}

	master_write_32 $jtag_master $PHY_CONTROL_ADDRESS $quad_phy_register_value_temp;
	# Applying Software Reset
	set quad_phy_register_value_temp [master_read_32 $jtag_master $PHY_CONTROL_ADDRESS 1];
	set quad_phy_register_value_temp [expr {$quad_phy_register_value_temp | 0x8000}];
	master_write_32 $jtag_master $PHY_CONTROL_ADDRESS $quad_phy_register_value_temp;
	#puts "PHY read Control Register				= [master_read_32 $jtag_master 0x280 1]";



	#### PHY AN Advertisement Register (REG 4)
	set quad_phy_register_value_temp [master_read_32 $jtag_master $PHY_ADVERTISEMENT_ADDRESS 1];
	set quad_phy_register_value_temp [expr {$quad_phy_register_value_temp & 0xFE1F}];

	if { $PHY_ADV_100BTX_FD == 1} {
		set quad_phy_register_value_temp [expr {$quad_phy_register_value_temp | 0x0100}];
		puts "Advertise PHY 100BASE-TX Full Duplex";
	}
	if { $PHY_ADV_100BTX_HD == 1} {
		set quad_phy_register_value_temp [expr {$quad_phy_register_value_temp | 0x0080}];
		puts "Advertise PHY 100BASE-TX Half Duplex";
	}
	if { $PHY_ADV_10BTX_FD == 1} {
		set quad_phy_register_value_temp [expr {$quad_phy_register_value_temp | 0x0040}];
		puts "Advertise PHY 10BASE-TX Full Duplex";
	}
	if { $PHY_ADV_10BTX_HD == 1} {
		set quad_phy_register_value_temp [expr {$quad_phy_register_value_temp | 0x0020}];
		puts "Advertise PHY 10BASE-TX Half Duplex";
	}

	master_write_32 $jtag_master $PHY_ADVERTISEMENT_ADDRESS $quad_phy_register_value_temp;
	# Applying Software Reset
	set quad_phy_register_value_temp [master_read_32 $jtag_master $PHY_CONTROL_ADDRESS 1];
	set quad_phy_register_value_temp [expr {$quad_phy_register_value_temp | 0x8000}];
	master_write_32 $jtag_master $PHY_CONTROL_ADDRESS $quad_phy_register_value_temp;
	puts "PHY read AN Advertisement Register		= [master_read_32 $jtag_master $PHY_ADVERTISEMENT_ADDRESS 1]";



	#### PHY 1000BASE-T Control Register (REG 9)
	set quad_phy_register_value_temp [master_read_32 $jtag_master $PHY_1000_BASE_T_ADDRESS 1];
	set quad_phy_register_value_temp [expr {$quad_phy_register_value_temp & 0xFCFF}];

	if { $PHY_ADV_1000BT_FD == 1} {
		set quad_phy_register_value_temp [expr {$quad_phy_register_value_temp | 0x0200}];
		puts "Advertise PHY 1000BASE-T Full Duplex";
	}
	if { $PHY_ADV_1000BT_HD == 1} {
		set quad_phy_register_value_temp [expr {$quad_phy_register_value_temp | 0x0100}];
		puts "Advertise PHY 1000BASE-T Half Duplex";
	}

	master_write_32 $jtag_master $PHY_1000_BASE_T_ADDRESS $quad_phy_register_value_temp;
	# Applying Software Reset
	set quad_phy_register_value_temp [master_read_32 $jtag_master $PHY_CONTROL_ADDRESS 1];
	set quad_phy_register_value_temp [expr {$quad_phy_register_value_temp | 0x8000}];
	master_write_32 $jtag_master $PHY_CONTROL_ADDRESS $quad_phy_register_value_temp;
	puts "PHY read 1000BASE-T Control Register		= [master_read_32 $jtag_master $PHY_1000_BASE_T_ADDRESS 1]";

	#### PHY PHY Specific Control Register (REG 16)
	set quad_phy_register_value_temp [master_read_32 $jtag_master $PHY_SPECIFIC_CONTROL_ADDRESS 1];
	set quad_phy_register_value_temp [expr {$quad_phy_register_value_temp | 0xC000}];
	puts "Set PHY Synchronizing FIFO to maximum";

	master_write_32 $jtag_master $PHY_SPECIFIC_CONTROL_ADDRESS $quad_phy_register_value_temp;
	# Applying Software Reset
	set quad_phy_register_value_temp [master_read_32 $jtag_master $PHY_CONTROL_ADDRESS 1];
	set quad_phy_register_value_temp [expr {$quad_phy_register_value_temp | 0x8000}];
	master_write_32 $jtag_master $PHY_CONTROL_ADDRESS $quad_phy_register_value_temp;
	puts "PHY read 1000BASE-T Control Register		= [master_read_32 $jtag_master $PHY_1000_BASE_T_ADDRESS 1]";

	#### PHY Extended PHY Specific Status Register (REG 27)
	set quad_phy_register_value_temp [master_read_32 $jtag_master $PHY_EXD_SPECIFIC_STATUS_ADDRESS 1];
	set quad_phy_register_value_temp [expr {$quad_phy_register_value_temp & 0xFFF0}];

	switch -exact -- $PHY_HWCFG_MODE {
	1 { set quad_phy_register_value_temp [expr {$quad_phy_register_value_temp | 0x0004}];
	puts "Set PHY HWCFG_MODE for SGMII to Copper Without Clock";
	}
	2 { set quad_phy_register_value_temp [expr {$quad_phy_register_value_temp | 0x000D}]; 
	puts "Set PHY HWCFG_MODE for TBI to Copper";
	}
	3 { set quad_phy_register_value_temp [expr {$quad_phy_register_value_temp | 0x000B}];
	puts "Set PHY HWCFG_MODE for RGMII to Copper"; 
	}
	4 { set quad_phy_register_value_temp [expr {$quad_phy_register_value_temp | 0x000F}];
	puts "Set PHY HWCFG_MODE for GMII/MII to Copper"; 
	}
	default { 
	set quad_phy_register_value_temp [expr {$quad_phy_register_value_temp | 0x0004}];
	puts "Set PHY HWCFG_MODE to default mode (SGMII to Copper Without Clock)"
	}
	};

	master_write_32 $jtag_master $PHY_EXD_SPECIFIC_STATUS_ADDRESS $quad_phy_register_value_temp;
	# Applying Software Reset
	set quad_phy_register_value_temp [master_read_32 $jtag_master $PHY_CONTROL_ADDRESS 1];
	set quad_phy_register_value_temp [expr {$quad_phy_register_value_temp | 0x8000}];
	master_write_32 $jtag_master $PHY_CONTROL_ADDRESS $quad_phy_register_value_temp;
	puts "PHY read Extended PHY Specific Status Register	= [master_read_32 $jtag_master $PHY_EXD_SPECIFIC_STATUS_ADDRESS 1]";
	
	puts "PHY read Control Register			= [master_read_32 $jtag_master $PHY_CONTROL_ADDRESS 1]";
	
	#### PHY Specific Status Register (REG 17)
	set PHY_TIMEOUT 1000;
	set PHY_COUNT_TEMP 0;
	set quad_phy_register_value_temp 0;
	while { ($quad_phy_register_value_temp == 0x00000000) && ($PHY_COUNT_TEMP < $PHY_TIMEOUT) } {
		set quad_phy_register_value_temp [master_read_32 $jtag_master $PHY_SPECIFIC_STATUS_ADDRESS 1];
		set quad_phy_register_value_temp [expr {$quad_phy_register_value_temp & 0x0400}];
		
		if {($quad_phy_register_value_temp == 0x00000400) && ($PHY_COUNT_TEMP < $PHY_TIMEOUT)} {
			puts "PHY Link Up.";
		}
		
		set PHY_COUNT_TEMP [expr {$PHY_COUNT_TEMP + 1}];
		
		if {$PHY_COUNT_TEMP == $PHY_TIMEOUT} {
			puts "PHY Link Down!";
		}
	}

	set PHY_COUNT_TEMP 0;
	set quad_phy_register_value_temp 0;
	while { ($quad_phy_register_value_temp == 0x00000000) && ($PHY_COUNT_TEMP < $PHY_TIMEOUT) } {
		set quad_phy_register_value_temp [master_read_32 $jtag_master $PHY_SPECIFIC_STATUS_ADDRESS 1];
		set quad_phy_register_value_temp [expr {$quad_phy_register_value_temp & 0x0800}];
		
		if {($quad_phy_register_value_temp == 0x00000800) && ($PHY_COUNT_TEMP < $PHY_TIMEOUT)} {
			puts "PHY Speed and Duplex Resolved.";
		}
		
		set PHY_COUNT_TEMP [expr {$PHY_COUNT_TEMP + 1}];
		
		if {$PHY_COUNT_TEMP == $PHY_TIMEOUT} {
			puts "PHY Speed and Duplex Resolve Failed!";
		}
	}

	set quad_phy_register_value_temp [master_read_32 $jtag_master $PHY_SPECIFIC_STATUS_ADDRESS 1];
	set quad_phy_register_value_temp [expr {$quad_phy_register_value_temp & 0x2000}];

	if { $quad_phy_register_value_temp == 0x00002000} {
		puts "PHY operating in Full Duplex mode.";
	} else {
		puts "PHY operating in Half Duplex mode.";
	}

	set quad_phy_register_value_temp [master_read_32 $jtag_master $PHY_SPECIFIC_STATUS_ADDRESS 1];
	set quad_phy_register_value_temp [expr {$quad_phy_register_value_temp & 0xC000}];

	if { $quad_phy_register_value_temp == 0x00000000 } {
		puts "PHY operating Speed 10Mbps";
	} elseif { $quad_phy_register_value_temp == 0x00004000 } {
		puts "PHY operating Speed 100Mbps";
	} elseif { $quad_phy_register_value_temp == 0x00008000 } {
		puts "PHY operating Speed 1000Mbps";
	} else {
		puts "PHY operating Speed Error!";
	}
	
}

close_service master $jtag_master;
puts "\nInfo: Closed JTAG Master Service\n\n";
