FROM centos:6

MAINTAINER "Andreas Stallinger" <astallinger@coati.io>

WORKDIR /opt

##RUN yum -y update && yum -y install wget && \
RUN yum -y install centos-release-scl epel-release && \
yum -y install wget devtoolset-4-gcc devtoolset-4-gcc-c++ devtoolset-4-binutils \
	wget tar bzip2 git libtool which fuse fuse-devel libpng-devel automake \
	glibc-headers libstdc++-devel gcc-c++ freetype-devel fontconfig-devel\
	libxml2-devel libstdc++-devel libXrender-devel patch xcb-util-keysyms-devel \
	libXi-devel libudev-devel.x86_64 openssl-devel sqlite-devel.x86_64 \ 
	gperftools.x86_64 gperf.x86_64 libicu-devel.x86_64 boost-devel.x86_64 \ 
	libxslt-devel.x86_64 python27.x86_64 \
	cmake3.x86_64 xz mesa-libEGL-devel mesa-libGL-devel glib-devel git19 \ 
	java-1.8.0-openjdk-devel re2c ImageMagick && \
yum clean all && \
ln -s /usr/bin/cmake3 /usr/local/bin/cmake

## set env
ARG QVERSION_SHORT=5.8
ARG QTVERSION=5.8.0

ENV QT_DIR=/opt/qt${QTVERSION} \ 
CXX=/opt/llvm/bin/clang++ \ 
CC=/opt/llvm/bin/clang \ 
CXX_TEST_DIR=/opt/cxxtest \
JAVA_HOME=/usr/lib/jvm/java-openjdk \
LLVM_DIR=/opt/llvm \
BOOST_DIR=/opt/boost \ 
DEVTOOLSET=/opt/rh/devtoolset-4/root/usr/ \
BOTAN_DIR=/opt/botan

# Install Qt
RUN mkdir -p /qt && cd /qt && \
wget http://download.qt.io/archive/qt/${QVERSION_SHORT}/${QTVERSION}/\
single/qt-everywhere-opensource-src-${QTVERSION}.tar.xz && \
tar xvf qt-everywhere-opensource-src-${QTVERSION}.tar.xz && \
ln -sf /opt/rh/devtoolset-4/root/usr/bin/g++ /usr/bin/g++ && \
ln -sf /opt/rh/devtoolset-4/root/usr/bin/c++ /usr/bin/c++ && \
cd /qt/qt-everywhere-opensource-src-${QTVERSION} && \
./configure -v -prefix /opt/qt${QTVERSION} -skip qtgamepad -platform linux-g++ -qt-pcre \ 
-qt-xcb -qt-xkbcommon -xkb-config-root /usr/share/X11/xkb \
-no-pch -release -no-compile-examples -confirm-license -opensource -nomake examples \
-nomake tests -skip sensors -skip webchannel -skip webengine -skip 3d \
-skip doc -skip multimedia -skip tools -skip connectivity -skip androidextras -skip canvas3d && \
make -j8 && \
make -j8 install && rm -Rf /qt

## Install llvm
ARG LLVM_VERSION=3.9.0
RUN mkdir -p /llvm && cd /llvm && \
wget http://llvm.org/releases/${LLVM_VERSION}/llvm-${LLVM_VERSION}.src.tar.xz && \
tar xvf llvm-${LLVM_VERSION}.src.tar.xz && \
cd llvm-${LLVM_VERSION}.src && \
cd tools && \
wget http://llvm.org/releases/${LLVM_VERSION}/cfe-${LLVM_VERSION}.src.tar.xz && \
tar xvf cfe-${LLVM_VERSION}.src.tar.xz && \
. /opt/rh/python27/enable && \
. /opt/rh/devtoolset-4/enable && \
python --version && \
cd /llvm/llvm-${LLVM_VERSION}.src && mkdir -p build && cd build && \
cmake .. -DCMAKE_INSTALL_PREFIX=/opt/llvm/ \
-DCMAKE_BUILD_TYPE=Release \ 
-DLLVM_ENABLE_RTTI=ON \ 
&& make -j8 install && rm -Rf /llvm
#COPY scripts/install-llvm.sh /opt/
#RUN ./install-llvm.sh

#WORKDIR /
#COPY llvm39.tar.bz2 /
#RUN tar xjf /llvm39.tar.bz2 && rm /llvm39.tar.bz2
#COPY qt58.tar.bz2 /
#RUN tar xjf /qt58.tar.bz2 && rm /qt58.tar.bz2

WORKDIR /opt
## Install botan
RUN git clone https://github.com/randombit/botan.git /botan && \
cd /botan && \
ln -sf /opt/rh/devtoolset-4/root/usr/bin/g++ /usr/bin/g++ && \
ln -sf /opt/rh/devtoolset-4/root/usr/bin/c++ /usr/bin/c++ && \
git checkout 1.11.34 && \
./configure.py --disable-shared --prefix=/opt/botan && \
make -j8 && make install && \
rm -rf /botan

## Boost
ARG BOOST_MAJOR=1
ARG BOOST_MINOR=61
ARG BOOST_PATCH=0
ENV BOOST_VERSION=${BOOST_MAJOR}.${BOOST_MINOR}.${BOOST_PATCH} \
BOOST_VERSION_UNDERSCORE=${BOOST_MAJOR}_${BOOST_MINOR}_${BOOST_PATCH}

RUN wget http://downloads.sourceforge.net/project/boost/boost/${BOOST_VERSION}/boost_${BOOST_VERSION_UNDERSCORE}.tar.gz && \
tar -xzf boost_${BOOST_VERSION_UNDERSCORE}.tar.gz && cd boost_${BOOST_VERSION_UNDERSCORE} && \
./bootstrap.sh --with-libraries=filesystem,program_options,system,date_time --prefix=/opt/boost && \
./b2 install --link=static --variant=release --threading=multi --runtime-link=static --cxxflags=-fPIC && \
cd .. && rm boost_${BOOST_VERSION_UNDERSCORE}.tar.gz && rm boost_${BOOST_VERSION_UNDERSCORE} -r

## Ninja
RUN git clone https://github.com/martine/ninja.git && \
cd ninja && \
git checkout release && \
./configure.py --bootstrap && \
mv ninja /usr/bin/ && \
cd .. && rm -rf ninja

## CxxTest
RUN git clone https://github.com/CxxTest/cxxtest.git && \
cd cxxtest && \
git checkout 4.4

#add user
RUN useradd -u 1000 builder

# Make sure the above SCLs are already enabled
ENTRYPOINT ["/usr/bin/scl", "enable", "python27", "devtoolset-4", "git19", "--"]
CMD ["/usr/bin/scl", "enable", "python27", "devtoolset-4", "git19", "--", "/bin/bash"]

RUN GCC_VERSION=$(g++ -dumpversion) && \
ln -s /opt/rh/devtoolset-4/root/usr/include/c++/${GCC_VERSION} /usr/include/c++/${GCC_VERSION} && \
ln -s /opt/rh/devtoolset-4/root/usr/lib/gcc/x86_64-redhat-linux/${GCC_VERSION} \
/usr/lib/gcc/x86_64-redhat-linux/${GCC_VERSION}

WORKDIR /home/builder
USER builder

