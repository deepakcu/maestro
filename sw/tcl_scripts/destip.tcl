# =======================================================================================
# Project     : Altera NetFPGA Design
# 
# Description : Altera NetFPGA Dest IP Configuration Setting Script
#
# Revision Control Information
#
# Author      : RCG
# Revision    : 
# Date        : 
# ======================================================================================

# Define Variable
# ===============

regexp {^(\d+)\.(\d+)\.(\d+)\.(\d+)$} $DEST_IP_0 _ a b c d
set IP_REG_00 [expr {($a << 24) + ($b << 16) + ($c << 8) + $d}]

regexp {^(\d+)\.(\d+)\.(\d+)\.(\d+)$} $DEST_IP_1 _ a b c d
set IP_REG_01 [expr {($a << 24) + ($b << 16) + ($c << 8) + $d}]

regexp {^(\d+)\.(\d+)\.(\d+)\.(\d+)$} $DEST_IP_2 _ a b c d
set IP_REG_02 [expr {($a << 24) + ($b << 16) + ($c << 8) + $d}]

regexp {^(\d+)\.(\d+)\.(\d+)\.(\d+)$} $DEST_IP_3 _ a b c d
set IP_REG_03 [expr {($a << 24) + ($b << 16) + ($c << 8) + $d}]


# Register Set 1
set WR_ADDR_REG_00 					0x00000001;
set RD_ADDR_REG_00 					0x00000001;

# Register Set 2
set WR_ADDR_REG_01 					0x00000002;
set RD_ADDR_REG_01 					0x00000002;

# Register Set 3
set WR_ADDR_REG_02 					0x00000003;
set RD_ADDR_REG_02 					0x00000003;

# Register Set 4
set WR_ADDR_REG_03 					0x00000004;
set RD_ADDR_REG_03 					0x00000004;

set jtag_master [lindex [get_service_paths master] 0];

# Register Address Offset
# Dest IP
set ROUTER_OP_LUT_DST_IP_FILTER_TABLE_ENTRY_IP_REG 							0x80001d0;
set ROUTER_OP_LUT_DST_IP_FILTER_TABLE_WR_ADDR_REG 							0x80001f0;
set ROUTER_OP_LUT_DST_IP_FILTER_TABLE_RD_ADDR_REG 							0x80001e0;

# Starting Altera NetFPGA Dest IP Configuration System Console
# =================================================
puts "=============================================================================="
puts "	Starting Altera NetFPGA Dest IP Configuration System Console                   			"
puts "==============================================================================\n\n"

# Open JTAG Master Service
# ========================
open_service master $jtag_master;

# Writing the first set of Registers
master_write_32 $jtag_master $ROUTER_OP_LUT_DST_IP_FILTER_TABLE_ENTRY_IP_REG $IP_REG_00;
master_write_32 $jtag_master $ROUTER_OP_LUT_DST_IP_FILTER_TABLE_WR_ADDR_REG $WR_ADDR_REG_00;
# Reading the first set of Registers
master_write_32 $jtag_master $ROUTER_OP_LUT_DST_IP_FILTER_TABLE_RD_ADDR_REG $RD_ADDR_REG_00;
#master_read_32 $jtag_master $ROUTER_OP_LUT_DST_IP_FILTER_TABLE_ENTRY_IP_REG $IP_REG_01;
puts "Dest ip Address 0 \t \t = [master_read_32 $jtag_master $ROUTER_OP_LUT_DST_IP_FILTER_TABLE_ENTRY_IP_REG 1]";

# Writing the second set of Registers
master_write_32 $jtag_master $ROUTER_OP_LUT_DST_IP_FILTER_TABLE_ENTRY_IP_REG $IP_REG_01;
master_write_32 $jtag_master $ROUTER_OP_LUT_DST_IP_FILTER_TABLE_WR_ADDR_REG $WR_ADDR_REG_01;
# Reading the second set of Registers
master_write_32 $jtag_master $ROUTER_OP_LUT_DST_IP_FILTER_TABLE_RD_ADDR_REG $RD_ADDR_REG_01;
#master_read_32 $jtag_master $ROUTER_OP_LUT_DST_IP_FILTER_TABLE_ENTRY_IP_REG $IP_REG_02;
puts "Dest ip  Address 1 \t \t = [master_read_32 $jtag_master $ROUTER_OP_LUT_DST_IP_FILTER_TABLE_ENTRY_IP_REG 1]";

# Writing the third set of Registers
master_write_32 $jtag_master $ROUTER_OP_LUT_DST_IP_FILTER_TABLE_ENTRY_IP_REG $IP_REG_02;
master_write_32 $jtag_master $ROUTER_OP_LUT_DST_IP_FILTER_TABLE_WR_ADDR_REG $WR_ADDR_REG_02;
# Reading the third set of Registers
master_write_32 $jtag_master $ROUTER_OP_LUT_DST_IP_FILTER_TABLE_RD_ADDR_REG $RD_ADDR_REG_02;
#master_read_32 $jtag_master $ROUTER_OP_LUT_DST_IP_FILTER_TABLE_ENTRY_IP_REG $IP_REG_03;
puts "Dest ip  Address 2 \t \t = [master_read_32 $jtag_master $ROUTER_OP_LUT_DST_IP_FILTER_TABLE_ENTRY_IP_REG 1]";

# Writing the fourth set of Registers
master_write_32 $jtag_master $ROUTER_OP_LUT_DST_IP_FILTER_TABLE_ENTRY_IP_REG $IP_REG_03;
master_write_32 $jtag_master $ROUTER_OP_LUT_DST_IP_FILTER_TABLE_WR_ADDR_REG $WR_ADDR_REG_03;
# Reading the fourth set of Registers
master_write_32 $jtag_master $ROUTER_OP_LUT_DST_IP_FILTER_TABLE_RD_ADDR_REG $RD_ADDR_REG_03;
#master_read_32 $jtag_master $ROUTER_OP_LUT_DST_IP_FILTER_TABLE_ENTRY_IP_REG $IP_REG_04;
puts "Dest ip  Address 3 \t \t = [master_read_32 $jtag_master $ROUTER_OP_LUT_DST_IP_FILTER_TABLE_ENTRY_IP_REG 1]";

close_service master $jtag_master;
puts "\nInfo: Closed JTAG Master Service\n\n";