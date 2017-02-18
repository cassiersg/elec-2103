# TCL File Generated by Component Editor 15.0
# Thu Feb 16 16:36:22 CET 2017
# DO NOT MODIFY


# 
# mtl_ip "mtl_ip" v1.0
#  2017.02.16.16:36:22
# 
# 

# 
# request TCL package from ACDS 15.0
# 
package require -exact qsys 15.0


# 
# module mtl_ip
# 
set_module_property DESCRIPTION ""
set_module_property NAME mtl_ip
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property GROUP Custom
set_module_property AUTHOR ""
set_module_property DISPLAY_NAME mtl_ip
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL mtl_touch_ip
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file i2c_touch_config.v VERILOG PATH ../src/mtl_touch_ip/i2c_touch_config.v
add_fileset_file mtl_touch_controller.sv SYSTEM_VERILOG PATH ../src/mtl_touch_ip/mtl_touch_controller.sv
add_fileset_file mtl_touch_ip.sv SYSTEM_VERILOG PATH ../src/mtl_touch_ip/mtl_touch_ip.sv TOP_LEVEL_FILE


# 
# parameters
# 


# 
# display items
# 


# 
# connection point clock
# 
add_interface clock clock end
set_interface_property clock clockRate 0
set_interface_property clock ENABLED true
set_interface_property clock EXPORT_OF ""
set_interface_property clock PORT_NAME_MAP ""
set_interface_property clock CMSIS_SVD_VARIABLES ""
set_interface_property clock SVD_ADDRESS_GROUP ""

add_interface_port clock clk clk Input 1


# 
# connection point reset
# 
add_interface reset reset end
set_interface_property reset associatedClock clock
set_interface_property reset synchronousEdges DEASSERT
set_interface_property reset ENABLED true
set_interface_property reset EXPORT_OF ""
set_interface_property reset PORT_NAME_MAP ""
set_interface_property reset CMSIS_SVD_VARIABLES ""
set_interface_property reset SVD_ADDRESS_GROUP ""

add_interface_port reset reset reset Input 1


# 
# connection point s0
# 
add_interface s0 avalon end
set_interface_property s0 addressUnits WORDS
set_interface_property s0 associatedClock clock
set_interface_property s0 associatedReset reset
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
add_interface_port s0 avs_s0_readdata readdata Output 32
set_interface_assignment s0 embeddedsw.configuration.isFlash 0
set_interface_assignment s0 embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment s0 embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment s0 embeddedsw.configuration.isPrintableDevice 0


# 
# connection point mtl_touch
# 
add_interface mtl_touch conduit end
set_interface_property mtl_touch associatedClock clock
set_interface_property mtl_touch associatedReset ""
set_interface_property mtl_touch ENABLED true
set_interface_property mtl_touch EXPORT_OF ""
set_interface_property mtl_touch PORT_NAME_MAP ""
set_interface_property mtl_touch CMSIS_SVD_VARIABLES ""
set_interface_property mtl_touch SVD_ADDRESS_GROUP ""

add_interface_port mtl_touch MTL_TOUCH_I2C_SCL i2c_scl Output 1
add_interface_port mtl_touch MTL_TOUCH_I2C_SDA i2c_sda Bidir 1
add_interface_port mtl_touch MTL_TOUCH_INT_n touch_int_n Input 1

