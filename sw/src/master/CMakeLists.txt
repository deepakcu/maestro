add_library(master master.cc ${WORKER_PB_SRC} ${WORKER_PB_HDR})
add_dependencies(master worker_proto)
