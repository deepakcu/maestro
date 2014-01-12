# =======================================================================================
# Project     : Altera NetFPGA Design
# 
# Description : Altera NetFPGA LPM Configuration Setting Script
#
# Revision Control Information
#
# Author      : RCG
# Revision    : 
# Date        : 
# ======================================================================================

# Define Variable
# ===============

# Update the lpm table if you need more entries
# LPM 1
regexp {^(\d+)\.(\d+)\.(\d+)\.(\d+)$} $LPM_IP_1 _ a b c d
set IP_REG_01 [expr {($a << 24) + ($b << 16) + ($c << 8) + $d}]
regexp {^(\d+)\.(\d+)\.(\d+)\.(\d+)$} $LPM_MASK_1 _ a b c d
set MASK_REG_01 [expr {($a << 24) + ($b << 16) + ($c << 8) + $d}]
regexp {^(\d+)\.(\d+)\.(\d+)\.(\d+)$} $LPM_NEXT_HOP_IP_1 _ a b c d
set NEXT_HOP_IP_REG_01 [expr {($a << 24) + ($b << 16) + ($c << 8) + $d}]
regexp {^(\d+)$} $LPM_OUTPUT_PORT_1 _ a
set OUTPUT_PORT_REG_01 [expr 0x$a]

# LPM 2
regexp {^(\d+)\.(\d+)\.(\d+)\.(\d+)$} $LPM_IP_2 _ a b c d
set IP_REG_02 [expr {($a << 24) + ($b << 16) + ($c << 8) + $d}]
regexp {^(\d+)\.(\d+)\.(\d+)\.(\d+)$} $LPM_MASK_2 _ a b c d
set MASK_REG_02 [expr {($a << 24) + ($b << 16) + ($c << 8) + $d}]
regexp {^(\d+)\.(\d+)\.(\d+)\.(\d+)$} $LPM_NEXT_HOP_IP_2 _ a b c d
set NEXT_HOP_IP_REG_02 [expr {($a << 24) + ($b << 16) + ($c << 8) + $d}]
regexp {^(\d+)$} $LPM_OUTPUT_PORT_2 _ a
set OUTPUT_PORT_REG_02 [expr 0x$a]

# LPM 3
regexp {^(\d+)\.(\d+)\.(\d+)\.(\d+)$} $LPM_IP_3 _ a b c d
set IP_REG_03 [expr {($a << 24) + ($b << 16) + ($c << 8) + $d}]
regexp {^(\d+)\.(\d+)\.(\d+)\.(\d+)$} $LPM_MASK_3 _ a b c d
set MASK_REG_03 [expr {($a << 24) + ($b << 16) + ($c << 8) + $d}]
regexp {^(\d+)\.(\d+)\.(\d+)\.(\d+)$} $LPM_NEXT_HOP_IP_3 _ a b c d
set NEXT_HOP_IP_REG_03 [expr {($a << 24) + ($b << 16) + ($c << 8) + $d}]
regexp {^(\d+)$} $LPM_OUTPUT_PORT_3 _ a
set OUTPUT_PORT_REG_03 [expr 0x$a]

# LPM 4
regexp {^(\d+)\.(\d+)\.(\d+)\.(\d+)$} $LPM_IP_4 _ a b c d
set IP_REG_04 [expr {($a << 24) + ($b << 16) + ($c << 8) + $d}]
regexp {^(\d+)\.(\d+)\.(\d+)\.(\d+)$} $LPM_MASK_4 _ a b c d
set MASK_REG_04 [expr {($a << 24) + ($b << 16) + ($c << 8) + $d}]
regexp {^(\d+)\.(\d+)\.(\d+)\.(\d+)$} $LPM_NEXT_HOP_IP_4 _ a b c d
set NEXT_HOP_IP_REG_04 [expr {($a << 24) + ($b << 16) + ($c << 8) + $d}]
regexp {^(\d+)$} $LPM_OUTPUT_PORT_4 _ a
set OUTPUT_PORT_REG_04 [expr 0x$a]


# Define Variable
# ===============
# Register Set 1
set WR_ADDR_REG_01 					0x00000000;
set RD_ADDR_REG_01 					0x00000000;

set WR_ADDR_REG_02 					0x0000000f;
set RD_ADDR_REG_02 					0x0000000f;

# Register Set 3
set WR_ADDR_REG_03 					0x00000005;
set RD_ADDR_REG_03 					0x00000005;

# Register Set 4
set WR_ADDR_REG_04 					0x00000007;
set RD_ADDR_REG_04 					0x00000007;



set jtag_master [lindex [get_service_paths master] 0];

# Register Address Offset
# LPM
set ROUTER_OP_LUT_ROUTE_TABLE_ENTRY_IP_REG 							0x8000120;
set ROUTER_OP_LUT_ROUTE_TABLE_ENTRY_MASK_REG 						0x8000130;
set ROUTER_OP_LUT_ROUTE_TABLE_ENTRY_NEXT_HOP_IP_REG 				0x8000140;
set ROUTER_OP_LUT_ROUTE_TABLE_ENTRY_OUTPUT_PORT_REG 				0x8000150;
set ROUTER_OP_LUT_ROUTE_TABLE_WR_ADDR_REG 							0x8000170;
set ROUTER_OP_LUT_ROUTE_TABLE_RD_ADDR_REG							0x8000160;

# Starting Altera NetFPGA LPM Configuration System Console
# =================================================
puts "=============================================================================="
puts "	Starting Altera NetFPGA LPM Configuration System Console                   			"
puts "==============================================================================\n\n"

# Open JTAG Master Service
# ========================
open_service master $jtag_master;
# Writing the first set of Registers
master_write_32 $jtag_master $ROUTER_OP_LUT_ROUTE_TABLE_ENTRY_IP_REG $IP_REG_01;
master_write_32 $jtag_master $ROUTER_OP_LUT_ROUTE_TABLE_ENTRY_MASK_REG $MASK_REG_01;
master_write_32 $jtag_master $ROUTER_OP_LUT_ROUTE_TABLE_ENTRY_NEXT_HOP_IP_REG $NEXT_HOP_IP_REG_01;
master_write_32 $jtag_master $ROUTER_OP_LUT_ROUTE_TABLE_ENTRY_OUTPUT_PORT_REG $OUTPUT_PORT_REG_01;
master_write_32 $jtag_master $ROUTER_OP_LUT_ROUTE_TABLE_WR_ADDR_REG $WR_ADDR_REG_01;

# Writing the second set of Registers
master_write_32 $jtag_master $ROUTER_OP_LUT_ROUTE_TABLE_ENTRY_IP_REG $IP_REG_02;
master_write_32 $jtag_master $ROUTER_OP_LUT_ROUTE_TABLE_ENTRY_MASK_REG $MASK_REG_02;
master_write_32 $jtag_master $ROUTER_OP_LUT_ROUTE_TABLE_ENTRY_NEXT_HOP_IP_REG $NEXT_HOP_IP_REG_02;
master_write_32 $jtag_master $ROUTER_OP_LUT_ROUTE_TABLE_ENTRY_OUTPUT_PORT_REG $OUTPUT_PORT_REG_02;
master_write_32 $jtag_master $ROUTER_OP_LUT_ROUTE_TABLE_WR_ADDR_REG $WR_ADDR_REG_02;

# Writing the third set of Registers
master_write_32 $jtag_master $ROUTER_OP_LUT_ROUTE_TABLE_ENTRY_IP_REG $IP_REG_03;
master_write_32 $jtag_master $ROUTER_OP_LUT_ROUTE_TABLE_ENTRY_MASK_REG $MASK_REG_03;
master_write_32 $jtag_master $ROUTER_OP_LUT_ROUTE_TABLE_ENTRY_NEXT_HOP_IP_REG $NEXT_HOP_IP_REG_03;
master_write_32 $jtag_master $ROUTER_OP_LUT_ROUTE_TABLE_ENTRY_OUTPUT_PORT_REG $OUTPUT_PORT_REG_03;
master_write_32 $jtag_master $ROUTER_OP_LUT_ROUTE_TABLE_WR_ADDR_REG $WR_ADDR_REG_03;

# Writing the fourth set of Registers
master_write_32 $jtag_master $ROUTER_OP_LUT_ROUTE_TABLE_ENTRY_IP_REG $IP_REG_04;
master_write_32 $jtag_master $ROUTER_OP_LUT_ROUTE_TABLE_ENTRY_MASK_REG $MASK_REG_04;
master_write_32 $jtag_master $ROUTER_OP_LUT_ROUTE_TABLE_ENTRY_NEXT_HOP_IP_REG $NEXT_HOP_IP_REG_04;
master_write_32 $jtag_master $ROUTER_OP_LUT_ROUTE_TABLE_ENTRY_OUTPUT_PORT_REG $OUTPUT_PORT_REG_04;
master_write_32 $jtag_master $ROUTER_OP_LUT_ROUTE_TABLE_WR_ADDR_REG $WR_ADDR_REG_04;



close_service master $jtag_master;
puts "\nInfo: Closed JTAG Master Service\n\n";