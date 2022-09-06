#!/usr/bin/env bash
#include build functions
CHECK=1
SKIP=0
source ./../common/buildfunc.sh

sudo apt-get update -qq && sudo apt-get -y install \
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

cd ~/ffmpeg_sources
wget http://ftp.gnu.org/gnu/automake/automake-1.16.5.tar.gz
tar xvfz automake-1.16.5.tar.gz
cd automake-1.16.5
./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin"
make -j$(nproc)
make install

cd ~/ffmpeg_sources
wget http://ftp.gnu.org/gnu/autoconf/autoconf-2.71.tar.gz
tar xvfz autoconf-2.71.tar.gz
cd autoconf-2.71
PATH="$HOME/bin:$PATH" ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" && \
make -j$(nproc) && \
make install

cd ~/ffmpeg_sources
wget https://distfiles.dereferenced.org/pkgconf/pkgconf-1.9.3.tar.gz
tar xvfz pkgconf-1.9.3.tar.gz
cd pkgconf-1.9.3
PATH="$HOME/bin:$PATH" ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" && \
make -j$(nproc) && \
make install

cd ~/ffmpeg_sources
wget https://ftp.gnu.org/gnu/m4/m4-1.4.19.tar.gz
tar xvfz m4-1.4.19.tar.gz
cd m4-1.4.19
PATH="$HOME/bin:$PATH" ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" && \
make -j$(nproc) && \
make install
#libxml2 has hardcoded reference to /usr/bin/m4
sudo ln /home/pi/bin/m4 /usr/bin/m4

cd ~/ffmpeg_sources
wget https://ftp.gnu.org/gnu/help2man/help2man-1.49.2.tar.xz
tar xf help2man-1.49.2.tar.xz
cd help2man-1.49.2
PATH="$HOME/bin:$PATH" ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" && \
make -j$(nproc) && \
make install

cd ~/ffmpeg_sources
git -C libtool pull 2> /dev/null || git clone  https://github.com/autotools-mirror/libtool.git
cd libtool
./bootstrap
PATH="$HOME/bin:$PATH" ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" && \
make -j$(nproc) && \
make install


cd ~/ffmpeg_sources && \
wget https://www.nasm.us/pub/nasm/releasebuilds/2.15.05/nasm-2.15.05.tar.bz2 && \
tar xjvf nasm-2.15.05.tar.bz2 && \
cd nasm-2.15.05 && \
./autogen.sh && \
PATH="$HOME/bin:$PATH" ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" && \
make -j$(nproc) && \
make install


cd ~/ffmpeg_sources && \
git -C x264 pull 2> /dev/null || git clone --depth 1 https://code.videolan.org/videolan/x264.git && \
cd x264 && \
PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" --enable-static --enable-pic && \
PATH="$HOME/bin:$PATH" make -j$(nproc) && \
make install

sudo apt-get install libnuma-dev && \
cd ~/ffmpeg_sources && \
wget -O x265.tar.bz2 https://bitbucket.org/multicoreware/x265_git/get/master.tar.bz2 && \
tar xjvf x265.tar.bz2 && \
cd multicoreware*/build/linux && \
PATH="$HOME/bin:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$HOME/ffmpeg_build" -DENABLE_SHARED=on ../../source && \
PATH="$HOME/bin:$PATH" make -j$(nproc) && \
make install


cd ~/ffmpeg_sources && \
git -C libvpx pull 2> /dev/null || git clone --depth 1 https://chromium.googlesource.com/webm/libvpx.git && \
cd libvpx && \
PATH="$HOME/bin:$PATH" ./configure --prefix="$HOME/ffmpeg_build" --disable-examples --enable-shared --enable-pic --disable-unit-tests --enable-vp9-highbitdepth --as=yasm && \
PATH="$HOME/bin:$PATH" make -j$(nproc) && \
make install


cd ~/ffmpeg_sources && \
git -C fdk-aac pull 2> /dev/null || git clone --depth 1 https://github.com/mstorsjo/fdk-aac && \
cd fdk-aac && \
autoreconf -fiv && \
./configure --prefix="$HOME/ffmpeg_build" --enable-pic && \
make -j$(nproc) && \
make install


cd ~/ffmpeg_sources && \
git -C opus pull 2> /dev/null || git clone --depth 1 https://github.com/xiph/opus.git && \
cd opus && \
./autogen.sh && \
./configure --prefix="$HOME/ffmpeg_build" && \
make -j$(nproc) && \
make install


cd ~/ffmpeg_sources && \
git -C aom pull 2> /dev/null || git clone --depth 1 https://aomedia.googlesource.com/aom && \
cd aom && \
mkdir -p aom_build && \
cd aom_build && \
#RPI
PATH="$HOME/bin:$PATH" cmake -G "Unix Makefiles" AOM_SRC -DENABLE_NASM=on -DCMAKE_INSTALL_PREFIX="$HOME/ffmpeg_build" -DPYTHON_EXECUTABLE="$(which python3)" -DCMAKE_C_FLAGS="-mfpu=vfp -mfloat-abi=hard" .. && \
sed -i 's/ENABLE_NEON:BOOL=ON/ENABLE_NEON:BOOL=OFF/' CMakeCache.txt && \
#x86_64
#PATH="$HOME/bin:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$HOME/ffmpeg_build" -DENABLE_TESTS=OFF -DENABLE_NASM=on ../aom && \
PATH="$HOME/bin:$PATH" make -j$(nproc) && \
make install

cd ~/ffmpeg_sources && \
git -C SVT-AV1 pull 2> /dev/null || git clone https://gitlab.com/AOMediaCodec/SVT-AV1.git && \
mkdir -p SVT-AV1/build && \
cd SVT-AV1/build && \
PATH="$HOME/bin:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$HOME/ffmpeg_build" -DCMAKE_BUILD_TYPE=Release -DBUILD_DEC=OFF -DBUILD_SHARED_LIBS=ON .. && \
PATH="$HOME/bin:$PATH" make -j$(nproc) && \
make install


cd ~/ffmpeg_sources && \
git -C dav1d pull 2> /dev/null || git clone --depth 1 https://code.videolan.org/videolan/dav1d.git && \
mkdir -p dav1d/build && \
cd dav1d/build && \
meson setup -Denable_tools=false -Denable_tests=false --default-library=static .. --prefix="$HOME/ffmpeg_build" --libdir="$HOME/ffmpeg_build/lib" && \
PATH="$HOME/bin:$PATH" ninja && \
ninja install

cd ~/ffmpeg_sources && \
wget https://github.com/Netflix/vmaf/archive/v2.1.1.tar.gz && \
tar xvf v2.1.1.tar.gz && \
mkdir -p vmaf-2.1.1/libvmaf/build &&\
cd vmaf-2.1.1/libvmaf/build && \
meson setup -Denable_tests=false -Denable_docs=false --buildtype=release --default-library=static .. --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" --libdir="$HOME/ffmpeg_build/lib" && \
ninja && \
ninja install

cd ~/ffmpeg_sources && \
git clone -b release-3.0.4 https://github.com/sekrit-twc/zimg.git && \
cd zimg && \
sh autogen.sh && \
./configure --prefix="$HOME/ffmpeg_build" && \
make -j$(nproc) && \
make install

cd ~/ffmpeg_sources && \
git clone --depth 1 https://github.com/ultravideo/kvazaar.git  && \
cd kvazaar && \
./autogen.sh && \
./configure --prefix="$HOME/ffmpeg_build" && \
make -j$(nproc) && \
make install

cd ~/ffmpeg_sources && \
git clone https://github.com/google/snappy.git && \
cd snappy && \
git submodule update --init && \
mkdir build && cd build
PATH="$HOME/bin:$PATH" cmake -DCMAKE_INSTALL_PREFIX="$HOME/ffmpeg_build" -DCMAKE_BUILD_TYPE=Release .. && \
PATH="$HOME/bin:$PATH" make -j$(nproc) && \
make install

cd ~/ffmpeg_sources && \
git clone https://github.com/chirlu/soxr.git && \
cd soxr && \
mkdir build && cd build && \
PATH="$HOME/bin:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$HOME/ffmpeg_build" -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON .. && \
PATH="$HOME/bin:$PATH" make -j$(nproc) && \
make install


cd ~/ffmpeg_sources && \
git clone --recurse-submodules -j$(nproc) https://github.com/openssl/openssl.git
cd openssl
git checkout tags/OpenSSL_1_1_1q
./config --release --prefix="$HOME/ffmpeg_build" --libdir="$HOME/ffmpeg_build/lib" --openssldir="$HOME/ffmpeg_build/ssl"
make -j$(nproc)
make -j$(nproc) install

cd ~/ffmpeg_sources && \
git clone https://git.libssh.org/projects/libssh.git && \
cd libssh && \
git checkout tags/libssh-0.10.2 && \
mkdir build && cd build && \
PATH="$HOME/bin:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$HOME/ffmpeg_build" -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON .. && \
PATH="$HOME/bin:$PATH" make -j$(nproc) && \
make install


cd ~/ffmpeg_sources && \
git clone https://github.com/webmproject/libwebp.git && \
cd libwebp && \
mkdir build && cd build && \
PATH="$HOME/bin:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$HOME/ffmpeg_build" -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON .. && \
PATH="$HOME/bin:$PATH" make -j$(nproc) && \
make install

cd ~/ffmpeg_sources && \
git clone https://gitlab.freedesktop.org/mesa/drm.git && \
cd drm && \
meson setup --prefix="$HOME/ffmpeg_build" --libdir="$HOME/ffmpeg_build/lib" build && \
PATH="$HOME/bin:$PATH" ninja && \
ninja install -C build

cd ~/ffmpeg_sources && \
git clone https://github.com/GNOME/libxml2.git && \
cd libxml2 && \
git checkout tags/v2.10.3
PATH="$HOME/bin:$PATH" ./autogen.sh
PATH="$HOME/bin:$PATH" ./configure --prefix="$HOME/ffmpeg_build" --with-python=off && \
make -j$(nproc) && \
make install

sudo ldconfig

cd ~/ffmpeg_sources && \
wget -O ffmpeg-snapshot.tar.bz2 https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2 && \
tar xjvf ffmpeg-snapshot.tar.bz2 && \
cd ffmpeg &&
PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure \
  --prefix="$HOME/ffmpeg_build" \
  --pkg-config-flags="--static" \
  --extra-cflags="-I$HOME/ffmpeg_build/include" \
  --extra-ldflags="-L$HOME/ffmpeg_build/lib" \
  --extra-libs="-lpthread -lm -latomic" \
  --ld="g++" \
  --bindir="$HOME/bin" \
  --arch=armel \
  --enable-gmp \
  --enable-gpl \
  --enable-libaom \
  --enable-libass \
  --enable-libdav1d \
  --enable-libdrm \
  --enable-libfdk-aac \
  --enable-libfreetype \
  --enable-libkvazaar \
  --enable-libmp3lame \
  --enable-libopus \
  --enable-libsnappy \
  --enable-libsoxr \
  --enable-libssh \
  --enable-libsvtav1 \
  --enable-libvorbis \
  --enable-libvpx \
  --enable-libwebp \
  --enable-libzimg \
  --enable-libx264 \
  --enable-libx265 \
  --enable-libxml2 \
  --enable-mmal \
  --enable-nonfree \
  --enable-version3 \
  --enable-pic \
  --enable-shared \
  --target-os=linux \
  --enable-pthreads \
  --enable-openssl \
  --enable-hardcoded-tables && \
PATH="$HOME/bin:$PATH" make -j$(nproc) && \
make install && \
hash -r

#LD_LIBRARY_PATH=$HOME/ffmpeg_build/lib
#LIBRARY_PATH=$HOME/ffmpeg_build/include
#PKG_CONFIG_PATH