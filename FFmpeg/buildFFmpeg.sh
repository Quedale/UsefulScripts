#!/usr/bin/env bash
#include build functions
CHECK=0
SKIP=1
source $(dirname "$0")/../common/buildfunc.sh

arch=$(echo $(uname -a) | awk '{print $12}')
echo "*****************************"
echo "*** Architecture $arch ***"
echo "*****************************"
if [[ "$arch" -ne "armv7l" && "$arch" -eq "x86_64" ]]; then
  echo "Unknown arch : $arch"
  exit 1
fi

echo "*****************************"
echo "*** Installing dependencies ${srcdir} ***"
echo "*****************************"
sudo apt-get update -qq && sudo apt-get install \
  autoconf \
  build-essential \
  cmake \
  git-core \
  libass-dev \
  libfreetype6-dev \
  libgnutls28-dev \
  libmp3lame-dev \
  libsdl2-dev \
  libtool \
  libva-dev \
  libvdpau-dev \
  libvorbis-dev \
  libxcb1-dev \
  libxcb-shm0-dev \
  libxcb-xfixes0-dev \
  pkg-config \
  texinfo \
  wget \
  yasm \
  zlib1g-dev \
  python3-pip

sudo apt install libunistring-dev


mkdir -p ~/ffmpeg_sources ~/bin

sudo python3 -m pip install meson
sudo python3 -m pip install ninja

downloadAndExtract (){
  local path file # reset first
  local "${@}"

  if [ ! -f "${file}" ]; then
    echo "*****************************"
    echo "*** Downloading : ${path} ***"
    echo "*****************************"
    wget ${path}
  else
    echo "*****************************"
    echo "*** Source already downloaded : ${path} ***"
    echo "*****************************"
  fi

  echo "*****************************"
  echo "*** Extracting : ${file} ***"
  echo "*****************************"
  if [[ ${file} == *.tar.gz ]]; then
    tar xfz ${file}
  elif [[ ${file} == *.tar.xz ]]; then
    tar xf ${file}
  elif [[ ${file} == *.tar.bz2 ]]; then
    tar xjf ${file}
  else
    echo "ERROR FILE NOT FOUND ${path} // ${file}"
    exit 1
  fi
  
}
buildMake1() {
    local srcdir prefix binddir bootstrap autogen autoreconf configure configcustom cmakedir cmakeargs # reset first
    local "${@}"
    
    if [ $SKIP -eq 1 ]
    then
        echo "*****************************"
        echo "*** Skipping ${srcdir} ***"
        echo "*****************************"
        return
    fi

    echo "*****************************"
    echo "* Building Github Project"
    echo "* Src dir : ${srcdir}"
    echo "* Prefix : ${prefix}"
    echo "* Bind dir: ${binddir}"
    echo "* Bootstrap: ${bootstrap}"
    echo "*****************************"

    cd ${srcdir}
    if [ ! -z "${bootstrap}" ] 
    then
      echo "*****************************"
      echo "*** bootstrap ${srcdir} ***"
      echo "*****************************"
      PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig"  ./bootstrap 
    fi
    if [ ! -z "${autogen}" ] 
    then
      echo "*****************************"
      echo "*** autogen ${srcdir} ***"
      echo "*****************************"
      PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig"  ./autogen.sh 
    fi
    if [ ! -z "${autoreconf}" ] 
    then
      echo "*****************************"
      echo "*** autoreconf ${srcdir} ***"
      echo "*****************************"
      autoreconf -fiv
    fi
    if [ ! -z "${cmakedir}" ] 
    then
      echo "*****************************"
      echo "*** cmake ${srcdir} ***"
      echo "*****************************"
      PATH="$HOME/bin:$PATH" cmake -G "Unix Makefiles" \
            ${cmakeargs} \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_INSTALL_PREFIX="$HOME/ffmpeg_build" \
            -DENABLE_TESTS=OFF -DENABLE_SHARED=on \
            -DENABLE_NASM=on \
            -DPYTHON_EXECUTABLE="$(which python3)" \
            -DBUILD_DEC=OFF \
            ${cmakedir}
    fi
    echo "custom ${configcustom}"
    if [ ! -z "${configcustom}" ]; then
      echo "*****************************"
      echo "*** sh custom config x2 ${srcdir} ***"
      echo "*** ${configcustom} ***"
      echo "*** ${configcustom} ***"
      echo "*****************************"
      PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" bash -c ${configcustom}
    elif [ -f "./configure" ]; then
      echo "*****************************"
      echo "*** configure ${srcdir} ***"
      echo "*****************************"
      echo $(ls)
      PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure --prefix=${prefix} --disable-unit-tests --disable-examples ${configure}
    else
      echo "*****************************"
      echo "*** no configuration available ${srcdir} ***"
      echo "*****************************"
    fi
    echo "*****************************"
    echo "*** compile ${srcdir} ***"
    echo "*****************************"
    PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" make -j$(nproc)

    echo "*****************************"
    echo "*** install ${srcdir} ***"
    echo "*****************************"
    PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" make -j$(nproc) install

    checkWithUser
}

buildMeson() {
    local srcdir mesonargs prefix libdir
    local "${@}"

    if [ $SKIP -eq 1 ]
    then
        echo "*****************************"
        echo "*** Skipping ${srcdir} ***"
        echo "*****************************"
        return
    fi

    echo "*****************************"
    echo "* Building Github Project"
    echo "* Src dir : ${srcdir}"
    echo "* Prefix : ${prefix}"
    echo "* libdir : ${libdir}"
    echo "*****************************"

    mkdir -p ${srcdir}/build
    cd ${srcdir}/build
    PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" meson setup \
                ${mesonargs} \
                --default-library=static .. \
                --prefix=${prefix} \
                --libdir=${libdir} \
                --buildtype=release
    PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ninja
    PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ninja install
    checkWithUser
}

cd ~/ffmpeg_sources
downloadAndExtract file=autoconf-2.71.tar.gz path=http://ftp.gnu.org/gnu/autoconf/autoconf-2.71.tar.gz
buildMake1 srcdir="autoconf-2.71" prefix="$HOME/ffmpeg_build" binddir="$HOME/bin"

cd ~/ffmpeg_sources
downloadAndExtract file=automake-1.16.5.tar.gz path=http://ftp.gnu.org/gnu/automake/automake-1.16.5.tar.gz
buildMake1 srcdir="automake-1.16.5" prefix="$HOME/ffmpeg_build" binddir="$HOME/bin"

cd ~/ffmpeg_sources
downloadAndExtract file=pkgconf-1.9.3.tar.gz path=https://distfiles.dereferenced.org/pkgconf/pkgconf-1.9.3.tar.gz
buildMake1 srcdir="pkgconf-1.9.3" prefix="$HOME/ffmpeg_build" binddir="$HOME/bin"

cd ~/ffmpeg_sources
downloadAndExtract file=m4-1.4.19.tar.gz path=https://ftp.gnu.org/gnu/m4/m4-1.4.19.tar.gz
buildMake1 srcdir="m4-1.4.19" prefix="$HOME/ffmpeg_build" binddir="$HOME/bin"
#libxml2 has hardcoded reference to /usr/bin/m4
sudo ln /home/pi/bin/m4 /usr/bin/m4

cd ~/ffmpeg_sources
downloadAndExtract file=help2man-1.49.2.tar.xz path=https://ftp.gnu.org/gnu/help2man/help2man-1.49.2.tar.xz
buildMake1 srcdir="help2man-1.49.2" prefix="$HOME/ffmpeg_build" binddir="$HOME/bin"

cd ~/ffmpeg_sources
git -C libtool pull 2> /dev/null || git clone -j$(nproc) https://github.com/autotools-mirror/libtool.git
buildMake1 srcdir="libtool" prefix="$HOME/ffmpeg_build" binddir="$HOME/bin" bootstrap=true

cd ~/ffmpeg_sources
downloadAndExtract file=nasm-2.15.05.tar.bz2 path=https://www.nasm.us/pub/nasm/releasebuilds/2.15.05/nasm-2.15.05.tar.bz2
buildMake1 srcdir="nasm-2.15.05" prefix="$HOME/ffmpeg_build" binddir="$HOME/bin" autogen=true

cd ~/ffmpeg_sources && \
git -C x264 pull 2> /dev/null || git clone -j$(nproc) --depth 1 https://code.videolan.org/videolan/x264.git
buildMake1 srcdir="x264" prefix="$HOME/ffmpeg_build" binddir="$HOME/bin"

sudo apt-get install libnuma-dev && \
cd ~/ffmpeg_sources
downloadAndExtract file=master.tar.bz2 path=https://bitbucket.org/multicoreware/x265_git/get/master.tar.bz2
buildMake1 srcdir="multicoreware*/build/linux" prefix="$HOME/ffmpeg_build" binddir="$HOME/bin" cmakedir="../../source"

cd ~/ffmpeg_sources && \
git -C libvpx pull 2> /dev/null || git clone -j$(nproc) --depth 1 https://chromium.googlesource.com/webm/libvpx.git
buildMake1 srcdir="libvpx" prefix="$HOME/ffmpeg_build" binddir="$HOME/bin" configure="--enable-shared --enable-pic --enable-vp9-highbitdepth --as=yasm"

cd ~/ffmpeg_sources && \
git -C fdk-aac pull 2> /dev/null || git clone -j$(nproc) --depth 1 https://github.com/mstorsjo/fdk-aac && \
buildMake1 srcdir="fdk-aac" prefix="$HOME/ffmpeg_build" binddir="$HOME/bin" autoreconf=true configure="--enable-shared --enable-pic"

cd ~/ffmpeg_sources && \
git -C opus pull 2> /dev/null || git clone -j$(nproc) --depth 1 https://github.com/xiph/opus.git
buildMake1 srcdir="opus" prefix="$HOME/ffmpeg_build" binddir="$HOME/bin" autogen=true

cd ~/ffmpeg_sources && \
git -C aom pull 2> /dev/null || git clone -j$(nproc) --depth 1 https://aomedia.googlesource.com/aom
mkdir aom/aom_build
if [[ "$arch" -eq "x86_64" ]]; then
  buildMake1 srcdir="aom/aom_build" prefix="$HOME/ffmpeg_build" binddir="$HOME/bin" cmakedir=".."
elif [[ "$arch" -eq "armv7l" ]]; then
  buildMake1 srcdir="aom/aom_build" prefix="$HOME/ffmpeg_build" binddir="$HOME/bin" cmakedir=".." cmakeargs='-DCMAKE_C_FLAGS="-mfpu=vfp -mfloat-abi=hard"'
  #RPI specific - TODO Figure out how to inject this after cmake call
  #sed -i 's/ENABLE_NEON:BOOL=ON/ENABLE_NEON:BOOL=OFF/' CMakeCache.txt
else
  echo "Unknown arch : $arch"
  exit 1
fi


cd ~/ffmpeg_sources
git -C SVT-AV1 pull 2> /dev/null || git clone -j$(nproc) https://gitlab.com/AOMediaCodec/SVT-AV1.git
mkdir -p SVT-AV1/build
buildMake1 srcdir="SVT-AV1/build" prefix="$HOME/ffmpeg_build" binddir="$HOME/bin" cmakedir=".." cmakeargs="-DBUILD_SHARED_LIBS=ON"

cd ~/ffmpeg_sources
git -C dav1d pull 2> /dev/null || git clone -j$(nproc) --depth 1 https://code.videolan.org/videolan/dav1d.git
buildMeson srcdir="dav1d" prefix="$HOME/ffmpeg_build" libdir="$HOME/ffmpeg_build/lib" mesonargs="-Denable_tools=false -Denable_tests=false -Denable_docs=false"

cd ~/ffmpeg_sources && \
downloadAndExtract file=v2.1.1.tar.gz path=https://github.com/Netflix/vmaf/archive/v2.1.1.tar.gz
buildMeson srcdir="vmaf-2.1.1/libvmaf" prefix="$HOME/ffmpeg_build" libdir="$HOME/ffmpeg_build/lib" mesonargs="-Denable_tests=false -Denable_docs=false"

cd ~/ffmpeg_sources
git -C zimg pull origin tags/release-3.0.4 2> /dev/null || git clone -j$(nproc) -b release-3.0.4 https://github.com/sekrit-twc/zimg.git
echo "build zimg"
buildMake1 srcdir="zimg" prefix="$HOME/ffmpeg_build" binddir="$HOME/bin" autogen=true

cd ~/ffmpeg_sources && \
git -C kvazaar pull 2> /dev/null || git clone -j$(nproc) --depth 1 https://github.com/ultravideo/kvazaar.git
buildMake1 srcdir="kvazaar" prefix="$HOME/ffmpeg_build" binddir="$HOME/bin" autogen=true

cd ~/ffmpeg_sources && \
git -C snappy pull 2> /dev/null || git clone -j$(nproc) --recurse-submodules https://github.com/google/snappy.git
mkdir "snappy/build"
buildMake1 srcdir="snappy/build" prefix="$HOME/ffmpeg_build" binddir="$HOME/bin" cmakedir=".."

cd ~/ffmpeg_sources && \
git -C soxr pull 2> /dev/null || git clone -j$(nproc) https://github.com/chirlu/soxr.git
mkdir "soxr/build"
buildMake1 srcdir="soxr/build" prefix="$HOME/ffmpeg_build" binddir="$HOME/bin" cmakedir=".." cmakeargs="-DBUILD_SHARED_LIBS=ON"

cd ~/ffmpeg_sources
git -C libssh pull 2> /dev/null || git clone -b libssh-0.10.2 -j$(nproc) https://git.libssh.org/projects/libssh.git
mkdir "libssh/build"
buildMake1 srcdir="libssh/build" prefix="$HOME/ffmpeg_build" binddir="$HOME/bin" cmakedir=".." cmakeargs="-DBUILD_SHARED_LIBS=ON"

cd ~/ffmpeg_sources
git -C libwebp pull 2> /dev/null || git clone -j$(nproc) https://github.com/webmproject/libwebp.git
mkdir "libwebp/build"
buildMake1 srcdir="libwebp/build" prefix="$HOME/ffmpeg_build" binddir="$HOME/bin" cmakedir=".." cmakeargs="-DBUILD_SHARED_LIBS=ON"

cd ~/ffmpeg_sources
git -C drm pull 2> /dev/null || git clone -j$(nproc) https://gitlab.freedesktop.org/mesa/drm.git
buildMeson srcdir="drm" prefix="$HOME/ffmpeg_build" libdir="$HOME/ffmpeg_build/lib"

cd ~/ffmpeg_sources
git -C libxml2 pull 2> /dev/null || git clone -b v2.10.2 -j$(nproc) https://github.com/GNOME/libxml2.git
buildMake1 srcdir="libxml2" prefix="$HOME/ffmpeg_build" binddir="$HOME/bin" autogen=true

CHECK=1
SKIP=0
cd ~/ffmpeg_sources
git -C valgrind pull 2> /dev/null || git clone -j$(nproc) https://sourceware.org/git/valgrind.git
buildMake1 srcdir="valgrind" prefix="$HOME/ffmpeg_build" binddir="$HOME/bin" autogen=true

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
ffmpeg_enables+=" --enable-version3"
ffmpeg_enables+=" --enable-pic"
ffmpeg_enables+=" --enable-shared"
ffmpeg_enables+=" --enable-pthreads"
ffmpeg_enables+=" --enable-openssl"
ffmpeg_enables+=" --enable-hardcoded-tables"

if [[ "$arch" -eq "x86_64" ]]; then
  echo "x86"
elif [[ "$arch" -eq "armv7l" ]]; then
  ffmpeg_enables+=" --arch=armel"
  #Broadcom specific- AKA RPI
  ffmpeg_enables+=" --enable-mmal"
else
  echo "Unknown arch : $arch"
  exit 1
fi

cd ~/ffmpeg_sources
downloadAndExtract file=ffmpeg-snapshot.tar.bz2 path=https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2
cd ffmpeg &&
echo "*****************************"
echo "*** Configure FFmpeg      ***"
echo "*****************************"
PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure \
  --prefix="$HOME/ffmpeg_build" \
  --pkg-config-flags="--static" \
  --extra-cflags="-I$HOME/ffmpeg_build/include" \
  --extra-ldflags="-L$HOME/ffmpeg_build/lib" \
  --extra-libs="-lpthread -lm -latomic" \
  --ld="g++" \
  --bindir="$HOME/bin" \
  --target-os=linux \
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
#--enable-libopenh264
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

#LD_LIBRARY_PATH=$HOME/ffmpeg_build/lib
#LIBRARY_PATH=$HOME/ffmpeg_build/include
#PKG_CONFIG_PATH=$HOME/ffmpeg_build/lib/pkgconfig

LD_LIBRARY_PATH=$HOME/ffmpeg_build/lib PATH="$HOME/bin:$PATH" ffplay
