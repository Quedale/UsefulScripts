#!/usr/bin/env bash
#include build functions
PREFIX="$HOME/ffmpeg_build"
script_start=$SECONDS
CHECK=1
SKIP=0
echo "$(dirname "$0")"
source $(dirname "$0")/../common/buildfunc.sh

arch=$(uname -m)
echo "*****************************"
echo "*** Architecture $arch ***"
echo "*****************************"
if [[ "$arch" != "armv7l" && "$arch" != "x86_64" ]]; then
  echo "Unknown arch : $arch"
  exit 1
fi

if [ $SKIP -ne 1 ]
then
  echo "*****************************"
  echo "*** Installing dependencies ***"
  echo "*****************************"
  sudo apt install libunistring-dev

  sudo python3 -m pip install meson
  sudo python3 -m pip install cmake
  sudo python3 -m pip install ninja
  echo "*****************************"
  echo "*   Installing gobject"
  echo "*****************************"
  python3 -m pip install gobject
fi

mkdir -p ~/ffmpeg_sources ~/bin

cd ~/ffmpeg_sources
pullOrClone path="https://github.com/openssl/openssl.git" tag="OpenSSL_1_1_1q"
buildMake1 srcdir="openssl" prefix="$PREFIX" configcustom="./config --prefix=$PREFIX --openssldir=$PREFIX/ssl shared"
#TODO check if all distro uses /etc/ssl/certs
cp -r /etc/ssl/certs/* $PREFIX/ssl/certs

cd ~/ffmpeg_sources
downloadAndExtract file="Python-2.7.18.tar.xz" path="https://www.python.org/ftp/python/2.7.18/Python-2.7.18.tar.xz"
buildMake1 srcdir="Python-2.7.18" prefix="$PREFIX" configure="--enable-shared" #--enable-optimizations enable this for fast runtime but slower build

cd ~/ffmpeg_sources
downloadAndExtract file="autoconf-2.71.tar.gz" path="http://ftp.gnu.org/gnu/autoconf/autoconf-2.71.tar.gz"
buildMake1 srcdir="autoconf-2.71" prefix="$PREFIX" configure="--bindir=$HOME/bin"

cd ~/ffmpeg_sources
pullOrClone path="https://git.savannah.gnu.org/r/gawk.git"
buildMake1 srcdir="gawk" prefix="$PREFIX" configure="--bindir=$HOME/bin"

cd ~/ffmpeg_sources
pullOrClone path="https://git.savannah.gnu.org/git/automake.git"  tag="v1.16.5"
buildMake1 srcdir="automake" prefix="$PREFIX" configure="MAKEINFO=true --bindir=$HOME/bin"

cd ~/ffmpeg_sources
downloadAndExtract file="help2man-1.49.2.tar.xz" path="https://ftp.gnu.org/gnu/help2man/help2man-1.49.2.tar.xz"
buildMake1 srcdir="help2man-1.49.2" prefix="$PREFIX" configure="--bindir=$HOME/bin"

cd ~/ffmpeg_sources
pullOrClone path="https://github.com/debian-tex/texinfo.git"
buildMake1 srcdir="texinfo" prefix="$PREFIX" configure="--bindir=$HOME/bin"

#Depends on git://git.sv.gnu.org/gnulib --shallow-since=2019-02-19 - builds automatically
cd ~/ffmpeg_sources
downloadAndExtract file="m4-1.4.19.tar.gz" path="https://ftp.gnu.org/gnu/m4/m4-1.4.19.tar.gz"
buildMake1 srcdir="m4-1.4.19" prefix="$PREFIX"

echo "*****************************"
echo "*** ln /home/pi/bin/m4 /usr/bin/m4 ***"
echo "*** #libxml2 has hardcoded reference to /usr/bin/m4"
echo "*****************************"
sudo ln /home/pi/bin/m4 /usr/bin/m4

cd ~/ffmpeg_sources
downloadAndExtract file="pkgconf-1.9.3.tar.gz" path="https://distfiles.dereferenced.org/pkgconf/pkgconf-1.9.3.tar.gz"
buildMake1 srcdir="pkgconf-1.9.3" prefix="$PREFIX" configure="--bindir=$HOME/bin"

#Depends on git://git.sv.gnu.org/gnulib - builds automatically
cd ~/ffmpeg_sources
pullOrClone path="https://github.com/autotools-mirror/libtool.git" depth=1 tag="v2.4.7"
buildMake1 srcdir="libtool" prefix="$PREFIX" configure="--bindir=$HOME/bin"

cd ~/ffmpeg_sources
downloadAndExtract file="nasm-2.15.05.tar.bz2" path="https://www.nasm.us/pub/nasm/releasebuilds/2.15.05/nasm-2.15.05.tar.bz2"
buildMake1 srcdir="nasm-2.15.05" prefix="$PREFIX" configure="--bindir=$HOME/bin"

cd ~/ffmpeg_sources
pullOrClone path="https://code.videolan.org/videolan/x264.git" depth=1
buildMake1 srcdir="x264" prefix="$PREFIX" configure="--enable-shared --enable-pic --bindir=$HOME/bin"

cd ~/ffmpeg_sources
downloadAndExtract file="master.tar.bz2" path="https://bitbucket.org/multicoreware/x265_git/get/master.tar.bz2"
buildMake1 srcdir="multicoreware*/build/linux" prefix="$PREFIX" cmakedir="../../source" configure="--bindir=$HOME/bin"

cd ~/ffmpeg_sources
pullOrClone path="https://chromium.googlesource.com/webm/libvpx.git" depth=1
buildMake1 srcdir="libvpx" prefix="$PREFIX" configure="--enable-shared --enable-pic --enable-vp9-highbitdepth --as=yasm"

cd ~/ffmpeg_sources
pullOrClone path="https://github.com/mstorsjo/fdk-aac" depth=1
buildMake1 srcdir="fdk-aac" prefix="$PREFIX" autoreconf=true configure="--enable-shared --enable-pic"

cd ~/ffmpeg_sources
pullOrClone path="https://github.com/xiph/opus.git" depth=1
setup_patch="sed -i 's/PACKAGE_VERSION=\"unknown\"/PACKAGE_VERSION=\"1.3.2\"/' ./package_version"
buildMake1 srcdir="opus" prefix="$PREFIX" configure="--disable-doc" preconfigure="$setup_patch"

cd ~/ffmpeg_sources
pullOrClone path="https://aomedia.googlesource.com/aom" depth=1
mkdir aom/aom_build
if [[ "$arch" == "x86_64" ]]; then
  buildMake1 srcdir="aom/aom_build" prefix="$PREFIX" cmakedir=".."
elif [[ "$arch" == "armv7l" ]]; then
  #RPI specific TODO Detect more accuratly
  #/opt/vc/include/IL/OMX_Broadcom.h
  buildMake1 srcdir="aom/aom_build" prefix="$PREFIX" cmakedir=".." cmakeargs='-DENABLE_NEON=OFF -DCMAKE_C_FLAGS="-mfpu=vfp"'
else
  echo "Unknown platform $arch"
  exit 1
fi

cd ~/ffmpeg_sources
pullOrClone path="https://gitlab.com/AOMediaCodec/SVT-AV1.git"
mkdir -p SVT-AV1/build
buildMake1 srcdir="SVT-AV1/build" prefix="$PREFIX" cmakedir=".." cmakeargs="-DBUILD_SHARED_LIBS=ON"

cd ~/ffmpeg_sources
pullOrClone path="https://code.videolan.org/videolan/dav1d.git" depth=1
buildMeson1 srcdir="dav1d" prefix="$PREFIX" mesonargs="-Denable_tools=false -Denable_tests=false -Denable_docs=false"

cd ~/ffmpeg_sources
downloadAndExtract file=v2.1.1.tar.gz path="https://github.com/Netflix/vmaf/archive/v2.1.1.tar.gz"
buildMeson1 srcdir="vmaf-2.1.1/libvmaf" prefix="$PREFIX" mesonargs="-Denable_tests=false -Denable_docs=false"

cd ~/ffmpeg_sources
pullOrClone path="https://github.com/sekrit-twc/zimg.git" tag="release-3.0.4"
buildMake1 srcdir="zimg" prefix="$PREFIX"

cd ~/ffmpeg_sources
pullOrClone path="https://github.com/ultravideo/kvazaar.git" depth=1 tag="v2.1.0"
buildMake1 srcdir="kvazaar" prefix="$PREFIX"

cd ~/ffmpeg_sources
pullOrClone path="https://github.com/google/snappy.git" recurse=true
mkdir "snappy/build"
buildMake1 srcdir="snappy/build" prefix="$PREFIX" cmakedir=".."

cd ~/ffmpeg_sources
pullOrClone path="https://github.com/chirlu/soxr.git"
mkdir "soxr/build"
buildMake1 srcdir="soxr/build" prefix="$PREFIX" cmakedir=".." cmakeargs="-DBUILD_SHARED_LIBS=ON"

cd ~/ffmpeg_sources
pullOrClone path="https://git.libssh.org/projects/libssh.git" tag="libssh-0.10.4"
mkdir "libssh/build"
buildMake1 srcdir="libssh/build" prefix="$PREFIX" cmakedir=".." cmakeargs="-DBUILD_SHARED_LIBS=ON"

cd ~/ffmpeg_sources
pullOrClone path="https://github.com/webmproject/libwebp.git"
mkdir "libwebp/build"
buildMake1 srcdir="libwebp/build" prefix="$PREFIX" cmakedir=".." cmakeargs="-DBUILD_SHARED_LIBS=ON"

cd ~/ffmpeg_sources
pullOrClone path="https://github.com/freedesktop/xorg-macros.git"
buildMake1 srcdir="xorg-macros" prefix="$PREFIX"

cd ~/ffmpeg_sources
pullOrClone path="https://gitlab.freedesktop.org/xorg/lib/libpciaccess.git"
buildMeson1 srcdir="libpciaccess" prefix="$PREFIX"

cd ~/ffmpeg_sources
pullOrClone path="https://gitlab.freedesktop.org/mesa/drm.git"
buildMeson1 srcdir="drm" prefix="$PREFIX"

cd ~/ffmpeg_sources
pullOrClone path="https://github.com/GNOME/libxml2.git" tag="v2.10.2"
buildMake1 srcdir="libxml2" prefix="$PREFIX"

cd ~/ffmpeg_sources
pullOrClone path="https://sourceware.org/git/valgrind.git"
buildMake1 srcdir="valgrind" prefix="$PREFIX"

cd ~/ffmpeg_sources
pullOrClone path="https://github.com/fribidi/fribidi.git"
buildMeson1 srcdir="fribidi" prefix="$PREFIX" mesonargs="-Ddocs=false"

if [ -z "$(checkPkg name='libpcre2-8' prefix=$PREFIX)" ]; then
    cd $SOURCES
    pullOrClone path="https://github.com/PCRE2Project/pcre2.git" tag="pcre2-10.37"
    mkdir "pcre2/build"
    buildMake1 srcdir="pcre2/build" prefix="$PREFIX" configure="-Dtests=disabled -Ddocs=disabled" cmakedir=".."
else
    echo "libpcre2-8 already installed."
fi

if [ -z "$(checkPkg name='glib-2.0  >= 2.62.6' prefix=$PREFIX)" ]; then
    cd $SOURCES
    pullOrClone path="https://gitlab.gnome.org/GNOME/glib.git" tag="2.62.6" #Cerbero recipe version
    buildMeson1 srcdir="glib" prefix="$PREFIX" mesonargs="-Dinstalled_tests=false -Dgtk_doc=false -Dinstalled_tests=false"

    cd $SOURCES
    pullOrClone path="https://gitlab.gnome.org/GNOME/glib-networking.git" tag="2.62.3" #Cerbero recipe version
    buildMeson1 srcdir="glib-networking" prefix="$PREFIX" mesonargs="-Dopenssl=enabled"
else
    echo "glib already installed."
fi

if [ -z "$(checkPkg name='gobject-introspection-1.0' prefix=$PREFIX)" ]; then
    cd $SOURCES
    pullOrClone path="https://gitlab.gnome.org/GNOME/gobject-introspection.git" tag="1.71.0"
    buildMeson1 srcdir="gobject-introspection" prefix="$PREFIX" mesonargs=""
else
    echo "gobject-introspection-1.0 already installed."
fi

cd ~/ffmpeg_sources
pullOrClone path="https://github.com/harfbuzz/harfbuzz.git" tag="5.2.0"
buildMeson1 srcdir="harfbuzz" prefix="$PREFIX" mesonargs="-Ddefault_library=both -Dtests=disabled -Ddocs=disabled -Dintrospection=enabled"

cd ~/ffmpeg_sources
pullOrClone path="https://github.com/freedesktop/fontconfig.git"
buildMeson1 srcdir="fontconfig" prefix="$PREFIX" mesonargs="-Ddoc-man=disabled -Ddoc-pdf=disabled -Ddoc-html=disabled -Dtests=disabled"

cd ~/ffmpeg_sources
pullOrClone path="https://github.com/libass/libass.git"
buildMake1 srcdir="libass" prefix="$PREFIX"

cd ~/ffmpeg_sources
pullOrClone path="https://github.com/freedesktop/libXext.git"
buildMake1 srcdir="libXext" prefix="$PREFIX"

cd ~/ffmpeg_sources
pullOrClone path="https://github.com/libsdl-org/SDL.git"
buildMake1 srcdir="SDL" prefix="$PREFIX"

if [ -z "$(checkPkg name='gmp' prefix=$PREFIX)" ]; then
    cd ~/ffmpeg_sources
    downloadAndExtract file="gmp-6.2.1.tar.xz" path="https://gmplib.org/download/gmp/gmp-6.2.1.tar.xz"
    buildMake1 srcdir="gmp-6.2.1" prefix="$PREFIX"
else
    echo "gmp already installed."
fi

cd ~/ffmpeg_sources
downloadAndExtract file="mp3lame.tar.xz" path="https://sourceforge.net/projects/lame/files/latest/download"
buildMake1 srcdir="lame-3.100" prefix="$PREFIX"


cd ~/ffmpeg_sources
pullOrClone path="https://github.com/xiph/ogg.git" tag="v1.3.5"
mkdir "ogg/build"
buildMake1 srcdir="ogg/build" prefix="$PREFIX" cmakedir=".."

cd ~/ffmpeg_sources
pullOrClone path="https://github.com/xiph/vorbis.git" tag="v1.3.5"
buildMake1 srcdir="vorbis" prefix="$PREFIX"

cd ~/ffmpeg_sources
pullOrClone path="https://github.com/cisco/openh264.git"
buildMeson1 srcdir="openh264" prefix="$PREFIX" mesonargs="-Dtests=disabled"

echo "*****************************"
echo "*** sudo ldconfig ***"
echo "*****************************"
sudo ldconfig

ffmpeg_enables="--enable-gmp"
ffmpeg_enables+=" --enable-gpl"
ffmpeg_enables+=" --enable-libaom"
ffmpeg_enables+=" --enable-libass"
ffmpeg_enables+=" --enable-libdav1d"
ffmpeg_enables+=" --enable-libdrm"
ffmpeg_enables+=" --enable-libfdk-aac"
ffmpeg_enables+=" --enable-libfreetype"
ffmpeg_enables+=" --enable-libkvazaar"
ffmpeg_enables+=" --enable-libmp3lame"
ffmpeg_enables+=" --enable-libopus"
ffmpeg_enables+=" --enable-libsnappy"
ffmpeg_enables+=" --enable-libsoxr"
ffmpeg_enables+=" --enable-libssh"
ffmpeg_enables+=" --enable-libsvtav1"
ffmpeg_enables+=" --enable-libvorbis"
ffmpeg_enables+=" --enable-libvpx"
ffmpeg_enables+=" --enable-libwebp"
ffmpeg_enables+=" --enable-libzimg"
ffmpeg_enables+=" --enable-libx264"
ffmpeg_enables+=" --enable-libx265"
ffmpeg_enables+=" --enable-libxml2"
ffmpeg_enables+=" --enable-nonfree"
ffmpeg_enables+=" --enable-libopenh264"
ffmpeg_enables+=" --enable-version3"
ffmpeg_enables+=" --enable-pic"
ffmpeg_enables+=" --enable-shared"
ffmpeg_enables+=" --enable-pthreads"
ffmpeg_enables+=" --enable-openssl"
ffmpeg_enables+=" --enable-hardcoded-tables"

if [[ "$arch" == "armv7l" ]]; then
  ffmpeg_enables+=" --arch=armel"
  #Broadcom specific- AKA RPI
  #/opt/vc/include/IL/OMX_Broadcom.h
  ffmpeg_enables+=" --enable-mmal"
fi

cd ~/ffmpeg_sources
downloadAndExtract file=ffmpeg-snapshot.tar.bz2 path=https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2
cd ffmpeg
echo "*****************************"
echo "*** Configure FFmpeg      ***"
echo "*****************************"
PATH="$HOME/bin:$PATH" \
LD_LIBRARY_PATH="$PREFIX/lib" \
PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig" \
  ./configure \
    --prefix="$PREFIX" \
    --pkg-config-flags="--static" \
    --extra-cflags="-I$PREFIX/include" \
    --extra-ldflags="-L$PREFIX/lib" \
    --extra-libs="-lpthread -lm -latomic" \
    --ld="g++" \
    --bindir="$HOME/bin" \
    --target-os=linux \
    --enable-pic \
    --enable-shared \
    $ffmpeg_enables
echo "*****************************"
echo "*** Make FFmpeg      ***"
echo "*****************************"
PATH="$HOME/bin:$PATH" make -j$(nproc)
echo "*****************************"
echo "*** Install FFmpeg      ***"
echo "*****************************"
make install
echo "*****************************"
echo "*** Hash FFmpeg      ***"
echo "*****************************"
hash -r



#TODO
#--enable-libopencore-amrnb
#--enable-libopencore-amrwb
#--enable-libopenjpeg
#--enable-librav1e
#--enable-libtwolame
#--enable-vapoursynth
#--enable-libxavs
#--enable-libzvbi
#--enable-libmodplug
#--enable-libjxl
#--enable-libilbc
#--enable-libmfx
#--enable-libgme
#--enable-libuavs3d
#--enable-libdavs2
#--enable-libcodec2
#--enable-chromaprint
#--enable-avisynth
#--enable-amf

#LD_LIBRARY_PATH=$PREFIX/lib
#LIBRARY_PATH=$PREFIX/include
#PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig

LD_LIBRARY_PATH="$PREFIX/lib" PATH="$HOME/bin:$PATH" ffplay

script_time=$(( SECONDS - script_start ))
displaytime $script_time