add_library(kernel 
            kernel.cc 
            table-registry.cc 
            local-table.cc
            global-table.cc)
add_dependencies(kernel worker_proto)
