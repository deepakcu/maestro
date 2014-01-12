# =======================================================================================
# Project     : NetFPGA DE4
# 
# Description : Triple Speed Ethernet MAC + PCS + Marvel PHY Configuration Setting Script
#
# Revision Control Information
#
# Author      : RCG
# Revision    : 
# Date        : 
# ======================================================================================

# TSE MAC Configuration Setting
# =============================
set MAC_2_BASE_ADDRESS     		0x20000800;
set MAC_SCRATCH					0xaaaaaaaa;
# COMMAND_CONFIG
set ENA_TX 				1;
set ENA_RX 				1;
set XON_GEN 			0;
set ETH_SPEED 			1;	# 10/100Mbps = 0 & 1000Mbps = 1
set PROMIS_EN			1;
set PAD_EN 				0;
set CRC_FWD 			0;
set PAUSE_FWD 			0;
set PAUSE_IGNORE		0;
set TX_ADDR_INS 		0;
set HD_ENA 				0;
set EXCESS_COL 			0;
set LATE_COL			0;
set SW_RESET 			0;
set MHASH_SEL			0;
set LOOP_ENA			0;
set TX_ADDR_SEL 		0x0;
set MAGIC_ENA			0;
set SLEEP	 			0;
set WAKEUP 				0;
set XOFF_GEN 			0;
set CTRL_FRM_ENA 		0;
set NO_LGTH_CHECK		1;
set ENA_10 				0; # 100Mbps = 0 & 10Mbps = 1
set RX_ERR_DISC 		0;
set DISABLE_RD_TIMEOUT	0;
set CNT_RESET			0;

set MAC_0 				0x32464e00; #00:4e:46:32:43:02
set MAC_1 				0x00000243;
set FRM_LENGTH  		1500;
set PAUSE_QUANT  		0;
set RX_SECTION_EMPTY 	0;
set RX_SECTION_FULL  	0;
set TX_SECTION_EMPTY 	0;
set TX_SECTION_FULL  	0;
set RX_ALMOST_EMPTY 	8;
set RX_ALMOST_FULL  	14;
set TX_ALMOST_EMPTY  	8;
set TX_ALMOST_FULL 		3;
set MDIO_ADDR0  		0;
set MDIO_ADDR1  		0;

set TX_IPG_LENGTH 		12;

set TX_OMIT_CRC 		0;

set TX_SHIFT16 			0;
set RX_SHIFT16 			0;

# TSE PCS Configuration Setting
# =============================
set PCS_SCRATCH 			0x0000aaaa;

# PCS if_mode
set PCS_SGMII_ENA 			1;		# Enable SGMII mode
set PCS_SGMII_AN 			1;		# Enable Auto-Negotiation In SGMII mode
set PCS_SGMII_ETH_SPEED 	1000;	# 10Mbps or 100Mbps or 1000Mbps
set PCS_SGMII_HALF_DUPLEX 	0;		# Enable SGMII Half-Duplex

# PCS Control Register
set PCS_CTRL_ENABLE_AN 		1;		# Enable PCS Auto-Negotiation

# Marvell PHY Configuration Setting 
# =================================
# PHY MISC
set PHY_ENABLE 			1;		# Enable PHY Port 0
set PHY_ADDR 			2;		# PHY Address

# PHY Configuration
# PHY PHY Control Register (REG 0)
set PHY_ETH_SPEED 		1000;	# 10Mbps or 100Mbps or 1000Mbps
set PHY_ENABLE_AN 		1;		# Enable PHY Auto-Negotiation
set PHY_COPPER_DUPLEX	1;		# FD = 1 and HD = 0

# PHY AN Advertisement Register (REG 4)
set PHY_ADV_100BTX_FD 	1;		# Advertise 100BASE-TX Full Duplex
set PHY_ADV_100BTX_HD 	1;		# Advertise 100BASE-TX Half Duplex
set PHY_ADV_10BTX_FD 	1;		# Advertise 10BASE-TX Full Duplex
set PHY_ADV_10BTX_HD 	1;		# Advertise 10BASE-TX Half Duplex

# PHY 1000BASE-T Control Register (REG 9)
set PHY_ADV_1000BT_FD 	1;		# Advertise 1000BASE-T Full Duplex
set PHY_ADV_1000BT_HD 	1;		# Advertise 1000BASE-T Half Duplex

# PHY Extended PHY Specific Status REgister (REG 27)
set PHY_HWCFG_MODE 		1;		# 1 (default) = SGMII to Copper Without Clock
								# 2 = TBI to Copper
								# 3 = RGMII to Copper
								# 4 = GMII/MII to Copper			
										



										
# =======================================================================================
# Project     : NetFPGA DE4
# 
# Description : Triple Speed Ethernet MAC Configuration Setting Script
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
# MAC

set REV_ADDRESS 				[expr {$MAC_2_BASE_ADDRESS + 0x0}];
set MAC_SCRATCH_ADDRESS 		[expr {$MAC_2_BASE_ADDRESS + 0x4}];
set COMMAND_CONFIG_ADDRESS		[expr {$MAC_2_BASE_ADDRESS + 0x8}];
set MAC_0_ADDRESS 				[expr {$MAC_2_BASE_ADDRESS + 0xC}];
set MAC_1_ADDRESS 				[expr {$MAC_2_BASE_ADDRESS + 0x10}];
set FRM_LENGTH_ADDRESS 			[expr {$MAC_2_BASE_ADDRESS + 0x14}];
set PAUSE_QUANT_ADDRESS 		[expr {$MAC_2_BASE_ADDRESS + 0x18}];
set RX_SECTION_EMPTY_ADDRESS	[expr {$MAC_2_BASE_ADDRESS + 0x1C}];
set RX_SECTION_FULL_ADDRESS 	[expr {$MAC_2_BASE_ADDRESS + 0x20}];
set TX_SECTION_EMPTY_ADDRESS 	[expr {$MAC_2_BASE_ADDRESS + 0x24}];
set TX_SECTION_FULL_ADDRESS 	[expr {$MAC_2_BASE_ADDRESS + 0x28}];
set RX_ALMOST_EMPTY_ADDRESS 	[expr {$MAC_2_BASE_ADDRESS + 0x2C}];
set RX_ALMOST_FULL_ADDRESS 		[expr {$MAC_2_BASE_ADDRESS + 0x30}];
set TX_ALMOST_EMPTY_ADDRESS 	[expr {$MAC_2_BASE_ADDRESS + 0x34}];
set TX_ALMOST_FULL_ADDRESS 		[expr {$MAC_2_BASE_ADDRESS + 0x38}];
set MDIO_ADDR0_ADDRESS 			[expr {$MAC_2_BASE_ADDRESS + 0x3C}];
set MDIO_ADDR1_ADDRESS 			[expr {$MAC_2_BASE_ADDRESS + 0x40}];
set REG_STATUS_ADDRESS 			[expr {$MAC_2_BASE_ADDRESS + 0x58}];
set TX_IPG_LENGTH_ADDRESS 		[expr {$MAC_2_BASE_ADDRESS + 0x5C}];
set TX_CMD_STAT_ADDRESS 		[expr {$MAC_2_BASE_ADDRESS + 0xE8}];
set RX_CMD_STAT_ADDRESS 		[expr {$MAC_2_BASE_ADDRESS + 0xEC}];
set MAC_ADDRESS_NEXT 			[expr {$MAC_2_BASE_ADDRESS + 0x400}];
# Combine Configuration Value
# MAC
set COMMAND_CONFIG_VALUE [expr (0 \
| $ENA_TX 				<< 0 \
| $ENA_RX 				<< 1 \
| $XON_GEN 				<< 2 \
| $ETH_SPEED 			<< 3 \
| $PROMIS_EN			<< 4 \
| $PAD_EN 				<< 5 \
| $CRC_FWD 				<< 6 \
| $PAUSE_FWD 			<< 7 \
| $PAUSE_IGNORE			<< 8 \
| $TX_ADDR_INS 			<< 9 \
| $HD_ENA 				<< 10 \
| $EXCESS_COL 			<< 11 \
| $LATE_COL				<< 12 \
| $SW_RESET 			<< 13 \
| $MHASH_SEL			<< 14 \
| $LOOP_ENA				<< 15 \
| $TX_ADDR_SEL 			<< 18 \
| $MAGIC_ENA			<< 19 \
| $SLEEP	 			<< 20 \
| $WAKEUP 				<< 21 \
| $XOFF_GEN 			<< 22 \
| $CTRL_FRM_ENA 		<< 23 \
| $NO_LGTH_CHECK		<< 24 \
| $ENA_10 				<< 25 \
| $RX_ERR_DISC 			<< 26 \
| $DISABLE_RD_TIMEOUT	<< 27 \
| $CNT_RESET			<< 31 \
| 0)];

set TX_CMD_STAT_VALUE [expr (0 \
| $TX_OMIT_CRC << 17 \
| $TX_SHIFT16 << 18 \
| 0)];

set RX_CMD_STAT_VALUE [expr (0 \
| $RX_SHIFT16 << 25 \
| 0)];



# Starting Marvell PHY Configuration System Console
# =================================================
puts "=============================================================================="
puts "	Starting TSE MAC Configuration System Console                   			"
puts "==============================================================================\n\n"

# Open JTAG Master Service
# ========================
open_service master $jtag_master;
master_write_32 $jtag_master MAC_ADDRESS_NEXT 0x00000000;

puts "\nInfo: Opened JTAG Master Service\n\n";

puts "\nInfo: Configure TSE MAC\n\n";

# Configuration Command
# MAC
puts "TSE MAC Rev \t \t = [master_read_32 $jtag_master $REV_ADDRESS 1]";

master_write_32 $jtag_master $MAC_SCRATCH_ADDRESS $MAC_SCRATCH;
puts "TSE MAC write Scratch \t = $MAC_SCRATCH";
puts "TSE MAC read Scratch \t = [master_read_32 $jtag_master $MAC_SCRATCH_ADDRESS 1]";

master_write_32 $jtag_master $COMMAND_CONFIG_ADDRESS [expr ($COMMAND_CONFIG_VALUE | (1 << 13))];
#puts "Command Config = [master_read_32 $jtag_master $COMMAND_CONFIG_ADDRESS 1]";

master_write_32 $jtag_master $COMMAND_CONFIG_ADDRESS $COMMAND_CONFIG_VALUE;
puts "Command Config \t \t = [master_read_32 $jtag_master $COMMAND_CONFIG_ADDRESS 1]";

master_write_32 $jtag_master $MAC_0_ADDRESS $MAC_0;
puts "MAC Address 0 \t \t = [master_read_32 $jtag_master $MAC_0_ADDRESS 1]";

master_write_32 $jtag_master $MAC_1_ADDRESS $MAC_1;
puts "MAC Address 1 \t \t = [master_read_32 $jtag_master $MAC_1_ADDRESS 1]";

master_write_32 $jtag_master $FRM_LENGTH_ADDRESS $FRM_LENGTH;
puts "Frame Length \t \t = [master_read_32 $jtag_master $FRM_LENGTH_ADDRESS 1]";

master_write_32 $jtag_master $PAUSE_QUANT_ADDRESS $PAUSE_QUANT;
puts "Pause Quanta \t \t = [master_read_32 $jtag_master $PAUSE_QUANT_ADDRESS 1]";

master_write_32 $jtag_master $RX_SECTION_EMPTY_ADDRESS $RX_SECTION_EMPTY;
puts "RX Section Empty \t \t = [master_read_32 $jtag_master $RX_SECTION_EMPTY_ADDRESS 1]";

master_write_32 $jtag_master $RX_SECTION_FULL_ADDRESS $RX_SECTION_FULL;
puts "RX Section Full \t \t = [master_read_32 $jtag_master $RX_SECTION_FULL_ADDRESS 1]";

master_write_32 $jtag_master $TX_SECTION_EMPTY_ADDRESS $TX_SECTION_EMPTY;
puts "TX Section Empty \t \t = [master_read_32 $jtag_master $TX_SECTION_EMPTY_ADDRESS 1]";

master_write_32 $jtag_master $TX_SECTION_FULL_ADDRESS $TX_SECTION_FULL;
puts "TX Section Full \t \t = [master_read_32 $jtag_master $TX_SECTION_FULL_ADDRESS 1]";

master_write_32 $jtag_master $RX_ALMOST_EMPTY_ADDRESS $RX_ALMOST_EMPTY;
puts "RX Almost Empty \t \t = [master_read_32 $jtag_master $RX_ALMOST_EMPTY_ADDRESS 1]";

master_write_32 $jtag_master $RX_ALMOST_FULL_ADDRESS $RX_ALMOST_FULL;
puts "RX Almost Full \t \t = [master_read_32 $jtag_master $RX_ALMOST_FULL_ADDRESS 1]";

master_write_32 $jtag_master $TX_ALMOST_EMPTY_ADDRESS $TX_ALMOST_EMPTY;
puts "TX Almost Empty \t \t = [master_read_32 $jtag_master $TX_ALMOST_EMPTY_ADDRESS 1]";

master_write_32 $jtag_master $TX_ALMOST_FULL_ADDRESS $TX_ALMOST_FULL;
puts "TX Almost Full \t \t = [master_read_32 $jtag_master $TX_ALMOST_FULL_ADDRESS 1]";

master_write_32 $jtag_master $MDIO_ADDR0_ADDRESS $MDIO_ADDR0;
puts "MDIO Address 0 \t \t = [master_read_32 $jtag_master $MDIO_ADDR0_ADDRESS 1]";

master_write_32 $jtag_master $MDIO_ADDR1_ADDRESS $MDIO_ADDR1;
puts "MDIO Address 1 \t \t = [master_read_32 $jtag_master $MDIO_ADDR1_ADDRESS 1]";

puts "Regiter Status \t \t = [master_read_32 $jtag_master $REG_STATUS_ADDRESS 1]";

master_write_32 $jtag_master $TX_IPG_LENGTH_ADDRESS $TX_IPG_LENGTH;
puts "TX IPG Length \t \t = [master_read_32 $jtag_master $TX_IPG_LENGTH_ADDRESS 1]";

master_write_32 $jtag_master $TX_CMD_STAT_ADDRESS $TX_CMD_STAT_VALUE;
puts "TX Command Status \t \t = [master_read_32 $jtag_master $TX_CMD_STAT_ADDRESS 1]";

master_write_32 $jtag_master $RX_CMD_STAT_ADDRESS $RX_CMD_STAT_VALUE;
puts "RX Command Status \t \t = [master_read_32 $jtag_master $RX_CMD_STAT_ADDRESS 1]";

close_service master $jtag_master;
puts "\nInfo: Closed JTAG Master Service\n\n";
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

set PHY_CONFIG_ADDRESS 					[expr {$MAC_2_BASE_ADDRESS + 0x40}];  
set PHY_CONTROL_ADDRESS 				[expr {$MAC_2_BASE_ADDRESS + 0x280}];
set PHY_ADVERTISEMENT_ADDRESS 			[expr {$MAC_2_BASE_ADDRESS + 0x290}];
set PHY_1000_BASE_T_ADDRESS 			[expr {$MAC_2_BASE_ADDRESS + 0x2A4}];
set PHY_SPECIFIC_CONTROL_ADDRESS 		[expr {$MAC_2_BASE_ADDRESS + 0x2C0}];
set PHY_EXD_SPECIFIC_STATUS_ADDRESS 	[expr {$MAC_2_BASE_ADDRESS + 0x2EC}];
set PHY_SPECIFIC_STATUS_ADDRESS 		[expr {$MAC_2_BASE_ADDRESS + 0x2C4}];

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

set PCS_REV_ADDRESS 				[expr {$MAC_2_BASE_ADDRESS + 0x244}];
set PCS_SCRATCH_ADDRESS 			[expr {$MAC_2_BASE_ADDRESS + 0x240}];
set PCS_IF_MODE_ADDRESS 			[expr {$MAC_2_BASE_ADDRESS + 0x250}];
set PCS_CONTROL_ADDRESS 			[expr {$MAC_2_BASE_ADDRESS + 0x200}];
set PCS_STATUS_ADDRESS 				[expr {$MAC_2_BASE_ADDRESS + 0x204}];
set PCS_PARTNER_ABILITY_ADDRESS 	[expr {$MAC_2_BASE_ADDRESS + 0x214}];

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
