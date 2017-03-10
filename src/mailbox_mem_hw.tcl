# TCL File Generated by Component Editor 15.0
# Fri Mar 10 17:26:17 CET 2017
# DO NOT MODIFY


# 
# mailbox_mem "mailbox_mem" v1.0
#  2017.03.10.17:26:17
# 
# 

# 
# request TCL package from ACDS 15.0
# 
package require -exact qsys 15.0


# 
# module mailbox_mem
# 
set_module_property DESCRIPTION ""
set_module_property NAME mailbox_mem
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property GROUP Custom
set_module_property AUTHOR ""
set_module_property DISPLAY_NAME mailbox_mem
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL mailbox_mem
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file mailbox_mem.sv SYSTEM_VERILOG PATH mailbox_mem.sv TOP_LEVEL_FILE


# 
# parameters
# 


# 
# display items
# 


# 
# connection point s0
# 
add_interface s0 avalon end
set_interface_property s0 addressUnits WORDS
set_interface_property s0 associatedClock clock0
set_interface_property s0 associatedReset reset0
set_interface_property s0 bitsPerSymbol 8
set_interface_property s0 burstOnBurstBoundariesOnly false
set_interface_property s0 burstcountUnits WORDS
set_interface_property s0 explicitAddressSpan 0
set_interface_property s0 holdTime 0
set_interface_property s0 linewrapBursts false
set_interface_property s0 maximumPendingReadTransactions 0
set_interface_property s0 maximumPendingWriteTransactions 0
set_interface_property s0 readLatency 0
set_interface_property s0 readWaitTime 1
set_interface_property s0 setupTime 0
set_interface_property s0 timingUnits Cycles
set_interface_property s0 writeWaitTime 0
set_interface_property s0 ENABLED true
set_interface_property s0 EXPORT_OF ""
set_interface_property s0 PORT_NAME_MAP ""
set_interface_property s0 CMSIS_SVD_VARIABLES ""
set_interface_property s0 SVD_ADDRESS_GROUP ""

add_interface_port s0 avs_s0_address address Input 5
add_interface_port s0 avs_s0_writedata writedata Input 32
add_interface_port s0 avs_s0_readdata readdata Output 32
add_interface_port s0 avs_s0_write write Input 1
add_interface_port s0 avs_s0_read read Input 1
set_interface_assignment s0 embeddedsw.configuration.isFlash 0
set_interface_assignment s0 embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment s0 embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment s0 embeddedsw.configuration.isPrintableDevice 0


# 
# connection point s1
# 
add_interface s1 avalon end
set_interface_property s1 addressUnits WORDS
set_interface_property s1 associatedClock clock1
set_interface_property s1 associatedReset reset1
set_interface_property s1 bitsPerSymbol 8
set_interface_property s1 burstOnBurstBoundariesOnly false
set_interface_property s1 burstcountUnits WORDS
set_interface_property s1 explicitAddressSpan 0
set_interface_property s1 holdTime 0
set_interface_property s1 linewrapBursts false
set_interface_property s1 maximumPendingReadTransactions 0
set_interface_property s1 maximumPendingWriteTransactions 0
set_interface_property s1 readLatency 0
set_interface_property s1 readWaitTime 1
set_interface_property s1 setupTime 0
set_interface_property s1 timingUnits Cycles
set_interface_property s1 writeWaitTime 0
set_interface_property s1 ENABLED true
set_interface_property s1 EXPORT_OF ""
set_interface_property s1 PORT_NAME_MAP ""
set_interface_property s1 CMSIS_SVD_VARIABLES ""
set_interface_property s1 SVD_ADDRESS_GROUP ""

add_interface_port s1 avs_s1_address address Input 5
add_interface_port s1 avs_s1_writedata writedata Input 32
add_interface_port s1 avs_s1_readdata readdata Output 32
add_interface_port s1 avs_s1_write write Input 1
add_interface_port s1 avs_s1_read read Input 1
set_interface_assignment s1 embeddedsw.configuration.isFlash 0
set_interface_assignment s1 embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment s1 embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment s1 embeddedsw.configuration.isPrintableDevice 0


# 
# connection point clock0
# 
add_interface clock0 clock end
set_interface_property clock0 clockRate 0
set_interface_property clock0 ENABLED true
set_interface_property clock0 EXPORT_OF ""
set_interface_property clock0 PORT_NAME_MAP ""
set_interface_property clock0 CMSIS_SVD_VARIABLES ""
set_interface_property clock0 SVD_ADDRESS_GROUP ""

add_interface_port clock0 clk0 clk Input 1


# 
# connection point clock1
# 
add_interface clock1 clock end
set_interface_property clock1 clockRate 0
set_interface_property clock1 ENABLED true
set_interface_property clock1 EXPORT_OF ""
set_interface_property clock1 PORT_NAME_MAP ""
set_interface_property clock1 CMSIS_SVD_VARIABLES ""
set_interface_property clock1 SVD_ADDRESS_GROUP ""

add_interface_port clock1 clk1 clk Input 1


# 
# connection point reset0
# 
add_interface reset0 reset end
set_interface_property reset0 associatedClock clock0
set_interface_property reset0 synchronousEdges DEASSERT
set_interface_property reset0 ENABLED true
set_interface_property reset0 EXPORT_OF ""
set_interface_property reset0 PORT_NAME_MAP ""
set_interface_property reset0 CMSIS_SVD_VARIABLES ""
set_interface_property reset0 SVD_ADDRESS_GROUP ""

add_interface_port reset0 reset0 reset Input 1


# 
# connection point reset1
# 
add_interface reset1 reset end
set_interface_property reset1 associatedClock clock1
set_interface_property reset1 synchronousEdges DEASSERT
set_interface_property reset1 ENABLED true
set_interface_property reset1 EXPORT_OF ""
set_interface_property reset1 PORT_NAME_MAP ""
set_interface_property reset1 CMSIS_SVD_VARIABLES ""
set_interface_property reset1 SVD_ADDRESS_GROUP ""

add_interface_port reset1 reset1 reset Input 1

