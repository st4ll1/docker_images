FROM centos:6

MAINTAINER "Andreas Stallinger" <astallinger@coati.io>

WORKDIR /opt

RUN yum -y update && yum -y install wget && \
yum -y install centos-release-scl epel-release && \
yum -y update && \
yum -y install devtoolset-4-gcc devtoolset-4-gcc-c++ devtoolset-4-binutils \
	wget tar bzip2 git libtool which fuse fuse-devel libpng-devel automake \
	glibc-headers libstdc++-devel gcc-c++ freetype-devel fontconfig-devel i \
	libxml2-devel libstdc++-devel libXrender-devel patch xcb-util-keysyms-devel \
	libXi-devel libudev-devel.x86_64 openssl-devel sqlite-devel.x86_64 \ 
	gperftools.x86_64 gperf.x86_64 libicu-devel.x86_64 boost-devel.x86_64 \ 
	libxslt-devel.x86_64 docbook-style-xsl.noarch python27.x86_64 \
	cmake3.x86_64 xz mesa-libEGL-devel mesa-libGL-devel glib-devel git19 \ 
	java-1.8.0-openjdk-devel re2c && \
yum clean all

# Install Qt
ENV QVERSION_SHORT=5.7 QTVERSION=5.7.0

RUN mkdir -p /qt && cd /qt && \
wget http://download.qt.io/archive/qt/${QVERSION_SHORT}/${QTVERSION}/\
single/qt-everywhere-opensource-src-${QTVERSION}.tar.xz && \
tar xvf qt-everywhere-opensource-src-${QTVERSION}.tar.xz && \
ln -sf /opt/rh/devtoolset-4/root/usr/bin/g++ /usr/bin/g++ && \
ln -sf /opt/rh/devtoolset-4/root/usr/bin/c++ /usr/bin/c++ && \
cd /qt/qt-everywhere-opensource-src-${QTVERSION} && \
./configure -v -skip qtgamepad -platform linux-g++ -qt-pcre \ 
-qt-xcb -qt-xkbcommon -xkb-config-root /usr/share/X11/xkb \
-no-pch -confirm-license -opensource && \
make -j 8 || make -j 1 install; make -j8 install && rm -Rf /qt

