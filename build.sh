#!/usr/bin/bash
export NDK=/home/nredko/android-ndk-r21d

export ZLIB=zlib-1.2.11
export PCRE=pcre-8.44
export OPENSSL=openssl-1.1.1i
export LIGHTTPD=lighttpd-1.4.58

#############################################################
set -e
mkdir -p src
cd src
wget -nc https://zlib.net/$ZLIB.tar.xz
wget -nc https://ftp.pcre.org/pub/pcre/$PCRE.tar.gz
wget -nc https://www.openssl.org/source/$OPENSSL.tar.gz
wget -nc https://download.lighttpd.net/lighttpd/releases-1.4.x/$LIGHTTPD.tar.xz


export TARGET=armv7a-linux-androideabi
export ARM=arm-linux-androideabi
export API=28
export BLD=`pwd`
export ANDROID_NDK_HOME=$NDK
export TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/linux-x86_64

export AR=$TOOLCHAIN/bin/$ARM-ar
export AS=$TOOLCHAIN/bin/$ARM-as
export CC=$TOOLCHAIN/bin/$TARGET$API-clang
export CXX=$TOOLCHAIN/bin/$TARGET$API-clang++
export LD=$TOOLCHAIN/bin/$ARM-ld
export RANLIB=$TOOLCHAIN/bin/$ARM-ranlib
export STRIP=$TOOLCHAIN/bin/$ARM-strip


if [ ! -f "$BLD/include/zlib.h" ]; then
cd $BLD/$ZLIB
./configure --prefix=$BLD --static
make install
fi

if [ ! -f "$BLD/include/pcre.h" ]; then
cd $BLD/$PCRE
./configure --host=$TARGET --prefix=$BLD --disable-shared
make install
fi

if [ ! -f "$BLD/include/openssl/ssl.h" ]; then
echo BUILDING OPENSSL
cd $BLD/$OPENSSL
export PATH=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin:$ANDROID_NDK_HOME/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/bin:$PATH
./Configure android-arm no-shared -D__ANDROID_API__=$API --prefix=$BLD
make install
fi



echo BUILDING LIGHTTPD
cd $BLD/$LIGHTTPD
if [ -f "Makefile" ]; then
make distclean
fi
rm -f src/plugin-static.h 
cp $BLD/plugin-static.h ./src/
CPPFLAGS=-DLIGHTTPD_STATIC LIGHTTPD_STATIC=yes ./configure -C --host=$TARGET --enable-static=yes --enable-shared=no --disable-shared --prefix=$BLD --disable-ipv6 --with-pcre=$BLD --with-zlib=$BLD --with-openssl=$BLD
sed -i.bak '/lighttpd-mod_webdav/d' ./src/Makefile
make install-strip

