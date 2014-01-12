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

set REV_ADDRESS 				[expr {$MAC_0_BASE_ADDRESS + 0x0}];
set MAC_SCRATCH_ADDRESS 		[expr {$MAC_0_BASE_ADDRESS + 0x4}];
set COMMAND_CONFIG_ADDRESS		[expr {$MAC_0_BASE_ADDRESS + 0x8}];
set MAC_0_ADDRESS 				[expr {$MAC_0_BASE_ADDRESS + 0xC}];
set MAC_1_ADDRESS 				[expr {$MAC_0_BASE_ADDRESS + 0x10}];
set FRM_LENGTH_ADDRESS 			[expr {$MAC_0_BASE_ADDRESS + 0x14}];
set PAUSE_QUANT_ADDRESS 		[expr {$MAC_0_BASE_ADDRESS + 0x18}];
set RX_SECTION_EMPTY_ADDRESS	[expr {$MAC_0_BASE_ADDRESS + 0x1C}];
set RX_SECTION_FULL_ADDRESS 	[expr {$MAC_0_BASE_ADDRESS + 0x20}];
set TX_SECTION_EMPTY_ADDRESS 	[expr {$MAC_0_BASE_ADDRESS + 0x24}];
set TX_SECTION_FULL_ADDRESS 	[expr {$MAC_0_BASE_ADDRESS + 0x28}];
set RX_ALMOST_EMPTY_ADDRESS 	[expr {$MAC_0_BASE_ADDRESS + 0x2C}];
set RX_ALMOST_FULL_ADDRESS 		[expr {$MAC_0_BASE_ADDRESS + 0x30}];
set TX_ALMOST_EMPTY_ADDRESS 	[expr {$MAC_0_BASE_ADDRESS + 0x34}];
set TX_ALMOST_FULL_ADDRESS 		[expr {$MAC_0_BASE_ADDRESS + 0x38}];
set MDIO_ADDR0_ADDRESS 			[expr {$MAC_0_BASE_ADDRESS + 0x3C}];
set MDIO_ADDR1_ADDRESS 			[expr {$MAC_0_BASE_ADDRESS + 0x40}];
set REG_STATUS_ADDRESS 			[expr {$MAC_0_BASE_ADDRESS + 0x58}];
set TX_IPG_LENGTH_ADDRESS 		[expr {$MAC_0_BASE_ADDRESS + 0x5C}];
set TX_CMD_STAT_ADDRESS 		[expr {$MAC_0_BASE_ADDRESS + 0xE8}];
set RX_CMD_STAT_ADDRESS 		[expr {$MAC_0_BASE_ADDRESS + 0xEC}];
set MAC_ADDRESS_NEXT 			[expr {$MAC_0_BASE_ADDRESS + 0x400}];
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
