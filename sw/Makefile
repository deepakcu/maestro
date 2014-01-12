CXX ?= g++
CC ?= gcc
CMAKE = cmake
TOP = $(shell pwd)
MAKE := $(MAKE) --no-print-directory
#OPROFILE = 1

#ifeq ($(shell which distcc > /dev/null; echo $$?), 0)
#	CXX := distcc $(CXX)
#	CC := distcc $(CC)
#	PARALLELISM := $(shell distcc -j)
#else
	PARALLELISM = 1
#endif

export CXX CC CFLAGS CPPFLAGS OPROFILE

all: release 

release: 
	@mkdir -p bin/release
	@cd bin/release && $(CMAKE) -DCMAKE_BUILD_TYPE=Release $(TOP)/src
	@cd bin/release && $(MAKE) -j${PARALLELISM}

debug: 
	@mkdir -p bin/debug
	@cd bin/debug && $(CMAKE) -DCMAKE_BUILD_TYPE=Debug $(TOP)/src
	@cd bin/debug  && $(MAKE) -j${PARALLELISM}

docs:
	@cd docs/ && $(MAKE)

clean:
	rm -rf bin/*

.DEFAULT: bin/debug/Makefile bin/release/Makefile
	@cd bin/release && $(MAKE) $@
	@cd bin/debug && $(MAKE) $@
