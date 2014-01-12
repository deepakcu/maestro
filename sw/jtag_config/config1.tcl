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
set MAC_1_BASE_ADDRESS     		0x20000400;
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

set MAC_0 				0x32464e00; #00:4e:46:32:43:01
set MAC_1 				0x00000143;
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
set PHY_ADDR 			1;		# PHY Address

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
										
source tse_mac_config1.tcl
source tse_marvel_phy1.tcl
source tse_pcs_config1.tcl



										
