# =======================================================================================
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

# Update the arp table if you need more entries
# arp 1
regexp {^(\d+)\.(\d+)\.(\d+)\.(\d+)$} $NEXT_HOP_IP_1 _ a b c d
set NEXT_HOP_IP_REG_01 [expr {($a << 24) + ($b << 16) + ($c << 8) + $d}]
scan $NEXT_HOP_MAC_1 %x:%x:%x:%x:%x:%x a b c d e f
set MAC_HI_REG_01 [expr {($a << 8) + $b}]
set MAC_LO_REG_01 [expr {($c << 24) + ($d << 16) + ($e << 8) + $f}]

# arp 2
regexp {^(\d+)\.(\d+)\.(\d+)\.(\d+)$} $NEXT_HOP_IP_2 _ a b c d
set NEXT_HOP_IP_REG_02 [expr {($a << 24) + ($b << 16) + ($c << 8) + $d}]
scan $NEXT_HOP_MAC_2 %x:%x:%x:%x:%x:%x a b c d e f
set MAC_HI_REG_02 [expr {($a << 8) + $b}]
set MAC_LO_REG_02 [expr {($c << 24) + ($d << 16) + ($e << 8) + $f}]

# arp 3
regexp {^(\d+)\.(\d+)\.(\d+)\.(\d+)$} $NEXT_HOP_IP_3 _ a b c d
set NEXT_HOP_IP_REG_03 [expr {($a << 24) + ($b << 16) + ($c << 8) + $d}]
scan $NEXT_HOP_MAC_3 %x:%x:%x:%x:%x:%x a b c d e f
set MAC_HI_REG_03 [expr {($a << 8) + $b}]
set MAC_LO_REG_03 [expr {($c << 24) + ($d << 16) + ($e << 8) + $f}]

# arp 4
regexp {^(\d+)\.(\d+)\.(\d+)\.(\d+)$} $NEXT_HOP_IP_4 _ a b c d
set NEXT_HOP_IP_REG_04 [expr {($a << 24) + ($b << 16) + ($c << 8) + $d}]
scan $NEXT_HOP_MAC_4 %x:%x:%x:%x:%x:%x a b c d e f
set MAC_HI_REG_04 [expr {($a << 8) + $b}]
set MAC_LO_REG_04 [expr {($c << 24) + ($d << 16) + ($e << 8) + $f}]


# Register Set 1
set WR_ADDR_REG_01 								0x00000000;
set RD_ADDR_REG_01 								0x00000000;

# Register Set 2
set WR_ADDR_REG_02 								0x00000001;
set RD_ADDR_REG_02								0x00000001;

# Register Set 3
set WR_ADDR_REG_03 								0x00000002;
set RD_ADDR_REG_03 								0x00000002;

# Register Set 4
set WR_ADDR_REG_04 								0x00000003;
set RD_ADDR_REG_04 								0x00000003;

set jtag_master [lindex [get_service_paths master] 0];

# Register Address Offset
# Dest IP
set ROUTER_OP_LUT_ARP_TABLE_ENTRY_NEXT_HOP_IP_REG 							0x80001a0;
set ROUTER_OP_LUT_ARP_TABLE_ENTRY_MAC_HI_REG 								0x8000180;
set ROUTER_OP_LUT_ARP_TABLE_ENTRY_MAC_LO_REG 								0x8000190;
set ROUTER_OP_LUT_ARP_TABLE_WR_ADDR_REG 									0x80001c0;
set ROUTER_OP_LUT_ARP_TABLE_RD_ADDR_REG 									0x80001b0;

# Starting Altera NetFPGA ARP Configuration System Console
# =================================================
puts "=============================================================================="
puts "	Starting Altera NetFPGA ARP Configuration System Console                   			"
puts "==============================================================================\n\n"

# Open JTAG Master Service
# ========================
open_service master $jtag_master;

# Writing the first set of Registers
master_write_32 $jtag_master $ROUTER_OP_LUT_ARP_TABLE_ENTRY_NEXT_HOP_IP_REG $NEXT_HOP_IP_REG_01;
master_write_32 $jtag_master $ROUTER_OP_LUT_ARP_TABLE_ENTRY_MAC_HI_REG $MAC_HI_REG_01;
master_write_32 $jtag_master $ROUTER_OP_LUT_ARP_TABLE_ENTRY_MAC_LO_REG $MAC_LO_REG_01;
master_write_32 $jtag_master $ROUTER_OP_LUT_ARP_TABLE_WR_ADDR_REG $WR_ADDR_REG_01;
# Reading the first set of Registers
master_write_32 $jtag_master $ROUTER_OP_LUT_ARP_TABLE_RD_ADDR_REG $RD_ADDR_REG_01;
puts "ARP NEXT HOP IP Address 0 \t \t = [master_read_32 $jtag_master $ROUTER_OP_LUT_ARP_TABLE_ENTRY_NEXT_HOP_IP_REG 1]";
puts "ARP MAC HI Address 0 \t \t = [master_read_32 $jtag_master $ROUTER_OP_LUT_ARP_TABLE_ENTRY_MAC_HI_REG 1]";
puts "ARP MAC LOW Address 0 \t \t = [master_read_32 $jtag_master $ROUTER_OP_LUT_ARP_TABLE_ENTRY_MAC_LO_REG 1]";
#master_read_32 $jtag_master $ROUTER_OP_LUT_ARP_TABLE_ENTRY_NEXT_HOP_IP_REG $NEXT_HOP_IP_REG_01;
#master_read_32 $jtag_master $ROUTER_OP_LUT_ARP_TABLE_ENTRY_MAC_HI_REG $MAC_HI_REG_01;
#master_read_32 $jtag_master $ROUTER_OP_LUT_ARP_TABLE_ENTRY_MAC_LO_REG $MAC_LO_REG_01;

# Writing the second set of Registers
master_write_32 $jtag_master $ROUTER_OP_LUT_ARP_TABLE_ENTRY_NEXT_HOP_IP_REG $NEXT_HOP_IP_REG_02;
master_write_32 $jtag_master $ROUTER_OP_LUT_ARP_TABLE_ENTRY_MAC_HI_REG $MAC_HI_REG_02;
master_write_32 $jtag_master $ROUTER_OP_LUT_ARP_TABLE_ENTRY_MAC_LO_REG $MAC_LO_REG_02;
master_write_32 $jtag_master $ROUTER_OP_LUT_ARP_TABLE_WR_ADDR_REG $WR_ADDR_REG_02;
# Reading the second set of Registers
master_write_32 $jtag_master $ROUTER_OP_LUT_ARP_TABLE_RD_ADDR_REG $RD_ADDR_REG_02;
puts "ARP NEXT HOP IP Address 1 \t \t = [master_read_32 $jtag_master $ROUTER_OP_LUT_ARP_TABLE_ENTRY_NEXT_HOP_IP_REG 1]";
puts "ARP MAC HI Address 1 \t \t = [master_read_32 $jtag_master $ROUTER_OP_LUT_ARP_TABLE_ENTRY_MAC_HI_REG 1]";
puts "ARP MAC LOW Address 1 \t \t = [master_read_32 $jtag_master $ROUTER_OP_LUT_ARP_TABLE_ENTRY_MAC_LO_REG 1]";

# Writing the third set of Registers
master_write_32 $jtag_master $ROUTER_OP_LUT_ARP_TABLE_ENTRY_NEXT_HOP_IP_REG $NEXT_HOP_IP_REG_03;
master_write_32 $jtag_master $ROUTER_OP_LUT_ARP_TABLE_ENTRY_MAC_HI_REG $MAC_HI_REG_03;
master_write_32 $jtag_master $ROUTER_OP_LUT_ARP_TABLE_ENTRY_MAC_LO_REG $MAC_LO_REG_03;
master_write_32 $jtag_master $ROUTER_OP_LUT_ARP_TABLE_WR_ADDR_REG $WR_ADDR_REG_03;
# Reading the third set of Registers
#master_read_32 $jtag_master $ROUTER_OP_LUT_ARP_TABLE_RD_ADDR_REG $RD_ADDR_REG_03;
#master_read_32 $jtag_master $ROUTER_OP_LUT_ARP_TABLE_ENTRY_NEXT_HOP_IP_REG $NEXT_HOP_IP_REG_03;
#master_read_32 $jtag_master $ROUTER_OP_LUT_ARP_TABLE_ENTRY_MAC_HI_REG $MAC_HI_REG_03;
#master_read_32 $jtag_master $ROUTER_OP_LUT_ARP_TABLE_ENTRY_MAC_LO_REG $MAC_LO_REG_03;

# Writing the fourth set of Registers
master_write_32 $jtag_master $ROUTER_OP_LUT_ARP_TABLE_ENTRY_NEXT_HOP_IP_REG $NEXT_HOP_IP_REG_04;
master_write_32 $jtag_master $ROUTER_OP_LUT_ARP_TABLE_ENTRY_MAC_HI_REG $MAC_HI_REG_04;
master_write_32 $jtag_master $ROUTER_OP_LUT_ARP_TABLE_ENTRY_MAC_LO_REG $MAC_LO_REG_04;
master_write_32 $jtag_master $ROUTER_OP_LUT_ARP_TABLE_WR_ADDR_REG $WR_ADDR_REG_04;
# Reading the fourth set of Registers
#master_read_32 $jtag_master $ROUTER_OP_LUT_ARP_TABLE_RD_ADDR_REG $RD_ADDR_REG_04;
#master_read_32 $jtag_master $ROUTER_OP_LUT_ARP_TABLE_ENTRY_NEXT_HOP_IP_REG $NEXT_HOP_IP_REG_04;
#master_read_32 $jtag_master $ROUTER_OP_LUT_ARP_TABLE_ENTRY_MAC_HI_REG $MAC_HI_REG_04;
#master_read_32 $jtag_master $ROUTER_OP_LUT_ARP_TABLE_ENTRY_MAC_LO_REG $MAC_LO_REG_04;

close_service master $jtag_master;
puts "\nInfo: Closed JTAG Master Service\n\n";