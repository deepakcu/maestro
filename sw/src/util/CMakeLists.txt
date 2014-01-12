protobuf_generate_cpp(COMMON_PB_SRC COMMON_PB_HDR ${MAITER_SOURCE_DIR} common.proto)

add_custom_target(common_proto DEPENDS ${COMMON_PB_HDR})
add_library(common
            common.cc 
            file.cc 
            stringpiece.cc
            rpc.cc 
            static-initializers.cc 
	    fpga.cc
            ${COMMON_PB_SRC} 
            ${COMMON_PB_HDR})