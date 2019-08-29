#
SHELL=/bin/bash

# Make sure the .dependencies file exists, otherwise the include at the bottom will choke
$(shell touch .dependencies)

SRC=
HDR=
OBJ=$(subst .cpp,.o,${SRC})

TESTSRC=test.cpp
TESTOBJ=$(subst .cpp,.o,${TESTSRC})
TESTBIN=test
TESTLIB=-L./ -lthreadpool -lpthread

LIBSRC=threadpool.cpp
LIBHDR=threadpool.h
LIBOBJ=$(subst .cpp,.o,${LIBSRC})
LIBBIN=libthreadpool.so

GCC_VERSION=`g++ -dumpversion`
ARCH=x86_64-linux-gnu
OS=linux

BACKUP=threadpool.tar.gz
EXTRA= Makefile .dependencies README.md GPL-3.0 .gitignore

INCLUDEPATHS= -I. \
	-I/usr/include/c++/${GCC_VERSION} \
	-I/usr/include/c++/${GCC_VERSION}/${ARCH} \
	-I/usr/lib/gcc/${ARCH}/${GCC_VERSION}/include \
	-I/usr/include/${ARCH} \
	-I/usr/include/${ARCH}/c++/${GCC_VERSION} \
	`pkg-config Magick++ --cflags`

LIBSEARCH=-L./
LIBRARIES=
DEBUG=0

CPU_EXTRAS=-D C_USAGE

ifeq (${DEBUG},1)
  CPUOPT=-g3 -Wall -Wunused -pg -fno-strict-aliasing -finline-functions -std=c++11
  LIBS=${LIBSEARCH} ${LIBRARIES} -pg
else
  CPUOPT=-Wall -Wunused -mhard-float -fno-strict-aliasing -finline-functions -std=c++11
  LIBS=${LIBSEARCH} ${LIBRARIES}
endif

ifneq (${OS},darwin)
  override CPUOPT+= $(patsubst %,%,-Wno-unused-but-set-variable)
  override CPUOPT+= $(patsubst %,%,-std=gnu++0x)
else
  override CPUOPT += $(patsubst %,%,-D__DARWIN__)
endif

BIN=image

CC=g++ $(CPUOPT) $(CPU_EXTRAS) $(INCLUDEPATHS) 
LINK=g++ -o $(BIN) $(OBJ) $(LIBS)

CCTEST=g++ -Wall -std=c++11 -c $(TESTSRC)
LINKTEST=g++ -o test $(TESTOBJ) $(TESTLIB)

all:	lib

install:
	@cp ${LIBBIN} ${HOME}/lib/
	@cp ${LIBHDR} ${HOME}/include

clean:
	rm -f $(BIN) $(OBJ) $(LIBOBJ) $(LIBBIN) $(TESTBIN) $(TESTOBJ) *~ *.bak

tidy:
	rm -f $(BIN) $(OBJ) $(LIBOBJ) $(LIBBIN)

force:	tidy all

${BIN}:	$(HDR) $(OBJ)
	@echo ">>>>>>>>>>>> Linking <<<<<<<<<<<<<"
	$(LINK)
        ifeq (${DEBUG},0)
	  @strip ${BIN} ${LIBBIN}
        endif

${TESTBIN}: $(TESTSRC) $(TESTOBJ)
	@echo ">>>>>>>>>>>> Linking <<<<<<<<<<<<<"
	$(LINKTEST)
        ifeq (${DEBUG},0)
	  @strip ${TESTBIN}
        endif

.cpp.o:
	@echo ">>>>>>>>>>>> Compiling $< -> $@ <<<<<<<<<<<<<"
	$(CC) -c $< -o $@

lib:
	@echo ">>>>>>>>>>>> Making Library <<<<<<<<<<<<<"
	$(CC) -fPIC -c ${LIBSRC}
	$(CC) -shared -o ${LIBBIN} ${LIBOBJ} -pthread 

backup:
	@tar -zcf $(BACKUP) $(SRC) $(HDR) $(LIBSRC) $(LIBHDR) $(EXTRA)

depend dep:
ifneq (${OS},darwin)
	makedepend  $(CPU_EXTRAS) $(INCLUDEPATHS) $(SRC) -f .dependencies;
else
	makedepend -D__DARWIN__ $(INCLUDEPATHS) $(SRC) -f .dependencies;
endif

include .dependencies
# DO NOT DELETE
