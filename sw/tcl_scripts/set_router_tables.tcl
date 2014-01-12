# =======================================================================================
# Project     : NetFPGA DE4
# 
# Description : Router table configuration
#
# Revision Control Information
#
# Author      : RCG
# Revision    : 
# Date        : 
# ======================================================================================

# MAC Table Configuration
# =======================

set MAC_ADDR_0     		00:4e:46:32:43:00
set MAC_ADDR_1			00:4e:46:32:43:01
set MAC_ADDR_2      	00:4e:46:32:43:02
set MAC_ADDR_3      	00:4e:46:32:43:03

# Destination IP Table Configuration
# ===================================

set DEST_IP_0      		20.1.1.1;
set DEST_IP_1      		20.2.1.1;
set DEST_IP_2      		10.2.3.1;
set DEST_IP_3      		10.1.4.1;

# LPM Table Configuration
# =======================
# Port numbers are set as per the table below
# PORT:		MAC0 	CPU0 	MAC1 	CPU1 	MAC2 	CPU2 	MAC3 	CPU3
# NO: 		 1		 2   	 4		 8  	 10		 20 	 40		 80

set LPM_IP_1      		10.1.4.0;
set LPM_MASK_1			255.255.255.0;
set LPM_NEXT_HOP_IP_1	10.1.4.1;
set LPM_OUTPUT_PORT_1	40; #MAC3

set LPM_IP_2      		10.2.3.0;
set LPM_MASK_2			255.255.255.0;
set LPM_NEXT_HOP_IP_2	10.2.3.1;
set LPM_OUTPUT_PORT_2	10; #MAC2

set LPM_IP_3      		20.5.1.0;
set LPM_MASK_3			255.255.255.0;
set LPM_NEXT_HOP_IP_3	20.5.1.5;
set LPM_OUTPUT_PORT_3	1; #MAC0

set LPM_IP_4      		30.7.2.0;
set LPM_MASK_4			255.255.255.0;
set LPM_NEXT_HOP_IP_4	30.7.2.1;
set LPM_OUTPUT_PORT_4	4; #MAC1

# ARP Table Configuration
# =======================

set NEXT_HOP_IP_1      	10.1.4.1;
set NEXT_HOP_MAC_1		00:4e:46:32:43:03;

set NEXT_HOP_IP_2      	10.2.3.1;
set NEXT_HOP_MAC_2		00:4e:46:32:43:02;

set NEXT_HOP_IP_3      	20.2.3.1;
set NEXT_HOP_MAC_3		00:f0:f1:e0:e1:00;

set NEXT_HOP_IP_4      	30.2.3.1;
set NEXT_HOP_MAC_4		00:d0:d1:c0:c1:00;

source mac.tcl
source destip.tcl
source lpm.tcl
source arp.tcl

