#!/usr/bin/env bash
#include build functions
PREFIX="$HOME/ffmpeg_build"
CHECK=1
SKIP=0
source $(dirname "$0")/../common/buildfunc.sh

arch=$(echo $(uname -a) | awk '{print $12}')
echo "*****************************"
echo "*** Architecture $arch ***"
echo "*****************************"

#python3-gi python3-gi-cairo
sudo apt install python3-pip gir1.2-gtk-3.0 make flex bison
#Custom dependencie by glib-networking where custom build location  is not picked up
#sudo apt install libssl-dev

sudo python3 -m pip install --upgrade pip
sudo python3 -m pip install meson
sudo python3 -m pip install cmake
sudo python3 -m pip install ninja
sudo python3 -m pip install nasm
sudo python3 -m pip install gi
sudo python3 -m pip install pycairo

#Incompabible with apt version
#sudo apt remove libglib2.0-dev

#buildNinja "tinyalsa" "tinyalsa"

echo "*****************************"
echo "*** Pull/Clone Gstreamer MonoRepo ***"
echo "*****************************"
cd /tmp
git -C gstreamer pull origin tags/1.20.3 2> /dev/null || git clone -b 1.20.3 https://gitlab.freedesktop.org/gstreamer/gstreamer.git
cd gstreamer


# cd /tmp && \
# git -C libass pull 2> /dev/null || git clone --depth 1 https://github.com/libass/libass.git && \
# cd libass && \
# ./autogen.sh && \
# ./configure --prefix="$HOME/ffmpeg_build" && \
# make -j$(nproc) && \
# make install

echo "*****************************"
echo "*** Patch PyObject glib 2.73.0 ***"
echo "*****************************"
sed -i 's/revision=glib-2-70/revision=2.73.3/' ./subprojects/glib.wrap


gst_enables="--prefix=$PREFIX"
gst_enables+=" -Dlibnice=enabled"
gst_enables+=" -Dbuildtype=release"
gst_enables+=' -Dpackage-origin="GitlabMonoRepo"'
gst_enables+=" --libdir=$HOME/ffmpeg_build/lib"
if [[ "$arch" == "armv7l" ]]; then
    echo "arch is arm : $arch"
    gst_enables+=" -Domx=enabled"
    #TODO Validate rpi board
    gst_enables+=" -Dgst-omx:target=rpi"
    gst_enables+=" -Dgst-omx:header_path=/opt/vc/include/IL"
fi

echo "*****************************"
echo "*** reset build ***"
echo "*****************************"
#sudo rm -rf build
echo "*****************************"
echo "*** Meson Setup : $gst_enables ***"
echo "*** Purpose : Download Wrap Projects ***"
echo "*****************************"
#Initiate meson setup. Expecting failure by goobject-introspection.wrap
PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" \
    C_INCLUDE_PATH="$HOME/ffmpeg_build/include" \
    LIBRARY_PATH="$HOME/ffmpeg_build/include" \
    PATH="$HOME/bin:$PATH" \
    meson setup $gst_enables build

checkWithUser

echo "*****************************"
echo "*** Patch gobject-introspection.wrap revision master->main ***"
echo "*****************************"
sed -i 's/revision=master/revision=main/' ./subprojects/pygobject/subprojects/gobject-introspection.wrap
sed -i 's/revision=master/revision=main/' ./subprojects/pango/subprojects/gobject-introspection.wrap

echo "*****************************"
echo "*** Meson Setup : $gst_enables ***"
echo "*** Purpose : Reinitialized patched wrap file ***"
echo "*****************************"
#Reinitialize setup with patched gobject-introspection.wrap 
PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" \
    C_INCLUDE_PATH="$HOME/ffmpeg_build/include" \
    LIBRARY_PATH="$HOME/ffmpeg_build/include" \
    PATH="$HOME/bin:$PATH" \
    meson setup $gst_enables --reconfigure build

echo "*****************************"
echo "*** Compile ***"
echo "*****************************" 
checkWithUser
PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" \
    C_INCLUDE_PATH="$HOME/ffmpeg_build/include" \
    LIBRARY_PATH="$HOME/ffmpeg_build/include" \
    PATH="$HOME/bin:$PATH" \
    ninja -C build

echo "*****************************"
echo "*** Install ***"
echo "*** First compile. (Missing self dependencies) ***"
echo "*****************************"
#install first set of dependencies
meson install -C build
checkWithUser

echo "*****************************"
echo "*** Meson Setup : $gst_enables ***"
echo "*** Purpose : Reinitialized with self dependencies ***"
echo "*****************************"
#reconfigure to discover self dependencies
PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" \
    C_INCLUDE_PATH="$HOME/ffmpeg_build/include" \
    LIBRARY_PATH="$HOME/ffmpeg_build/include" \
    PATH="$HOME/bin:$PATH" \
    meson $gst_enables --reconfigure build
checkWithUser

echo "*****************************"
echo "*** Compile ***"
echo "*****************************" 
PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" \
    C_INCLUDE_PATH="$HOME/ffmpeg_build/include" \
    LIBRARY_PATH=$HOME/ffmpeg_build/include \
    PATH="$HOME/bin:$PATH" \
    ninja -C build
checkWithUser

echo "*****************************"
echo "*** Full Install ***"
echo "*****************************"
meson install -C build
checkWithUser


echo "*****************************"
echo "*** Copy typelib file in path ***"
echo "*** TODO Handle this better ***"
echo "*****************************"
#Armbian jammy rockpro64
#sudo cp /usr/local/lib/aarch64-linux-gnu/girepository-1.0/Gst* /usr/lib/aarch64-linux-gnu/girepository-1.0/
#x86_64
#sudo cp /usr/local/lib/x86_64-linux-gnu/girepository-1.0/* /usr/lib/x86_64-linux-gnu/girepository-1.0/
#Raspbian
#sudo cp /usr/local/lib/arm-linux-gnueabihf/girepository-1.0/Gst* /usr/lib/arm-linux-gnueabihf/girepository-1.0/


##run Gstreamer portably* and force reload plugins
sudo rm -rf /home/pi/.cache/gstreamer-1.0/registry.armv7l.bin
PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" \
    C_INCLUDE_PATH="$HOME/ffmpeg_build/include" \
    LIBRARY_PATH="$HOME/ffmpeg_build/include" \
    PATH="$HOME/bin:$PATH" \
    $PREFIX/bin/gst-launch-1.0 --version