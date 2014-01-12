/********************************************************
*
* C register defines file for reference_router
*
********************************************************/

`ifndef _REG_DEFINES_
`define _REG_DEFINES_

/* ========= Constants ========= */

// ===== File: lib/verilog/core/common/xml/global.xml =====

// Maximum number of phy ports
`define MAX_PHY_PORTS                             4

// PCI address bus width
`define PCI_ADDR_WIDTH                            32

// PCI data bus width
`define PCI_DATA_WIDTH                            32

// PCI byte enable bus width
`define PCI_BE_WIDTH                              4

// CPCI--CNET address bus width. This is byte addresses even though bottom bits are zero.
`define CPCI_CNET_ADDR_WIDTH                      27

// CPCI--CNET data bus width
`define CPCI_CNET_DATA_WIDTH                      32

// CPCI--NF2 address bus width. This is byte addresses even though bottom bits are zero.
`define CPCI_NF2_ADDR_WIDTH                       27

// CPCI--NF2 data bus width
`define CPCI_NF2_DATA_WIDTH                       32

// DMA data bus width
`define DMA_DATA_WIDTH                            32

// DMA control bus width
`define DMA_CTRL_WIDTH                            4

// CPCI debug bus width
`define CPCI_DEBUG_DATA_WIDTH                     29

// SRAM address width
//`define SRAM_ADDR_WIDTH                           13 //DEEPAK SIZE 13->10
`define SRAM_ADDR_WIDTH				  10

// SRAM data width
`define SRAM_DATA_WIDTH                           36

// DRAM address width
`define DRAM_ADDR_WIDTH                           24


// ===== File: lib/verilog/core/common/xml/nf_defines.xml =====

// Clock period of 125 MHz clock in ns
`define FAST_CLK_PERIOD                           8

// Clock period of 62.5 MHz clock in ns
`define SLOW_CLK_PERIOD                           16

// Header value used by the IO queues
`define IO_QUEUE_STAGE_NUM                        8'hff

// Data path data width
`define DATA_WIDTH                                64

// Data path control width
`define CTRL_WIDTH                                8


// ===== File: lib/verilog/core/output_queues/sram_rr_output_queues/xml/sram_rr_output_queues.xml =====

`define NUM_OUTPUT_QUEUES                         8

`define OQ_DEFAULT_MAX_PKTS                       20'h7ffff

`define OQ_SRAM_PKT_CNT_WIDTH                     19

`define OQ_SRAM_WORD_CNT_WIDTH                    19

`define OQ_SRAM_BYTE_CNT_WIDTH                    19

`define OQ_ENABLE_SEND_BIT_NUM                    0

`define OQ_INITIALIZE_OQ_BIT_NUM                  1


// ===== File: lib/verilog/core/output_port_lookup/cam_router/xml/cam_router.xml =====

// Number of entrties in the ARP table
`define ROUTER_OP_LUT_ARP_TABLE_DEPTH             32

// Number of entrties in the routing table table
`define ROUTER_OP_LUT_ROUTE_TABLE_DEPTH           32

// Number of entrties in the destination IP filter table
`define ROUTER_OP_LUT_DST_IP_FILTER_TABLE_DEPTH   32

// Default MAC address for port 0
`define ROUTER_OP_LUT_DEFAULT_MAC_0               48'hcafef00d0001
`define ROUTER_OP_LUT_DEFAULT_MAC_0_HI            32'h0000cafe
`define ROUTER_OP_LUT_DEFAULT_MAC_0_LO            32'hf00d0001

// Default MAC address for port 1
`define ROUTER_OP_LUT_DEFAULT_MAC_1               48'hcafef00d0002
`define ROUTER_OP_LUT_DEFAULT_MAC_1_HI            32'h0000cafe
`define ROUTER_OP_LUT_DEFAULT_MAC_1_LO            32'hf00d0002

// Default MAC address for port 2
`define ROUTER_OP_LUT_DEFAULT_MAC_2               48'hcafef00d0003
`define ROUTER_OP_LUT_DEFAULT_MAC_2_HI            32'h0000cafe
`define ROUTER_OP_LUT_DEFAULT_MAC_2_LO            32'hf00d0003

// Default MAC address for port 3
`define ROUTER_OP_LUT_DEFAULT_MAC_3               48'hcafef00d0004
`define ROUTER_OP_LUT_DEFAULT_MAC_3_HI            32'h0000cafe
`define ROUTER_OP_LUT_DEFAULT_MAC_3_LO            32'hf00d0004


// ===== File: lib/verilog/core/utils/xml/device_id_reg.xml =====

// Total number of registers
`define DEV_ID_NUM_REGS                           32

// Number of non string registers
`define DEV_ID_NON_DEV_STR_REGS                   7

// Device description length (in words, not chars)
`define DEV_ID_DEV_STR_WORD_LEN                   25

// Device description length (in bytes/chars)
`define DEV_ID_DEV_STR_BYTE_LEN                   100

// Device description length (in bits)
`define DEV_ID_DEV_STR_BIT_LEN                    800

// Length of MD5 sum (bits)
`define DEV_ID_MD5SUM_LENGTH                      128

// MD5 sum of the string "device_id.v"
`define DEV_ID_MD5_VALUE                          128'h4071736d8a603d2b4d55f62989a73c95
`define DEV_ID_MD5_VALUE_0                        32'h4071736d
`define DEV_ID_MD5_VALUE_1                        32'h8a603d2b
`define DEV_ID_MD5_VALUE_2                        32'h4d55f629
`define DEV_ID_MD5_VALUE_3                        32'h89a73c95


// ===== File: lib/verilog/core/io_queues/ethernet_mac/xml/ethernet_mac.xml =====

// TX queue disable bit
`define MAC_GRP_TX_QUEUE_DISABLE_BIT_NUM          0

// RX queue disable bit
`define MAC_GRP_RX_QUEUE_DISABLE_BIT_NUM          1

// Reset MAC bit
`define MAC_GRP_RESET_MAC_BIT_NUM                 2

// MAC TX queue disable bit
`define MAC_GRP_MAC_DISABLE_TX_BIT_NUM            3

// MAC RX queue disable bit
`define MAC_GRP_MAC_DISABLE_RX_BIT_NUM            4

// MAC disable jumbo TX bit
`define MAC_GRP_MAC_DIS_JUMBO_TX_BIT_NUM          5

// MAC disable jumbo RX bit
`define MAC_GRP_MAC_DIS_JUMBO_RX_BIT_NUM          6

// MAC disable crc check disable bit
`define MAC_GRP_MAC_DIS_CRC_CHECK_BIT_NUM         7

// MAC disable crc generate bit
`define MAC_GRP_MAC_DIS_CRC_GEN_BIT_NUM           8


// -------------------------------------
//   Modules
// -------------------------------------

// Module tags
`define CORE_BASE_ADDR           0x0000000
`define DEV_ID_BASE_ADDR         0x0400000
`define MDIO_BASE_ADDR           0x0440000
`define DMA_BASE_ADDR            0x0500000
`define MAC_GRP_0_BASE_ADDR      0x0600000
`define MAC_GRP_1_BASE_ADDR      0x0640000
`define MAC_GRP_2_BASE_ADDR      0x0680000
`define MAC_GRP_3_BASE_ADDR      0x06c0000
`define CPU_QUEUE_0_BASE_ADDR    0x0700000
`define CPU_QUEUE_1_BASE_ADDR    0x0740000
`define CPU_QUEUE_2_BASE_ADDR    0x0780000
`define CPU_QUEUE_3_BASE_ADDR    0x07c0000
`define SRAM_BASE_ADDR           0x1000000
`define UDP_BASE_ADDR            0x2000000
`define ROUTER_OP_LUT_BASE_ADDR  0x2000000
`define STRIP_HEADERS_BASE_ADDR  0x2000100
`define IN_ARB_BASE_ADDR         0x2000200
`define OQ_BASE_ADDR             0x2001000
`define DRAM_BASE_ADDR           0x4000000

`define CPU_QUEUE_OFFSET       0x0040000
`define MAC_GRP_OFFSET         0x0040000


/* ========== Registers ========== */

// Name: device_id (DEV_ID)
// Description: Device identification
// File: lib/verilog/core/utils/xml/device_id_reg.xml
`define DEV_ID_MD5_0_REG        0x0400000
`define DEV_ID_MD5_1_REG        0x0400004
`define DEV_ID_MD5_2_REG        0x0400008
`define DEV_ID_MD5_3_REG        0x040000c
`define DEV_ID_DEVICE_ID_REG    0x0400010
`define DEV_ID_REVISION_REG     0x0400014
`define DEV_ID_CPCI_ID_REG      0x0400018
`define DEV_ID_DEV_STR_0_REG    0x040001c
`define DEV_ID_DEV_STR_1_REG    0x0400020
`define DEV_ID_DEV_STR_2_REG    0x0400024
`define DEV_ID_DEV_STR_3_REG    0x0400028
`define DEV_ID_DEV_STR_4_REG    0x040002c
`define DEV_ID_DEV_STR_5_REG    0x0400030
`define DEV_ID_DEV_STR_6_REG    0x0400034
`define DEV_ID_DEV_STR_7_REG    0x0400038
`define DEV_ID_DEV_STR_8_REG    0x040003c
`define DEV_ID_DEV_STR_9_REG    0x0400040
`define DEV_ID_DEV_STR_10_REG   0x0400044
`define DEV_ID_DEV_STR_11_REG   0x0400048
`define DEV_ID_DEV_STR_12_REG   0x040004c
`define DEV_ID_DEV_STR_13_REG   0x0400050
`define DEV_ID_DEV_STR_14_REG   0x0400054
`define DEV_ID_DEV_STR_15_REG   0x0400058
`define DEV_ID_DEV_STR_16_REG   0x040005c
`define DEV_ID_DEV_STR_17_REG   0x0400060
`define DEV_ID_DEV_STR_18_REG   0x0400064
`define DEV_ID_DEV_STR_19_REG   0x0400068
`define DEV_ID_DEV_STR_20_REG   0x040006c
`define DEV_ID_DEV_STR_21_REG   0x0400070
`define DEV_ID_DEV_STR_22_REG   0x0400074
`define DEV_ID_DEV_STR_23_REG   0x0400078
`define DEV_ID_DEV_STR_24_REG   0x040007c

// Name: mdio (MDIO)
// Description: MDIO interface
// File: lib/verilog/core/io/mdio/xml/mdio.xml
`define MDIO_PHY_0_CONTROL_REG                                  0x0440000
`define MDIO_PHY_0_STATUS_REG                                   0x0440004
`define MDIO_PHY_0_PHY_ID_0_REG                                 0x0440008
`define MDIO_PHY_0_PHY_ID_1_REG                                 0x044000c
`define MDIO_PHY_0_AUTONEGOTIATION_ADVERT_REG                   0x0440010
`define MDIO_PHY_0_AUTONEG_LINK_PARTNER_BASE_PAGE_ABILITY_REG   0x0440014
`define MDIO_PHY_0_AUTONEG_EXPANSION_REG                        0x0440018
`define MDIO_PHY_0_AUTONEG_NEXT_PAGE_TX_REG                     0x044001c
`define MDIO_PHY_0_AUTONEG_LINK_PARTNER_RCVD_NEXT_PAGE_REG      0x0440020
`define MDIO_PHY_0_MASTER_SLAVE_CTRL_REG                        0x0440024
`define MDIO_PHY_0_MASTER_SLAVE_STATUS_REG                      0x0440028
`define MDIO_PHY_0_PSE_CTRL_REG                                 0x044002c
`define MDIO_PHY_0_PSE_STATUS_REG                               0x0440030
`define MDIO_PHY_0_MMD_ACCESS_CTRL_REG                          0x0440034
`define MDIO_PHY_0_MMD_ACCESS_STATUS_REG                        0x0440038
`define MDIO_PHY_0_EXTENDED_STATUS_REG                          0x044003c
`define MDIO_PHY_1_CONTROL_REG                                  0x0440080
`define MDIO_PHY_1_STATUS_REG                                   0x0440084
`define MDIO_PHY_1_PHY_ID_0_REG                                 0x0440088
`define MDIO_PHY_1_PHY_ID_1_REG                                 0x044008c
`define MDIO_PHY_1_AUTONEGOTIATION_ADVERT_REG                   0x0440090
`define MDIO_PHY_1_AUTONEG_LINK_PARTNER_BASE_PAGE_ABILITY_REG   0x0440094
`define MDIO_PHY_1_AUTONEG_EXPANSION_REG                        0x0440098
`define MDIO_PHY_1_AUTONEG_NEXT_PAGE_TX_REG                     0x044009c
`define MDIO_PHY_1_AUTONEG_LINK_PARTNER_RCVD_NEXT_PAGE_REG      0x04400a0
`define MDIO_PHY_1_MASTER_SLAVE_CTRL_REG                        0x04400a4
`define MDIO_PHY_1_MASTER_SLAVE_STATUS_REG                      0x04400a8
`define MDIO_PHY_1_PSE_CTRL_REG                                 0x04400ac
`define MDIO_PHY_1_PSE_STATUS_REG                               0x04400b0
`define MDIO_PHY_1_MMD_ACCESS_CTRL_REG                          0x04400b4
`define MDIO_PHY_1_MMD_ACCESS_STATUS_REG                        0x04400b8
`define MDIO_PHY_1_EXTENDED_STATUS_REG                          0x04400bc
`define MDIO_PHY_2_CONTROL_REG                                  0x0440100
`define MDIO_PHY_2_STATUS_REG                                   0x0440104
`define MDIO_PHY_2_PHY_ID_0_REG                                 0x0440108
`define MDIO_PHY_2_PHY_ID_1_REG                                 0x044010c
`define MDIO_PHY_2_AUTONEGOTIATION_ADVERT_REG                   0x0440110
`define MDIO_PHY_2_AUTONEG_LINK_PARTNER_BASE_PAGE_ABILITY_REG   0x0440114
`define MDIO_PHY_2_AUTONEG_EXPANSION_REG                        0x0440118
`define MDIO_PHY_2_AUTONEG_NEXT_PAGE_TX_REG                     0x044011c
`define MDIO_PHY_2_AUTONEG_LINK_PARTNER_RCVD_NEXT_PAGE_REG      0x0440120
`define MDIO_PHY_2_MASTER_SLAVE_CTRL_REG                        0x0440124
`define MDIO_PHY_2_MASTER_SLAVE_STATUS_REG                      0x0440128
`define MDIO_PHY_2_PSE_CTRL_REG                                 0x044012c
`define MDIO_PHY_2_PSE_STATUS_REG                               0x0440130
`define MDIO_PHY_2_MMD_ACCESS_CTRL_REG                          0x0440134
`define MDIO_PHY_2_MMD_ACCESS_STATUS_REG                        0x0440138
`define MDIO_PHY_2_EXTENDED_STATUS_REG                          0x044013c
`define MDIO_PHY_3_CONTROL_REG                                  0x0440180
`define MDIO_PHY_3_STATUS_REG                                   0x0440184
`define MDIO_PHY_3_PHY_ID_0_REG                                 0x0440188
`define MDIO_PHY_3_PHY_ID_1_REG                                 0x044018c
`define MDIO_PHY_3_AUTONEGOTIATION_ADVERT_REG                   0x0440190
`define MDIO_PHY_3_AUTONEG_LINK_PARTNER_BASE_PAGE_ABILITY_REG   0x0440194
`define MDIO_PHY_3_AUTONEG_EXPANSION_REG                        0x0440198
`define MDIO_PHY_3_AUTONEG_NEXT_PAGE_TX_REG                     0x044019c
`define MDIO_PHY_3_AUTONEG_LINK_PARTNER_RCVD_NEXT_PAGE_REG      0x04401a0
`define MDIO_PHY_3_MASTER_SLAVE_CTRL_REG                        0x04401a4
`define MDIO_PHY_3_MASTER_SLAVE_STATUS_REG                      0x04401a8
`define MDIO_PHY_3_PSE_CTRL_REG                                 0x04401ac
`define MDIO_PHY_3_PSE_STATUS_REG                               0x04401b0
`define MDIO_PHY_3_MMD_ACCESS_CTRL_REG                          0x04401b4
`define MDIO_PHY_3_MMD_ACCESS_STATUS_REG                        0x04401b8
`define MDIO_PHY_3_EXTENDED_STATUS_REG                          0x04401bc

`define MDIO_PHY_GROUP_BASE_ADDR   0x0440000
`define MDIO_PHY_GROUP_INST_OFFSET 0x0000080

// Name: dma (DMA)
// Description: DMA transfer module
// File: lib/verilog/core/dma/xml/dma.xml

// Name: nf2_mac_grp (MAC_GRP_0)
// Description: Ethernet MAC group
// File: lib/verilog/core/io_queues/ethernet_mac/xml/ethernet_mac.xml
`define MAC_GRP_0_CONTROL_REG                          0x0600000
`define MAC_GRP_0_RX_QUEUE_NUM_PKTS_IN_QUEUE_REG       0x0600004
`define MAC_GRP_0_RX_QUEUE_NUM_PKTS_STORED_REG         0x0600008
`define MAC_GRP_0_RX_QUEUE_NUM_PKTS_DROPPED_FULL_REG   0x060000c
`define MAC_GRP_0_RX_QUEUE_NUM_PKTS_DROPPED_BAD_REG    0x0600010
`define MAC_GRP_0_RX_QUEUE_NUM_PKTS_DEQUEUED_REG       0x0600014
`define MAC_GRP_0_RX_QUEUE_NUM_WORDS_PUSHED_REG        0x0600018
`define MAC_GRP_0_RX_QUEUE_NUM_BYTES_PUSHED_REG        0x060001c
`define MAC_GRP_0_TX_QUEUE_NUM_PKTS_IN_QUEUE_REG       0x0600020
`define MAC_GRP_0_TX_QUEUE_NUM_PKTS_ENQUEUED_REG       0x0600024
`define MAC_GRP_0_TX_QUEUE_NUM_PKTS_SENT_REG           0x0600028
`define MAC_GRP_0_TX_QUEUE_NUM_WORDS_PUSHED_REG        0x060002c
`define MAC_GRP_0_TX_QUEUE_NUM_BYTES_PUSHED_REG        0x0600030

// Name: nf2_mac_grp (MAC_GRP_1)
// Description: Ethernet MAC group
// File: lib/verilog/core/io_queues/ethernet_mac/xml/ethernet_mac.xml
`define MAC_GRP_1_CONTROL_REG                          0x0640000
`define MAC_GRP_1_RX_QUEUE_NUM_PKTS_IN_QUEUE_REG       0x0640004
`define MAC_GRP_1_RX_QUEUE_NUM_PKTS_STORED_REG         0x0640008
`define MAC_GRP_1_RX_QUEUE_NUM_PKTS_DROPPED_FULL_REG   0x064000c
`define MAC_GRP_1_RX_QUEUE_NUM_PKTS_DROPPED_BAD_REG    0x0640010
`define MAC_GRP_1_RX_QUEUE_NUM_PKTS_DEQUEUED_REG       0x0640014
`define MAC_GRP_1_RX_QUEUE_NUM_WORDS_PUSHED_REG        0x0640018
`define MAC_GRP_1_RX_QUEUE_NUM_BYTES_PUSHED_REG        0x064001c
`define MAC_GRP_1_TX_QUEUE_NUM_PKTS_IN_QUEUE_REG       0x0640020
`define MAC_GRP_1_TX_QUEUE_NUM_PKTS_ENQUEUED_REG       0x0640024
`define MAC_GRP_1_TX_QUEUE_NUM_PKTS_SENT_REG           0x0640028
`define MAC_GRP_1_TX_QUEUE_NUM_WORDS_PUSHED_REG        0x064002c
`define MAC_GRP_1_TX_QUEUE_NUM_BYTES_PUSHED_REG        0x0640030

// Name: nf2_mac_grp (MAC_GRP_2)
// Description: Ethernet MAC group
// File: lib/verilog/core/io_queues/ethernet_mac/xml/ethernet_mac.xml
`define MAC_GRP_2_CONTROL_REG                          0x0680000
`define MAC_GRP_2_RX_QUEUE_NUM_PKTS_IN_QUEUE_REG       0x0680004
`define MAC_GRP_2_RX_QUEUE_NUM_PKTS_STORED_REG         0x0680008
`define MAC_GRP_2_RX_QUEUE_NUM_PKTS_DROPPED_FULL_REG   0x068000c
`define MAC_GRP_2_RX_QUEUE_NUM_PKTS_DROPPED_BAD_REG    0x0680010
`define MAC_GRP_2_RX_QUEUE_NUM_PKTS_DEQUEUED_REG       0x0680014
`define MAC_GRP_2_RX_QUEUE_NUM_WORDS_PUSHED_REG        0x0680018
`define MAC_GRP_2_RX_QUEUE_NUM_BYTES_PUSHED_REG        0x068001c
`define MAC_GRP_2_TX_QUEUE_NUM_PKTS_IN_QUEUE_REG       0x0680020
`define MAC_GRP_2_TX_QUEUE_NUM_PKTS_ENQUEUED_REG       0x0680024
`define MAC_GRP_2_TX_QUEUE_NUM_PKTS_SENT_REG           0x0680028
`define MAC_GRP_2_TX_QUEUE_NUM_WORDS_PUSHED_REG        0x068002c
`define MAC_GRP_2_TX_QUEUE_NUM_BYTES_PUSHED_REG        0x0680030

// Name: nf2_mac_grp (MAC_GRP_3)
// Description: Ethernet MAC group
// File: lib/verilog/core/io_queues/ethernet_mac/xml/ethernet_mac.xml
`define MAC_GRP_3_CONTROL_REG                          0x06c0000
`define MAC_GRP_3_RX_QUEUE_NUM_PKTS_IN_QUEUE_REG       0x06c0004
`define MAC_GRP_3_RX_QUEUE_NUM_PKTS_STORED_REG         0x06c0008
`define MAC_GRP_3_RX_QUEUE_NUM_PKTS_DROPPED_FULL_REG   0x06c000c
`define MAC_GRP_3_RX_QUEUE_NUM_PKTS_DROPPED_BAD_REG    0x06c0010
`define MAC_GRP_3_RX_QUEUE_NUM_PKTS_DEQUEUED_REG       0x06c0014
`define MAC_GRP_3_RX_QUEUE_NUM_WORDS_PUSHED_REG        0x06c0018
`define MAC_GRP_3_RX_QUEUE_NUM_BYTES_PUSHED_REG        0x06c001c
`define MAC_GRP_3_TX_QUEUE_NUM_PKTS_IN_QUEUE_REG       0x06c0020
`define MAC_GRP_3_TX_QUEUE_NUM_PKTS_ENQUEUED_REG       0x06c0024
`define MAC_GRP_3_TX_QUEUE_NUM_PKTS_SENT_REG           0x06c0028
`define MAC_GRP_3_TX_QUEUE_NUM_WORDS_PUSHED_REG        0x06c002c
`define MAC_GRP_3_TX_QUEUE_NUM_BYTES_PUSHED_REG        0x06c0030

// Name: cpu_dma_queue (CPU_QUEUE_0)
// Description: CPU DMA queue
// File: lib/verilog/core/io_queues/cpu_dma_queue/xml/cpu_dma_queue.xml

// Name: cpu_dma_queue (CPU_QUEUE_1)
// Description: CPU DMA queue
// File: lib/verilog/core/io_queues/cpu_dma_queue/xml/cpu_dma_queue.xml

// Name: cpu_dma_queue (CPU_QUEUE_2)
// Description: CPU DMA queue
// File: lib/verilog/core/io_queues/cpu_dma_queue/xml/cpu_dma_queue.xml

// Name: cpu_dma_queue (CPU_QUEUE_3)
// Description: CPU DMA queue
// File: lib/verilog/core/io_queues/cpu_dma_queue/xml/cpu_dma_queue.xml

// Name: SRAM (SRAM)
// Description: SRAM

// Name: router_op_lut (ROUTER_OP_LUT)
// Description: Output port lookup for IPv4 router (CAM based)
// File: lib/verilog/core/output_port_lookup/cam_router/xml/cam_router.xml
`define ROUTER_OP_LUT_ARP_NUM_MISSES_REG                  0x2000000
`define ROUTER_OP_LUT_LPM_NUM_MISSES_REG                  0x2000004
`define ROUTER_OP_LUT_NUM_CPU_PKTS_SENT_REG               0x2000008
`define ROUTER_OP_LUT_NUM_BAD_OPTS_VER_REG                0x200000c
`define ROUTER_OP_LUT_NUM_BAD_CHKSUMS_REG                 0x2000010
`define ROUTER_OP_LUT_NUM_BAD_TTLS_REG                    0x2000014
`define ROUTER_OP_LUT_NUM_NON_IP_RCVD_REG                 0x2000018
`define ROUTER_OP_LUT_NUM_PKTS_FORWARDED_REG              0x200001c
`define ROUTER_OP_LUT_NUM_WRONG_DEST_REG                  0x2000020
`define ROUTER_OP_LUT_NUM_FILTERED_PKTS_REG               0x2000024
`define ROUTER_OP_LUT_MAC_0_HI_REG                        0x2000028
`define ROUTER_OP_LUT_MAC_0_LO_REG                        0x200002c
`define ROUTER_OP_LUT_MAC_1_HI_REG                        0x2000030
`define ROUTER_OP_LUT_MAC_1_LO_REG                        0x2000034
`define ROUTER_OP_LUT_MAC_2_HI_REG                        0x2000038
`define ROUTER_OP_LUT_MAC_2_LO_REG                        0x200003c
`define ROUTER_OP_LUT_MAC_3_HI_REG                        0x2000040
`define ROUTER_OP_LUT_MAC_3_LO_REG                        0x2000044
`define ROUTER_OP_LUT_ROUTE_TABLE_ENTRY_IP_REG            0x2000048
`define ROUTER_OP_LUT_ROUTE_TABLE_ENTRY_MASK_REG          0x200004c
`define ROUTER_OP_LUT_ROUTE_TABLE_ENTRY_NEXT_HOP_IP_REG   0x2000050
`define ROUTER_OP_LUT_ROUTE_TABLE_ENTRY_OUTPUT_PORT_REG   0x2000054
`define ROUTER_OP_LUT_ROUTE_TABLE_RD_ADDR_REG             0x2000058
`define ROUTER_OP_LUT_ROUTE_TABLE_WR_ADDR_REG             0x200005c
`define ROUTER_OP_LUT_ARP_TABLE_ENTRY_MAC_HI_REG          0x2000060
`define ROUTER_OP_LUT_ARP_TABLE_ENTRY_MAC_LO_REG          0x2000064
`define ROUTER_OP_LUT_ARP_TABLE_ENTRY_NEXT_HOP_IP_REG     0x2000068
`define ROUTER_OP_LUT_ARP_TABLE_RD_ADDR_REG               0x200006c
`define ROUTER_OP_LUT_ARP_TABLE_WR_ADDR_REG               0x2000070
`define ROUTER_OP_LUT_DST_IP_FILTER_TABLE_ENTRY_IP_REG    0x2000074
`define ROUTER_OP_LUT_DST_IP_FILTER_TABLE_RD_ADDR_REG     0x2000078
`define ROUTER_OP_LUT_DST_IP_FILTER_TABLE_WR_ADDR_REG     0x200007c

// Name: strip_headers (STRIP_HEADERS)
// Description: Strip headers from data
// File: lib/verilog/core/strip_headers/keep_length/xml/strip_headers.xml

// Name: in_arb (IN_ARB)
// Description: Round-robin input arbiter
// File: lib/verilog/core/input_arbiter/rr_input_arbiter/xml/rr_input_arbiter.xml
`define IN_ARB_NUM_PKTS_SENT_REG        0x2000200
`define IN_ARB_LAST_PKT_WORD_0_HI_REG   0x2000204
`define IN_ARB_LAST_PKT_WORD_0_LO_REG   0x2000208
`define IN_ARB_LAST_PKT_CTRL_0_REG      0x200020c
`define IN_ARB_LAST_PKT_WORD_1_HI_REG   0x2000210
`define IN_ARB_LAST_PKT_WORD_1_LO_REG   0x2000214
`define IN_ARB_LAST_PKT_CTRL_1_REG      0x2000218
`define IN_ARB_STATE_REG                0x200021c

// Name: output_queues (OQ)
// Description: SRAM-based output queue using round-robin removal
// File: lib/verilog/core/output_queues/sram_rr_output_queues/xml/sram_rr_output_queues.xml
`define OQ_QUEUE_0_CTRL_REG                         0x2001000
`define OQ_QUEUE_0_NUM_PKT_BYTES_STORED_REG         0x2001004
`define OQ_QUEUE_0_NUM_OVERHEAD_BYTES_STORED_REG    0x2001008
`define OQ_QUEUE_0_NUM_PKT_BYTES_REMOVED_REG        0x200100c
`define OQ_QUEUE_0_NUM_OVERHEAD_BYTES_REMOVED_REG   0x2001010
`define OQ_QUEUE_0_NUM_PKTS_STORED_REG              0x2001014
`define OQ_QUEUE_0_NUM_PKTS_DROPPED_REG             0x2001018
`define OQ_QUEUE_0_NUM_PKTS_REMOVED_REG             0x200101c
`define OQ_QUEUE_0_ADDR_LO_REG                      0x2001020
`define OQ_QUEUE_0_ADDR_HI_REG                      0x2001024
`define OQ_QUEUE_0_RD_ADDR_REG                      0x2001028
`define OQ_QUEUE_0_WR_ADDR_REG                      0x200102c
`define OQ_QUEUE_0_NUM_PKTS_IN_Q_REG                0x2001030
`define OQ_QUEUE_0_MAX_PKTS_IN_Q_REG                0x2001034
`define OQ_QUEUE_0_NUM_WORDS_IN_Q_REG               0x2001038
`define OQ_QUEUE_0_NUM_WORDS_LEFT_REG               0x200103c
`define OQ_QUEUE_0_FULL_THRESH_REG                  0x2001040
`define OQ_QUEUE_1_CTRL_REG                         0x2001200
`define OQ_QUEUE_1_NUM_PKT_BYTES_STORED_REG         0x2001204
`define OQ_QUEUE_1_NUM_OVERHEAD_BYTES_STORED_REG    0x2001208
`define OQ_QUEUE_1_NUM_PKT_BYTES_REMOVED_REG        0x200120c
`define OQ_QUEUE_1_NUM_OVERHEAD_BYTES_REMOVED_REG   0x2001210
`define OQ_QUEUE_1_NUM_PKTS_STORED_REG              0x2001214
`define OQ_QUEUE_1_NUM_PKTS_DROPPED_REG             0x2001218
`define OQ_QUEUE_1_NUM_PKTS_REMOVED_REG             0x200121c
`define OQ_QUEUE_1_ADDR_LO_REG                      0x2001220
`define OQ_QUEUE_1_ADDR_HI_REG                      0x2001224
`define OQ_QUEUE_1_RD_ADDR_REG                      0x2001228
`define OQ_QUEUE_1_WR_ADDR_REG                      0x200122c
`define OQ_QUEUE_1_NUM_PKTS_IN_Q_REG                0x2001230
`define OQ_QUEUE_1_MAX_PKTS_IN_Q_REG                0x2001234
`define OQ_QUEUE_1_NUM_WORDS_IN_Q_REG               0x2001238
`define OQ_QUEUE_1_NUM_WORDS_LEFT_REG               0x200123c
`define OQ_QUEUE_1_FULL_THRESH_REG                  0x2001240
`define OQ_QUEUE_2_CTRL_REG                         0x2001400
`define OQ_QUEUE_2_NUM_PKT_BYTES_STORED_REG         0x2001404
`define OQ_QUEUE_2_NUM_OVERHEAD_BYTES_STORED_REG    0x2001408
`define OQ_QUEUE_2_NUM_PKT_BYTES_REMOVED_REG        0x200140c
`define OQ_QUEUE_2_NUM_OVERHEAD_BYTES_REMOVED_REG   0x2001410
`define OQ_QUEUE_2_NUM_PKTS_STORED_REG              0x2001414
`define OQ_QUEUE_2_NUM_PKTS_DROPPED_REG             0x2001418
`define OQ_QUEUE_2_NUM_PKTS_REMOVED_REG             0x200141c
`define OQ_QUEUE_2_ADDR_LO_REG                      0x2001420
`define OQ_QUEUE_2_ADDR_HI_REG                      0x2001424
`define OQ_QUEUE_2_RD_ADDR_REG                      0x2001428
`define OQ_QUEUE_2_WR_ADDR_REG                      0x200142c
`define OQ_QUEUE_2_NUM_PKTS_IN_Q_REG                0x2001430
`define OQ_QUEUE_2_MAX_PKTS_IN_Q_REG                0x2001434
`define OQ_QUEUE_2_NUM_WORDS_IN_Q_REG               0x2001438
`define OQ_QUEUE_2_NUM_WORDS_LEFT_REG               0x200143c
`define OQ_QUEUE_2_FULL_THRESH_REG                  0x2001440
`define OQ_QUEUE_3_CTRL_REG                         0x2001600
`define OQ_QUEUE_3_NUM_PKT_BYTES_STORED_REG         0x2001604
`define OQ_QUEUE_3_NUM_OVERHEAD_BYTES_STORED_REG    0x2001608
`define OQ_QUEUE_3_NUM_PKT_BYTES_REMOVED_REG        0x200160c
`define OQ_QUEUE_3_NUM_OVERHEAD_BYTES_REMOVED_REG   0x2001610
`define OQ_QUEUE_3_NUM_PKTS_STORED_REG              0x2001614
`define OQ_QUEUE_3_NUM_PKTS_DROPPED_REG             0x2001618
`define OQ_QUEUE_3_NUM_PKTS_REMOVED_REG             0x200161c
`define OQ_QUEUE_3_ADDR_LO_REG                      0x2001620
`define OQ_QUEUE_3_ADDR_HI_REG                      0x2001624
`define OQ_QUEUE_3_RD_ADDR_REG                      0x2001628
`define OQ_QUEUE_3_WR_ADDR_REG                      0x200162c
`define OQ_QUEUE_3_NUM_PKTS_IN_Q_REG                0x2001630
`define OQ_QUEUE_3_MAX_PKTS_IN_Q_REG                0x2001634
`define OQ_QUEUE_3_NUM_WORDS_IN_Q_REG               0x2001638
`define OQ_QUEUE_3_NUM_WORDS_LEFT_REG               0x200163c
`define OQ_QUEUE_3_FULL_THRESH_REG                  0x2001640
`define OQ_QUEUE_4_CTRL_REG                         0x2001800
`define OQ_QUEUE_4_NUM_PKT_BYTES_STORED_REG         0x2001804
`define OQ_QUEUE_4_NUM_OVERHEAD_BYTES_STORED_REG    0x2001808
`define OQ_QUEUE_4_NUM_PKT_BYTES_REMOVED_REG        0x200180c
`define OQ_QUEUE_4_NUM_OVERHEAD_BYTES_REMOVED_REG   0x2001810
`define OQ_QUEUE_4_NUM_PKTS_STORED_REG              0x2001814
`define OQ_QUEUE_4_NUM_PKTS_DROPPED_REG             0x2001818
`define OQ_QUEUE_4_NUM_PKTS_REMOVED_REG             0x200181c
`define OQ_QUEUE_4_ADDR_LO_REG                      0x2001820
`define OQ_QUEUE_4_ADDR_HI_REG                      0x2001824
`define OQ_QUEUE_4_RD_ADDR_REG                      0x2001828
`define OQ_QUEUE_4_WR_ADDR_REG                      0x200182c
`define OQ_QUEUE_4_NUM_PKTS_IN_Q_REG                0x2001830
`define OQ_QUEUE_4_MAX_PKTS_IN_Q_REG                0x2001834
`define OQ_QUEUE_4_NUM_WORDS_IN_Q_REG               0x2001838
`define OQ_QUEUE_4_NUM_WORDS_LEFT_REG               0x200183c
`define OQ_QUEUE_4_FULL_THRESH_REG                  0x2001840
`define OQ_QUEUE_5_CTRL_REG                         0x2001a00
`define OQ_QUEUE_5_NUM_PKT_BYTES_STORED_REG         0x2001a04
`define OQ_QUEUE_5_NUM_OVERHEAD_BYTES_STORED_REG    0x2001a08
`define OQ_QUEUE_5_NUM_PKT_BYTES_REMOVED_REG        0x2001a0c
`define OQ_QUEUE_5_NUM_OVERHEAD_BYTES_REMOVED_REG   0x2001a10
`define OQ_QUEUE_5_NUM_PKTS_STORED_REG              0x2001a14
`define OQ_QUEUE_5_NUM_PKTS_DROPPED_REG             0x2001a18
`define OQ_QUEUE_5_NUM_PKTS_REMOVED_REG             0x2001a1c
`define OQ_QUEUE_5_ADDR_LO_REG                      0x2001a20
`define OQ_QUEUE_5_ADDR_HI_REG                      0x2001a24
`define OQ_QUEUE_5_RD_ADDR_REG                      0x2001a28
`define OQ_QUEUE_5_WR_ADDR_REG                      0x2001a2c
`define OQ_QUEUE_5_NUM_PKTS_IN_Q_REG                0x2001a30
`define OQ_QUEUE_5_MAX_PKTS_IN_Q_REG                0x2001a34
`define OQ_QUEUE_5_NUM_WORDS_IN_Q_REG               0x2001a38
`define OQ_QUEUE_5_NUM_WORDS_LEFT_REG               0x2001a3c
`define OQ_QUEUE_5_FULL_THRESH_REG                  0x2001a40
`define OQ_QUEUE_6_CTRL_REG                         0x2001c00
`define OQ_QUEUE_6_NUM_PKT_BYTES_STORED_REG         0x2001c04
`define OQ_QUEUE_6_NUM_OVERHEAD_BYTES_STORED_REG    0x2001c08
`define OQ_QUEUE_6_NUM_PKT_BYTES_REMOVED_REG        0x2001c0c
`define OQ_QUEUE_6_NUM_OVERHEAD_BYTES_REMOVED_REG   0x2001c10
`define OQ_QUEUE_6_NUM_PKTS_STORED_REG              0x2001c14
`define OQ_QUEUE_6_NUM_PKTS_DROPPED_REG             0x2001c18
`define OQ_QUEUE_6_NUM_PKTS_REMOVED_REG             0x2001c1c
`define OQ_QUEUE_6_ADDR_LO_REG                      0x2001c20
`define OQ_QUEUE_6_ADDR_HI_REG                      0x2001c24
`define OQ_QUEUE_6_RD_ADDR_REG                      0x2001c28
`define OQ_QUEUE_6_WR_ADDR_REG                      0x2001c2c
`define OQ_QUEUE_6_NUM_PKTS_IN_Q_REG                0x2001c30
`define OQ_QUEUE_6_MAX_PKTS_IN_Q_REG                0x2001c34
`define OQ_QUEUE_6_NUM_WORDS_IN_Q_REG               0x2001c38
`define OQ_QUEUE_6_NUM_WORDS_LEFT_REG               0x2001c3c
`define OQ_QUEUE_6_FULL_THRESH_REG                  0x2001c40
`define OQ_QUEUE_7_CTRL_REG                         0x2001e00
`define OQ_QUEUE_7_NUM_PKT_BYTES_STORED_REG         0x2001e04
`define OQ_QUEUE_7_NUM_OVERHEAD_BYTES_STORED_REG    0x2001e08
`define OQ_QUEUE_7_NUM_PKT_BYTES_REMOVED_REG        0x2001e0c
`define OQ_QUEUE_7_NUM_OVERHEAD_BYTES_REMOVED_REG   0x2001e10
`define OQ_QUEUE_7_NUM_PKTS_STORED_REG              0x2001e14
`define OQ_QUEUE_7_NUM_PKTS_DROPPED_REG             0x2001e18
`define OQ_QUEUE_7_NUM_PKTS_REMOVED_REG             0x2001e1c
`define OQ_QUEUE_7_ADDR_LO_REG                      0x2001e20
`define OQ_QUEUE_7_ADDR_HI_REG                      0x2001e24
`define OQ_QUEUE_7_RD_ADDR_REG                      0x2001e28
`define OQ_QUEUE_7_WR_ADDR_REG                      0x2001e2c
`define OQ_QUEUE_7_NUM_PKTS_IN_Q_REG                0x2001e30
`define OQ_QUEUE_7_MAX_PKTS_IN_Q_REG                0x2001e34
`define OQ_QUEUE_7_NUM_WORDS_IN_Q_REG               0x2001e38
`define OQ_QUEUE_7_NUM_WORDS_LEFT_REG               0x2001e3c
`define OQ_QUEUE_7_FULL_THRESH_REG                  0x2001e40

`define OQ_QUEUE_GROUP_BASE_ADDR   0x2001000
`define OQ_QUEUE_GROUP_INST_OFFSET 0x0000200

// Name: DRAM (DRAM)
// Description: DRAM




`endif

