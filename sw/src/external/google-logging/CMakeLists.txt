include_directories( ${MAITER_SOURCE_DIR}/external/google-flags/)

add_library(glog
            utilities.cc
            vlog_is_on.cc
            demangle.cc
            logging.cc
            symbolize.cc
            signalhandler.cc
            raw_logging.cc)
